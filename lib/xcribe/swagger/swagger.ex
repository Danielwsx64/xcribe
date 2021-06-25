defmodule Xcribe.Swagger do
  @moduledoc false

  alias Xcribe.{Config, DocException, JSON, Request}
  alias Xcribe.Swagger.Formatter

  import Xcribe.Swagger.Formatter, only: [raw_openapi_object: 0]

  @doc """
  Return an OpenAPI Document builded from the given requests list
  """
  def generate_doc(requests) do
    raw_openapi_object()
    |> mount_data_in_raw_object(requests)
    |> json_encode!()
  end

  defp mount_data_in_raw_object(openapi, requests) do
    %{
      openapi
      | info: Formatter.info_object(xcribe_info()),
        servers: Formatter.server_object(xcribe_info()),
        paths: build_paths_object(requests),
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

  defp build_paths_object(requests),
    do: Enum.reduce(requests, %{}, &paths_object_func/2)

  defp paths_object_func(%Request{path: path, verb: verb} = request, paths) do
    item = Formatter.path_item_object_from_request(request)

    Map.update(
      paths,
      path,
      item,
      &Formatter.merge_path_item_objects(&1, item, verb)
    )
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp xcribe_info, do: apply(Config.fetch!(:xcribe_information_source), :api_info, [])
  defp json_encode!(openapi), do: JSON.encode!(openapi)
end
