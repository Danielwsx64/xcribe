defmodule Xcribe.ModuleExample do
  use Xcribe.Information

  xcribe_info Xcribe.FakeController do
    description("some cool description")
    parameters(id: "This is the user id", tag: "a usefull tag")
    attributes(name: "the protocol name", priority: "the priority of the protocol")

    actions(
      index: [
        description: "other cool description",
        parameters: [value: "some value", id: "This is the action id"]
      ]
    )

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

  describe "resource_attributes/1" do
    test "return description" do
      assert ModuleExample.resource_attributes(Xcribe.FakeController) == %{
               "name" => "the protocol name",
               "priority" => "the priority of the protocol"
             }
    end

    test "unknow controller" do
      assert ModuleExample.resource_attributes(Xcribe.UnknowController) == %{}
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
    test "return action parameters merged with controller parameters" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "index") == %{
               "value" => "some value",
               "id" => "This is the action id",
               "tag" => "a usefull tag"
             }
    end

    test "action with no defined params return just the controller parameters" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "update") == %{
               "id" => "This is the user id",
               "tag" => "a usefull tag"
             }
    end

    test "unknow action return controller parameters" do
      assert ModuleExample.action_parameters(Xcribe.FakeController, "invalid") == %{
               "id" => "This is the user id",
               "tag" => "a usefull tag"
             }
    end

    test "unknow controller" do
      assert ModuleExample.action_parameters(Xcribe.UnknowController, "index") == %{}
    end
  end
end
