defmodule Xcribe.Specification do
  @moduledoc """
  Add this doc
  """

  @doc false
  def api_specification(%{specification_source: file} = _config) do
    if File.exists?(file) do
      file
      |> File.read!()
      |> eval()
      |> merge_with_defaults()
      |> validate()
      |> include_servers_path_as_ignored_namespaces()
    else
      # TODO: handle it
    end
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

  defp validate(specifications) do
    # TODO: handle it
    specifications
  end

  defp parse_url(%{url: url}) do
    url
    |> URI.parse()
    |> Map.get(:path)
  end

  defp eval(string) do
    {%{} = map, _bindings} = Code.eval_string(string)

    map
  rescue
    _any ->
      # TODO: handle this
      %{}
  end
end
