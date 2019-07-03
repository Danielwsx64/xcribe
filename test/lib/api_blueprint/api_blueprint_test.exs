defmodule Xcribe.ApiBlueprintTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples

  alias Xcribe.ApiBlueprint

  describe "group_requests/1" do
    test "group requests" do
      assert ApiBlueprint.group_requests(@sample_requests) == @grouped_sample_requests
    end
  end

  describe "grouped_requests_to_string/1" do
    test "parse routes to string" do
      assert ApiBlueprint.grouped_requests_to_string(@grouped_sample_requests) ==
               @sample_requests_as_string
    end
  end

  describe "generate_doc/1" do
    test "parse requests to string" do
      assert ApiBlueprint.generate_doc(@sample_requests) == @sample_requests_as_string
    end
  end
end
