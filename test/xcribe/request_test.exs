defmodule Xcribe.RequestTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request

  describe "remove_ignored_prefixes/2" do
    test "ignore prefixes in specification rules" do
      specification = %{ignore_namespaces: ["/sandbox", "/api/v1"]}

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

      expected = %Request{
        groups_tags: ["Organizations Companies Contacts"],
        path: "/organizations/{organization_id}/companies/{company_id}/contacts",
        resource: "Organizations Companies Contacts"
      }

      assert Request.remove_ignored_prefixes(request_api, specification) == expected
      assert Request.remove_ignored_prefixes(request_sandbox, specification) == expected
    end
  end
end
