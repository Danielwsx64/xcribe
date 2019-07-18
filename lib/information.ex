defmodule Xcribe.Information do
  defmacro __using__(_opts \\ []) do
    quote do
      import Xcribe.Information

      @before_compile Xcribe.Information
    end
  end

  defmacro xcribe_info(controller, do: information) do
    resource_desc = fetch_information(information, :description)
    actions = fetch_information(information, :actions, [])

    quote bind_quoted: [actions: actions, controller: controller, resource_desc: resource_desc] do
      def resource_description(unquote(controller)), do: unquote(resource_desc)

      actions
      |> Enum.each(fn {action, description} ->
        action_name = Atom.to_string(action)

        def action_description(unquote(controller), unquote(action_name)),
          do: unquote(description)
      end)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def resource_description(_), do: nil
      def action_description(_, _), do: nil
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
end
