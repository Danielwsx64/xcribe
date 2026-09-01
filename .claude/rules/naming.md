# Rules: Naming

- **Filename and module name must agree** — enforced by
  `CredoNaming.Check.Consistency.ModuleFilename`, with `lib/mix/tasks` excluded because the Mix
  task naming convention wins there (`lib/mix/tasks/xcribe.doc.ex` → `Mix.Tasks.Xcribe.Doc`).
- **A namespace root lives at `lib/xcribe/<ns>/<ns>.ex`**, inside the directory it names:

      lib/xcribe/request/request.ex             -> Xcribe.Request
      lib/xcribe/swagger/swagger.ex             -> Xcribe.Swagger
      lib/xcribe/api_blueprint/api_blueprint.ex -> Xcribe.ApiBlueprint

  **Not** `lib/xcribe/swagger.ex`. Sub-namespaces mirror directories exactly (`CLI`, `Web`,
  `Helpers`, `Request`, `Tasks`, `ApiBlueprint`, `Swagger`).
- **Multi-alias braces are the house style** — `alias Xcribe.{ConnParser, Recorder}` — and the
  list is **alphabetical** (`Credo.Check.Readability.AliasOrder` is on;
  `Consistency.MultiAliasImportRequireUse` is off). `import` is always scoped:
  `import Xcribe.Helpers.Formatter, only: [content_type: 1, authorization: 1]`.
- **Alias anything you fully-qualify more than once.** `Credo.Check.Design.AliasUsage` runs with
  `if_called_more_often_than: 0` and `if_nested_deeper_than: 2`.
- Predicate functions end in `?` and do **not** start with `is_` (`active?/0`, not
  `is_active/0`); `is_` is reserved for guards. Functions that raise end in `!` (`encode!/3`).
- Modules are `CamelCase`; functions and variables `snake_case`. **No abbreviated names** —
  `request`, not `req`; `config`, not `cfg`. Single-letter bindings only in a pipeline's
  anonymous function.
- **`Xcribe.Writter` is misspelled.** It is `@moduledoc false`, but it is referenced across the
  codebase and by anyone who has read the source. **Do not rename it in a patch release** — a
  rename is a change to be batched into a major bump with the rest, not a drive-by cleanup.
  The same applies to `test/support/samples/swagger_formater/`.
- **Never nest two modules in one file** — with one deliberate exception,
  `lib/xcribe/exceptions.ex`, which holds every custom exception (see [errors.md](errors.md)).
  Don't add a second exception to that rule.
