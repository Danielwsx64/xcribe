defmodule Xcribe.Swagger.DescriptorTest do
  use ExUnit.Case, async: true

  alias Xcribe.Swagger.Descriptor

  describe "get_content_type/1" do
    test "when header is in the format app/json; chartset" do
      request = %{
        resp_headers: [
          {"content-type", "application/json; charset=utf-8"},
          {"cache-control", "max-age=0, private, must-revalidate"}
        ]
      }

      actual = Descriptor.get_content_type(request)

      assert actual == "application/json"
    end

    test "when header is in the format app/json" do
      request = %{
        resp_headers: [
          {"content-type", "application/xml"}
        ]
      }

      actual = Descriptor.get_content_type(request)

      assert actual == "application/xml"
    end
  end

  describe "get_request_description/1" do
    test "when there is a description available" do
      request = %{
        controller: Elixir.Xcribe.ProtocolsController
      }

      assert Descriptor.get_request_description(request) ==
               "Application protocols is a awesome feature of our app"
    end

    test "when there is not a description available" do
      request = %{
        controller: Elixir.Xcribe.UsersController
      }

      assert Descriptor.get_request_description(request) == ""
    end
  end

  describe "get_param_description/3" do
    test "when there is a description in resource parameters" do
      actual =
        Descriptor.get_param_description("server_id", Elixir.Xcribe.ProtocolsController, "index")

      assert actual == "The id number of the server"
    end

    test "when there is a description in action parameters" do
      actual = Descriptor.get_param_description("id", Elixir.Xcribe.ProtocolsController, "show")

      assert actual == "the number id of the protocol"
    end

    test "when there is not a description available" do
      actual = Descriptor.get_param_description("name", Elixir.Xcribe.ProtocolsController, "show")

      assert actual == ""
    end
  end

  describe "get_attr_description/2" do
    test "when there is attr description available" do
      actual = Descriptor.get_attr_description("name", Elixir.Xcribe.ProtocolsController)

      assert actual == "The protocol full name"
    end

    test "when there is not an attr description available" do
      actual = Descriptor.get_attr_description("id", Elixir.Xcribe.ProtocolsController)

      assert actual == ""
    end
  end
end
