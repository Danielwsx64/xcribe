defmodule Xcribe.APIModel do
  @moduledoc false

  alias Xcribe.APIModel.{Operation, Route}
  alias Xcribe.{DocException, Request, Schema}

  defstruct routes: [], schemas: %{}, security_schemes: []

  @doc """
  Build a format agnostic model of the documented API from a list of recorded requests.

  Requests sharing a path and a verb collapse into one operation: parameters are unioned by name
  and location, request and response bodies are merged into one schema per content type, and every
  recorded request is kept as an example so a format can render one block per test scenario. The
  named schemas of every operation are collected into a single registry, which a format can emit as
  components and reference by name instead of repeating them.

  The ignored namespaces and resource prefixes of the given specification are stripped from each
  request first, since they rewrite the path, the resource and the tags this grouping keys on.

  Requests are sorted before being reduced and every collection in the result is sorted, so the
  same set of requests always builds the same model no matter the order the suite recorded them.
  """
  def build(requests, specification, config) do
    requests
    |> sort_requests()
    |> reduce_routes(specification, config)
    |> sort_routes()
    |> to_model()
  end

  defp sort_requests(requests), do: Enum.sort_by(requests, &request_sort_key/1)

  defp request_sort_key(%Request{} = request) do
    {file, line} = Request.document_location(request)

    {request.path, request.verb, request.status_code, request.description, file, line}
  end

  defp reduce_routes(requests, specification, config) do
    Enum.reduce(requests, %{}, fn request, routes ->
      route = route_from_request(request, specification, config)

      Map.update(routes, route.path, route, &Route.merge(&1, route))
    end)
  end

  defp route_from_request(request, specification, config) do
    request
    |> Request.remove_ignored_prefixes(specification)
    |> Route.from_request(config)
  rescue
    exception -> raise DocException, {request, exception, __STACKTRACE__}
  end

  defp sort_routes(routes), do: routes |> Map.values() |> Enum.sort_by(&Route.sort_key/1)

  defp to_model(routes) do
    operations = Enum.flat_map(routes, & &1.operations)

    %__MODULE__{
      routes: routes,
      schemas: collect_schemas(operations),
      security_schemes: collect_security_schemes(operations)
    }
  end

  defp collect_schemas(operations) do
    operations
    |> Enum.flat_map(&bodies_of/1)
    |> Enum.reduce(%{}, &Schema.merge(&2, %{&1.schema_name => &1.schema}))
  end

  defp bodies_of(%Operation{request_content: request_content, responses: responses}),
    do: Enum.concat(request_content, Enum.flat_map(responses, & &1.content))

  defp collect_security_schemes(operations) do
    operations
    |> Enum.flat_map(& &1.security)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
