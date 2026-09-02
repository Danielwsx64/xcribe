defmodule Xcribe.OpenAPI do
  @moduledoc false

  alias Xcribe.APIModel
  alias Xcribe.APIModel.{Operation, Route}
  alias Xcribe.{DocException, JSON}
  alias Xcribe.OpenAPI.{Formatter, Merge}

  def generate_doc(%APIModel{} = model, specification, config) do
    model
    |> build_paths(specification)
    |> build_openapi_object(model, specification)
    |> json_encode!(config)
  end

  defp build_paths(%APIModel{routes: routes}, specification) do
    routes
    |> Map.new(&{&1.path, path_item_object(&1)})
    |> Merge.overlay_paths(specification.paths)
  end

  defp path_item_object(%Route{operations: operations}),
    do: Map.new(operations, &{&1.verb, operation_object(&1)})

  defp operation_object(%Operation{} = operation) do
    Formatter.operation_object(operation)
  rescue
    exception -> raise DocException, {List.first(operation.examples), exception, __STACKTRACE__}
  end

  defp build_openapi_object(paths, model, specification) do
    %{
      Formatter.openapi_object(specification)
      | paths: paths,
        components: Formatter.components_object(model, specification)
    }
  end

  defp json_encode!(openapi, config), do: JSON.encode!(openapi, [], config)
end
