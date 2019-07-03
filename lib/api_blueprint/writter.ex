defmodule Xcribe.ApiBlueprint.Writter do
  def group_requests(requests) do
    requests
    |> group_by_resource_group()
    |> group_by_resource_name()
    |> group_by_action()
  end

  def grouped_requests_to_string(requests) do
    ""
  end

  defp group_by_resource_group(requests),
    do: requests |> Enum.group_by(& &1.resource_group) |> Enum.sort()

  defp group_by_resource_name(requests) do
    requests
    |> Enum.map(fn {resource_group, reqs} ->
      {resource_group, reqs |> Enum.group_by(& &1.resource) |> Enum.sort()}
    end)
  end

  defp group_by_action(requests) do
    requests
    |> Enum.map(fn {key, reqs} -> {key, group_the_actions(reqs)} end)
  end

  defp group_the_actions(resource_requests) do
    resource_requests
    |> Enum.map(fn {resource_name, reqs} ->
      {resource_name, reqs |> Enum.group_by(& &1.action) |> Enum.sort()}
    end)
  end
end
