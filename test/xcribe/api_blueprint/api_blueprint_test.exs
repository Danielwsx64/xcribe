defmodule Xcribe.ApiBlueprintTest do
  use ExUnit.Case, async: true

  alias Xcribe.{ApiBlueprint, DocException, Request}
  alias Xcribe.Support.RequestsGenerator

  @sample_apib_output File.read!("test/support/api_blueprint_example.apib")

  setup do
    {:ok,
     %{config: %{specification_source: "test/support/.simple_example.exs", json_library: Jason}}}
  end

  describe "generate_doc/2" do
    test "generate doc", %{config: config} do
      requests = [
        RequestsGenerator.users_index([:basic_auth]),
        RequestsGenerator.users_show([:basic_auth]),
        RequestsGenerator.users_create([:bearer_auth]),
        RequestsGenerator.users_update([:bearer_auth]),
        RequestsGenerator.users_delete([:bearer_auth]),
        RequestsGenerator.users_custom_action([:api_key_auth]),
        RequestsGenerator.users_posts_index([:api_key_auth]),
        RequestsGenerator.users_posts_create([:api_key_auth]),
        RequestsGenerator.users_posts_update([:api_key_auth])
      ]

      assert ApiBlueprint.generate_doc(requests, config) == @sample_apib_output
    end

    test "document a request without groups tags", %{config: config} do
      requests = [RequestsGenerator.users_index(groups_tags: [])]

      doc = ApiBlueprint.generate_doc(requests, config)

      refute doc =~ "## Group"
      assert doc =~ "### Users index [GET /users]"
    end

    test "use the description of a specified path" do
      config = %{
        specification_source: "test/support/.paths_example.exs",
        json_library: Jason
      }

      doc = ApiBlueprint.generate_doc([RequestsGenerator.users_index()], config)

      assert doc =~ "### Users index [GET /users]\nList every user in the account\n\n"
    end

    test "name a schema in the generated document", %{config: config} do
      requests = [RequestsGenerator.users_create(schema: "Users", req_schema: "createUsers")]

      doc = ApiBlueprint.generate_doc(requests, config)

      assert doc =~ ~s("title": "createUsers")
      assert doc =~ ~s("title": "Users")
    end

    test "strip ignored namespaces and resource prefixes" do
      config = %{
        specification_source: "test/support/.ignore_example.exs",
        json_library: Jason
      }

      requests = [RequestsGenerator.notes_index(), RequestsGenerator.users_posts_index()]

      doc = ApiBlueprint.generate_doc(requests, config)

      assert doc =~ "## Group Notes"
      assert doc =~ "## Notes [/notes]"
      assert doc =~ "## Group Posts"
      refute doc =~ "Namespace Ignored"
    end

    @tag :tmp_dir
    test "document an api with no servers", %{tmp_dir: tmp_dir} do
      spec_file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(spec_file, ~s(%{name: "Basic API", servers: []}\n))

      config = %{specification_source: spec_file, json_library: Jason}

      doc = ApiBlueprint.generate_doc([RequestsGenerator.users_index()], config)

      assert doc =~ "HOST: \n"
      assert doc =~ "# Basic API"
    end

    test "handle exception", %{config: config} do
      requests = [
        %Request{
          __meta__: %{
            call: %{
              description: "conn test",
              file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
              line: 25
            }
          }
        }
      ]

      assert_raise DocException, "An exception was raised. Elixir.FunctionClauseError", fn ->
        ApiBlueprint.generate_doc(requests, config)
      end
    end
  end
end
