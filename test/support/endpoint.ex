defmodule Xcribe.Endpoint do
  use Phoenix.Endpoint, otp_app: :xcribe_api

  plug(
    Plug.Static,
    at: "/",
    from: :xcribe_api,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
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

  plug(Xcribe.WebRouter)
end
