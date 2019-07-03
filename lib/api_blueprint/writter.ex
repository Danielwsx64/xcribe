defmodule Xcribe.ApiBlueprint.Writter do
  alias Xcribe.ApiBlueprint.Formatter

  def requests_to_string(requests) do
    requests
    |> group_requests()
    |> grouped_requests_to_string()
  end

  def group_requests(requests) do
    requests
    |> group_by_resource_group()
    |> group_by_resource_name()
    |> group_by_action()
  end

  def grouped_requests_to_string(requests) do
    requests
    |> Enum.reduce("", fn {group, reqs}, acc ->
      acc <> group <> resource_to_string(reqs)
    end)
  end

  defp resource_to_string(resources) do
    resources
    |> Enum.reduce("", fn {resource, reqs}, acc ->
      acc <> resource <> actions_to_string(reqs)
    end)
  end

  defp actions_to_string(actions) do
    actions
    |> Enum.reduce("", fn {action, reqs}, acc ->
      acc <> action <> action_requests_to_string(reqs)
    end)
  end

  defp action_requests_to_string(requests) do
    requests
    |> Enum.reduce("", fn req, acc ->
      acc <> Formatter.full_request(req)
    end)
  end

  defp group_by_resource_group(requests),
    do: requests |> Enum.group_by(&Formatter.resource_group(&1)) |> Enum.sort()

  defp group_by_resource_name(requests) do
    requests
    |> Enum.map(fn {resource_group, reqs} ->
      {resource_group, reqs |> Enum.group_by(&Formatter.resource(&1)) |> Enum.sort()}
    end)
  end

  defp group_by_action(requests) do
    requests
    |> Enum.map(fn {key, reqs} -> {key, group_the_actions(reqs)} end)
  end

  defp group_the_actions(resource_requests) do
    resource_requests
    |> Enum.map(fn {resource_name, reqs} ->
      {resource_name, reqs |> Enum.group_by(&Formatter.resource_action(&1)) |> Enum.sort()}
    end)
  end
end
