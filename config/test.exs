use Mix.Config

config :phoenix, :json_library, Jason

config :xcribe, Xcribe.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tGNNYXq5iErTYThrtQmu5oFVPspt6+rpQN+eXR8VMlhzMC/YENkFNmxkyUeU/Gr/"

config :logger, level: :warn
