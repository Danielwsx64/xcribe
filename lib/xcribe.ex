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

  See more about documentation macro `Xcribe.Document`.


  ## Running

  You can run Xcribe by:

  ```sh
  mix xcribe.doc
  ```

  see `Mix.Tasks.Xcribe.Doc`

  ## API information

  The API title, description, version and servers come from a specification file, `.xcribe.exs`.
  Generate one with `mix xcribe.gen.spec`.

  See `Xcribe.Specification` for more details.

  ## JSON

  Xcribe uses Jason to handle json content, and you can configure xcribe to use your
  preferred library. Poison and Jason are the most popular json libraries common used
  in Elixir and Xcribe works fine with both.

  ## Configuration

  #### Available configurations:

    * `:format` - Format to generate documentation, allowed `:api_blueprint` and
    `:swagger`. Default `:swagger`.
    * `:output` - The name of the generated documentation file. The default changes
    with the format: `"api_doc.apib"` for Blueprint and `"openapi.json"` for Swagger.
    * `:json_library` - The library to be used for json decode/encode (Jason
    and Poison are supported). Default `Jason`.
    * `:serve` - Enable Xcribe serve mode. Default `false`. See more `Serving doc`
    * `:specification_source` - Path to the specification file. Default `".xcribe.exs"`.
    See `Xcribe.Specification`.
  """
  alias Xcribe.{
    ApiBlueprint,
    APIModel,
    CLI.Output,
    Config,
    DocException,
    Recorder,
    Request,
    Request.Error,
    Request.Validator,
    Specification,
    SpecificationFile,
    Swagger,
    Writter
  }

  @doc false
  def document_all_records(override_func \\ nil) do
    get_records_with_endpoint()
    |> fetch_config(override_func)
    |> generate()
    |> handle_result()
  end

  @doc false
  def document(records, config) when is_list(records) do
    records
    |> validate_records()
    |> build_api_model(config)
    |> generate_docs(config)
    |> write(config)
  rescue
    e in [DocException, SpecificationFile] -> {:error, e}
  end

  defp get_records_with_endpoint do
    case Recorder.pop_all() do
      %{errors: []} = recorded -> {:ok, Map.delete(recorded, :errors)}
      %{errors: errors} -> {:error, errors}
    end
  end

  defp fetch_config({:ok, recorded}, override_func) do
    Enum.reduce_while(recorded, {:ok, []}, fn {endpoint, records}, {:ok, acc} ->
      endpoint
      |> Config.fetch_config()
      |> apply_override(override_func, endpoint)
      |> Config.check_configurations()
      |> case do
        {:ok, config} -> {:cont, {:ok, [{records, config} | acc]}}
        {:error, _errs} = error -> {:halt, error}
      end
    end)
  end

  defp fetch_config(error, _function), do: error

  defp apply_override(config, function, endpoint) when is_function(function, 2) do
    function.(endpoint, config)
  end

  defp apply_override(config, _function, _endpoint), do: config

  defp generate({:ok, recorded_list}) do
    Enum.reduce_while(recorded_list, :ok, fn {records, config}, :ok ->
      case document(records, config) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp generate(error), do: error

  defp validate_records(records),
    do: Enum.reduce(records, {:ok, []}, &validate_request/2)

  defp validate_request(%Request{} = request, acc) do
    request
    |> Validator.validate()
    |> add_result(acc)
  end

  defp add_result({:error, error}, {:error, errs}), do: {:error, [error | errs]}
  defp add_result({:error, error}, {:ok, _requests}), do: {:error, [error]}
  defp add_result({:ok, request}, {:ok, requests}), do: {:ok, [request | requests]}
  defp add_result({:ok, _request}, {:error, _errs} = errs), do: errs

  defp build_api_model({:ok, requests}, config) do
    specification = Specification.api_specification(config)

    {:ok, {APIModel.build(requests, specification, config), specification}}
  end

  defp build_api_model(error, _config), do: error

  defp generate_docs({:ok, {model, specification}}, %{format: doc_format} = config) do
    case doc_format do
      :api_blueprint -> ApiBlueprint.generate_doc(model, specification, config)
      :swagger -> Swagger.generate_doc(model, specification, config)
    end
  end

  defp generate_docs({:error, _errs} = error, _config), do: error

  defp write(text, config) when is_binary(text), do: Writter.write(text, config)
  defp write({:error, _msg} = err, _config), do: err

  defp handle_result({:error, %SpecificationFile{} = e}) do
    Output.print_specification_error(e)

    :error
  end

  defp handle_result({:error, %DocException{} = e}) do
    Output.print_doc_exception(e)

    :error
  end

  defp handle_result({:error, [%Error{} | _t] = errors}) do
    Output.print_request_errors(errors)

    :error
  end

  defp handle_result({:error, errors}) when is_list(errors) do
    Output.print_configuration_errors(errors)

    :error
  end

  defp handle_result(:error), do: :error

  defp handle_result(:ok), do: :ok
end
