defmodule Xcribe.ContentDecoderTest do
  use ExUnit.Case, async: true

  alias Xcribe.ContentDecoder
  alias Xcribe.ContentDecoder.UnknownType

  describe "decode!/3" do
    test "decode content when type is know json" do
      config = %{json_library: Jason}
      value = "{\"key\":\"value\"}"

      assert ContentDecoder.decode!(value, "application/json", config) == %{"key" => "value"}

      assert ContentDecoder.decode!(value, "application/vnd.api+json", config) == %{
               "key" => "value"
             }
    end

    test "decode content when type is know text plain" do
      value = "successfuly created!"

      assert ContentDecoder.decode!(value, "text/plain", %{}) == value
    end

    test "raise UnknownType when content_type is unknown" do
      assert_raise UnknownType, "Couldn't decode value. Type application/xml is unknown.", fn ->
        assert ContentDecoder.decode!("", "application/xml", %{})
      end
    end

    test "raise blabla when value cant be decoded" do
      assert_raise Jason.DecodeError, fn ->
        config = %{json_library: Jason}
        assert ContentDecoder.decode!("invalidjson", "application/json", config)
      end
    end
  end

  describe "decode/3" do
    test "decode content when type is know json" do
      config = %{json_library: Jason}
      value = "{\"key\":\"value\"}"

      assert ContentDecoder.decode(value, "application/json", config) ==
               {:ok, %{"key" => "value"}}

      assert ContentDecoder.decode(value, "application/vnd.api+json", config) ==
               {:ok, %{"key" => "value"}}
    end

    test "decode content when type is know text plain" do
      value = "successfuly created!"

      assert ContentDecoder.decode(value, "text/plain", %{}) == {:ok, value}
    end

    test "return an error when content_type is unknown" do
      assert ContentDecoder.decode("", "application/xml", %{}) ==
               {:error, {:unknown_content_type, "application/xml"}}
    end

    test "raise when a known content type holds an invalid value" do
      assert_raise Jason.DecodeError, fn ->
        ContentDecoder.decode("invalidjson", "application/json", %{json_library: Jason})
      end
    end
  end
end
