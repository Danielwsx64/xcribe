# credo:disable-for-this-file Credo.Check.Readability.RedundantBlankLines
defmodule Xcribe.CLI.OutputTest do
  use ExUnit.Case, async: true

  alias Xcribe.CLI.Output
  alias Xcribe.DocException
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
            file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
            line: 13
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
            file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
            line: 27
          }
        }
      }

      expected_output = """
      \e[44m\e[37m  [ Xcribe ] Parsing and validation errors                                                       \e[0m
      \e[34m┃\e[0m
      \e[34m┃\e[0m [P] → \e[33m route not found
      \e[34m┃\e[0m        \e[34m> test name\n\e[34m┃\e[0m        \e[38;5;240mtest/xcribe/cli/output_test.exs:13
      \e[38;5;25m┃\e[0m
      \e[38;5;25m┃\e[0m        \e[38;5;37m# |> document(as: "some cool description")
      \e[38;5;25m┃\e[0m        \e[38;5;25m     ^^^^^^^^                             
      \e[38;5;25m┃\e[0m

      \e[34m┃\e[0m
      \e[34m┃\e[0m [P] → \e[33m invalid Router or invalid Conn
      \e[34m┃\e[0m        \e[34m> conn test
      \e[34m┃\e[0m        \e[38;5;240mtest/xcribe/cli/output_test.exs:27
      \e[38;5;25m┃\e[0m
      \e[38;5;25m┃\e[0m        \e[38;5;37m# |> document(as: \"awesome route\")
      \e[38;5;25m┃\e[0m        \e[38;5;25m     ^^^^^^^^                     
      \e[38;5;25m┃\e[0m

      """

      assert capture_io(fn ->
               assert Output.print_request_errors([route_error, conn_error]) == :ok
             end) == expected_output
    end

    test "printing request validation error" do
      validation_error = %Error{
        type: :validation,
        message:
          "The Plug.Conn params must be valid HTTP params. A struct Elixir.Date was found!",
        __meta__: %{
          call: %{
            description: "test name",
            file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
            line: 13
          }
        }
      }

      expected_output = """
      \e[44m\e[37m  [ Xcribe ] Parsing and validation errors                                                       \e[0m
      \e[34m┃\e[0m
      \e[34m┃\e[0m [V] → \e[33m The Plug.Conn params must be valid HTTP params. A struct Elixir.Date was found!
      \e[34m┃\e[0m        \e[34m> test name
      \e[34m┃\e[0m        \e[38;5;240mtest/xcribe/cli/output_test.exs:13
      \e[38;5;25m┃\e[0m
      \e[38;5;25m┃\e[0m        \e[38;5;37m# |> document(as: \"some cool description\")
      \e[38;5;25m┃\e[0m        \e[38;5;25m     ^^^^^^^^                             
      \e[38;5;25m┃\e[0m
      \

      """

      assert capture_io(fn ->
               assert Output.print_request_errors([validation_error]) == :ok
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
      \e[42m\e[37m  [ Xcribe ] Configuration errors                                                                \e[0m
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

    test "with a nil key and value" do
      errors = [
        {nil, nil,
         "When serve config is true you must confiture output to \"priv/static\" folder",
         "You must configure output as: `config :xcribe, output: \"priv/static/doc.json\"`"}
      ]

      expected_output = """
      \e[42m\e[37m  [ Xcribe ] Configuration errors                                                                \e[0m
      \e[32m┃\e[0m
      \e[32m┃\e[0m [C] → \e[34m When serve config is true you must confiture output to \"priv/static\" folder
      \e[38;5;100m┃\e[0m
      \e[38;5;100m┃\e[0m        \e[38;5;100mYou must configure output as: `config :xcribe, output: \"priv/static/doc.json\"`
      \e[38;5;100m┃\e[0m

      """

      assert capture_io(fn ->
               assert Output.print_configuration_errors(errors) == :ok
             end) == expected_output
    end
  end

  describe "print_file_errors/1" do
    test "prints output file erro message" do
      expected_output = """
      \e[41m\e[37m  [ Xcribe ] Output file errors                                                                  \e[0m
      \e[31m┃\e[0m
      \e[31m┃\e[0m [E] → \e[31m Could not write to /some/file/path
      \e[31m┃\e[0m        \e[31mError: eacces
      \e[38;5;88m┃\e[0m
      \e[38;5;88m┃\e[0m \e[38;5;88mThe destination path for documentation artifact cannot be accessed.
      \e[38;5;88m┃\e[0m \e[38;5;88mCommon reasons for this error are missing write permissions or the directory does not exist.
      \e[38;5;88m┃\e[0m

      """

      assert capture_io(fn ->
               assert Output.print_file_errors({"/some/file/path", :eacces}) == :ok
             end) == expected_output
    end
  end

  describe "print_doc_exception/1" do
    test "document excption" do
      message = "An exception was raised. Elixir.FunctionClauseError"

      stacktrace = """
      (xcribe 0.6.0) lib/swagger/swagger.ex:53: Xcribe.Swagger.paths_object_func/2
      (elixir 1.10.3) lib/enum.ex:2111: Enum."-reduce/3-lists^foldl/2-0-"/3
      (xcribe 0.6.0) lib/swagger/swagger.ex:23: Xcribe.Swagger.mount_data_in_raw_object/2
      (xcribe 0.6.0) lib/swagger/swagger.ex:14: Xcribe.Swagger.generate_doc/1
      (xcribe 0.6.0) lib/formatter.ex:48: Xcribe.Formatter.handle_cast/2
      test/lib/formatter_test.exs:129: (test)
      """

      exception = %DocException{
        message: message,
        exception: FunctionClauseError,
        stacktrace: stacktrace,
        request_error: %Error{
          __meta__: %{
            call: %{
              description: "conn test",
              file: File.cwd!() <> "/test/xcribe/cli/output_test.exs",
              line: 27
            }
          },
          type: :exception,
          message: message
        }
      }

      expected_output = """
      \e[41m\e[37m  [ Xcribe ] Exception                                                                           \e[0m
      \e[31m┃\e[0m
      \e[31m┃\e[0m [E] → \e[31m An exception was raised. Elixir.FunctionClauseError
      \e[31m┃\e[0m        \e[34m> conn test
      \e[31m┃\e[0m        \e[38;5;240mtest/xcribe/cli/output_test.exs:27
      \e[38;5;88m┃\e[0m
      \e[38;5;88m┃\e[0m        \e[38;5;37m# |> document(as: \"awesome route\")
      \e[38;5;88m┃\e[0m        \e[38;5;88m     ^^^^^^^^                     
      \e[38;5;88m┃\e[0m
        
       - Exception stacktrace:

      (xcribe 0.6.0) lib/swagger/swagger.ex:53: Xcribe.Swagger.paths_object_func/2
      (elixir 1.10.3) lib/enum.ex:2111: Enum.\"-reduce/3-lists^foldl/2-0-\"/3
      (xcribe 0.6.0) lib/swagger/swagger.ex:23: Xcribe.Swagger.mount_data_in_raw_object/2
      (xcribe 0.6.0) lib/swagger/swagger.ex:14: Xcribe.Swagger.generate_doc/1
      (xcribe 0.6.0) lib/formatter.ex:48: Xcribe.Formatter.handle_cast/2
      test/lib/formatter_test.exs:129: (test)


      """

      assert capture_io(fn ->
               assert Output.print_doc_exception(exception) == :ok
             end) == expected_output
    end
  end
end
