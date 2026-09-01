defmodule Xcribe.Specification do
  @moduledoc """
  The specification file.

  Xcribe reads everything it cannot learn from a `Plug.Conn` — your API's title, description,
  version and servers — from a specification file. It is plain Elixir that evaluates to a map, and
  it follows the OpenAPI v3.0.3 structure.

  Generate one with `mix xcribe.gen.spec` (see `Mix.Tasks.Xcribe.Gen.Spec`):

  ```sh
  mix xcribe.gen.spec
  ```

  The default path is `.xcribe.exs` in the project root, and it is optional — without it Xcribe
  documents your API using the defaults below. Point the `:specification_source` config key at
  another path to move it.

  ## Keys

    * `:name` - The API title. Default `"API Documentation"`.

    * `:description` - A long description of the API. Default `""`.

    * `:version` - The API version. Default `"1.0.0"`. Swagger only; API Blueprint has no
    field for it.

    * `:servers` - A list of maps, each with a `:url` and an optional `:description`. Swagger emits
    all of them; API Blueprint has a single `HOST` and uses the first.

    * `:paths` - Values to overlay onto the generated routes, keyed by path and then by HTTP verb.
    Anything you write here wins over what Xcribe generated. **The path key must be the path as it
    appears in the finished document** — that is, after `:ignore_namespaces` and the server paths
    have been stripped. With `ignore_namespaces: ["/api/v1"]`, the route `/api/v1/users` is keyed
    as `"/users"`. Swagger accepts a full OpenAPI Path Item Object, and a path no test documented
    is added to the document as-is. API Blueprint has no equivalent structure: it reads only
    `:description`, and it cannot add a route no test documented.

    * `:schemas` - Named component schemas, merged with the ones Xcribe derives from your
    responses. Where both define the same name, your schema wins for every field except
    `properties`, which is merged, and a generated `example` or `format` on a leaf. Swagger only —
    API Blueprint has no component section.

    * `:ignore_namespaces` - Prefixes to strip from paths, default group tags and default schema
    names. Default `[]`. A leading slash is optional: `"api"` and `"/api"` behave the same. The
    path of every entry in `:servers` is added automatically, so a server
    `"http://app.com/v1"` contributes `"/v1"`. Longer prefixes are always tried first.

    * `:ignore_resources_prefix` - Prefixes to strip from group tags and default schema names,
    after `:ignore_namespaces` has been applied. Default `[]`. Useful for a nested resource:
    with `["Users"]`, the resource `"Users Posts"` is documented as `"Posts"`.

  ## Example

      %{
        name: "Basic API",
        description: "The description of the API",
        version: "1.0.0",
        servers: [%{url: "http://my-api.com"}],
        ignore_namespaces: ["/api/v1"],
        ignore_resources_prefix: ["Organizations"],
        paths: %{
          "/users" => %{
            "get" => %{description: "List every user in the account"}
          }
        },
        schemas: %{}
      }

  Note that paths and verbs are strings, while the keys inside a path item are atoms — that is
  what the map literal above gives you naturally.

  Only the keys listed above are read; anything else in the map is ignored, so a misspelled key is
  silently a no-op rather than an error.
  """

  alias Xcribe.{Config, SpecificationFile}

  @default_server_url "http://localhost:4000"

  @doc false
  def api_specification(%{specification_source: file}),
    do: file |> read(File.exists?(file)) |> merge_step()

  @doc false
  def defaults, do: merge_step(%{})

  defp read(file, true), do: file |> File.read!() |> eval(file)
  defp read(file, false), do: missing(file, file == Config.default_spec_file())

  defp missing(_file, true), do: %{}

  defp missing(file, false), do: raise(SpecificationFile, "File not found #{file}")

  defp merge_step(specifications) do
    specifications
    |> merge_with_defaults()
    |> include_servers_path_as_ignored_namespaces()
  end

  defp merge_with_defaults(specifications) do
    %{
      name: Map.get(specifications, :name, "API Documentation"),
      description: Map.get(specifications, :description, ""),
      version: Map.get(specifications, :version, "1.0.0"),
      servers: Map.get(specifications, :servers, [%{url: @default_server_url}]),
      paths: Map.get(specifications, :paths, %{}),
      schemas: Map.get(specifications, :schemas, %{}),
      ignore_namespaces: Map.get(specifications, :ignore_namespaces, []),
      ignore_resources_prefix: Map.get(specifications, :ignore_resources_prefix, [])
    }
  end

  defp include_servers_path_as_ignored_namespaces(specifications) do
    specifications
    |> Map.update!(:ignore_namespaces, fn namespaces ->
      specifications.servers
      |> Enum.map(&parse_url/1)
      |> Enum.concat(namespaces)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&with_leading_slash/1)
      |> Enum.uniq()
      |> Enum.sort_by(&byte_size/1, :desc)
    end)
  end

  defp with_leading_slash("/" <> _rest = namespace), do: namespace
  defp with_leading_slash(namespace), do: "/" <> namespace

  defp parse_url(%{url: url}) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
  end

  defp parse_url(server) do
    raise SpecificationFile,
          "Every entry in `servers` must be a map with a `:url` string. Got: #{inspect(server)}"
  end

  defp eval(string, file) do
    string
    |> Code.eval_string()
    |> to_specification(file)
  rescue
    e in [CompileError, SyntaxError, TokenMissingError, MismatchedDelimiterError] ->
      raise(
        SpecificationFile,
        {"Specification file has invalid Elixir syntax. Check: #{file}", e, __STACKTRACE__}
      )
  end

  defp to_specification({%{} = map, _bindings}, _file), do: map

  defp to_specification({other, _bindings}, file) do
    raise SpecificationFile,
          "Specification file must evaluate to a map. Check: #{file}. Got: #{inspect(other)}"
  end
end
