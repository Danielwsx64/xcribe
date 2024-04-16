defmodule Mix.Tasks.Xcribe.Gen.Spec do
  @moduledoc """
  Generate specification file.

  You can use OpenApi v3.0 specification to define schemas and custom path descriptions.
  See `Xcribe.Specification`

  ```sh
  mix xcribe.gen.spec
  ```
  """
  use Mix.Task

  alias Xcribe.CLI.Output
  alias Xcribe.Config
  alias Xcribe.Specification

  @shortdoc "Generate Xcribe specification file"

  @doc false
  def run(_opts) do
    default_file = Config.default_spec_file()

    if not File.exists?(default_file) do
      default_spec = Specification.api_specification(%{specification_source: default_file})

      File.write!(default_file, inspect(default_spec, pretty: true))
      Output.print_message("Created specification file #{default_file}")
    end
  end
end
