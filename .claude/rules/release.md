# Rules: Release

Merging to `master` publishes to Hex. There is no manual release step and no undo — a bad
version is public forever. What counts as breaking is [public-api.md](public-api.md).

- **Every user-visible change adds an entry under `## [Unreleased]` in `CHANGELOG.md`**, in the
  Keep a Changelog subsections (`### Added` / `### Changed` / `### Fixed` / `### Removed`).
  Entries are **multi-sentence prose explaining the *why* and the impact on a consumer**,
  matching the existing Unreleased block — not a one-line summary of the diff:

      ### Fixed

      - Route matching against Phoenix 1.8. The private router function xcribe uses to
        resolve a route swapped its argument order in Phoenix 1.8, which made every
        request fail to parse.

- **Version bumps go through `make release`** — it prompts major/minor/patch and rewrites
  `@version` in `mix.exs`, the `"~> X.Y.Z"` snippet in `README.md`, and the CHANGELOG heading
  plus its compare links. **Never hand-edit `@version`**; the three files drift silently and
  nothing catches it.
- **SemVer against the public API, strictly.** Major: breaking a documented config key, the
  `document/2` signature, the `Xcribe.Information` DSL, the generated output shape, or dropping
  an Elixir/OTP/Phoenix/Plug version ([dependencies.md](dependencies.md)). Minor: a new config
  key with a default, a new output format, a new documented capability. Patch: everything else.
- **Merging a PR to `master` runs `mix hex.publish --yes` and creates the `vX.Y.Z` tag.** The
  `mix_check_version` job fails any PR targeting `master` whose version is not **strictly
  greater** than the newest release on hex.pm — so the bump and the CHANGELOG must be in the PR,
  not a follow-up.
- **Patches target `master`; features target the current release branch** (`release-X.Y.Z`,
  the next minor). Working branches are `type/kebab-description` (`fix/update`,
  `feat/use-tags`, `chore/update-versions`). Two approvals to merge, per `CONTRIBUTING.md`.
- Before opening a PR: `mix precommit` green, CHANGELOG entry written, version bumped if the PR
  targets `master`, and `README.md` / `documentation/serving_doc.md` updated if a consumer can
  observe the change ([docs.md](docs.md)).
