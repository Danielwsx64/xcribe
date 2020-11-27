defmodule Xcribe.Request.Validator do
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
    request
    |> Map.fetch!(key)
    |> find_struct()
    |> handle_validate_params(request)
  end

  def find_struct(%{__struct__: module}) do
    %Error{
      type: :validation,
      message:
        "The Plug.Conn params must be valid HTTP params. A struct #{sanitize_module_name(module)} was found!"
    }
  end

  def find_struct(%{} = map), do: Enum.reduce_while(map, :ok, &reduce_map/2)
  def find_struct(list) when is_list(list), do: Enum.reduce_while(list, :ok, &reduce_list/2)
  def find_struct(_), do: :ok

  defp reduce_list(value, _acc), do: reduce_function(value)

  defp reduce_map({_key, value}, _acc), do: reduce_function(value)

  defp reduce_function(value) do
    case find_struct(value) do
      :ok -> {:cont, :ok}
      %Error{} = error -> {:halt, error}
    end
  end

  defp sanitize_module_name(module),
    do: module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")

  defp handle_validate_params(:ok, request), do: {:ok, request}
  defp handle_validate_params(%Error{} = error, _request), do: {:error, error}

  defp handle_validate({:ok, _req} = success, _request), do: success

  defp handle_validate({:error, error}, request),
    do: {:error, %{error | __meta__: request.__meta__}}
end
