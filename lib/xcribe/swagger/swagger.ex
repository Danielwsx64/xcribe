defmodule Xcribe.Swagger do
  @moduledoc false

  alias Xcribe.{DocException, JSON, Request}
  alias Xcribe.Swagger.Formatter

  import Xcribe.Swagger.Formatter, only: [raw_openapi_object: 0]

  @doc """
  Return an OpenAPI Document builded from the given requests list
  """
  def generate_doc(requests, config) do
    raw_openapi_object()
    |> mount_data_in_raw_object(requests, config)
    |> json_encode!(config)
  end

  defp mount_data_in_raw_object(openapi, requests, config) do
    xcribe_info = xcribe_info(config.information_source)

    %{
      openapi
      | info: Formatter.info_object(xcribe_info),
        servers: Formatter.server_object(xcribe_info),
        paths: build_paths_object(requests, config),
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
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
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

  defp xcribe_info(information_source), do: apply(information_source, :api_info, [])
  defp json_encode!(openapi, config), do: JSON.encode!(openapi, [], config)
end
