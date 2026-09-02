# Serving generated doc

You can use `Xcribe` to serve your API documentation. Currently we support serving
the `OpenAPI` format. To render documentation we use [Swagger UI](https://swagger.io/tools/swagger-ui/).

## Configuration

For serving with `Xcribe` you must configure doc format as `:openapi` the output path
must be `priv/static` and you must enable `serve` config.

```elixir
config :xcribe, YourAppWeb.Endpoint,
  format: :openapi,
  output: "priv/static/my_doc.json",
  serve: true
```

The title, description and server list shown by Swagger UI come from your specification file
(`.xcribe.exs` by default, see `Xcribe.Specification`), not from this configuration.

## Routing

Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

```
      scope "doc/openapi" do
        forward "/", Xcribe.Web.Plug, endpoint: YourAppWeb.Endpoint
      end

```
