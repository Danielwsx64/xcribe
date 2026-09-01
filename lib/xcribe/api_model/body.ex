defmodule Xcribe.APIModel.Body do
  @moduledoc false

  alias Xcribe.{JsonSchema, Schema}

  defstruct [:content_type, :schema_name, schema: %{}, examples: []]

  def new(content_type, schema_name, body) do
    %__MODULE__{
      content_type: content_type,
      schema_name: schema_name,
      schema: JsonSchema.schema_for({nil, body}, title: false, example: true),
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

  def sort_key(%__MODULE__{content_type: content_type}), do: content_type
end
