# Rules: Documentation

Note the inversion if you also work in `livecircle-web-api`: **that repo bans doc annotations;
this one requires them on its public surface.** xcribe publishes to Hex and its docs to
HexDocs, so the public modules' docs *are* the product. What makes a module public:
[public-api.md](public-api.md).

- **A real `@moduledoc` goes on public modules only** — writing one is what makes a module
  public. Every other module —
  including every new one — gets `@moduledoc false`. `Xcribe.Config`'s `@moduledoc` is the
  user-facing config reference: a new config key gets a `###` section there — what it means, the
  values it accepts, the behaviour of each — and its name joins the list in `Xcribe`'s
  `## Configuration`, or it is undocumented (see [config.md](config.md)).
- An internal module **may** carry `@doc` strings on its functions as developer notes, and
  several do. They are never published — ex_doc hides the module.
- **No `@spec`, `@type`, `@opaque`, `@behaviour`, `@impl`, `@callback`, `defprotocol`, or
  `defimpl`.** `lib/` contains none of them, and `Credo.Check.Readability.Specs` is `false` in
  `.credo.exs`. Behaviours arrive only through `use GenServer` / `use Application` /
  `use Plug.Router` / `use Mix.Task`, always **without** `@impl`.
- **`iex>` blocks inside a `@doc` are illustrative, not executed** — there are no doctests
  anywhere in `test/`, and at least one existing example is stale. Never add `doctest Module`
  expecting the existing examples to pass; if you want one verified, write a real test.
- **The code must describe itself.** Function names, argument names, and pattern-matched heads
  are the documentation. If a comment feels necessary to explain *what* a line does, rename or
  restructure instead.
- **A `#` comment is reserved for genuinely non-obvious *why*** — a hidden invariant, a
  workaround, a deliberate deviation. When one is warranted here it is a full multi-sentence
  explanation, not a fragment; the existing ones in `mix.exs`, the CI workflow and the release
  scripts are the model.
- **Never leave a `TODO`.** `Credo.Check.Design.TagTODO` runs with `exit_status: 2`, so a TODO
  fails `mix credo` and therefore CI.
- User-facing documentation is `README.md` (ex_doc's `main`) and
  `documentation/serving_doc.md`; both are wired into `docs()` in `mix.exs`. **A change a
  consumer can observe updates one of them** as well as `CHANGELOG.md`.

> This overrides any generic Elixir convention that requires typespecs or `@impl` annotations.
> This repo intentionally ships none.
