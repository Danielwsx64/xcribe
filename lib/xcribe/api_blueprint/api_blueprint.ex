defmodule Xcribe.ApiBlueprint do
  @moduledoc false

  alias Xcribe.ApiBlueprint.{APIB, Formatter}
  alias Xcribe.{DocException, Request, Specification}

  def generate_doc(requests, config) do
    requests
    |> apib_struct(config)
    |> APIB.encode(config)
  end

  def apib_struct(requests, config) do
    specifications = Specification.api_specification(config)

    %{
      host: host(specifications.servers),
      description: specifications.description,
      name: specifications.name,
      groups: reduce_groups(requests, specifications, config)
    }
  end

  defp host([%{url: url} | _rest]), do: url
  defp host([]), do: ""

  defp reduce_groups(requests, specifications, config),
    do: Enum.reduce(requests, %{}, &format_and_merge(&1, &2, specifications, config))

  defp format_and_merge(request, acc, specifications, config) do
    prepared =
      request
      |> Request.remove_ignored_prefixes(specifications)
      |> Map.update(:__meta__, %{config: config}, &Map.put(&1, :config, config))

    item =
      Formatter.full_request_object(
        prepared,
        action_description(specifications.paths, prepared)
      )

    Formatter.put_object_into_groups(acc, item)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp action_description(paths, %{path: path, verb: verb}) do
    paths
    |> Map.get(path, %{})
    |> Map.get(verb, %{})
    |> Map.get(:description, "")
  end
end
