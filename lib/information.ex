defmodule Xcribe.Information do
  @moduledoc """
  Add custom information for your API documentation.

  You must create a module to handle custom information about your API. That
  module must use `Xcribe.Information`.

      defmodule YourModuleInformation do
        use Xcribe.Information
      end

  The basic information is required and must be given inside `xcribe_info` block.

        xcribe_info do
          name "Your awesome API"
          description "The best API in the world"
          host "http://your-api.us"
        end
  """

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      import Xcribe.Information

      @before_compile Xcribe.Information

      def api_info do
        %{
          description: default_description(),
          host: default_host(),
          name: default_name()
        }
      end

      def namespaces, do: []

      defoverridable api_info: 0
      defoverridable namespaces: 0
    end
  end

  @doc """
  Defines the API custom information.

  This information will be used to build the final documentation.

  The required info are:

  - `name` - a name for your API.
  - `description` - a description about your API.
  - `host` - your API host url

  Example:

      defmodule YourModuleInformation do
        use Xcribe.Information

        xcribe_info do
          name "Your awesome API"
          description "The best API in the world"
          host "http://your-api.us"
        end
      end  
  """
  defmacro xcribe_info(do: information) do
    name = fetch_information(information, :name, default_name())
    description = fetch_information(information, :description, default_description())
    host = fetch_information(information, :host, default_host())
    namespaces = fetch_information(information, :namespaces, [])

    quote bind_quoted: [description: description, host: host, name: name, namespaces: namespaces] do
      def api_info do
        %{
          description: unquote(description),
          host: unquote(host),
          name: unquote(name)
        }
      end

      def namespaces, do: unquote(namespaces)
    end
  end

  @doc false
  defmacro xcribe_info(controller, do: information) do
    resource_desc = fetch_information(information, :description)
    actions = fetch_information(information, :actions, [])
    parameters = information |> fetch_information(:parameters, []) |> stringfy_keys()
    attributes = information |> fetch_information(:attributes, []) |> stringfy_keys()

    quote bind_quoted: [
            actions: actions,
            controller: controller,
            resource_desc: resource_desc,
            parameters: parameters,
            attributes: attributes
          ] do
      def resource_description(unquote(controller)), do: unquote(resource_desc)

      def resource_parameters(unquote(controller)), do: Map.new(unquote(parameters))

      def resource_attributes(unquote(controller)), do: Map.new(unquote(attributes))

      actions
      |> Enum.each(fn {action, action_info} ->
        action_name = Atom.to_string(action)
        action_desc = fetch_key(action_info, :description, nil)
        action_params = action_info |> fetch_key(:parameters, []) |> stringfy_keys()

        def action_description(unquote(controller), unquote(action_name)),
          do: unquote(action_desc)

        def action_parameters(unquote(controller), unquote(action_name)) do
          Map.merge(
            resource_parameters(unquote(controller)),
            Map.new(unquote(action_params))
          )
        end
      end)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def resource_description(_), do: nil
      def resource_parameters(_), do: %{}
      def resource_attributes(_), do: %{}
      def action_description(_, _), do: nil
      def action_parameters(controller, _), do: resource_parameters(controller)
    end
  end

  defp fetch_information({_, _, data}, key, default \\ nil) do
    data
    |> Enum.find(fn {k, _, _} -> k == key end)
    |> case do
      {_, _, [found | _t]} -> found
      _ -> default
    end
  end

  @doc false
  def stringfy_keys(keyword),
    do: Enum.map(keyword, fn {key, value} -> {to_string(key), value} end)

  @doc false
  def fetch_key(keyword, key, default) do
    case Keyword.fetch(keyword, key) do
      {:ok, value} -> value
      _ -> default
    end
  end

  @doc false
  def default_host, do: "http://example.com"
  @doc false
  def default_name, do: "API"
  @doc false
  def default_description, do: ""
end
