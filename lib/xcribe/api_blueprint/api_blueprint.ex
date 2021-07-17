defmodule Xcribe.ApiBlueprint do
  @moduledoc false

  alias Xcribe.ApiBlueprint.{APIB, Formatter}
  alias Xcribe.DocException

  def generate_doc(requests, config) do
    requests
    |> apib_struct(config)
    |> APIB.encode(config)
  end

  def apib_struct(requests, %{information_source: information_source} = config) do
    Map.put(
      xcribe_info(information_source),
      :groups,
      reduce_groups(requests, config)
    )
  end

  defp reduce_groups(requests, config),
    do: Enum.reduce(requests, %{}, &format_and_merge(&1, &2, config))

  defp format_and_merge(request, acc, config) do
    item =
      request
      |> Map.update(:__meta__, %{config: config}, &Map.put(&1, :config, config))
      |> Formatter.full_request_object()

    Formatter.merge_request(acc, item)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp xcribe_info(information_source), do: apply(information_source, :api_info, [])
end
