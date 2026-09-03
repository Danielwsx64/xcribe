# Rules: Public API

Xcribe is consumed by other people's applications. This file defines what they are allowed to
depend on. Version consequences live in [release.md](release.md).

- **A module is public surface exactly when it carries a real `@moduledoc`.** That is the whole
  test, and it needs no list: ex_doc publishes every module that has one and hides every module
  with `@moduledoc false`, so the published documentation *is* the inventory, and
  `groups_for_modules` in `mix.exs` is where the current set is declared. Run `mix docs` if you
  need to know what is in it.
- **The kinds of thing that are public**, so you can tell whether a new module belongs there: the
  entry-point module and the macro a consumer imports into their `ConnCase`, the configuration
  reference, the specification-file reference, the ExUnit formatter a consumer adds to
  `ExUnit.configure/1`, the plug that serves the generated document, and every `mix xcribe.*`
  task. Everything else — parsing, the API model, the formats, encoding, recording, printing,
  writing — is internal.
- **Inside a public module, only functions with a real `@doc` are public.** A public module is
  not a licence over everything it exports: the `@doc false` functions exist for internal
  callers, and so does any part of a data structure the docs do not describe.
- **Public by contract, though not a module**: every config key documented in `Xcribe.Config`'s
  `@moduledoc`, every top-level key of the `.xcribe.exs` specification file documented in
  `Xcribe.Specification`'s `@moduledoc`, the `document: 1, document: 2` entries in
  `.formatter.exs`'s `export: [locals_without_parens: ...]`, and the shape of the generated
  `.apib`/JSON output (see [output.md](output.md)).
- **`@moduledoc false` is the default for a new module.** Writing a real `@moduledoc` is a
  decision to support that module forever — take it deliberately, not by habit. Most of the
  modules in `lib/` are `@moduledoc false`; a new internal module joins them.
- An internal (`@moduledoc false`) module **may** still carry `@doc` strings on its functions
  as developer notes, and several do. Those docs are not published; ex_doc hides the module.
- **`@doc false` on functions that must be public for an internal caller but are not API** —
  every callback a `use` forces you to export (`run/1` of a Mix task, `init/1` and `call/2` of a
  plug, `__using__/1`), every injection seam a test needs to reach, and every entry point one of
  our own modules calls across a namespace.
- **Breaking any of the following is a major-version change**: a documented config key, the
  `document/2` signature or any of its documented options, a documented `.xcribe.exs` key, the
  interface of a public module, the options of a Mix task, or the generated output shape.
  **Prefer an additive config key with a default** over changing an existing one
  (see [config.md](config.md)).
- **Renaming `document/2` breaks consumers' `mix format`**, not just their tests — they
  `import_deps: [:xcribe]` and inherit the exported `locals_without_parens`. Treat the name as
  frozen.
- Test-support modules are compiled only in `:test` (`elixirc_paths(:test)`) and are **not**
  public API even though they sit under `Xcribe.*`. Never tell a consumer to use one.
