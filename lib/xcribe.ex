defmodule Xcribe do
  @moduledoc """
  Xcribe is a library for API documentation. It generates docs from your test specs.

  Xcribe use `Plug.Conn` struct to fetch information about requests and use them
  to document your API.  You must give requests examples (from your tests ) to Xcribe
  be able to document your routes.

  Each connection sent to documenting in your tests is parsed. Is expected that
  connection has been passed through the app `Endpoint` as a finished request.
  The parser will extract all needed info from `Conn` and uses app `Router`
  for additional information about the request.

  The attribute `description` may be given at `document` macro call with the
  option `:as`:

      test "test name", %{conn: conn} do
        ...

        document(conn, as: "description here")

        ...
      end

  If no description is given the current test description will be used.

  ## API information

  You must provide your API information by creatint a mudule that use
  `Xcribe.Information` macros.

  The required infor are:

  - `name` - a name for your API.
  - `description` - a description about your API.
  - `host` - your API host url

  This information is set by Xcribe macros inside the block `xcribe_info`. eg:

      defmodule YourModuleInformation do
        use Xcribe.Information

        xcribe_info do
          name "Your awesome API"
          description "The best API in the world"
          host "http://your-api.us"
        end
      end  

  See `Xcribe.Information` for more details about custom information.

  ## JSON

  Xcribe uses the same json library configured for Phoenix to handle json content.
  you can configure xcribe to use your preferred library. Poison and Jason are
  the most popular json libraries common used in Elixir and Xcribe works fine with both.

  ## Configuration

  The `config/test.exs` file is used for Xcribe configuration. You must configure
  at least the `information_source` and `format` for basic use.

  eg

      config: xcribe, [
        information_source: YourApp.YouModuleInformation,
        format: :swagger
      ]


  #### Available configurations:

    * `:information_source` - Module that implements `Xcribe.Information` with
    API information. It's required.
    * `:output` - The name of file output with generated configuration. Default
    value changes by the format, 'api_blueprint.apib' for Blueprint and
    'app_doc.json' for swagger.
    * `:format` - Format to generate documentation, allowed `:api_blueprint` and
    `:swagger`. Default `:api_blueprint`.
    * `:env_var` - Environment variable name for active Xcribe documentation
    generator. Default is `XCRIBE_ENV`.
    * `:json_library` - The library to be used for json decode/encode (Jason
    and Poison are supported). The default is the same as `Phoenix` configuration.
  """
  use Application

  require Xcribe.Helpers.Document

  @doc false
  def start(_type, _opts) do
    opts = [strategy: :one_for_one, name: Xcribe.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  @doc false
  def start(_options \\ []) do
    {:ok, _} = Application.start(:xcribe)

    :ok
  end

  defp children do
    import Supervisor.Spec

    [worker(Xcribe.Recorder, [])]
  end
end
