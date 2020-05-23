defmodule XcribeTest do
  use ExUnit.Case

  alias Xcribe.Recorder

  test "start Xcribe" do
    {:ok, _} = Xcribe.start([], [])

    assert Recorder.get_all() == []
  end

  test "README install version check" do
    app = :xcribe

    app_version = "#{Application.spec(app, :vsn)}"
    readme = File.read!("README.md")
    [_, readme_versions] = Regex.run(~r/{:#{app}, "(.+)"}/, readme)

    assert Version.match?(app_version, readme_versions)
  end

  describe "__using__/1" do
    test "using in conn case" do
      use Xcribe, :case

      assert document(%{}) == %{}
    end

    defmodule MyInformation do
      use Xcribe, :information
    end

    test "using in information module" do
      assert MyInformation.api_info()
    end
  end
end
