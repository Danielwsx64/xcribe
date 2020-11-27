defmodule Xcribe.JsonSchema do
  @moduledoc false

  alias Plug.Upload

  @doc """
  Return the type of given data
  """
  def type_for(item) when is_number(item), do: "number"
  def type_for(item) when is_binary(item), do: "string"
  def type_for(item) when is_boolean(item), do: "boolean"
  def type_for(item) when is_map(item), do: "object"
  def type_for(item) when is_list(item), do: "array"
  def type_for(_), do: "string"

  @doc ~S"""
  Return the format of given data
  """
  def format_for(data) when is_float(data), do: "float"
  def format_for(data) when is_integer(data), do: "int32"
  def format_for(_), do: ""

  @doc """
  Basic implementation of JSON Schema specification (http://json-schema.org/)

  ### Options:
    * `:title` - Include the schema title, default is `true`.
    * `:example` - Include the schema example, default is `false`.
  """
  def schema_for(data, opts \\ [title: true, example: true])

  def schema_for(data, opts) when is_map(data) or is_list(data),
    do: schema_object_for({nil, data}, opts)

  def schema_for({title, data}, opts), do: schema_object_for({title, data}, opts)

  @opt_no_title {:title, false}
  @opt_example {:example, true}

  defp schema_object_for({title, %Upload{}}, opts) do
    schema_add_title(
      %{type: "string", format: "binary"},
      title,
      @opt_no_title in opts
    )
  end

  defp schema_object_for({title, value}, opts) when is_map(value) do
    %{type: "object"}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_properties(value, opts)
  end

  defp schema_object_for({title, value}, opts) when is_list(value) do
    %{type: "array"}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_items(value, opts)
  end

  defp schema_object_for({title, value}, opts) do
    %{type: type_for(value)}
    |> schema_add_title(title, @opt_no_title in opts)
    |> schema_add_format(format_for(value))
    |> schema_add_example(value, @opt_example in opts)
  end

  defp schema_add_title(schema, nil, _active), do: schema
  defp schema_add_title(schema, _title, true), do: schema
  defp schema_add_title(schema, title, false), do: Map.put(schema, :title, title)

  defp schema_add_format(schema, ""), do: schema
  defp schema_add_format(schema, format), do: Map.put(schema, :format, format)

  defp schema_add_example(schema, value, true), do: Map.put(schema, :example, value)
  defp schema_add_example(schema, _value, false), do: schema

  defp schema_add_properties(schema, value, opts) do
    Map.put(schema, :properties, reduce_properties(value, opts))
  end

  defp reduce_properties(properties, opts) do
    property_opts = Keyword.merge(opts, title: false)

    Enum.reduce(properties, %{}, fn {title, value}, schema ->
      Map.put(
        schema,
        title,
        schema_object_for({:schema_add_properties, value}, property_opts)
      )
    end)
  end

  defp schema_add_items(schema, [], _opts), do: Map.put(schema, :items, %{type: "string"})

  defp schema_add_items(schema, [value | _], opts) do
    item_opts = Keyword.merge(opts, title: false)

    Map.put(
      schema,
      :items,
      schema_object_for({:schema_add_items, value}, item_opts)
    )
  end
end
