Xcribe is a published Hex library (`~> 1.0`, Apache-2.0) that generates API Blueprint and OpenAPI 3.0 documentation from the `Plug.Conn` structs a Phoenix app's ExUnit suite produces. Other people's applications depend on it, so **every change is a public contract change until proven otherwise** — there is no "just refactor it" here.

## Public API — treat as a contract

Seven modules are public surface: `Xcribe`, `Xcribe.Document`, `Xcribe.Specification`, `Xcribe.Formatter`, `Xcribe.Web.Plug`, `Mix.Tasks.Xcribe.Doc`, `Mix.Tasks.Xcribe.Gen.Spec`. Also public by contract: the config keys documented in `Xcribe`'s `@moduledoc`, the keys of the `.xcribe.exs` specification file, the `document/1,2` entries exported through `.formatter.exs` `locals_without_parens`, and the shape of the generated `.apib`/JSON output. **Everything else is `@moduledoc false` and free to change.** Full rule: `.claude/rules/public-api.md`.

## After any change

Run `mix precommit` (alias: `compile --warnings-as-errors`, `format`, `credo`, `test`). Resolve every issue before declaring the work done. Then add a why-focused entry under `## [Unreleased]` in `CHANGELOG.md` — CI's `mix_check_version` job fails any PR to `master` whose version was not bumped past the newest release on hex.pm, and merging to `master` publishes to Hex automatically.

## Comments and docs

A real `@moduledoc` goes on the seven public modules **only**; every new internal module gets `@moduledoc false`. **No `@spec`, `@type`, `@behaviour`, `@impl`, or protocols** — `lib/` contains zero of each and `Credo.Check.Readability.Specs` is `false` in `.credo.exs`. **Do not write comments that narrate *what* the code does** — function and argument names are the documentation. A `#` comment is allowed only for genuinely non-obvious *why*: a hidden invariant, a workaround, a deliberate deviation. Full rule and rationale: `.claude/rules/docs.md`.

## English only

All code, comments, docstrings, test descriptions, CHANGELOG entries, and commit/PR messages are in **English. No exceptions** — translate domain terms instead of transliterating them. `guide.md` at the repo root is a stale Portuguese scratch note, not a guide; do not extend it or cite it.

## Commit messages and PRs

Commit messages MUST be a single line: capitalized imperative subject stating the change and the *why* (`Handle umbrella apps path`). The old `fix:`/`chg:` prefixes are abandoned — do not reintroduce them. PR bodies follow `.github/PULL_REQUEST_TEMPLATE.md` (Motivation / Proposed solution) and stay high-level: what changes for a consumer and why, not a walkthrough of the diff. Patches target `master`; features target the current release branch (`release-X.Y.Z`).

## Agents — binding workflow

This repo's conventions are enforced by project agents in `.claude/agents/`. **This is not optional tooling.** Do **not** use the `elixir-tooling` plugin agents (`elixir-architect`, `elixir-qa`, `elixir-backend`) here — they demand `@spec`/`@doc` annotations this library deliberately does not carry.

- **`plan-builder` — invoke BEFORE drafting any plan** for a change that adds or alters an output format, changes the request pipeline (`Xcribe.ConnParser`, `Xcribe.Request`, `Xcribe.Request.Validator`, `Xcribe.Recorder`), adds or changes a config key, alters the generated output, or touches any of the seven public modules. Skip only for typo fixes, formatting, renames of private helpers, and doc-only edits.
- **`code-reviewer` — invoke AFTER writing or modifying ANY Elixir code**, before declaring the work done. Pass it the changed files. Resolve every issue it raises, or justify the exception, before finishing.

### Choosing the model when invoking an agent

A subagent can't switch its own model mid-run, so the **main session picks the model at invocation time** (`model:` override) based on the change surface:

- **`plan-builder`** — default `opus` (planning is architecture and contract reasoning). Drop to `sonnet` only for a small, well-understood change.
- **`code-reviewer`** — default `sonnet` (well-scoped rule matching). Escalate to `opus` when the diff touches the **public API, `Xcribe.Recorder`/GenServer state, or the generated-output path**.

## Rules index

The full conventions live as focused files in `.claude/rules/`. The agents load only the files relevant to a change; when you write Elixir directly, read the matching files first.

- `architecture.md` — the two entry points and one pipeline; the three-module shape of an output format; which module is allowed to write files and print.
- `public-api.md` — the seven public modules, `@moduledoc false` as the default, `@doc false`, what counts as a breaking change.
- `config.md` — endpoint-scoped config, `Xcribe.Config` as the only reader of `Application.get_env`, adding a key, validation shape.
- `errors.md` — the three error idioms chosen by who is at fault; narrow `rescue`; the `Xcribe.CLI.Output` funnel; `exit({:shutdown, 1})`.
- `control-flow.md` — pipe into private multi-clause dispatchers, `Enum.reduce_while`, guard and struct-pattern dispatch, `with`, injection over mocks.
- `naming.md` — module/filename agreement, namespace-root files, alias style, predicate and raising suffixes, the `Writter` spelling.
- `dependencies.md` — `:plug` is the only runtime dep, Phoenix reached reflectively, version floors, the five places a support-matrix change must land.
- `output.md` — generated documents must be byte-stable; stringified keys, explicit sorting, the golden files.
- `docs.md` — the `@moduledoc` policy, no typespecs, `iex>` is decorative, no `TODO`, which user-facing docs to update.
- `tests.md` — path-mirrored layout, explicit `async:`, `describe "fun/arity"`, no mocking library, `Application.put_env` teardown, whole-value assertions.
- `release.md` — the CHANGELOG entry, `make release`, SemVer against the public API, the auto-publish and version-check gates, branch flow.
