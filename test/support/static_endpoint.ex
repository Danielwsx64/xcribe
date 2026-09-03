defmodule Xcribe.StaticEndpoint do
  use Phoenix.Endpoint, otp_app: :xcribe

  plug(
    Plug.Static,
    at: "/",
    from: "test/support/",
    gzip: false,
    only: ~w(openapi_example.json)
  )

  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
end
