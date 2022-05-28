defmodule Xcribe.Swagger do
  @moduledoc false

  alias Xcribe.DocException
  alias Xcribe.Specification
  alias Xcribe.JSON
  alias Xcribe.Request
  alias Xcribe.Swagger.Formatter

  def generate_doc(requests, config) do
    specification = Specification.api_specification(config)

    specification
    |> Formatter.openapi_object()
    |> build_paths_and_components(requests, config)
    |> json_encode!(config)
  end

  defp build_paths_and_components(openapi, requests, config) do
    %{
      openapi
      | paths: build_paths_object(requests, config),
        components: %{
          securitySchemes: build_security_schemes(requests)
        }
    }
  end

  defp build_security_schemes(requests) do
    Enum.reduce(requests, %{}, &merge_security_schemas/2)
  end

  defp merge_security_schemas(request, schemas) do
    Map.merge(schemas, Formatter.security_scheme_object_from_request(request))
  end

  defp build_paths_object(requests, config),
    do: Enum.reduce(requests, %{}, &paths_object_func(&1, &2, config))

  defp paths_object_func(%Request{path: path, verb: verb} = request, paths, config) do
    item =
      request
      |> Map.update(:__meta__, %{config: config}, &Map.put(&1, :config, config))
      |> Formatter.path_item_object_from_request()

    Map.update(
      paths,
      path,
      item,
      &Formatter.merge_path_item_objects(&1, item, verb)
    )
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp json_encode!(openapi, config), do: JSON.encode!(openapi, [], config)
end
