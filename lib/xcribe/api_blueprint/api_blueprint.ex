defmodule Xcribe.ApiBlueprint do
  @moduledoc false

  alias Xcribe.ApiBlueprint.{APIB, Formatter}
  alias Xcribe.APIModel
  alias Xcribe.APIModel.Operation
  alias Xcribe.DocException

  def generate_doc(%APIModel{} = model, specification, config) do
    model
    |> apib_struct(specification)
    |> APIB.encode(config)
  end

  def apib_struct(%APIModel{} = model, specification) do
    %{
      host: host(specification.servers),
      description: specification.description,
      name: specification.name,
      groups: reduce_groups(model, specification)
    }
  end

  defp host([%{url: url} | _rest]), do: url
  defp host([]), do: ""

  defp reduce_groups(%APIModel{routes: routes}, specification) do
    routes
    |> Enum.flat_map(& &1.operations)
    |> Enum.reduce(%{}, &put_operation(&1, &2, specification))
  end

  defp put_operation(%Operation{} = operation, groups, specification) do
    Formatter.put_operation_into_groups(
      groups,
      operation,
      action_description(specification.paths, operation)
    )
  rescue
    exception -> raise DocException, {List.first(operation.examples), exception, __STACKTRACE__}
  end

  defp action_description(paths, %Operation{path: path, verb: verb}) do
    paths
    |> Map.get(path, %{})
    |> Map.get(verb, %{})
    |> Map.get(:description, "")
  end
end
