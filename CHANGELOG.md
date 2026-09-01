# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A specification file, `.xcribe.exs`, replaces the `Xcribe.Information` module as the place your
  API's title, description, version and servers are declared. It is plain Elixir evaluating to a
  map, so it needs no compilation and no `use` — and it is optional, since Xcribe falls back to
  defaults. `mix xcribe.gen.spec` writes a starting point, and `--output` puts it somewhere other
  than the project root. See `Xcribe.Specification`.
- The specification file's `paths:` key lets you write documentation Xcribe cannot infer from a
  test: a description for a route, or a whole route your suite never exercises. Values you author
  there win over the generated ones. Swagger accepts a full OpenAPI Path Item Object; API Blueprint
  has no equivalent structure and reads only `description`.
- The specification file's `schemas:` key seeds `components.schemas`, so hand-written component
  schemas survive alongside the ones derived from your responses. Swagger only.
- `ignore_namespaces:` and `ignore_resources_prefix:` strip routing noise out of the generated
  document. An app that mounts everything under `/api/v1` no longer gets that prefix repeated in
  every path, group tag and schema name. The path of each configured server is stripped
  automatically, and longer prefixes are applied first so a short one cannot leave a fragment
  behind.
- `document/2` accepts `schema:` and `req_schema:` to name the response and request schemas of a
  route, and the `@xcribe_schema` / `@xcribe_req_schema` module attributes do the same for a whole
  test file. In Swagger the name becomes a `components.schemas` key referenced by `$ref`, which
  removes the schema duplication that made large documents unreadable. API Blueprint has no
  component section, so the name surfaces as the JSON Schema `title`.
- `document/2` accepts `tags: false` to document a route without a group tag, for endpoints that do
  not belong in any group.
- The `:specification_source` config key points at the specification file. Default `".xcribe.exs"`.

### Changed

- **Breaking.** `Xcribe.Information`, the `xcribe_info` DSL and the `information_source` config key
  are removed. They required consumers to compile a module whose only job was to hold static text,
  and the DSL had to be re-learned to change an API description. Run `mix xcribe.gen.spec` and move
  the values across to `.xcribe.exs`.
- **Breaking.** The generated Swagger document now references named schemas under
  `components.schemas` with `$ref` instead of inlining a copy into every operation, and no longer
  emits the always-empty `summary` field on operations. Both change a committed document's diff, so
  expect one large diff on first regeneration.
- Resource names now split on underscores, so a route mounted under `/namespace_with_underscore`
  reads as `Namespace With Underscore` rather than as a single run-together word.
- Requires Elixir 1.18+, Erlang/OTP 27+, Phoenix 1.8.9+ and Plug 1.18.5+. The
  Phoenix and Plug floors are the first releases without known security advisories.
- `phoenix` moved to a dev/test-only dependency; it is no longer pulled into
  consumers' dependency trees.
- Updated `plug`, `jason`, `floki`, `ex_doc`, `excoveralls`, `credo` and
  `credo_naming` to current releases; dropped the unused `earmark` dependency.
- Bundled Swagger UI updated from 3.x to 5.32.14.

### Fixed

- Requests documented with `tags: false` were silently dropped from the API Blueprint output
  entirely, because the formatter grouped requests by tag and a request with no tags reduced to
  nothing. They are now documented in the unnamed group.
- Merging two responses that returned arrays of different types collapsed them into whichever was
  recorded first. Array schemas keep their reference under `items`, and the deduplication only
  looked for a top-level `$ref`, so every array compared equal.
- Merging two object-typed query parameters dropped any property that only the first one had.
- The `parameters` list of a generated operation is now sorted by name, and `oneOf` schema lists are
  sorted too. Both previously followed map iteration order, which is unspecified past 32 keys and
  can change between Erlang/OTP releases.
- An unreadable specification file now prints an Xcribe error report instead of a raw stacktrace,
  and no longer takes the ExUnit formatter process down with it. A file that parses but does not
  evaluate to a map, and a `servers` entry without a `:url`, are reported as themselves rather than
  as a syntax error.
- A specification listing no servers no longer crashes the API Blueprint format.
- A `schemas:` entry in the specification file crashed with a `KeyError` whenever it named a schema
  Xcribe also derived from a response — which is the whole point of the key. Hand-written schemas
  carry only the fields their author cared about, and the merge assumed every schema had
  `properties`.
- The API Blueprint document now orders groups, resources, actions, requests, parameters and
  headers explicitly. They followed map iteration order, which stops matching term order once a map
  passes 32 keys, so a large API's document could reshuffle wholesale on adding a single route.
- An output file that cannot be written is now reported and returns `:error`, instead of raising
  `FunctionClauseError` out of `document_all_records/1` after printing the error — which took the
  ExUnit formatter process down with it.
- `mix xcribe.gen.spec` exits non-zero when it refuses to overwrite an existing file, so it can be
  chained in a script.
