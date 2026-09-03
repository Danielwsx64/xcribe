# Serving generated doc

You can use `Xcribe` to serve your API documentation. Currently we support serving
the `OpenAPI` format. To render documentation we use [Swagger UI](https://swagger.io/tools/swagger-ui/).

## Configuration

For serving with `Xcribe` you must configure doc format as `:openapi`, the output path
must be inside `priv/static` and you must enable `serve` config.

```elixir
config :xcribe, YourAppWeb.Endpoint,
  format: :openapi,
  output: "priv/static/my_doc.json",
  serve: true
```

The title, description and server list shown by Swagger UI come from your specification file
(`.xcribe.exs` by default, see `Xcribe.Specification`), not from this configuration.

## Serving the generated file

`Xcribe.Web.Plug` renders the Swagger UI page and points it at the doc file, but it does not
serve the file itself — your application does. The URL handed to Swagger UI is the `output`
path with the `priv/static` prefix removed, so `priv/static/my_doc.json` is requested as
`/my_doc.json`.

That request has to reach a `Plug.Static` in your endpoint that serves your application's
`priv/static` at the root:

```elixir
plug Plug.Static,
  at: "/",
  from: :your_app,
  only: YourAppWeb.static_paths()
```

A Phoenix-generated endpoint already has this plug, but its `only:` option is an allow list,
so a file that is not named there is never served and Swagger UI gets a 404 instead of the
document. Add the doc file to it:

```elixir
# lib/your_app_web.ex
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt my_doc.json)
```

If your `Plug.Static` is mounted somewhere other than `at: "/"`, or serves a directory other
than your application's `priv/static`, the stripped path will not resolve — mount an
additional `Plug.Static` for the doc at the root, or choose a different way to expose the
file.

## Routing

Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

```
      scope "doc/openapi" do
        forward "/", Xcribe.Web.Plug, endpoint: YourAppWeb.Endpoint
      end

```
