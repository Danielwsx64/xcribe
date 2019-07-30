use Mix.Config

config :xcribe, :information_source, Xcribe.Support.Information
config :xcribe, :output_file, "teste.apib"

# Support Config
import_config "test_support.exs"
