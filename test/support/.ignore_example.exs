%{
  name: "Basic API",
  description: "The description of the API",
  version: "1.0.0",
  servers: [%{url: "http://my-api.com"}],
  ignore_namespaces: ["namespace_ignored", "/namespace_with_undescore"],
  ignore_resources_prefix: ["Users"],
  paths: %{
    "/notes" => %{"get" => %{description: "Keyed by the stripped path, not the routed one"}}
  },
  schemas: %{}
}
