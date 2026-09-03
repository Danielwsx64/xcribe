# Rules: Generated output

The `.apib` / JSON document xcribe writes is part of the public contract
([public-api.md](public-api.md)) — consumers commit it and review its diffs.

- **A generated document must be byte-identical across runs, machines, Elixir/OTP releases, and
  test-execution order.** A diff in a consumer's committed doc must mean *their API changed*.
  Anything else is a bug in xcribe, not noise.
- **Map keys are stringified before encoding.** `Xcribe.JSON.encode!/3` walks the value through
  `stringify_keys/1` first, because maps with atom keys iterate in atom-table order, which is
  arbitrary and varies between releases. **Never** hand an atom-keyed map to
  `json_library.encode!/2` directly, and never bypass `Xcribe.JSON`.
- **Every collection that reaches the output is explicitly sorted.** The existing sorts are the
  pattern:

      Enum.sort_by(requests, &request_sort_key/1)  # Xcribe.APIModel, a total key per request
      Enum.sort_by(key_function)                   # Xcribe.APIModel.Merge.by_key/4, every collection
      Enum.sort_by(&{&1.name, &1.location})        # Xcribe.OpenAPI.Formatter, parameter objects

  **Never rely on the iteration order of a map, `Enum.group_by/3`, `Map.new/2`, or
  `MapSet`** — and never rely on the order requests were recorded in, which follows ExUnit's
  scheduling and changes with `async: true`.
- **The golden files pin the contract**: `test/support/openapi_example.json` and
  `test/support/api_blueprint_example.apib`. Changing either is a deliberate,
  CHANGELOG-worthy behaviour change — **never** an incidental test fixup to make a diff go
  away. If a change to `lib/` moves a golden file, say why in the CHANGELOG entry and confirm
  it is not a breaking output change (see [release.md](release.md)).
- Output paths come from the `file_path:` and `file_name:` config keys, joined by
  `Xcribe.Config.output_path/1`, with a per-format `file_name` default; `Xcribe.Writter` is
  the only module that writes (see [architecture.md](architecture.md)). Never build a path from
  `File.cwd!/0` or an env var.
