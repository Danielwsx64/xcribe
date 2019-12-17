defmodule Xcribe.Swagger.Descriptor do
  @moduledoc """
  Gets descriptions from Information source
  """
  alias Xcribe.Config
  alias Xcribe.Helpers.Formatter, as: HelperFormatter

  def get_content_type(%{resp_headers: headers}) do
    headers
    |> HelperFormatter.find_content_type()
    |> (fn string -> Regex.run(~r/\w*\/\w*/, string) end).()
    |> List.first()
  end

  def get_request_description(%{controller: controller}) do
    controller
    |> resource_description()
    |> handle_resource_description()
  end

  def get_param_description(name, controller, action) do
    resource_params =
      controller
      |> resource_parameters()
      |> Map.fetch(name)

    controller
    |> action_parameters(action)
    |> Map.fetch(name)
    |> handle_param_description(resource_params)
  end

  def get_attr_description(name, controller) do
    controller
    |> resource_attributes()
    |> Map.fetch(name)
    |> handle_resource_attributes()
  end

  def get_action_description(%{controller: controller, action: action}) do
    controller
    |> action_description(action)
    |> handle_resource_description()
  end

  defp handle_param_description({:ok, desc}, _), do: desc
  defp handle_param_description(:error, {:ok, desc}), do: desc
  defp handle_param_description(:error, :error), do: ""

  defp handle_resource_description(nil), do: ""
  defp handle_resource_description(any), do: any

  defp handle_resource_attributes({:ok, desc}), do: desc
  defp handle_resource_attributes(:error), do: ""

  defp resource_description(controller),
    do: apply(Config.xcribe_information_source(), :resource_description, [controller])

  defp resource_parameters(controller),
    do: apply(Config.xcribe_information_source(), :resource_parameters, [controller])

  defp resource_attributes(controller),
    do: apply(Config.xcribe_information_source(), :resource_attributes, [controller])

  defp action_description(controller, action),
    do: apply(Config.xcribe_information_source(), :action_description, [controller, action])

  defp action_parameters(controller, action),
    do: apply(Config.xcribe_information_source(), :action_parameters, [controller, action])
end
