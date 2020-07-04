# Serving generated doc

You can use `Xcribe` to serve your API documentation. Currently we support serve
`Swagger` format. To render documentation we use [Swagger UI](https://swagger.io/tools/swagger-ui/).

## Configuration

For serving with `Xcribe` you must configure doc format as `:swagger` the output path
must be `priv/static` and you must enable `serve` config.

```
      config :xcribe,
        information_source: YourApp.YouModuleInformation,
        format: :swagger,
        output: "priv/static/my_doc.json",
        serve: true

```

## Routing
