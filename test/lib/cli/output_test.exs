defmodule Xcribe.CLI.OutputTest do
  use ExUnit.Case, async: true

  alias Xcribe.CLI.Output
  alias Xcribe.Request.Error

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
      \e[44m\e[37m  [ Xcribe ] Parsing Errors                                                                      \e[0m
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

  describe "print_configuration_errors/1" do
    test "configuration errors" do
      errors = [
        {:json_library, FakeJson, "Given json library doesn't implement needed functions",
         "Try configure Xcribe with Jason or Poison `config :xcribe, [json_library: Jason]`"},
        {:information_source, FakeInfo,
         "Sees like the given module is not using Xcribe as :information",
         "Add `use Xcribe, :information` on top of your module"},
        {:format, :invalid, "An unsupported format was configured",
         "Xcribe supports Swagger and Blueprint, configure as: `config :xcribe, [format: :swagger]`"}
      ]

      expected_output = """
      \e[42m\e[37m  [ Xcribe ] Configuration Errors                                                                \e[0m
      \e[32m┃\e[0m
      \e[32m┃\e[0m [C] → \e[34m Given json library doesn't implement needed functions
      \e[32m┃\e[0m        \e[38;5;240m> Config key: json_library
      \e[38;5;100m┃\e[0m
      \e[38;5;100m┃\e[0m        Given value: \e[38;5;37mFakeJson
      \e[38;5;100m┃\e[0m        \e[38;5;100mTry configure Xcribe with Jason or Poison `config :xcribe, [json_library: Jason]`
      \e[38;5;100m┃\e[0m

      \e[32m┃\e[0m
      \e[32m┃\e[0m [C] → \e[34m Sees like the given module is not using Xcribe as :information
      \e[32m┃\e[0m        \e[38;5;240m> Config key: information_source
      \e[38;5;100m┃\e[0m
      \e[38;5;100m┃\e[0m        Given value: \e[38;5;37mFakeInfo
      \e[38;5;100m┃\e[0m        \e[38;5;100mAdd `use Xcribe, :information` on top of your module
      \e[38;5;100m┃\e[0m

      \e[32m┃\e[0m
      \e[32m┃\e[0m [C] → \e[34m An unsupported format was configured
      \e[32m┃\e[0m        \e[38;5;240m> Config key: format
      \e[38;5;100m┃\e[0m
      \e[38;5;100m┃\e[0m        Given value: \e[38;5;37m:invalid
      \e[38;5;100m┃\e[0m        \e[38;5;100mXcribe supports Swagger and Blueprint, configure as: `config :xcribe, [format: :swagger]`
      \e[38;5;100m┃\e[0m

      """

      assert capture_io(fn ->
               assert Output.print_configuration_errors(errors) == :ok
             end) == expected_output
    end
  end
end
