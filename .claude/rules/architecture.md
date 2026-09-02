# Rules: Architecture

Closed decisions. Two entry points, one pipeline, and a fixed shape for every output format.
Error *shapes* live in [errors.md](errors.md); config threading in [config.md](config.md).

- **Two entry points, one pipeline.** `Xcribe.Document.document/2` (a macro imported into the
  consumer's `ConnCase`) records requests into `Xcribe.Recorder`; the documents are then
  generated either by `Xcribe.Formatter` (an ExUnit formatter, on suite end) or by
  `Mix.Tasks.Xcribe.Doc`. Both funnel into `Xcribe.document_all_records/1`.
- `Xcribe.document_all_records/1` (`lib/xcribe.ex`) is the whole flow, readable top to bottom:

      get_records_with_endpoint()
      |> fetch_config(override_func)
      |> generate()
      |> handle_result()

  A new stage is a new step in that pipe with its own short-circuit clause — **never** a
  branch hidden inside an existing stage.
- **`Xcribe.ConnParser.execute/2` is the only place a `Plug.Conn` becomes an
  `%Xcribe.Request{}`**, and `Xcribe.Request.Validator.validate/1` is the only gate a request
  passes before it reaches a formatter. Nothing downstream re-reads the `conn`.
- **`Xcribe.APIModel.build/3` is the only place a list of `%Xcribe.Request{}` becomes the
  documented API**, and no format ever sees a `%Request{}`. It groups the requests by path and
  verb, merges their parameters and schemas, keeps every recorded request as an
  `%Xcribe.APIModel.Example{}`, and applies the specification's ignored prefixes on the way in.
  A format reads the model and translates; it never regroups requests of its own.
- **`Xcribe.Specification.api_specification/1` is the only reader of the `.xcribe.exs` file's
  contents**, the way `Xcribe.Config` is the only reader of `Application.get_env`. (`Xcribe.Config`
  stats the path to validate it exists, and reports a missing one as a configuration error with
  instructions — it never reads it.) It normalizes the file into a map
  with every key defaulted; every other module receives that map and pattern-matches the keys it
  needs. `Xcribe.document/2` calls it once, in `build_api_model/2`, and passes the map on to the
  format orchestrator alongside the model.
- **`Xcribe.Writter` is the only module that touches the filesystem** and
  **`Xcribe.CLI.Output` is the only module that prints.** Every other module returns data and
  lets those two act. No `IO.puts`, no `File.write`, no `Logger` anywhere else in `lib/`.
- Recording is **opt-in and inert by default**: `Xcribe.Config.active?/0` reads
  `XCRIBE_ENV` (`"1"`, `"true"`, `"TRUE"`) and `Xcribe.Recorder` carries an active flag.
  A consumer who merely adds the dependency must see no behaviour change — **never** make
  recording unconditional or start doing work at compile time.

## Adding or changing an output format

- **A format is always three modules**, and they never collapse into each other:

      Xcribe.OpenAPI        / Xcribe.ApiBlueprint          # orchestrator: generate_doc/3
      Xcribe.OpenAPI.Formatter / Xcribe.ApiBlueprint.Formatter  # builds intermediate maps/objects
      Xcribe.JSON              / Xcribe.ApiBlueprint.APIB       # encodes to the final binary

- The orchestrator only reduces the API model's operations through the formatter and hands the
  result to the encoder — it **never** builds intermediate structures itself, and the formatter
  **never** encodes.
- The orchestrator is where an operation-level failure is wrapped:
  `raise DocException, {List.first(operation.examples), exception, __STACKTRACE__}`. The example
  is the wrap subject because `DocException.exception/1` needs only a `__meta__` and an example
  carries the one of the `document/2` call that recorded it (see [errors.md](errors.md)).
  A failure while *building* the model is wrapped inside `Xcribe.APIModel`, per request.
- A new format needs a clause in `Xcribe.Config`'s `format` validation, a default `output:`
  filename, a bullet in `Xcribe`'s `@moduledoc`, and a golden file under `test/support`
  (see [output.md](output.md)). Adding one is a **minor** version bump.
