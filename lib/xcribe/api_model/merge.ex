defmodule Xcribe.APIModel.Merge do
  @moduledoc false

  @doc """
  Merge two collections of structs, pairing entries by `key_function` and combining each pair with
  `merge_function`. Entries sharing a key inside a single collection are merged too, and the result
  is always sorted by the same key.
  """
  def by_key(base, new, key_function, merge_function) do
    base
    |> Enum.concat(new)
    |> Enum.reduce(%{}, fn item, indexed ->
      Map.update(indexed, key_function.(item), item, &merge_function.(&1, item))
    end)
    |> Map.values()
    |> Enum.sort_by(key_function)
  end
end
