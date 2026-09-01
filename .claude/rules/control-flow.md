# Rules: Control Flow

- **The dominant shape is a pipe into private multi-clause dispatchers**, not `if`/`case` in a
  function body. Each stage takes the previous stage's tagged tuple, and each has a
  short-circuit clause so a failure falls through untouched:

      def document_all_records(override_func \\ nil) do
        get_records_with_endpoint()
        |> fetch_config(override_func)
        |> generate()
        |> handle_result()
      end

      defp fetch_config({:ok, recorded}, override_func), do: # ...
      defp fetch_config(error, _function), do: error

  A new step in a flow is a new stage in the pipe with its own pass-through clause — **never**
  an `if` nested inside an existing stage.
- **`Enum.reduce_while` with `{:cont, _}` / `{:halt, _}` is the early-exit tool.** Use it to
  stop at the first configuration error or first failing endpoint instead of collecting work
  that will be thrown away.
- **`|> case do ... end` is the accepted way to branch at the end of a pipe** (see
  `Xcribe.fetch_config/2`, `Xcribe.Information.fetch_information/3`). Don't bind an intermediate
  variable just to run a `case` on it.
- **Pipes may start from a plain value and may have a single step.**
  `:xcribe |> Application.get_env(endpoint, []) |> apply_default_values()` is house style;
  `Credo.Check.Refactor.PipeChainStart` and `Credo.Check.Readability.SinglePipe` are both
  disabled in `.credo.exs`. Don't "fix" existing pipes to satisfy a check that isn't running.
- **`with` is for a validation chain with a single catch-all `else`**, and stays flat. There is
  one use in `lib/` (`Mix.Tasks.Xcribe.Doc.endpoint_path/2`); it returns the same
  `{:error, [{key, value, message, instructions}]}` shape as config validation. Never nest a
  `with` inside a `case` or an `if`.
- **Dispatch on types with guard clauses and on shapes with a pattern in the head**, not with a
  body-level conditional:

      def validate(%Request{} = request)
      defp find_struct(%Upload{}, "multipart" <> _rest)
      defp type_for(value) when is_binary(value), do: "string"

  Binary-prefix matching in a head (`"multipart" <> _rest`) is idiomatic here. Guards stay
  type-oriented and simple — `is_atom/1`, `is_list/1`, `is_binary/1`, `is_function(f, 2)`,
  `typ in [:parsing, :validation]`.
- **Specific clauses come before general ones**; a catch-all above a specific clause is a bug.
- **Injection over mocks.** An external collaborator is a defaulted function or module argument,
  so a test can pass a fake without a mocking library:

      def run_task(opts, task_function \\ &run_mix_test_task/1, project_module \\ Mix.Project)
      def document_all_records(override_func \\ nil)

  See [tests.md](tests.md).
