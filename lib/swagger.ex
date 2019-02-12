defmodule Xcribe.Swagger do
  alias Xcribe.Structs.{SwaggerData, ParsedRequest}

  def add_request(%SwaggerData{} = data, %ParsedRequest{} = request) do
    data
    |> include_path(request)
    |> include_verb(request)
  end

  defp include_path(%{paths: paths} = data, %{path: path}) do
    if path_already_included?(paths, path) do
      data
    else
      paths
      |> Map.put(path, %{})
      |> update_paths_on_data(data)
    end
  end

  defp include_verb(%{paths: paths} = data, %{path: path, verb: verb} = request) do
    if verb_already_included?(paths, path, verb) do
      data
    else
      request
      |> build_verb_struct()
      |> include_verb_on_path(paths, path, verb)
      |> update_path_on_paths(paths, path)
      |> update_paths_on_data(data)
    end
  end

  defp path_already_included?(paths, path), do: Map.has_key?(paths, path)

  defp verb_already_included?(paths, path, verb),
    do: paths |> Map.fetch!(path) |> Map.has_key?(verb)

  defp update_paths_on_data(updated_paths, data),
    do: Map.put(data, :paths, updated_paths)

  defp update_path_on_paths(updated_path, paths, path),
    do: Map.put(paths, path, updated_path)

  defp include_verb_on_path(verb_struct, paths, path, verb),
    do: paths |> Map.fetch!(path) |> Map.put(verb, verb_struct)

  defp build_verb_struct(request) do
    %{
      "summary" => build_verb_summary(request),
      "operationId" => build_verb_operation_id(request)
    }
    |> Map.merge(build_verb_produces(request))
  end

  defp build_verb_produces(%{resp_headers: headers}) do
    headers
    |> Enum.find(fn
      {"content-type", _} -> true
      {_, _} -> false
    end)
    |> parse_produces_type()
  end

  defp parse_produces_type(nil), do: %{}
  defp parse_produces_type([_, matched]), do: %{"produces" => [matched]}

  defp parse_produces_type({_, type}) do
    ~r/(^\w+\/\w+).*/
    |> Regex.run(type)
    |> parse_produces_type()
  end

  defp build_verb_summary(%{resource: resource, action: action}),
    do: "#{resource} #{action}" |> String.capitalize()

  defp build_verb_operation_id(%{resource: resource, action: action}),
    do: "#{resource}#{String.capitalize(action)}"
end
