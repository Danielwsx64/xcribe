defmodule Xcribe.SpecificationTest do
  use ExUnit.Case, async: true

  alias Xcribe.Specification
  alias Xcribe.SpecificationFile

  describe "api_specification/1" do
    test "return specifications defined by the file" do
      config = %{specification_source: "test/support/.xcribe.exs"}

      assert Specification.api_specification(config) ==
               %{
                 description:
                   "Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse exercitation amet.\nNisi anim cupidatat excepteur officia. Reprehenderit nostrud nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor minim nulla est proident.\nNostrud officia pariatur ut officia. Sit irure elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris cupidatat officia voluptate.\nCulpa proident adipisicing id nulla nisi laboris ex in Lorem sunt duis officia eiusmod. Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim.\nVoluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa et culpa duis.\nLorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.\n",
                 name: "Xcribe API",
                 paths: %{},
                 schemas: %{},
                 ignore_namespaces: ["/v1"],
                 ignore_resources_prefix: [],
                 servers: [
                   %{url: "https://api.xcribe.com/v1"},
                   %{
                     description:
                       "Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint consectetur cupidatat.\n",
                     url: "https://sandbox.xcribe.com/v1"
                   }
                 ],
                 version: "1.0.0"
               }
    end

    test "use default values for undefined specifications" do
      config = %{specification_source: "test/support/.empty.exs"}

      assert Specification.api_specification(config) == %{
               description: "",
               name: "API Documentation",
               paths: %{},
               schemas: %{},
               ignore_namespaces: ["/v1"],
               ignore_resources_prefix: [],
               servers: [%{url: "https://api.xcribe.com/v1"}],
               version: "1.0.0"
             }
    end

    test "merge specific ignored namespaces with namespaces from servers urls" do
      config = %{specification_source: "test/support/.name_spaces_example.exs"}

      assert %{
               ignore_namespaces: ["/v1", "/sandbox/v1", "api", "v1"],
               servers: [
                 %{url: "https://api.xcribe.com/v1"},
                 %{url: "https://sandbox.xcribe.com/sandbox/v1"}
               ]
             } = Specification.api_specification(config)
    end

    test "merge empty map when default file does not exist" do
      config = %{specification_source: ".xcribe.exs"}

      assert Specification.api_specification(config) == %{
               description: "",
               ignore_namespaces: ["/v1"],
               ignore_resources_prefix: [],
               name: "API Documentation",
               paths: %{},
               schemas: %{},
               servers: [%{url: "https://api.xcribe.com/v1"}],
               version: "1.0.0"
             }
    end

    test "raise error when file has invalid sintax" do
      config = %{specification_source: "test/support/.invalid_sintax.exs"}

      assert_raise SpecificationFile,
                   "Specification file has invalid Elixir syntax. Check: test/support/.invalid_sintax.exs\n** (SyntaxError) nofile:3:3: syntax error before: \"missing_comma\"\n",
                   fn ->
                     Specification.api_specification(config)
                   end
    end

    test "raise error when file does not exist" do
      config = %{specification_source: "test/support/.not_exists.exs"}

      assert_raise SpecificationFile, "File not found test/support/.not_exists.exs", fn ->
        Specification.api_specification(config)
      end
    end
  end
end
