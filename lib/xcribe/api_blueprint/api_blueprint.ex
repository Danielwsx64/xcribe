defmodule Xcribe.ApiBlueprint do
  @moduledoc false

  alias Xcribe.ApiBlueprint.APIB
  alias Xcribe.ApiBlueprint.Formatter
  alias Xcribe.DocException
  alias Xcribe.Request
  alias Xcribe.Specification

  def generate_doc(requests, config) do
    requests
    |> apib_struct(config)
    |> APIB.encode(config)
  end

  def apib_struct(requests, config) do
    specifications = Specification.api_specification(config)

    %{
      host: List.first(specifications.servers).url,
      description: specifications.description,
      name: specifications.name,
      groups: reduce_groups(requests, specifications, config)
    }
  end

  defp reduce_groups(requests, specifications, config),
    do: Enum.reduce(requests, %{}, &format_and_merge(&1, &2, specifications, config))

  defp format_and_merge(request, acc, specifications, config) do
    item =
      request
      |> Request.remove_ignored_prefixes(specifications)
      |> Map.update(:__meta__, %{config: config}, &Map.put(&1, :config, config))
      |> Formatter.full_request_object()

    Formatter.put_object_into_groups(acc, item)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end
end
