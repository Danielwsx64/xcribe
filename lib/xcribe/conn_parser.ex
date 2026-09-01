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
    with {:ok, schema} <- schema_name(opts, :schema),
         {:ok, req_schema} <- schema_name(opts, :req_schema) do
      %{request | schema: schema, req_schema: req_schema}
    else
      {:error, error} -> error
    end
  end

  defp build_opts(opts), do: Keyword.put_new(opts, :description, "")

  defp identify_route(%{method: method, host: host, path_info: path} = conn) do
    module = router_module(conn)
    route = module.__match_route__(method, decode_uri(path), host)

    extract_route_info(route)
  rescue
    _e in [UndefinedFunctionError, FunctionClauseError, KeyError, BadMapError] ->
      %{@error_struct | message: "An invalid Plug.Conn was given or maybe an invalid Router"}
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

  @invalid_schema_message "An invalid schema name was given. Schema names MUST be an String.t()"

  defp schema_name(opts, key), do: opts |> Keyword.get(key) |> validate_schema_name()

  defp validate_schema_name(nil), do: {:ok, nil}

  # Schema names become OpenAPI component keys, which cannot contain spaces.
  defp validate_schema_name(name) when is_binary(name),
    do: {:ok, String.replace(name, " ", "")}

  defp validate_schema_name(_name),
    do: {:error, %{@error_struct | message: @invalid_schema_message}}
end
