# Release gate: fails unless the version in mix.exs is greater than the latest
# release published to Hex.
#
# Uses the public Hex API over :httpc rather than Hex's internal modules
# (Mix.Tasks.Hex.auth_info/1, Hex.API.Package.get/3), which are private and have
# broken across Hex releases before.

package = "xcribe"
current_version = "#{Application.spec(:xcribe, :vsn)}"

Mix.ensure_application!(:inets)
Mix.ensure_application!(:ssl)

url = ~c"https://hex.pm/api/packages/#{package}"
headers = [{~c"user-agent", ~c"xcribe-check-version"}]

abort = fn message ->
  IO.puts(:stderr, IO.ANSI.format([:red, message]))
  exit({:shutdown, 1})
end

http_opts = [ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get()]]

case :httpc.request(:get, {url, headers}, http_opts, body_format: :binary) do
  {:ok, {{_, status, _}, _headers, body}} when status in 200..299 ->
    latest_version =
      body
      |> :json.decode()
      |> Map.fetch!("releases")
      |> Enum.map(&Map.fetch!(&1, "version"))
      |> Enum.max_by(&Version.parse!/1, Version)

    if Version.compare(current_version, latest_version) != :gt do
      abort.("New version should be greater than `#{latest_version}` got `#{current_version}`")
    end

    IO.puts("Version `#{current_version}` is greater than published `#{latest_version}`")

  {:ok, {{_, 404, _}, _headers, _body}} ->
    abort.("No package with name #{package}")

  other ->
    abort.("Failed to retrieve package information: #{inspect(other)}")
end
