defmodule Xcribe.Swagger do
  @moduledoc false

  alias Xcribe.{DocException, JSON, Request, Schema, Specification}
  alias Xcribe.Swagger.{Formatter, Merge}

  def generate_doc(requests, config) do
    specification = Specification.api_specification(config)

    requests
    |> build_paths_and_components(specification, config)
    |> build_openapi_object(specification)
    |> json_encode!(config)
  end

  defp build_paths_and_components(requests, spec, config) do
    initial = %{paths: %{}, schemas: spec.schemas, security: %{}}

    requests
    |> Enum.reduce(initial, fn request, acc ->
      request
      |> request_objects(spec, config)
      |> merge_objects(acc, request)
    end)
    |> Map.update!(:paths, &Merge.overlay_paths(&1, spec.paths))
  end

  defp build_openapi_object(%{paths: _, schemas: _, security: _} = params, specification) do
    %{
      Formatter.openapi_object(specification)
      | paths: params.paths,
        components: %{schemas: params.schemas, securitySchemes: params.security}
    }
  end

  defp merge_objects(news, acc, request) do
    %{
      acc
      | paths: Merge.paths(acc.paths, news.path),
        schemas: Schema.merge(acc.schemas, news.schemas),
        security: Map.merge(acc.security, news.security)
    }
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp request_objects(request, specification, config) do
    request
    |> Request.remove_ignored_prefixes(specification)
    |> Formatter.request_objects(config)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp json_encode!(openapi, config), do: JSON.encode!(openapi, [], config)
end
