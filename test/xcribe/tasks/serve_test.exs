defmodule Xcribe.Tasks.ServeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Xcribe.Serve
  alias Xcribe.StaticEndpoint

  setup do
    on_exit(fn ->
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))
    end)
  end

  describe "run/1" do
    test "exit with error when no endpoint is configured to serve" do
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run([])) == {:shutdown, 1}
        end)

      assert io_output =~ "Xcribe has no endpoint configured to serve documentation for"
      assert io_output =~ "config :xcribe, YourAppWeb.Endpoint"
      assert io_output =~ "Xcribe Task - aborted"
    end

    test "report the endpoint already running when starting the real server" do
      # Xcribe.StaticEndpoint is a supervised child of the test application, so
      # the copy the task supervises itself cannot start — which is the only way
      # this suite can reach the real start_server/1.
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run([])) == {:shutdown, 1}
        end)

      assert io_output =~ "because it is already running"
      assert io_output =~ "Xcribe Task - aborted"
    end
  end

  describe "run_task/3" do
    test "serve the documentation of the endpoint configured to serve" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn -> catch_exit(Serve.run_task([], server_function, browser_function)) end)

      assert_received {:server_started, config}
      assert config.endpoint == StaticEndpoint
      assert config.serve == true
      assert config.server_port == 4040

      assert io_output =~ "serving documentation on http://localhost:4040"
    end

    test "serve the documentation of the endpoint given by the endpoint option" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      Application.put_env(:xcribe, Xcribe.Endpoint, serve: true, format: :openapi)

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      capture_io(fn ->
        catch_exit(
          Serve.run_task(["-e", "Xcribe.StaticEndpoint"], server_function, browser_function)
        )
      end)

      assert_received {:server_started, %{endpoint: StaticEndpoint}}
    end

    test "serve an endpoint given by the endpoint option with serve mode disabled" do
      Application.put_env(:xcribe, StaticEndpoint,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      capture_io(fn ->
        catch_exit(
          Serve.run_task(["-e", "Xcribe.StaticEndpoint"], server_function, browser_function)
        )
      end)

      assert_received {:server_started, %{endpoint: StaticEndpoint, serve: true}}
    end

    test "exit with error when the given endpoint is not configured" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(
                   Serve.run_task(
                     ["--endpoint", "Other.Endpoint"],
                     server_function,
                     browser_function
                   )
                 ) == {:shutdown, 1}
        end)

      assert io_output =~ "Xcribe has no configuration for the given endpoint"
      assert io_output =~ "config :xcribe, Other.Endpoint, serve: true"
      assert io_output =~ "Xcribe.StaticEndpoint"
      refute_received {:server_started, _config}
    end

    test "exit with error when more than one endpoint is configured to serve" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      Application.put_env(:xcribe, Xcribe.Endpoint, serve: true, format: :openapi)

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], server_function, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "More than one endpoint is configured to serve documentation"
      assert io_output =~ "mix xcribe.serve -e"
      refute_received {:server_started, _config}
    end

    test "ignore endpoints that are not configured to serve" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      Application.put_env(:xcribe, Xcribe.Endpoint, format: :openapi)

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      capture_io(fn -> catch_exit(Serve.run_task([], server_function, browser_function)) end)

      assert_received {:server_started, %{endpoint: StaticEndpoint}}
    end

    test "exit without starting the server when the configuration is invalid" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :api_blueprint,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], server_function, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "When serve config is true you must use the :openapi format"
      refute_received {:server_started, _config}
    end

    test "exit with error when the configured port is already in use" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      failed_server = fn _config ->
        {:error, {:shutdown, {:failed_to_start_child, :listener, :eaddrinuse}}}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], failed_server, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "Xcribe couldn't start the documentation server on the configured port"
      assert io_output =~ "Config key: server_port"
    end

    test "exit with error when the web server fails for an unknown reason" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      failed_server = fn _config -> {:error, :closed} end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], failed_server, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "Xcribe couldn't start the documentation server"
      assert io_output =~ "The supervisor reported :closed"
    end

    test "exit with error when the document was not generated yet" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: {"priv/static", "api"},
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], server_function, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "The documentation file to be served doesn't exist"
      assert io_output =~ "mix xcribe.doc"
      assert_received {:server_started, _config}
    end

    test "exit with error when the endpoint doesn't serve the generated document" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "api_blueprint_example.apib"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn ->
          assert catch_exit(Serve.run_task([], server_function, browser_function)) ==
                   {:shutdown, 1}
        end)

      assert io_output =~ "a request for it didn't return the file"
      assert io_output =~ "Make file_path and file_name match a Plug.Static"
      assert_received {:server_started, _config}
    end

    test "open the browser when the open_browser config is true" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json",
        open_browser: true,
        server_port: 4321
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      capture_io(fn -> catch_exit(Serve.run_task([], server_function, browser_function)) end)

      assert_received {:browser_opened, "http://localhost:4321"}
    end

    test "do not open the browser by default" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json"
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      capture_io(fn -> catch_exit(Serve.run_task([], server_function, browser_function)) end)

      refute_received {:browser_opened, _url}
    end

    test "serve on the configured server port" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json",
        server_port: 4321
      )

      server_function = fn config ->
        send(self(), {:server_started, config})

        {:ok, spawn(fn -> :ok end)}
      end

      browser_function = fn url -> send(self(), {:browser_opened, url}) end

      io_output =
        capture_io(fn -> catch_exit(Serve.run_task([], server_function, browser_function)) end)

      assert_received {:server_started, %{server_port: 4321}}
      assert io_output =~ "serving documentation on http://localhost:4321"
    end

    test "exit with the reason the served documentation went down with" do
      Application.put_env(:xcribe, StaticEndpoint,
        serve: true,
        format: :openapi,
        file_path: "test/support",
        file_name: "openapi_example.json",
        open_browser: true
      )

      server = spawn(fn -> receive do: (_any -> :ok) end)

      # The task monitors the server before it opens the browser, so stopping the
      # server from the browser function cannot race the monitor.
      capture_io(fn ->
        assert catch_exit(
                 Serve.run_task(
                   [],
                   fn _config -> {:ok, server} end,
                   fn _url -> Process.exit(server, :shutdown) end
                 )
               ) == :shutdown
      end)
    end
  end
end
