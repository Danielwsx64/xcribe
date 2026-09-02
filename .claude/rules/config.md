# Rules: Configuration

Config is endpoint-scoped and read in exactly one place. Which module receives it and how it
flows is [architecture.md](architecture.md); the error tuple it returns is [errors.md](errors.md).

- **`Application.get_env/3` for `:xcribe` appears only in `Xcribe.Config`.** There is currently
  exactly one call site (`lib/xcribe/config.ex:10`, plus `Application.get_all_env/1` in
  `all_endpoints/0`) — keep it that way. A second reader anywhere else is a bug.
- Config is **scoped per endpoint**, never global:

      config :xcribe, YourAppWeb.Endpoint, format: :openapi, output: "openapi.json"

  read with `Xcribe.Config.fetch_config/1`, which normalizes the keyword list into a **map with
  every default already applied** (`format: :openapi`, `json_library: Jason`,
  `output:` per format, `serve: false`, `specification_source: ".xcribe.exs"`).
- **Every other module receives that map as a trailing `config` argument and pattern-matches
  only the keys it needs** — the argument name is the documentation:

      # do
      def encode!(value, options, %{json_library: json_library})

      # not
      def encode!(value, options), do: Application.get_env(:xcribe, ...)

- **Adding a key is a five-part change**: a default in `apply_default_values/1`, a
  `validate_config/2` clause, a bullet in `Xcribe`'s `@moduledoc` (that moduledoc *is* the
  user-facing config reference), a test in `test/xcribe/config_test.exs`, and a `CHANGELOG.md`
  entry. An additive key with a default is a **minor** bump; changing an existing key's meaning
  is **major** — see [public-api.md](public-api.md).
- **Validation accumulates, never raises, never logs, never returns partial config.**
  `check_configurations/2` reduces over the keys and answers `{:ok, config}` or
  `{:error, [{key, value, message, instructions}]}`.
- **A validation clause's message and instructions are module-attribute string constants
  declared immediately above the clause that uses them** — the pair reads as one unit:

      @format_message "Xcribe doesn't support the configured documentation format"
      @format_instructions "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."
      defp validate_config(:format, {_errors, config} = results) do

  `instructions` is the copy-pasteable fix the user needs. Never leave it blank.
- **Activation is separate from configuration.** `Xcribe.Config.active?/0` reads the
  `XCRIBE_ENV` environment variable (`"1"`, `"true"`, `"TRUE"`) — not a config key — so a
  consumer's normal test run is unaffected by merely having xcribe configured.
