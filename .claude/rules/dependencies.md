# Rules: Dependencies & support matrix

xcribe ships into other people's dependency trees. Every dep is a cost they pay.

- **`:plug` is the only runtime dependency.** Everything else in `mix.exs` is `only: :dev`,
  `only: :test`, or both. `:phoenix` is `only: [:dev, :test]` **and must stay that way** — it
  was deliberately moved out of the runtime tree, and moving it back is a breaking change to
  every consumer's dependency resolution.
- **Therefore Phoenix is reached reflectively, never by reference.** `lib/` must not `alias`,
  `import`, or `use` a Phoenix module. The three permitted reflective touchpoints, all in
  `Xcribe.ConnParser` and `Mix.Tasks.Xcribe.Doc`:

      Map.fetch!(conn.private, :phoenix_endpoint)
      %{private: %{phoenix_router: router}} = conn
      router.__match_route__(method, path, host)
      endpoint.config(:otp_app)

  `__match_route__/3` is a **private Phoenix function** — it changed argument order in Phoenix
  1.8. Every reflective call is wrapped in a `rescue` that **enumerates** its exceptions so the
  next such change surfaces as a real failure instead of a generic parse error (see
  [errors.md](errors.md)).
- **The JSON library is the consumer's choice.** Call it through `Xcribe.JSON`, which reads
  `json_library` from the config map. `Jason` appears in `lib/` exactly once, as the default in
  `Xcribe.Config` — **never** hard-code it anywhere else, and never add it as a runtime dep.
- **Version floors use the explicit range form** for `plug` and `phoenix`
  (`">= 1.18.5 and < 2.0.0"`), not `~>`, because the floor carries meaning: it is *the first
  release without a known security advisory*. The comment in `mix.exs` says so — keep it true
  when you bump, or delete it.
- **No new dependency without a stated reason in the PR.** There is no dialyzer/dialyxir here
  (and no typespecs for it to check — see [docs.md](docs.md)); don't add one incidentally.
- **A support-matrix change must land in every one of these, or CI lies:**

      mix.exs                      # `elixir:` requirement and the dep floors
      .tool-versions               # the newest pair, used locally and as CI's lint toolchain
      README.md                    # the "Requirements" section
      .github/workflows/ci.yml     # the `mix_test` matrix (oldest supported → newest)
      .github/workflows/ci.yml     # the sed + `grep -q` guards in `mix_test_floor_deps`

  The `grep -q` guards in the floor-deps job exist to **fail loudly when the constraint strings
  in `mix.exs` change** — otherwise that job silently degrades into a duplicate of the matrix.
  Update the guards; never delete them.
- Dropping support for an Elixir/OTP/Phoenix/Plug version is a **major** bump — see
  [release.md](release.md).
