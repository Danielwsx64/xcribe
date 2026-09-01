defmodule Xcribe.APIModel.MergeTest do
  use ExUnit.Case, async: true

  alias Xcribe.APIModel.Merge

  describe "by_key/4" do
    test "merge the items sharing a key and sort the result by the same key" do
      base = [%{name: "b", values: [1]}, %{name: "a", values: [2]}]
      new = [%{name: "a", values: [3]}, %{name: "c", values: [4]}]

      assert Merge.by_key(base, new, & &1.name, &concat_values/2) == [
               %{name: "a", values: [2, 3]},
               %{name: "b", values: [1]},
               %{name: "c", values: [4]}
             ]
    end

    test "merge the items sharing a key inside a single collection" do
      new = [%{name: "b", values: [1]}, %{name: "a", values: [2]}, %{name: "b", values: [3]}]

      assert Merge.by_key([], new, & &1.name, &concat_values/2) == [
               %{name: "a", values: [2]},
               %{name: "b", values: [1, 3]}
             ]
    end

    test "return the base when the new collection is empty" do
      base = [%{name: "a", values: [1]}]

      assert Merge.by_key(base, [], & &1.name, &concat_values/2) == base
    end

    test "return an empty list for two empty collections" do
      assert Merge.by_key([], [], & &1.name, &concat_values/2) == []
    end
  end

  defp concat_values(base, new), do: %{base | values: base.values ++ new.values}
end
