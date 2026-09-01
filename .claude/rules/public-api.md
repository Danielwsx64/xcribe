# Rules: Public API

Xcribe is consumed by other people's applications. This file defines what they are allowed to
depend on. Version consequences live in [release.md](release.md).

- **Seven modules are public surface**, and they are the only ones:

      Xcribe                     # config reference (its @moduledoc IS the user-facing config doc)
      Xcribe.Document            # the document/1,2 macro imported into the consumer's ConnCase
      Xcribe.Specification       # the `.xcribe.exs` file format (its @moduledoc IS that reference)
      Xcribe.Formatter           # the ExUnit formatter a consumer adds to ExUnit.configure/1
      Xcribe.Web.Plug            # serving the generated Swagger doc
      Mix.Tasks.Xcribe.Doc       # the `mix xcribe.doc` task and its CLI options
      Mix.Tasks.Xcribe.Gen.Spec  # the `mix xcribe.gen.spec` task and its `--output` option

- **Public by contract, though not a module**: every config key documented in `Xcribe`'s
  `@moduledoc`, every top-level key of the `.xcribe.exs` specification file documented in
  `Xcribe.Specification`'s `@moduledoc`, the `document: 1, document: 2` entries in
  `.formatter.exs`'s `export: [locals_without_parens: ...]`, and the shape of the generated
  `.apib`/JSON output (see [output.md](output.md)).
- **`@moduledoc false` is the default for a new module.** Writing a real `@moduledoc` is a
  decision to support that module forever — take it deliberately, not by habit. Most of the
  modules in `lib/` are `@moduledoc false`; a new internal module joins them.
- An internal (`@moduledoc false`) module **may** still carry `@doc` strings on its functions
  as developer notes — `Xcribe.JSON`, `Xcribe.Swagger.Formatter`, `Xcribe.JsonSchema` and
  `Xcribe.Helpers.Formatter` do. Those docs are not published; ex_doc hides the module.
- **`@doc false` on functions that must be public for an internal caller but are not API** —
  `Xcribe.document_all_records/1`, `Xcribe.document/2`, `__using__/1`, `__before_compile__/1`,
  `Plug.init/1`, `Plug.call/2`, `Mix.Task.run/1`.
- **Breaking any of the following is a major-version change**: a documented config key, the
  `document/2` signature or its `as:`/`schema:`/`req_schema:`/`tags:` options, a documented
  `.xcribe.exs` key, the
  `Xcribe.Formatter` or `Xcribe.Web.Plug` interface, `mix xcribe.doc`'s options, or the
  generated output shape. **Prefer an additive config key with a default** in `Xcribe.Config`
  over changing an existing one (see [config.md](config.md)).
- **Renaming `document/2` breaks consumers' `mix format`**, not just their tests — they
  `import_deps: [:xcribe]` and inherit the exported `locals_without_parens`. Treat the name as
  frozen.
- Test-support modules are compiled only in `:test` (`elixirc_paths(:test)`) and are **not**
  public API even though they sit under `Xcribe.*` — `Xcribe.ConnCase`, `Xcribe.Endpoint`,
  `Xcribe.WebRouter`, `Xcribe.Support.*`. Never tell a consumer to use one.
