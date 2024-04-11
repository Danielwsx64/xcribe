# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

<<<<<<< HEAD
[unreleased]: https://github.com/brainnco/xcribe/compare/v0.7.9...master
[1.0.0]: https://github.com/brainnco/xcribe/compare/v0.7.11...v1.0.0
=======
[unreleased]: https://github.com/Finbits/xcribe/compare/v0.7.13...master
[0.7.13]: https://github.com/Finbits/xcribe/compare/v0.7.12...v0.7.13
[0.8.0]: https://github.com/Finbits/xcribe/compare/v0.7.13...v0.8.0
>>>>>>> d453e1d (chg: updating version)
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
