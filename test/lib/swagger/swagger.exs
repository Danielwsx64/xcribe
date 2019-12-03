defmodule Xcribe.SwaggerTest do
  use ExUnit.Case, async: true
  use Xcribe.RequestsExamples
  use Xcribe.SwaggerExamples

  alias Xcribe.Swagger

  describe "generate_doc/1" do
    test "parse requests do string" do
      assert Jason.decode!(Swagger.generate_doc(@sample_requests)) ==
               Jason.decode!(@sample_swagger_output)
    end
  end
end
