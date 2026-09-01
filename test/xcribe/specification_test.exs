defmodule Xcribe.SpecificationTest do
  use ExUnit.Case, async: false

  alias Xcribe.Config
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
               ignore_namespaces: [],
               ignore_resources_prefix: [],
               servers: [%{url: "http://localhost:4000"}],
               version: "1.0.0"
             }
    end

    test "merge specific ignored namespaces with namespaces from servers urls" do
      config = %{specification_source: "test/support/.name_spaces_example.exs"}

      # Slash-less entries in the file gain a leading slash, and the list is ordered longest first
      # so a shorter namespace cannot strip part of a longer one.
      assert Specification.api_specification(config) == %{
               description: "",
               name: "API Documentation",
               paths: %{},
               schemas: %{},
               ignore_namespaces: ["/sandbox/v1", "/api", "/v1"],
               ignore_resources_prefix: [],
               servers: [
                 %{url: "https://api.xcribe.com/v1"},
                 %{url: "https://sandbox.xcribe.com/sandbox/v1"}
               ],
               version: "1.0.0"
             }
    end

    test "merge empty map when default file does not exist" do
      config = %{specification_source: Config.default_spec_file()}

      refute File.exists?(config.specification_source),
             "this test asserts the defaults, so the repository must not carry a spec file"

      assert Specification.api_specification(config) == %{
               description: "",
               ignore_namespaces: [],
               ignore_resources_prefix: [],
               name: "API Documentation",
               paths: %{},
               schemas: %{},
               servers: [%{url: "http://localhost:4000"}],
               version: "1.0.0"
             }
    end

    @tag :tmp_dir
    test "raise error when file has invalid syntax", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, ~s(%{\n  "missing_comma" => 1\n  "missing_comma" => 2\n}\n))

      config = %{specification_source: file}

      assert_raise SpecificationFile,
                   ~r"Specification file has invalid Elixir syntax\. Check: #{file}",
                   fn -> Specification.api_specification(config) end
    end

    @tag :tmp_dir
    test "raise error when file does not evaluate to a map", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, ~s([name: "API"]\n))

      config = %{specification_source: file}

      assert_raise SpecificationFile,
                   ~r"Specification file must evaluate to a map\. Check: #{file}",
                   fn -> Specification.api_specification(config) end
    end

    @tag :tmp_dir
    test "raise error when a server has no url", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, ~s(%{servers: [%{"url" => "http://my-api.com"}]}\n))

      config = %{specification_source: file}

      assert_raise SpecificationFile,
                   ~r"Every entry in `servers` must be a map with a `:url` string",
                   fn -> Specification.api_specification(config) end
    end

    @tag :tmp_dir
    test "raise error when a key that must be a map is not one", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, ~s(%{schemas: []}\n))

      config = %{specification_source: file}

      assert_raise SpecificationFile,
                   ~s(The `schemas` key of the specification file must be a map. Got: []),
                   fn -> Specification.api_specification(config) end
    end

    @tag :tmp_dir
    test "raise error when a key that must be a list is not one", %{tmp_dir: tmp_dir} do
      file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(file, ~s(%{servers: %{url: "http://my-api.com"}}\n))

      config = %{specification_source: file}

      assert_raise SpecificationFile,
                   ~r"The `servers` key of the specification file must be a list",
                   fn -> Specification.api_specification(config) end
    end

    test "raise when a configured file does not exist, guarding skipped config validation" do
      config = %{specification_source: "test/support/.not_exists.exs"}

      assert_raise SpecificationFile, "File not found test/support/.not_exists.exs", fn ->
        Specification.api_specification(config)
      end
    end
  end

  describe "defaults/0" do
    test "return the normalized specification with no file involved" do
      assert Specification.defaults() == %{
               description: "",
               name: "API Documentation",
               paths: %{},
               schemas: %{},
               ignore_namespaces: [],
               ignore_resources_prefix: [],
               servers: [%{url: "http://localhost:4000"}],
               version: "1.0.0"
             }
    end
  end
end
