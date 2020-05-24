defmodule Xcribe.CLI.OutputTest do
  use ExUnit.Case, async: true

  alias Xcribe.Request.Error
  alias Xcribe.CLI.Output

  import ExUnit.CaptureIO

  describe "print_request_errors/1" do
    test "parsing errors" do
      # |> document(as: "some cool description")

      route_error = %Error{
        type: :parsing,
        message: "route not found",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/lib/cli/output_test.exs",
            line: 11
          }
        }
      }

      # |> document(as: "awesome route")

      conn_error = %Error{
        type: :parsing,
        message: "invalid Router or invalid Conn",
        __meta__: %{
          call: %{
            description: "conn test",
            file: File.cwd!() <> "/test/lib/cli/output_test.exs",
            line: 25
          }
        }
      }

      expected_output = """
      \e[44m\e[37m  Xcribe found errors                                                             \e[0m
      \e[34m┃\e[0m
      \e[34m┃\e[0m [P] → \e[33m route not found
      \e[34m┃\e[0m        \e[34m> test name\n\e[34m┃\e[0m        \e[38;5;240m/test/lib/cli/output_test.exs:11
      \e[38;5;25m┃\e[0m
      \e[38;5;25m┃\e[0m        \e[38;5;37m# |> document(as: "some cool description")
      \e[38;5;25m┃\e[0m        \e[38;5;25m     ^^^^^^^^                             
      \e[38;5;25m┃\e[0m

      \e[34m┃\e[0m
      \e[34m┃\e[0m [P] → \e[33m invalid Router or invalid Conn
      \e[34m┃\e[0m        \e[34m> conn test
      \e[34m┃\e[0m        \e[38;5;240m/test/lib/cli/output_test.exs:25
      \e[38;5;25m┃\e[0m
      \e[38;5;25m┃\e[0m        \e[38;5;37m# |> document(as: \"awesome route\")
      \e[38;5;25m┃\e[0m        \e[38;5;25m     ^^^^^^^^                     
      \e[38;5;25m┃\e[0m

      """

      assert capture_io(fn ->
               assert Output.print_request_errors([route_error, conn_error]) == :ok
             end) == expected_output
    end
  end
end
