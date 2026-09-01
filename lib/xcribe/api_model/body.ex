defmodule Xcribe.APIModel.Body do
  @moduledoc false

  alias Xcribe.{JsonSchema, Schema}

  defstruct [:content_type, :schema_name, collection: false, schema: %{}, examples: []]

  @doc """
  Build the content of one content type from a recorded payload.

  `schema` always describes a single item and `collection` tells whether the payload is a list of
  them. Keeping the two apart is what lets a route documented by one test returning a list and
  another returning a single object share one named schema instead of replacing each other.
  """
  def new(content_type, schema_name, body) do
    {collection, schema} =
      {nil, body}
      |> JsonSchema.schema_for(title: false, example: true)
      |> pop_collection()

    %__MODULE__{
      content_type: content_type,
      schema_name: schema_name,
      collection: collection,
      schema: schema,
      examples: [body]
    }
  end

  def merge(%__MODULE__{} = base, %__MODULE__{} = new) do
    %{
      base
      | schema: Schema.merge_schema(base.schema, new.schema),
        examples: base.examples |> Enum.concat(new.examples) |> Enum.uniq() |> Enum.sort()
    }
  end

  def sort_key(%__MODULE__{} = body),
    do: {body.content_type, body.schema_name, body.collection}

  defp pop_collection(%{type: "array", items: items}), do: {true, items}
  defp pop_collection(schema), do: {false, schema}
end
