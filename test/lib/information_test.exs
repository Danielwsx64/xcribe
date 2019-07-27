defmodule Xcribe.ModuleExample do
  use Xcribe.Information

  xcribe_info Xcribe.FakeController do
    description("some cool description")
    parameters(id: "This is the user id", tag: "a usefull tag")

    actions(index: [description: "other cool description", parameters: [value: "some value"]])
    actions(create: [parameters: [key: "key value"]])
    actions(update: [description: "update description"])
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

  describe "resource_parameters/1" do
    test "return description" do
      assert ModuleExample.resource_parameters(Xcribe.FakeController) == %{
               "id" => "This is the user id",
               "tag" => "a usefull tag"
             }
    end

    test "unknow controller" do
      assert ModuleExample.resource_parameters(Xcribe.UnknowController) == %{}
    end
  end

  describe "action_description/2" do
    test "return description" do
      assert ModuleExample.action_description(Xcribe.FakeController, "index") ==
               "other cool description"
    end

    test "action with no defined description" do
      assert ModuleExample.action_description(Xcribe.FakeController, "create") == nil
    end

    test "unknow action" do
      assert ModuleExample.action_description(Xcribe.FakeController, "invalid") == nil
    end

    test "unknow controller" do
      assert ModuleExample.action_description(Xcribe.Fak, "index") == nil
    end
  end

  describe "action_parameters/2" do
    test "return description" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "index") == %{
               "value" => "some value"
             }
    end

    test "action with no defined params" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "update") == %{}
    end

    test "unknow action" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "invalid") == %{}
    end

    test "unknow controller" do
      assert ModuleExample.action_parameters(Xcribe.UnknowController, "index") == %{}
    end
  end
end
