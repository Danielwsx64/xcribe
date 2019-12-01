defmodule Xcribe.ApiBlueprint do
  alias Xcribe.ApiBlueprint.Formatter
  alias Xcribe.Config

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
    |> Enum.reduce(api_metadata(), fn {group, reqs}, acc ->
      acc <> group <> resource_to_string(reqs)
    end)
  end

  defp resource_to_string(resources) do
    resources
    |> Enum.reduce("", &resource_reducer/2)
  end

  defp resource_reducer({resource, reqs}, doc) do
    request_example = resource_request_example(reqs)
    description = resource_description(request_example)

    parameters =
      Formatter.resource_parameters(request_example, resource_parameters(request_example))

    resource_string =
      if(is_nil(description), do: resource, else: "#{resource <> description}\n\n")

    doc <> resource_string <> parameters <> actions_to_string(reqs)
  end

  defp resource_request_example([{_, [request | _]} | _]), do: request

  defp actions_to_string(actions) do
    actions
    |> Enum.reduce("", &action_reducer/2)
  end

  defp action_reducer({action, reqs}, doc) do
    request_example = action_request_example(reqs)
    description = request_example |> action_description()
    parameters = Formatter.action_parameters(request_example)

    action_string = if(is_nil(description), do: action, else: "#{action <> description}\n\n")

    doc <> action_string <> parameters <> action_requests_to_string(reqs)
  end

  defp action_request_example([request | _]), do: request

  defp action_requests_to_string(requests) do
    requests
    |> Enum.reduce("", fn req, acc ->
      attributes = resource_attributes(req)

      acc <> Formatter.full_request(req, attributes)
    end)
  end

  defp group_by_resource_group(requests),
    do: requests |> Enum.group_by(&Formatter.resource_group(&1)) |> Enum.sort()

  defp group_by_resource_name(requests) do
    requests
    |> Enum.map(fn {resource_group, reqs} ->
      {resource_group, reqs |> Enum.group_by(&Formatter.resource_section(&1)) |> Enum.sort()}
    end)
  end

  defp group_by_action(requests) do
    requests
    |> Enum.map(fn {key, reqs} -> {key, group_the_actions(reqs)} end)
  end

  defp group_the_actions(resource_requests) do
    resource_requests
    |> Enum.map(fn {resource_name, reqs} ->
      {resource_name, reqs |> Enum.group_by(&Formatter.action_section(&1)) |> Enum.sort()}
    end)
  end

  defp api_metadata, do: Formatter.metadata_section(xcribe_info())

  defp resource_description(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_description, [controller])

  defp resource_parameters(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_parameters, [controller])

  defp resource_attributes(%{controller: controller}),
    do: apply(Config.xcribe_information_source(), :resource_attributes, [controller])

  defp action_description(%{controller: controller, action: action}),
    do: apply(Config.xcribe_information_source(), :action_description, [controller, action])

  defp xcribe_info,
    do: apply(Config.xcribe_information_source(), :api_info, [])
end
