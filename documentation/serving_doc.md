# Serving generated doc

You can use `Xcribe` to serve your API documentation. Currently we support serving
the `OpenAPI` format. To render documentation we use [Swagger UI](https://swagger.io/tools/swagger-ui/).

## Configuration

For serving with `Xcribe` you must configure doc format as `:openapi`, enable the `serve`
config, and say where the generated document is written with `file_path` and `file_name`.

```elixir
config :xcribe, YourAppWeb.Endpoint,
  format: :openapi,
  file_path: {"priv/static", "api"},
  file_name: "my_doc.json",
  serve: true
```

The title, description and server list shown by Swagger UI come from your specification file
(`.xcribe.exs` by default, see `Xcribe.Specification`), not from this configuration.

## Serving the generated file

`Xcribe.Web.Plug` renders the Swagger UI page and points it at the doc file, but it does not
serve the file itself — your application does. The directory a `Plug.Static` reads from never
appears in the URL it answers on, so a single path cannot describe both where the document is
written and where it is served. That is what the `{static_dir, sub_path}` tuple is for:

| `file_path`                  | written to                        | served at        |
| ---------------------------- | --------------------------------- | ---------------- |
| `{"priv/static", "api"}`     | `priv/static/api/my_doc.json`     | `/api/my_doc.json` |
| `{"priv/static", ""}`        | `priv/static/my_doc.json`         | `/my_doc.json`   |
| `"priv/static"`              | `priv/static/my_doc.json`         | `/my_doc.json`   |
| `nil`                        | `my_doc.json`                     | `/my_doc.json`   |

The served request has to reach a `Plug.Static` in your endpoint that serves the directory the
document was written to:

```elixir
plug Plug.Static,
  at: "/",
  from: :your_app,
  only: YourAppWeb.static_paths()
```

A Phoenix-generated endpoint already has this plug, but its `only:` option is an allow list,
so a file or directory that is not named there is never served and Swagger UI gets a 404
instead of the document. Add the doc to it:

```elixir
# lib/your_app_web.ex
def static_paths, do: ~w(assets fonts images favicon.ico robots.txt api)
```

If your `Plug.Static` is mounted somewhere other than `at: "/"`, or serves a directory other
than the one the document is written to, the served path will not resolve — mount an
additional `Plug.Static` for the doc at the root, or choose a different way to expose the
file. `mix xcribe.serve` checks this for you once your endpoint is running and tells you when
the document could not be fetched; the router forward checks nothing, so a path that does not
resolve simply shows up as a 404 in Swagger UI.

## Serving without touching your router

`mix xcribe.serve` starts your endpoint and serves the documentation, so nothing has to be
added to your router:

```sh
mix xcribe.serve
```

It only serves — generate the document with `mix xcribe.doc` first, and keep a web server in your
dependencies, either Bandit or `Plug.Cowboy` (a Phoenix application already has one). The port
comes from the `server_port` config key (default `4040`), and `open_browser: true` opens the
documentation in your browser.

The task serves the endpoint you configured with `serve: true`. When more than one endpoint has
it, name the one you want with `mix xcribe.serve -e YourAppWeb.Endpoint`; a named endpoint is
served whether or not its `serve` config is enabled.

The task has to run in the environment your Xcribe configuration lives in, so add it to
`preferred_envs` in your `mix.exs`:

```elixir
def cli do
  [preferred_envs: ["xcribe.doc": :test, "xcribe.serve": :test]]
end
```

See `Mix.Tasks.Xcribe.Serve` for more details.

## Routing

Add a doc scope to your router, and forward all requests to `Xcribe.Web.Plug`

```
      scope "/doc/openapi" do
        forward "/", Xcribe.Web.Plug, endpoint: YourAppWeb.Endpoint
      end

```
