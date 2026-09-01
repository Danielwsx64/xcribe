package = :xcribe
current_version = "#{Application.spec(package, :vsn)}"
auth = Mix.Tasks.Hex.auth_info(:read)

case Hex.API.Package.get(nil, to_string(package), auth) do
  {:ok, {code, body, _}} when code in 200..299 ->
    latest_version =
      body
      |> Map.get("releases")
      |> Enum.map(&Map.get(&1, "version"))
      |> Enum.sort(fn a, b -> Version.compare(a, b) == :gt end)
      |> List.first()

    unless Version.compare(current_version, latest_version) == :gt do
      Hex.Shell.error(
        "New version should be greater than `#{latest_version}` got `#{current_version}`"
      )

      exit({:shutdown, 1})
    end

  {:ok, {404, _, _}} ->
    Hex.Shell.error("No package with name #{package}")
    exit({:shutdown, 1})

  other ->
    Hex.Shell.error("Failed to retrieve package information")
    Hex.Utils.print_error_result(other)
    exit({:shutdown, 1})
end
