defmodule Xcribe.ApiBlueprint do
  alias Xcribe.ApiBlueprint.Formatter
  alias Xcribe.Information

  def generate_doc(requests) do
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
    |> Enum.reduce("", &resource_reducer/2)
  end

  defp resource_reducer({resource, reqs}, doc) do
    description = reqs |> resource_request_example() |> Information.resource_description()

    resource_string =
      if(is_nil(description), do: resource, else: "#{resource <> description}\n\n")

    doc <> resource_string <> actions_to_string(reqs)
  end

  defp resource_request_example([{_, [request | _]} | _]), do: request

  defp actions_to_string(actions) do
    actions
    |> Enum.reduce("", &action_reducer/2)
  end

  defp action_reducer({action, reqs}, doc) do
    description = reqs |> action_request_example() |> Information.action_description()

    action_string = if(is_nil(description), do: action, else: "#{action <> description}\n\n")

    doc <> action_string <> action_requests_to_string(reqs)
  end

  defp action_request_example([request | _]), do: request

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
