defmodule Xcribe do
  @moduledoc """
  Xcribe is a library for API documentation. It generates docs from your test specs.

  Xcribe use `Plug.Conn` struct to fetch information about requests and use them
  to document your API.  You must give requests examples (from your tests ) to Xcribe
  be able to document your routes.

  Each connection sent to documenting in your tests is parsed. Is expected that
  connection has been passed through the app `Endpoint` as a finished request.
  The parser will extract all needed info from `Conn` and uses app `Router`
  for additional information about the request.

  The attribute `description` may be given at `document` macro call with the
  option `:as`:

      test "test name", %{conn: conn} do
        ...

        document(conn, as: "description here")

        ...
      end

  If no description is given the current test description will be used.

  ## API information

  You must provide your API information by creatint a mudule that use
  `Xcribe.Information` macros.

  The required info are:

  - `name` - a name for your API.
  - `description` - a description about your API.
  - `host` - your API host url

  This information is set by Xcribe macros inside the block `xcribe_info`. eg:

      defmodule YourModuleInformation do
        use Xcribe.Information

        xcribe_info do
          name "Your awesome API"
          description "The best API in the world"
          host "http://your-api.us"
        end
      end

  See `Xcribe.Information` for more details about custom information.

  ## JSON

  Xcribe uses the same json library configured for Phoenix to handle json content.
  you can configure xcribe to use your preferred library. Poison and Jason are
  the most popular json libraries common used in Elixir and Xcribe works fine with both.

  ## Configuration

  You must configure  the `information_source`.

  eg:

      config :xcribe, information_source: YourApp.YouModuleInformation

  #### Available configurations:

    * `:information_source` - Module that implements `Xcribe.Information` with
    API information. It's required.
    * `:output` - The name of file output with generated configuration. Default
    value changes by the format, 'api_blueprint.apib' for Blueprint and
    'app_doc.json' for swagger.
    * `:format` - Format to generate documentation, allowed `:api_blueprint` and
    `:swagger`. Default `:swagger`.
    * `:env_var` - Environment variable name for active Xcribe documentation
    generator. Default is `XCRIBE_ENV`.
    * `:json_library` - The library to be used for json decode/encode (Jason
    and Poison are supported). The default is the same as `Phoenix` configuration.
    * `:serve` - Enable Xcribe serve mode. Default `false`. See more `Serving doc`
  """
  require Logger

  alias Xcribe.{
    ApiBlueprint,
    CLI.Output,
    Config,
    DocException,
    Recorder,
    Request,
    Request.Error,
    Request.Validator,
    Swagger,
    Writter
  }

  @doc false
  def suite_finished do
    check_configurations()
    |> get_recorded_requests()
    |> validate_records()
    |> order_by_path()
    |> generate_docs()
    |> write()
  rescue
    e in DocException ->
      Output.print_doc_exception(e)
  end

  defp check_configurations do
    case Config.check_configurations() do
      {:error, errs} -> Output.print_configuration_errors(errs) && :error
      :ok -> :ok
    end
  end

  defp get_recorded_requests(:ok), do: Recorder.get_all()
  defp get_recorded_requests(:error), do: :error

  defp validate_records(:error), do: :error

  defp validate_records(records) when is_list(records) do
    records
    |> Enum.reduce({:ok, []}, &validate_request/2)
    |> handle_errors()
  end

  defp validate_request(%Request{} = request, acc) do
    request
    |> Validator.validate()
    |> add_result(acc)
  end

  defp validate_request(%Error{} = err, {:ok, _requests}), do: {:error, [err]}
  defp validate_request(%Error{} = err, {:error, errs}), do: {:error, [err | errs]}

  defp add_result({:error, error}, {:error, errs}), do: {:error, [error | errs]}
  defp add_result({:error, error}, {:ok, _requests}), do: {:error, [error]}
  defp add_result({:ok, request}, {:ok, requests}), do: {:ok, [request | requests]}
  defp add_result({:ok, _request}, {:error, _errs} = errs), do: errs

  defp handle_errors({:error, errs}), do: Output.print_request_errors(errs) && :error
  defp handle_errors({:ok, requests}), do: requests

  defp order_by_path(:error), do: :error
  defp order_by_path(requests), do: Enum.sort(requests, &(&1.path >= &2.path))

  defp generate_docs(:error), do: :error

  defp generate_docs(requests) when is_list(requests) do
    case Config.fetch!(:doc_format) do
      :api_blueprint -> ApiBlueprint.generate_doc(requests)
      :swagger -> Swagger.generate_doc(requests)
    end
  end

  defp write(:error), do: :error
  defp write(text) when is_binary(text), do: Writter.write(text)
end
