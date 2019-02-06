defmodule ApiBluefy.Endpoint do
  use Phoenix.Endpoint, otp_app: :api_bluefy

  plug(
    Plug.Static,
    at: "/",
    from: :api_bluefy,
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

  plug(ApiBluefy.WebRouter)

  def init(_key, config), do: {:ok, config}
end
