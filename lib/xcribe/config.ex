defmodule Xcribe.Config do
  @moduledoc """
  Xcribe configuration.

  Every key has a default, so generating documentation needs no configuration at
  all: Xcribe documents your API as OpenAPI 3.0 into `openapi.json` at the root
  of your project. Serving that document is the exception — `mix xcribe.serve`
  and `Xcribe.Web.Plug` have to be told which endpoint serves it and from where:

      config :xcribe, YourAppWeb.Endpoint,
        serve: true,
        file_path: {"priv/static", "api"}

  Configuration is always scoped by the endpoint module it documents, so an
  application with more than one endpoint describes each of them on its own.
  `fetch_config/1` reads the keys of one endpoint and returns them as a map with
  every default applied, plus the `:endpoint` they were read for;
  `check_configurations/2` answers whether that map can be used.

  Recording is not configured here. `Xcribe.Document.document/2` records only
  when the `XCRIBE_ENV` environment variable is set (see `active?/0`), which is
  what `mix xcribe.doc` does for you, so adding Xcribe to a project changes
  nothing until you ask for it.

  ## Keys

  ### `:format`

  Which documentation format to generate.

    * `:openapi` (default) - OpenAPI 3.0, encoded as JSON. The only format that
      can be served, since Swagger UI reads it.
    * `:api_blueprint` - API Blueprint, encoded as Markdown.

  Any other value is a configuration error. The `:swagger` format was renamed to
  `:openapi`, and the old name is rejected rather than silently accepted.

  ### `:file_name`

  The name of the generated document, without any directory.

    * A non-empty string - used as given.
    * Not configured (default) - `"openapi.json"` for the `:openapi` format and
      `"api_doc.apib"` for `:api_blueprint`, so the name follows the format
      unless you pin it.

  `nil` and `""` are configuration errors.

  ### `:file_path`

  Where the generated document is written, and — when it is served — which part
  of that path the URL keeps. See `output_path/1` and `serving_path/1`.

    * Not configured (default) - written to the root of your project. Fine for a
      document you commit and read with an external viewer, but a document at the
      project root cannot be served by any `Plug.Static`.
    * A directory string, `"priv/static"` - written into that directory, and
      served from the endpoint root under `:file_name`.
    * A `{static_dir, sub_path}` tuple, `{"priv/static", "api"}` - written to
      `static_dir/sub_path/file_name`, and served at `sub_path/file_name`.
      `static_dir` is the directory your `Plug.Static` reads from, so it never
      appears in the URL. Use this whenever the document is served from a
      subdirectory. A leading slash in `sub_path` is ignored.

  Any other value is a configuration error. Every part of the path must be a
  string.

  ### `:json_library`

  The library used to encode the OpenAPI document and to decode the request and
  response bodies of your tests. Xcribe calls it through an internal wrapper and
  never references it directly, so any module exporting `encode!/2` and
  `decode!/2` works.

    * `Jason` (default) - no dependency of Xcribe's, it has to be in your own
      dependency tree, which for a Phoenix application it already is.
    * `Poison` - works the same way.

  A module that does not export `decode!/2` is a configuration error. The module
  is loaded before that check, so a library that has not been loaded yet is not
  mistaken for a missing one.

  ### `:serve`

  Whether this endpoint serves its generated document.

    * `false` (default) - `Xcribe.Web.Plug` answers 404 for everything, and
      `mix xcribe.serve` does not consider this endpoint.
    * `true` - the plug renders Swagger UI, and `mix xcribe.serve` serves this
      endpoint. Requires the `:openapi` format, and a `:file_path` and
      `:file_name` that a `Plug.Static` in your endpoint actually serves — both
      are checked, and reported as configuration errors when they do not hold.

  The strings `"true"`, `"TRUE"`, `"1"`, `"false"`, `"FALSE"` and `"0"` are
  accepted too, for a value read from an environment variable. Anything else is
  a configuration error.

  ### `:server_port`

  The port `mix xcribe.serve` listens on. Unrelated to the port your application
  uses, since the task starts a server of its own.

    * `4040` (default).
    * Any integer from `1` to `65535`.

  Any other value is a configuration error. When the port is already taken the
  task reports that instead of failing to boot.

  ### `:open_browser`

  Whether `mix xcribe.serve` opens the served documentation in your browser when
  it starts.

    * `false` (default) - the task only prints the URL.
    * `true` - the URL is also opened with `open`, `xdg-open` or `start`,
      whichever suits the operating system.

  As with `:serve`, the strings `"true"`, `"TRUE"`, `"1"`, `"false"`, `"FALSE"`
  and `"0"` are accepted. Anything else is a configuration error.

  ### `:specification_source`

  Path to the specification file that carries the API title, description, version
  and servers — everything Xcribe cannot infer from a test. See
  `Xcribe.Specification` for the file's own keys.

    * `".xcribe.exs"` (default) - read when it exists. It is optional at this
      path only: without it Xcribe falls back to its built-in defaults instead of
      failing, so a project that never runs `mix xcribe.gen.spec` still generates
      a document.
    * Any other path - required to exist. A missing file is a configuration
      error, because naming a path and not having it there is a mistake rather
      than a choice.
  """

  @valid_formats [:api_blueprint, :openapi]
  @default_server_port 4040
  @truthy_values [true, "true", "TRUE", "1"]
  @falsy_values [false, "false", "FALSE", "0", nil]

  @doc false
  def default_spec_file, do: ".xcribe.exs"

  @doc """
  Whether Xcribe should record the documented requests.

  Reads the `XCRIBE_ENV` environment variable, so merely configuring Xcribe
  leaves a normal test run untouched.
  """
  def active?, do: System.get_env("XCRIBE_ENV") in ["1", "true", "TRUE"]

  @doc """
  Every endpoint module configured under `:xcribe`.
  """
  def all_endpoints do
    :xcribe
    |> Application.get_all_env()
    |> Keyword.keys()
    |> Enum.filter(&valid_endpoint?/1)
  end

  @doc """
  The configuration of the given endpoint, with every default applied.
  """
  def fetch_config(endpoint) when is_atom(endpoint) do
    :xcribe
    |> Application.get_env(endpoint, [])
    |> apply_default_values(endpoint)
  end

  @doc """
  The path the generated document is served at, relative to the endpoint root.

  This is the path Swagger UI requests, so the `Plug.Static` directory of a
  `{static_dir, sub_path}` tuple is dropped from it. See `output_path/1` for the
  path the same document is written to.
  """
  def serving_path(%{file_path: {_static_dir, sub_path}, file_name: file_name}) do
    [sub_path, file_name] |> Path.join() |> String.trim_leading("/")
  end

  def serving_path(%{file_name: file_name}), do: file_name

  @doc """
  The path the generated document is written to.

  Unlike `serving_path/1` this keeps every segment of `file_path`, including the
  `Plug.Static` directory of a `{static_dir, sub_path}` tuple.
  """
  def output_path(%{file_path: {static_dir, sub_path}, file_name: file_name}) do
    Path.join([static_dir, sub_path, file_name])
  end

  def output_path(%{file_path: file_path, file_name: file_name}) when is_binary(file_path) do
    Path.join(file_path, file_name)
  end

  def output_path(%{file_name: file_name}), do: file_name

  @doc false
  def prefix_file_path(%{file_path: {static_dir, sub_path}} = config, prefix) do
    %{config | file_path: {Path.join(prefix, static_dir), sub_path}}
  end

  @doc false
  def prefix_file_path(%{file_path: nil} = config, prefix) do
    %{config | file_path: prefix}
  end

  @doc false
  def prefix_file_path(%{file_path: file_path} = config, prefix) do
    %{config | file_path: Path.join(prefix, file_path)}
  end

  @default_keys_to_validate [
    :format,
    :specification_source,
    :json_library,
    :file_path,
    :file_name,
    :server_port,
    :open_browser,
    :serve
  ]

  @doc """
  Validate a configuration map, accumulating every problem it finds.

  Returns `{:ok, config}` or `{:error, [{key, value, message, instructions}]}`.
  The `:served_document` key is not validated by default: it asks the endpoint
  for the generated document, so it only answers usefully once the document
  exists and the endpoint is running.
  """
  def check_configurations(config, keys \\ @default_keys_to_validate) do
    case Enum.reduce(keys, {:ok, config}, &validate_config/2) do
      {:ok, config} -> {:ok, config}
      {{:error, _list} = err, _config} -> err
    end
  end

  @format_message "Xcribe doesn't support the configured documentation format"
  @format_instructions "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."
  defp validate_config(:format, {_errors, config} = results) do
    format = Map.fetch!(config, :format)

    if format in @valid_formats do
      results
    else
      add_error(results, :format, format, @format_message, @format_instructions)
    end
  end

  @spec_file_message "The configured specification file doesn't exist"
  @spec_file_instructions "Add a valid spec file path in `config :xcribe, Endpoint, specification_source: \".xcribe.exs\"`"
  defp validate_config(:specification_source, {_errors, config} = results) do
    file = Map.fetch!(config, :specification_source)

    if file == default_spec_file() or File.exists?(file) do
      results
    else
      add_error(results, :specification_source, file, @spec_file_message, @spec_file_instructions)
    end
  end

  @json_lib_message "The configured json library doesn't implement the needed functions"
  @json_lib_instructions "Try configure Xcribe with Jason or Poison `config :xcribe, Endpoint, json_library: Jason`"
  defp validate_config(:json_library, {_errors, config} = results) do
    lib = Map.fetch!(config, :json_library)

    if exports?(lib, :decode!, 2) do
      results
    else
      add_error(results, :json_library, lib, @json_lib_message, @json_lib_instructions)
    end
  end

  @file_path_message "The configured file path is not a directory nor a {static_dir, sub_path} tuple"
  @file_path_instructions ~s(Configure a directory: `config :xcribe, Endpoint, file_path: "priv/static"`, or the two parts of a served path: `config :xcribe, Endpoint, file_path: {"priv/static", "api"}`)
  defp validate_config(:file_path, {_errors, config} = results) do
    file_path = Map.fetch!(config, :file_path)

    if valid_file_path?(file_path) do
      results
    else
      add_error(results, :file_path, file_path, @file_path_message, @file_path_instructions)
    end
  end

  @file_name_message "The configured file name is not a name for the generated document"
  @file_name_instructions "Configure the document file name: `config :xcribe, Endpoint, file_name: \"openapi.json\"`"
  defp validate_config(:file_name, {_errors, config} = results) do
    file_name = Map.fetch!(config, :file_name)

    if is_binary(file_name) and file_name != "" do
      results
    else
      add_error(results, :file_name, file_name, @file_name_message, @file_name_instructions)
    end
  end

  @server_port_message "The configured server port is not a port number"
  @server_port_instructions "Configure a port between 1 and 65535: `config :xcribe, Endpoint, server_port: 4040`"
  defp validate_config(:server_port, {_errors, config} = results) do
    port = Map.fetch!(config, :server_port)

    if is_integer(port) and port in 1..65_535 do
      results
    else
      add_error(results, :server_port, port, @server_port_message, @server_port_instructions)
    end
  end

  @open_browser_message "The configured open browser value is not a boolean"
  @open_browser_instructions "Configure open_browser as a boolean: `config :xcribe, Endpoint, open_browser: true`"
  defp validate_config(:open_browser, {_errors, config} = results) do
    open_browser = Map.fetch!(config, :open_browser)

    if is_boolean(open_browser) do
      results
    else
      add_error(
        results,
        :open_browser,
        open_browser,
        @open_browser_message,
        @open_browser_instructions
      )
    end
  end

  @serve_message "The configured serve value is not a boolean"
  @serve_instructions "Configure serve as a boolean: `config :xcribe, Endpoint, serve: true`"
  defp validate_config(:serve, {_errors, config} = results) do
    config
    |> Map.fetch!(:serve)
    |> case do
      true -> validate_serve_format(results)
      false -> results
      serve -> add_error(results, :serve, serve, @serve_message, @serve_instructions)
    end
  end

  defp validate_config(:served_document, {_errors, config} = results) do
    if Map.fetch!(config, :serve) do
      validate_generated_document(results)
    else
      results
    end
  end

  @serve_format_message "When serve config is true you must use the :openapi format"
  @serve_format_instructions "You must use the OpenAPI format: `config :xcribe, Endpoint, format: :openapi`"
  defp validate_serve_format({_errors, config} = results) do
    format = Map.fetch!(config, :format)

    if format == :openapi do
      results
    else
      add_error(results, :format, format, @serve_format_message, @serve_format_instructions)
    end
  end

  @document_message "The documentation file to be served doesn't exist"
  @document_instructions "Generate the documentation before serving it: `mix xcribe.doc`"
  defp validate_generated_document({_errors, config} = results) do
    output_path = output_path(config)

    if File.exists?(output_path) do
      validate_served_document(results)
    else
      add_error(results, :file_path, output_path, @document_message, @document_instructions)
    end
  end

  @serving_message "Your Endpoint must be able to serve the generated document, but a request for it didn't return the file"
  @serving_instructions ~s(Make file_path and file_name match a Plug.Static in your Endpoint — the directory it serves and its `only:` allow list: `config :xcribe, Endpoint, file_path: {"priv/static", "api"}, file_name: "openapi.json"`)
  defp validate_served_document({_errors, config} = results) do
    serving_path = serving_path(config)

    case request_document(Map.fetch!(config, :endpoint), serving_path) do
      %{status: 200} ->
        results

      _not_served ->
        add_error(results, :file_path, serving_path, @serving_message, @serving_instructions)
    end
  end

  defp request_document(endpoint, serving_path) do
    :get
    |> Plug.Test.conn(Path.join("/", serving_path))
    |> call_endpoint(endpoint)
  end

  defp call_endpoint(conn, endpoint) do
    endpoint.call(conn, [])
  rescue
    _error in [ArgumentError, UndefinedFunctionError, FunctionClauseError, KeyError] ->
      :not_served
  end

  defp add_error({:ok, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info}]}, config}
  end

  defp add_error({{:error, errs}, config}, key, value, msg, info) do
    {{:error, [{key, value, msg, info} | errs]}, config}
  end

  defp apply_default_values(keyword, endpoint) do
    format = Keyword.get(keyword, :format, :openapi)
    json_library = Keyword.get(keyword, :json_library, Jason)
    file_path = Keyword.get(keyword, :file_path)
    file_name = Keyword.get(keyword, :file_name, default_output(format))
    serve = Keyword.get(keyword, :serve, false)
    server_port = Keyword.get(keyword, :server_port, @default_server_port)
    open_browser = Keyword.get(keyword, :open_browser, false)
    specification_source = Keyword.get(keyword, :specification_source, default_spec_file())

    %{
      endpoint: endpoint,
      format: format,
      json_library: json_library,
      file_path: file_path,
      file_name: file_name,
      serve: normalize_boolean(serve),
      server_port: server_port,
      open_browser: normalize_boolean(open_browser),
      specification_source: specification_source
    }
  end

  defp valid_file_path?(nil), do: true
  defp valid_file_path?({static_dir, sub_path}), do: is_binary(static_dir) and is_binary(sub_path)
  defp valid_file_path?(file_path), do: is_binary(file_path)

  defp normalize_boolean(value) when value in @truthy_values, do: true
  defp normalize_boolean(value) when value in @falsy_values, do: false
  defp normalize_boolean(value), do: value

  defp default_output(format) do
    case format do
      :api_blueprint -> "api_doc.apib"
      :openapi -> "openapi.json"
      _ -> ""
    end
  end

  defp valid_endpoint?(module), do: exports?(module, :config, 1)

  # `mix xcribe.serve` runs with `app.config`, which loads no application, so a
  # module that is only named in the configuration has not been loaded yet and
  # `function_exported?/3` would answer false for every function it has.
  defp exports?(module, function, arity) do
    Code.ensure_loaded(module)

    function_exported?(module, function, arity)
  end
end
