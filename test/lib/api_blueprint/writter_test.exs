defmodule Xcribe.ApiBlueprint.WritterTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples

  alias Xcribe.ApiBlueprint.Writter

  describe "group_requests/1" do
    test "group requests" do
      assert Writter.group_requests(@sample_requests) == @grouped_sample_requests
    end
  end

  describe "grouped_requests_to_string/1" do
    test "parse routes to string" do
      assert Writter.grouped_requests_to_string(@grouped_sample_requests) ==
               @sample_requests_as_string
    end
  end

  describe "requests_to_string" do
    test "parse requests to string" do
      assert Writter.requests_to_string(@sample_requests) == @sample_requests_as_string
    end
  end
end
