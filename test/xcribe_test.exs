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
end