- Route matching against Phoenix 1.8. The private router function xcribe uses to
  resolve a route swapped its argument order in Phoenix 1.8, which made every
  request fail to parse. The `rescue` around the call was also narrowed so a future
  signature change surfaces instead of being reported as a generic parsing error.
- Generated JSON now has a stable key order. Object keys were inherited from the
  iteration order of maps with atom keys, which is arbitrary and changes between
  Elixir/OTP releases.

## [1.0.0] - 2021-07-17

## Added

- Mix task xcribe.doc
- Allow multiple endpoints config

### Changed

- Xcribe configuration is scoped by application endpoint module
- Documentation route foward to Xcribe.Web.Plug you must provide the application
  endpoint.

### Removed

- The env var config was removed. Now you must use `XCRIBE_ENV` to active xcribe
  when running `mix test`

## [0.7.13] - 2024-04-11

### Changed

- Updated Phoenix to 1.15 and updated dependencies.

## [0.7.12] - 2022-01-05

### Changed

- Repository migrated to finbits organization.

## [0.7.11] - 2021-05-29

### Fixed

- Handle events from ExUnit 1.12

## [0.7.10] - 2021-04-25

### Fixed

- Fix output documentation artifact unavailable crash message

## [0.7.9] - 2020-11-30

### Fixed

- Handle Plug.Upload and generate doc as specified by formats (Swagger and ApiBlueprint)

## [0.7.8] - 2020-11-27

### Fixed

- Add query strings to API Blueprint formatter

## [0.7.7] - 2020-11-27

### Fixed

- Validate requests and report an error message when found structs in HTTP params

## [0.7.6] - 2020-11-14

### Fixed

- Compilation warning about Phoenix module.

## [0.7.5] - 2020-11-13

### Fixed

- Exception on parsing route without pipeline ( routes without pipeline will be out of a group section in ApiBlueprint format ).

## [0.7.4] - 2020-10-19

- Remove usage of deprecated `Supervisor.Spec`

## [0.7.2] - 2020-06-11

### Enhancements

- Add PR template
- Move Code of Conduct to a separate file
- Add links to badges in readme
- Make all badges have the same appearance

## [0.7.2] - 2020-06-09

### Fixed

- Relative path format on errors.
- Changelog links.

## [0.7.1] - 2020-06-09

### Fixed

- Improve internal modules naming and location.

## [0.7.0] - 2020-06-06

### Added

- Serve Swagger documentation

### Deprecations

- Configuration key `:output_file` in favor of `:output`
- Configuration key `:doc_format` in favor of `:format`

### Enhancements

- Xcribe contributing documentation
- ApiBlueprint formatter modules

## [0.6.1] - 2020-06-08

### Enhancements

Improve CI/CD flow:

- Run credo
- Publish after tests completed
- Create github release + git tag

## [0.6.0] - 2020-05-23

### Added

- Validate configuration before generate documentation
- Handle parsing errors and exceptions and print it friendly
- Requests are ordered by path to avoid big diffs btw docs
- Write a message with output file path

### Fixed

- Use success requests to build Swagger parameter and request body examples

### Enhancements

- Xcribe documentation

## [0.5.0] - 2020-05-12

### Added

- Automatic publish to hex.pm.

## [0.4.0] - 2020-05-11

### Added

- New "tags" parameter to operations object in Swagger format.
- Add changelog and Makefile.

[unreleased]: https://github.com/brainnco/xcribe/compare/v0.7.9...master
[1.0.0]: https://github.com/brainnco/xcribe/compare/v0.7.11...v1.0.0
[0.8.0]: https://github.com/Finbits/xcribe/compare/v0.7.13...v0.8.0
[0.7.13]: https://github.com/Finbits/xcribe/compare/v0.7.12...v0.7.13
[0.7.12]: https://github.com/Finbits/xcribe/compare/v0.7.11...v0.7.12
[0.7.11]: https://github.com/brainnco/xcribe/compare/v0.7.10...v0.7.11
[0.7.9]: https://github.com/brainnco/xcribe/compare/v0.7.8...v0.7.9
[0.7.8]: https://github.com/brainnco/xcribe/compare/v0.7.7...v0.7.8
[0.7.7]: https://github.com/brainnco/xcribe/compare/v0.7.6...v0.7.7
[0.7.6]: https://github.com/brainnco/xcribe/compare/v0.7.5...v0.7.6
[0.7.5]: https://github.com/brainnco/xcribe/compare/v0.7.4...v0.7.5
[0.7.4]: https://github.com/brainnco/xcribe/compare/v0.7.3...v0.7.4
[0.7.3]: https://github.com/brainnco/xcribe/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/brainnco/xcribe/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/brainnco/xcribe/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/brainnco/xcribe/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/brainnco/xcribe/compare/0.6.0...v0.6.1
[0.6.0]: https://github.com/brainnco/xcribe/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/brainnco/xcribe/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/brainnco/xcribe/compare/0.3.0...0.4.0
