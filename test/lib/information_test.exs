defmodule Xcribe.ModuleExample do
  use Xcribe.Information

  xcribe_info Xcribe.FakeController do
    description("some cool description")
    actions(index: "other cool description")
  end
end

defmodule Xcribe.InformationTest do
  use ExUnit.Case, async: true
  alias Xcribe.ModuleExample

  describe "resource_description/1" do
    test "return description" do
      assert ModuleExample.resource_description(Xcribe.FakeController) == "some cool description"
    end

    test "unknow controller" do
      assert ModuleExample.resource_description(Xcribe.Fak) == nil
    end
  end

  describe "action_description/2" do
    test "return description" do
      assert ModuleExample.action_description(Xcribe.FakeController, "index") ==
               "other cool description"
    end

    test "unknow action" do
      assert ModuleExample.action_description(Xcribe.FakeController, "create") == nil
    end

    test "unknow controller" do
      assert ModuleExample.action_description(Xcribe.Fak, "index") == nil
    end
  end
end
