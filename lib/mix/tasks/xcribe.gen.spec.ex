defmodule Mix.Tasks.Xcribe.Gen.Spec do
  @moduledoc """
  Generate specification file.

  You can use OpenApi v3.0 specification to define schemas and custom path descriptions.
  See `Xcribe.Specification`

  ```sh
  mix xcribe.gen.spec
  ```

  The file is created at `.xcribe.exs`. Use `--output` (`-o`) to write it somewhere else, and
  point `specification_source` at that path.

  ```sh
  mix xcribe.gen.spec -o priv/api_spec.exs
  ```

  An existing file is never overwritten.
  """
  use Mix.Task

  alias Xcribe.{CLI.Output, Config, Specification, Writter}

  @shortdoc "Generate Xcribe specification file"

  @doc false
  def run(opts) do
    opts
    |> output_path()
    |> write_specification()
  end

  defp output_path(opts) do
    {options, _rest, _invalid} =
      OptionParser.parse_head(opts, aliases: [o: :output], strict: [output: :string])

    Keyword.get(options, :output, Config.default_spec_file())
  end

  defp write_specification(file), do: write_specification(file, File.exists?(file))

  defp write_specification(file, true) do
    Output.print_message("Specification file #{file} already exists", :error)

    exit({:shutdown, 1})
  end

  defp write_specification(file, false) do
    Writter.write(template(Specification.defaults()), %{output: file}, "specification file")
  end

  defp template(defaults) do
    """
    %{
      name: #{inspect(defaults.name)},
      description: #{inspect(defaults.description)},
      version: #{inspect(defaults.version)},
      servers: #{inspect(defaults.servers)},
      ignore_namespaces: #{inspect(defaults.ignore_namespaces)},
      ignore_resources_prefix: #{inspect(defaults.ignore_resources_prefix)},
      paths: #{inspect(defaults.paths)},
      schemas: #{inspect(defaults.schemas)}
    }
    """
  end
end
