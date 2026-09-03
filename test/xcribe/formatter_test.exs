defmodule Xcribe.FormatterTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Xcribe.{Formatter, Recorder, Request, Request.Error}

  alias Xcribe.Support.RequestsGenerator

  setup do
    Recorder.pop_all()
    Recorder.set_active(false)

    Application.put_env(
      :xcribe,
      Xcribe.Endpoint,
      file_path: "/tmp/test",
      file_name: "test.json",
      specification_source: "test/support/.xcribe.exs",
      format: :openapi,
      json_library: Jason
    )

    on_exit(fn ->
      :xcribe
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(:xcribe, &1))

      Recorder.set_active(false)
    end)
  end

  describe "init/1" do
    test "return active false when recorder is not active" do
      assert Formatter.init([]) == {:ok, active?: false}
    end

    test "return active true when recorder is active" do
      Recorder.set_active(true)
      assert Formatter.init([]) == {:ok, active?: true}
    end
  end

  describe "handle suite_finished callback" do
    @tag :tmp_dir
    test "report an unreadable specification file instead of crashing", %{tmp_dir: tmp_dir} do
      spec_file = Path.join(tmp_dir, ".xcribe.exs")
      File.write!(spec_file, ~s(%{\n  "missing_comma" => 1\n  "missing_comma" => 2\n}\n))

      Application.put_env(:xcribe, Xcribe.Endpoint,
        file_path: tmp_dir,
        file_name: "openapi_doc.json",
        specification_source: spec_file,
        format: :openapi,
        json_library: Jason
      )

      Recorder.add(RequestsGenerator.users_index())

      output =
        capture_io(fn ->
          assert Formatter.handle_cast({:suite_finished, 1}, active?: true) == {:noreply, :ok}
        end)

      assert output =~ "Specification file errors"
      assert output =~ "invalid Elixir syntax"
      refute File.exists?(Path.join(tmp_dir, "openapi_doc.json"))
    end

    test "report an unwritable output file without taking the formatter down" do
      Application.put_env(:xcribe, Xcribe.Endpoint,
        file_path: "/root",
        file_name: "null",
        specification_source: "test/support/.simple_example.exs",
        format: :openapi,
        json_library: Jason
      )

      Recorder.add(RequestsGenerator.users_index())

      output =
        capture_io(fn ->
          assert Formatter.handle_cast({:suite_finished, 1}, active?: true) == {:noreply, :ok}
        end)

      assert output =~ "Output file errors"
    end

    test "write documentation when is active" do
      status = [active?: true]

      Recorder.add(RequestsGenerator.users_index())

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
             end) =~ "Xcribe documentation written in /tmp/test/test.json"
    end

    test "ignore suite_finished when is not active" do
      status = [active?: false]

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) ==
                        {:noreply, status}
             end) == ""
    end

    @tag :tmp_dir
    test "Output config errors", %{tmp_dir: tmp_dir} do
      status = [active?: true]

      Application.put_env(:xcribe, Xcribe.Endpoint,
        serve: true,
        file_path: tmp_dir,
        output: "anywhere"
      )

      Recorder.add(RequestsGenerator.users_index())

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
             end) =~ "Configuration errors"
    end

    test "ignore when has no records" do
      status = [active?: true]

      assert capture_io(fn ->
               assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
             end) == ""
    end
  end

  test "output document exceptions" do
    status = [active?: true]

    Recorder.add(%Request{
      endpoint: Xcribe.Endpoint,
      __meta__: %{
        call: %{
          description: "conn test",
          file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
          line: 25
        }
      }
    })

    output =
      capture_io(fn ->
        assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
      end)

    assert output =~ "[ Xcribe ] Exception"
    assert output =~ "An exception was raised. Elixir.FunctionClauseError"
  end

  test "Print only parsing error when has a invalid request too" do
    status = [active?: true]

    Recorder.add(%Error{
      type: :parsing,
      message: "route not found",
      __meta__: %{
        call: %{
          description: "test name",
          file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
          line: 1
        }
      }
    })

    Recorder.add(%Request{
      endpoint: Xcribe.Endpoint,
      request_body: %{date: ~D[2021-01-01]},
      __meta__: %{
        call: %{
          description: "test name",
          file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
          line: 1
        }
      }
    })

    output =
      capture_io(fn ->
        assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
      end)

    assert output =~ "[ Xcribe ] Parsing and validation errors"
    assert output =~ "route not found"
  end

  test "when has only parse errors" do
    status = [active?: true]

    Recorder.add(%Error{
      type: :parsing,
      message: "route not found",
      __meta__: %{
        call: %{
          description: "test name",
          file: File.cwd!() <> "/test/xcribe/formatter_test.exs",
          line: 1
        }
      }
    })

    output =
      capture_io(fn ->
        assert Formatter.handle_cast({:suite_finished, 1, 2}, status) == {:noreply, :ok}
      end)

    assert output =~ "[ Xcribe ] Parsing and validation errors"
    assert output =~ "route not found"
  end

  test "for ExUnit =< 1.11" do
    Recorder.add(RequestsGenerator.users_index())

    capture_io(fn ->
      assert Formatter.handle_cast({:suite_finished, 1, 2}, active?: true) == {:noreply, :ok}
    end) =~ "Xcribe documentation written in /tmp/test"
  end

  test "for ExUnit =~ 1.12" do
    Recorder.add(RequestsGenerator.users_index())

    capture_io(fn ->
      assert Formatter.handle_cast(
               {:suite_finished, %{run: 1, async: 2, load: 3}},
               active?: true
             ) ==
               {:noreply, :ok}
    end) =~ "Xcribe documentation written in /tmp/test"
  end

  test "unexpected event" do
    assert Formatter.handle_cast({:other_event}, nil) == {:noreply, nil}
  end
end
