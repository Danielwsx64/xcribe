# Rules: Errors

Which idiom a failure uses is decided by **who is at fault**. Printing belongs to
`Xcribe.CLI.Output` alone (see [architecture.md](architecture.md)); config validation shape is
in [config.md](config.md).

## The three idioms

- **The consumer misconfigured xcribe** → accumulate `{key, value, message, instructions}`
  4-tuples and return `{:error, list}`. Never raise, never log. See [config.md](config.md).
- **A request could not be parsed or validated** → an `%Xcribe.Request.Error{}` struct, not an
  exception. `type` is one of `[:parsing, :validation, :exception]`. Build it from the module's
  template attribute so the type is set in one place:

      @error_struct %Error{type: :parsing}

      %{@error_struct | message: "An invalid Plug.Conn was given or maybe an invalid Router"}

  **Never drop `__meta__`.** It carries `%{call: %{description:, file:, line:}}` from the
  `document/2` call site, which is the only way `Xcribe.CLI.Output` can point the user at the
  failing line in *their* test file.
- **The consumer's `.xcribe.exs` cannot be read** → raise `Xcribe.SpecificationFile`. This is the
  one place a *consumer* mistake raises rather than returning a tuple, because the specification
  file is read from deep inside a format orchestrator, after config validation has already passed.
  `Xcribe.document/2` rescues it and `Xcribe.CLI.Output.print_specification_error/1` prints it, so
  the consumer still sees an error box rather than a stacktrace.
- **A bug — in xcribe, or in the consumer's doc code** → raise, and wrap it at the format
  orchestrator boundary so the offending request travels with the exception:

      rescue
        exception -> raise DocException, {request, exception, __STACKTRACE__}

  `Xcribe.document/2` then has a function-level `rescue e in DocException -> {:error, e}`, so a
  single bad request fails the doc generation with a useful report instead of a bare stacktrace.

## Rescuing

- **Every `rescue` enumerates the exceptions it expects.** A bare `rescue exception ->` is
  allowed *only* at the wrap-into-`DocException` boundary above:

      # do — in ConnParser, around the reflective Phoenix route lookup
      rescue
        _e in [UndefinedFunctionError, FunctionClauseError, KeyError, BadMapError] ->

      # not — hides an upstream signature change as a generic parsing error
      rescue
        _e ->

  This is not hypothetical: a broad rescue is exactly what turned the Phoenix 1.8
  `__match_route__/3` argument swap into a silent "couldn't parse" for every request. See
  [dependencies.md](dependencies.md).
- `lib/` contains six `rescue` blocks. Adding a seventh needs a reason; converting one to a
  catch-all needs a very good one.

## Exceptions and reporting

- **New exceptions go in `lib/xcribe/exceptions.ex`**, `@moduledoc false`, with `defexception`
  plus a custom `exception/1` that takes a **non-keyword** argument
  (`def exception({request, exception, stacktrace})`). Names need no `Error` suffix —
  `Credo.Check.Consistency.ExceptionNames` is disabled for exactly this.
- **`Xcribe.CLI.Output` is the only printer**, and `handle_result/1` in `lib/xcribe.ex` is the
  only dispatcher: it pattern-matches the error *shape* to pick the printer
  (`print_doc_exception/1`, `print_request_errors/1`, `print_configuration_errors/1`,
  `print_file_errors/1`) and returns a bare `:ok | :error`. A new error shape adds a clause
  there and a printer there — nowhere else.
- **A failing Mix task exits with `exit({:shutdown, 1})`** — never `System.halt/1`, which would
  kill the consumer's VM mid-suite and skip ExUnit's own reporting.
- Public functions signal expected failure with tagged tuples. **Never** return a bare `nil` or
  `false` to mean failure.
