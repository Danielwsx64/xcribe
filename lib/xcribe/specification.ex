defmodule Xcribe.Specification do
  def api_specification(%{specification_source: file} = _config) do
    if File.exists?(file) do
      file
      |> File.read!()
      |> eval()
      |> merge_with_defaults()
      |> validate()
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
      schemas: Map.get(specifications, :schemas, %{})
    }
  end

  defp validate(specifications) do
    # TODO: handle it
    specifications
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
