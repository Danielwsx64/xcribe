defmodule Xcribe.SwaggerExamples do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Xcribe.Request

      @sample_swagger_output File.read!("test/support/swagger_example.json")
    end
  end
end
