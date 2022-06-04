defmodule Xcribe.Schema do
  def merge(base, new) do
    Enum.reduce(new, base, fn {name, schema}, all ->
      Map.update(all, name, schema, &merge_schema(&1, schema))
    end)
  end

  defp merge_schema(%{type: "object"} = base, %{type: "object"} = new) do
    %{base | properties: merge_properties(base.properties, new.properties)}
  end

  defp merge_schema(%{type: "array"} = base, %{type: "array"} = new) do
    Map.put(base, :items, merge_schema(Map.get(base, :items, %{}), new.items))
  end

  defp merge_schema(%{type: t} = base, %{type: t} = new) do
    Map.merge(base, Map.take(new, [:example, :format]))
  end

  defp merge_schema(_base, new_with_diff_type) do
    new_with_diff_type
  end

  defp merge_properties(base, new) do
    Enum.reduce(new, base, fn {name, schema}, all ->
      Map.update(all, name, schema, &merge_schema(&1, schema))
    end)
  end
end
