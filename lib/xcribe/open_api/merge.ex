defmodule Xcribe.OpenAPI.Merge do
  @moduledoc false

  @doc """
  Overlay the path items authored in the specification file onto the generated ones.

  A value from the specification always wins; a generated value survives wherever the
  specification is silent. A path or verb the specification names but no test documented is added
  as-is, so an endpoint without a test can still be described.
  """
  def overlay_paths(generated, specified) do
    Enum.reduce(specified, generated, fn {path, verbs}, all ->
      Map.update(all, path, verbs, &overlay_verbs(&1, verbs))
    end)
  end

  defp overlay_verbs(generated, specified) do
    Enum.reduce(specified, generated, fn {verb, object}, all ->
      Map.update(all, verb, object, &overlay(&1, object))
    end)
  end

  defp overlay(base, new) when is_map(base) and is_map(new) do
    Enum.reduce(new, base, fn {key, value}, acc ->
      Map.update(acc, key, value, &overlay(&1, value))
    end)
  end

  defp overlay(_base, new), do: new
end
