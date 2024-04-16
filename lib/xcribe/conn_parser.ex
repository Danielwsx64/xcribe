defmodule Xcribe.ConnParser do
  @moduledoc false

  alias Plug.Conn
  alias Xcribe.{Request, Request.Error}

  @error_struct %Error{type: :parsing}

  @doc """
  Parse the given `Plug.Conn` and transform it to a `Xcribe.Request`. A
  description can be provided.

  If any error occurs a `Xcribe.Request.Error` is returned
  """
  def execute(conn, options \\ [])

  def execute(%Conn{} = conn, options) do
    conn
    |> identify_route()
    |> parse_conn(conn, build_opts(options))
  end

  def execute(_conn, _opts) do
    %{@error_struct | message: "A Plug.Conn must be given"}
  end

  defp parse_conn(%Error{} = error, _conn, _description), do: error

  defp parse_conn(route, conn, opts) do
    path = format_path(route.route, conn.path_params)
    action = route |> router_options() |> Atom.to_string()
    resource = resource_name(route, action)

    add_schemas(
      %Request{
        action: action,
        header_params: conn.req_headers,
        controller: controller_module(route),
        description: Keyword.fetch!(opts, :description),
        endpoint: Map.fetch!(conn.private, :phoenix_endpoint),
        params: conn.params,
        path: path,
        path_params: conn.path_params,
        query_params: conn.query_params,
        request_body: conn.body_params,
        resource: resource,
        resp_body: conn.resp_body,
        resp_headers: conn.resp_headers,
        status_code: conn.status,
        verb: String.downcase(conn.method),
        groups_tags: opts |> Keyword.get(:groups_tags) |> build_groups_tags(resource)
      },
      opts
    )
  end

  defp add_schemas(request, opts) do
    %{request | schema: schema_name(opts), req_schema: req_schema_name(opts)}
  rescue
    _ ->
      %{
        @error_struct
        | message: "An invalid schema name was given. Schema names MUST be an String.t()"
      }
  end

  defp build_opts(opts), do: Keyword.put_new(opts, :description, "")

  defp identify_route(%{method: method, host: host, path_info: path} = conn) do
    module = router_module(conn)
    route = module.__match_route__(decode_uri(path), method, host)

    extract_route_info(route)
  rescue
    _ -> %{@error_struct | message: "An invalid Plug.Conn was given or maybe an invalid Router"}
  end

  defp router_module(%{private: %{phoenix_router: router}}), do: router

  defp decode_uri(path_info), do: Enum.map(path_info, &URI.decode/1)

  defp extract_route_info({%{} = route_info, _callback_one, _callback_two, _plug_info}),
    do: route_info

  defp extract_route_info(_),
    do: Map.put(@error_struct, :message, "A route wasn't found for given Conn")

  defp router_options(%{plug_opts: opts}), do: opts
  defp router_options(%{opts: opts}), do: opts

  defp controller_module(%{plug: controller}), do: controller

  defp resource_name(%{route: route}, action) do
    route
    |> String.split("/")
    |> Enum.filter(&(&1 != action and Regex.match?(~r/^\w+$/, &1)))
    |> Enum.map(&String.split(&1, "_"))
    |> List.flatten()
    |> Enum.map_join("\s", &String.capitalize(&1))
  end

  defp build_groups_tags(nil, resource), do: [resource]
  defp build_groups_tags(tags, _resource) when is_list(tags), do: tags

  defp format_path(path, params) do
    params |> Map.keys() |> Enum.reduce(path, &transform_param/2)
  end

  defp transform_param(param, path), do: String.replace(path, ":#{param}", "{#{param}}")

  defp schema_name(opts) do
    opts
    |> Keyword.get(:schema)
    |> case do
      nil -> nil
      {:module, schema} -> replace_s(schema)
      schema -> replace_s(schema)
    end
  end

  defp req_schema_name(opts) do
    opts
    |> Keyword.get(:req_schema)
    |> case do
      nil -> nil
      {:module, schema} -> replace_s(schema)
      schema -> replace_s(schema)
    end
  end

  defp replace_s(string), do: String.replace(string, " ", "")
end
