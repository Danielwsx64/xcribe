defmodule Xcribe.Schema do
  @moduledoc false

  @doc """
  Merge two collections of named schemas, deep merging every name present in both.
  """
  def merge(base, new) do
    Enum.reduce(new, base, fn {name, schema}, all ->
      Map.update(all, name, schema, &merge_schema(&1, schema))
    end)
  end

  @doc """
  Merge two single schema objects. A schema whose type differs from the base replaces it.
  """
  def merge_schema(%{type: "object"} = base, %{type: "object"} = new) do
    Map.put(
      base,
      :properties,
      merge(Map.get(base, :properties, %{}), Map.get(new, :properties, %{}))
    )
  end

  def merge_schema(%{type: "array"} = base, %{type: "array"} = new) do
    Map.put(base, :items, merge_schema(Map.get(base, :items, %{}), Map.get(new, :items, %{})))
  end

  def merge_schema(%{type: type} = base, %{type: type} = new) do
    Map.merge(base, Map.take(new, [:example, :format]))
  end

  def merge_schema(_base, new_with_diff_type), do: new_with_diff_type
end
