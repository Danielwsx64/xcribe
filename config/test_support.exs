import Config

config :phoenix, :json_library, Jason

# Phoenix config for the test-only endpoint in test/support/endpoint.ex
config :xcribe, Xcribe.Endpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("x", 64)

# Phoenix config for the test-only endpoint in test/support/static_endpoint.ex
config :xcribe, Xcribe.Support.StaticEndpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("x", 64)

config :logger, level: :warning
