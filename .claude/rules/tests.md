# Rules: Tests

Apply to every test we write or refactor. Code and its tests ship **together** in the same
change — never defer tests. Coverage is reported to Codecov by CI.

## Layout

- **`test/` mirrors `lib/` exactly**, with a `_test.exs` suffix and the module named after its
  subject plus `Test` — `lib/xcribe/conn_parser.ex` → `test/xcribe/conn_parser_test.exs` →
  `Xcribe.ConnParserTest`. Every module in `lib/` has a matching test file.
- `test/test_helper.exs` is one line (`ExUnit.start()`). Keep it that way — no global setup, no
  `Mimic.copy`, no config mutation.
- Support code lives in `test/support`, compiled only in `:test` via `elixirc_paths(:test)`, and
  is excluded from credo and from coverage (`coveralls.json`). It is still English-only,
  formatted code, and it is **not** public API ([public-api.md](public-api.md)).
- Infrastructure fakes are named bare `Xcribe.*` (`Xcribe.Endpoint`, `Xcribe.WebRouter`,
  `Xcribe.ConnCase`, `Xcribe.UsersController`); data builders and helpers are `Xcribe.Support.*`
  (`Xcribe.Support.RequestsGenerator`).

## Structure

- **`async:` is always explicit.** `async: true` is the default; use `async: false` for anything
  touching global state — `Application` env, the `Xcribe.Recorder` GenServer, captured IO, or
  the filesystem. `config_test`, `formatter_test`, `recorder_test`, `document_test`,
  `tasks/doc_test` and `web/plug_test` are all `async: false` for those reasons.
- Conn-based tests `use Xcribe.ConnCase` (an `ExUnit.CaseTemplate` that wires `Xcribe.Endpoint`,
  `Xcribe.WebRouter.Helpers` and a `build_conn/0` setup), not `ExUnit.Case`.
- **One `describe` block per function, named `"fun/arity"`** — `describe "execute/2"`,
  `describe "merge_path_item_objects/3"`. Not a behavioural phrase.
- Test names are lowercase declarative sentences with no "should" —
  `test "return true when env var is 1"`, `test "extract request data from an index request"`.
- Every test asserts or refutes at least once.

## Fixtures and injection

- **There is no mocking library** — no mox, no Mimic, no meck. Do not add one. Two substitutes:
  - **Inline `defmodule Fake*` modules at the top of the test file** — `FakeEndpoint`,
    `FakeProject`, `FakeProjectNonUmbrella`. Each implements only the
    function the code under test reflects on.
  - **Pass a function into an injected argument** (see [control-flow.md](control-flow.md)):

        mix_test_fun = fn opts -> send(self(), {:ran, opts}) && Recorder.add(request) end
        Doc.run_task([], mix_test_fun, FakeProjectNonUmbrella)

- **Request fixtures come from `Xcribe.Support.RequestsGenerator`** — one function per route in
  `Xcribe.WebRouter` (`users_index/1`, `users_posts_update/1`). A new route case means a new
  route in `Xcribe.WebRouter` **and** a new generator function, not a hand-built `%Request{}`.
- **Config in tests is `Application.put_env(:xcribe, <Endpoint>, ...)`, always torn down.** The
  canonical `on_exit` wipes everything so a leak can't reach another test file:

      on_exit(fn ->
        :xcribe |> Application.get_all_env() |> Keyword.keys()
        |> Enum.each(&Application.delete_env(:xcribe, &1))

        System.delete_env("XCRIBE_ENV")
      end)

- Recorder state is `Recorder.set_active(true)` / `Recorder.pop_all()` in `setup` and
  `Recorder.set_active(false)` in `on_exit`.

## Assertions

- **Assert the whole struct or the whole map, every field spelled out** —
  `assert ConnParser.execute(conn) == %Request{verb: "get", path: "/users", ...}`. Not
  field-by-field, not partial-key.
- Use `assert pattern = call()` (with pins for known values) only when you need to extract a
  dynamic value: `assert %{description: ^test_name, __meta__: ^meta} = Recorder.pop_all()`.
- **Large expected payloads move out of the test body** — to a module under
  `test/support/samples/**` returning the map, or to the golden files
  `test/support/swagger_example.json` / `api_blueprint_example.apib`. A golden-file change is a
  behaviour change ([output.md](output.md)).
- CLI output is tested with `import ExUnit.CaptureIO`, `capture_io(fn -> ... end)` and `=~`.
- **No doctests** — `iex>` examples in `@doc` are decorative ([docs.md](docs.md)).
