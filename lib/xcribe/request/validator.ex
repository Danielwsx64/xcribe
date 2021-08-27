defmodule Xcribe.Request.Validator do
  @moduledoc false

  alias Plug.Upload
  alias Xcribe.Helpers.Formatter
  alias Xcribe.Request
  alias Xcribe.Request.Error

  def validate(%Request{} = request) do
    {:ok, request}
    |> validate_parameters_in(:request_body)
    |> validate_parameters_in(:path_params)
    |> validate_parameters_in(:header_params)
    |> validate_parameters_in(:query_params)
    |> handle_validate(request)
  end

  defp validate_parameters_in({:error, _err} = error, _key), do: error

  defp validate_parameters_in({:ok, request}, key) do
    content_type = Formatter.content_type(request.header_params)

    request
    |> Map.fetch!(key)
    |> find_struct(content_type)
    |> handle_validate_params(request)
  end

  defp find_struct(%Upload{}, "multipart" <> _rest), do: :ok

  defp find_struct(%Upload{}, _content_type) do
    %Error{
      type: :validation,
      message:
        "A Plug.Upload struct found. To document an file upload you must set the content type header to multipart"
    }
  end

  defp find_struct(%{__struct__: module}, _content_type) do
    %Error{
      type: :validation,
      message:
        "The Plug.Conn params must be valid HTTP params. A struct #{sanitize_module_name(module)} was found!"
    }
  end

  defp find_struct(%{} = map, content_type) do
    Enum.reduce_while(map, :ok, fn {_key, value}, _acc ->
      recursive_search(value, content_type)
    end)
  end

  defp find_struct(list, content_type) when is_list(list) do
    Enum.reduce_while(list, :ok, fn value, _acc -> recursive_search(value, content_type) end)
  end

  defp find_struct(_, _content_type), do: :ok

  defp recursive_search(value, content_type) do
    case find_struct(value, content_type) do
      :ok -> {:cont, :ok}
      %Error{} = error -> {:halt, error}
    end
  end

  defp sanitize_module_name(module) do
    module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")
  end

  defp handle_validate_params(:ok, request), do: {:ok, request}
  defp handle_validate_params(%Error{} = error, _request), do: {:error, error}

  defp handle_validate({:ok, _req} = success, _request), do: success

  defp handle_validate({:error, error}, request) do
    {:error, %{error | __meta__: request.__meta__}}
  end
end
