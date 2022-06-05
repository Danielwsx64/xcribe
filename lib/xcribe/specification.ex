defmodule Xcribe.Specification do
  @moduledoc """
  Specification file.

  You can add additional information to generated doc by creating a specification
  file. With the spec file you can define description for routes, parameters, responses,
  and define custom Schemas. The specification file follows the struct of the 
  OpenApi v3.0.3 json specification.

  To generate a new specification file use 

  The specification file has two special parameters you can define.

    * `:ignore_namespaces` - A list with namespace prefix to be ignored from paths, default
    tags and schema names. The default value is an empty list. Paths from serves list
    will be automatic added as `ignored_namespaces`. Ex: A server `"http://app.com/v1"` will
    add the namespace `/v1` to be ignored on paths. If you add your custom list
    of namespaces it will be concatened with the list from servers paths.

    * `:ignore_resources_prefix` - A list with prefix to be removed from groups and schmas default names.


  Example of specification file

      %{
        name: "Basic API",
        description: "The description of the API",
        version: "1.0.0",
        servers: [%{url: "http://my-api.com"}],
        ignore_namespaces: ["/api/v1"],
        ignore_resources_prefix: ["Example"],
        paths: %{},
        schemas: %{}
       }
  """

  # TODO: add doc para mix generate

  alias Xcribe.Config
  alias Xcribe.SpecificationFile

  @doc false
  def api_specification(%{specification_source: file} = _config) do
    if File.exists?(file) do
      file
      |> File.read!()
      |> eval(file)
      |> merge_step()
    else
      if file == Config.default_spec_file() do
        merge_step(%{})
      else
        raise SpecificationFile, "File not found #{file}"
      end
    end
  end

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
      servers: Map.get(specifications, :servers, [%{url: "https://api.xcribe.com/v1"}]),
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
      |> Enum.reject(&is_nil(&1))
      |> Enum.uniq()
    end)
  end

  defp parse_url(%{url: url}) do
    url
    |> URI.parse()
    |> Map.get(:path)
  end

  defp eval(string, file) do
    {%{} = map, _bindings} = Code.eval_string(string)

    map
  rescue
    e ->
      raise(
        SpecificationFile,
        {"Specification file has invalid Elixir syntax. Check: #{file}", e, __STACKTRACE__}
      )
  end
end
