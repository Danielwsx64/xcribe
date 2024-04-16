defmodule Xcribe.RequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request

  describe "format_schema/1" do
    test "when has custom schema always return custom schema" do
      request = %Request{schema: "Users", status_code: 200}
      request_error = %Request{schema: "Users", status_code: 404}

      assert Request.format_schema(request) == request.schema
      assert Request.format_schema(request_error) == request_error.schema
    end

    test "when has not custom schema return resource and change by status" do
      request = %Request{schema: nil, status_code: 200, resource: "Users Posts"}
      request_error = %Request{schema: nil, status_code: 404, resource: "Users Posts"}

      assert Request.format_schema(request) == "UsersPosts"
      assert Request.format_schema(request_error) == "404_UsersPosts"
    end
  end

  describe "format_req_schema/1" do
    test "when has custom req_schema always return custom req_schema" do
      request_create = %Request{req_schema: "Users", action: "create", resource: "Users Posts"}
      request_update = %Request{req_schema: "Users", action: "update", resource: "Users Posts"}

      assert Request.format_req_schema(request_create) == request_create.req_schema
      assert Request.format_req_schema(request_update) == request_update.req_schema
    end

    test "when has not custom req_schema return resource and change by action" do
      request_create = %Request{req_schema: nil, action: "create", resource: "Users Posts"}
      request_update = %Request{req_schema: nil, action: "update", resource: "Users Posts"}

      assert Request.format_req_schema(request_create) == "createUsersPosts"
      assert Request.format_req_schema(request_update) == "updateUsersPosts"
    end
  end

  describe "remove_ignored_prefixes/2" do
    test "ignore prefixes in specification rules" do
      specification = %{
        ignore_namespaces: ["/sandbox", "/api/v1", "/with_underscore"],
        ignore_resources_prefix: ["Organizations Companies"]
      }

      request_api = %Request{
        groups_tags: ["Api V1 Organizations Companies Contacts"],
        path: "/api/v1/organizations/{organization_id}/companies/{company_id}/contacts",
        resource: "Api V1 Organizations Companies Contacts"
      }

      request_sandbox = %Request{
        groups_tags: ["Sandbox Organizations Companies Contacts"],
        path: "/sandbox/organizations/{organization_id}/companies/{company_id}/contacts",
        resource: "Sandbox Organizations Companies Contacts"
      }

      request_with_underscore = %Request{
        groups_tags: ["With Underscore Organizations Companies Contacts"],
        path: "/with_underscore/organizations/{organization_id}/companies/{company_id}/contacts",
        resource: "With Underscore Organizations Companies Contacts"
      }

      expected = %Request{
        groups_tags: ["Contacts"],
        path: "/organizations/{organization_id}/companies/{company_id}/contacts",
        resource: "Contacts"
      }

      assert Request.remove_ignored_prefixes(request_api, specification) == expected
      assert Request.remove_ignored_prefixes(request_sandbox, specification) == expected
      assert Request.remove_ignored_prefixes(request_with_underscore, specification) == expected
    end
  end
end
