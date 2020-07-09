defmodule Xcribe.Helpers.FormatterTest do
  use ExUnit.Case, async: true

  alias Xcribe.Helpers.Formatter

  describe "content_type/1" do
    test "return the request content type" do
      headers_one = [
        {"content-type", "application/json; charset=utf-8"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ]

      headers_two = [{"content-type", "text/plain"}]
      headers_three = []

      assert Formatter.content_type(headers_one) == "application/json"
      assert Formatter.content_type(headers_two) == "text/plain"
      assert Formatter.content_type(headers_three) == nil
    end

    test "handle composed vnd type" do
      headers = [{"content-type", "application/vnd.api+json; charset=utf-8"}]
      assert Formatter.content_type(headers) == "application/vnd.api+json"
    end

    test "return default value when not found" do
      headers_one = [
        {"content-type", "application/json; charset=utf-8"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ]

      headers_two = [{"content-type", "text/plain"}]
      headers_three = [{"authorization", "Basic token"}]

      opt = [default: "multipart/mixed"]

      assert Formatter.content_type(headers_one, opt) == "application/json"
      assert Formatter.content_type(headers_two, opt) == "text/plain"
      assert Formatter.content_type(headers_three, opt) == "multipart/mixed"
    end
  end

  describe "authorization/1" do
    test "return the request authorization header" do
      headers_one = [
        {"authorization", "Bearer token"},
        {"cache-control", "max-age=0, private, must-revalidate"}
      ]

      headers_two = [{"content-type", "text/plain"}]

      assert Formatter.authorization(headers_one) == "Bearer token"
      assert Formatter.authorization(headers_two) == nil
    end
  end

  describe "format_path_parameter/1" do
    test "format parameter" do
      assert Formatter.format_path_parameter("id") == "id"
      assert Formatter.format_path_parameter("user_id") == "userId"
      assert Formatter.format_path_parameter("comment_user_id") == "commentUserId"
    end
  end
end
