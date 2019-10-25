defmodule Xcribe.ConnParser do
  alias Xcribe.{Config, Request}

  def execute(conn, description \\ "sample request") do
    route = identify_route(conn)
    path = format_path(route.path, Map.keys(conn.path_params))
    namespaces = fetch_namespaces()

    %Request{
      action: Atom.to_string(route.plug_opts),
      header_params: conn.req_headers,
      controller: conn |> controller_module(),
      description: description,
      params: conn.params,
      path: path,
      path_params: conn.path_params,
      query_params: conn.query_params,
      request_body: conn.body_params,
      resource: resource_name(path, namespaces),
      resource_group: resource_group(route),
      resp_body: conn.resp_body,
      resp_headers: conn.resp_headers,
      status_code: conn.status,
      verb: Atom.to_string(route.verb)
    }
  end

  defp identify_route(conn) do
    conn
    |> router_module()
    |> apply(:__routes__, [])
    |> enum_find(conn)
  end

  defp enum_find(routes, conn) do
    routes
    |> Enum.find(fn route -> has_eql_values?(route, conn) end)
  end

  defp has_eql_values?(route, conn) do
    route.plug == controller_module(conn) and route.plug_opts == action_atom(conn) and
      route.verb == verb_atom(conn) and match_path?(route, conn)
  end

  defp match_path?(%{path: route_path}, %{request_path: conn_path}),
    do: Regex.match?(regex_to(route_path), conn_path)

  defp regex_to(path), do: ~r/#{replace_params(path)}/

  defp replace_params(path), do: String.replace(path, ~r/\:\w+/, ".*")

  defp router_module(%{private: %{phoenix_router: router}}), do: router

  defp controller_module(%{private: %{phoenix_controller: controller}}), do: controller

  defp action_atom(%{private: %{phoenix_action: action}}), do: action

  defp resource_group(%{pipe_through: [head | _rest]}), do: head

  defp resource_name(path, namespaces) do
    namespaces
    |> Enum.reduce(path, &remove_namespace/2)
    |> String.split("/")
    |> Enum.filter(&Regex.match?(~r/^\w+$/, &1))
    |> Enum.join("_")
  end

  defp remove_namespace(namespace, path), do: String.replace(path, ~r/^#{namespace}/, "")

  defp verb_atom(%{method: verb}), do: verb |> String.downcase() |> String.to_atom()

  defp format_path(path, params), do: Enum.reduce(params, path, &transform_param/2)

  defp transform_param(param, path), do: String.replace(path, ":#{param}", "{#{param}}")

  defp fetch_namespaces, do: apply(Config.xcribe_information_source(), :namespaces, [])
end
