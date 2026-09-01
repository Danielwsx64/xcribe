defmodule Xcribe.APIModel.Parameter do
  @moduledoc false

  alias Xcribe.{JsonSchema, Schema}

  defstruct [:name, :location, required: false, schema: %{}, examples: []]

  def new(name, location, value) do
    %__MODULE__{
      name: name,
      location: location,
      required: required?(location),
      schema: JsonSchema.schema_for({name, value}, title: false),
      examples: [value]
    }
  end

  def merge(%__MODULE__{} = base, %__MODULE__{} = new) do
    %{
      base
      | schema: Schema.merge_schema(base.schema, new.schema),
        examples: base.examples |> Enum.concat(new.examples) |> Enum.uniq() |> Enum.sort()
    }
  end

  def sort_key(%__MODULE__{name: name, location: location}), do: {location, name}

  defp required?(:path), do: true
  defp required?(_location), do: false
end
