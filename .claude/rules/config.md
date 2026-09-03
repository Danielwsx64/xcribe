# Rules: Configuration

Config is endpoint-scoped and read in exactly one place. Which module receives it and how it
flows is [architecture.md](architecture.md); the error tuple it returns is [errors.md](errors.md).

- **`Application.get_env/3` for `:xcribe` appears only in `Xcribe.Config`**, and only in the
  function that reads one endpoint's keys (plus the `Application.get_all_env/1` that lists the
  configured endpoints). A second reader anywhere else is a bug.
- Config is **scoped per endpoint**, never global:

      config :xcribe, YourAppWeb.Endpoint, format: :openapi, file_name: "openapi.json"

  read with `Xcribe.Config.fetch_config/1`, which normalizes the keyword list into a **map with
  every default already applied**, plus the `endpoint:` it was read for. The keys and their
  defaults are documented in `Xcribe.Config`'s `@moduledoc` — do not restate them here.
- **Every other module receives that map as a trailing `config` argument and pattern-matches
  only the keys it needs** — the argument name is the documentation:

      # do
      def encode!(value, options, %{json_library: json_library})

      # not
      def encode!(value, options), do: Application.get_env(:xcribe, ...)

- **Adding a key is a five-part change**: a default in `apply_default_values/2`, a
  `validate_config/2` clause, a `###` section in `Xcribe.Config`'s `@moduledoc` (that moduledoc
  *is* the user-facing config reference; `Xcribe`'s only lists the key names), a test in
  `test/xcribe/config_test.exs`, and a `CHANGELOG.md` entry. An additive key with a default is a **minor** bump; changing an existing key's meaning
  is **major** — see [public-api.md](public-api.md).
- **Validation accumulates, never raises, never logs, never returns partial config**, and never
  writes a file nor calls a running endpoint. `check_configurations/2` reduces over the keys and
  answers `{:ok, config}` or `{:error, [{key, value, message, instructions}]}`. It is called from
  `Xcribe.Application.start/2` at boot, so a side effect in a validation clause runs in every
  consumer's app on every boot. Reading is fine — the `:specification_source` clause stats its
  file — but the one key that asks a running endpoint whether it serves the generated document,
  `:served_document`, is **not** in `@default_keys_to_validate`: `Mix.Tasks.Xcribe.Serve` passes
  it explicitly, after the endpoint has started.
- **A validation clause's message and instructions are module-attribute string constants
  declared immediately above the clause that uses them** — the pair reads as one unit:

      @format_message "Xcribe doesn't support the configured documentation format"
      @format_instructions "Xcribe supports :openapi and :api_blueprint, configure as: `config :xcribe, Endpoint, format: :openapi`. The :swagger format was renamed to :openapi."
      defp validate_config(:format, {_errors, config} = results) do

  `instructions` is the copy-pasteable fix the user needs. Never leave it blank.
- **Activation is separate from configuration.** `Xcribe.Config.active?/0` reads the
  `XCRIBE_ENV` environment variable (`"1"`, `"true"`, `"TRUE"`) — not a config key — so a
  consumer's normal test run is unaffected by merely having xcribe configured.
