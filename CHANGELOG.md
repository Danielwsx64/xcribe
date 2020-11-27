# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

### Enhancements

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

## Enhancements

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

[unreleased]: https://github.com/brainn-co/xcribe/compare/v0.7.8...master
[0.7.8]: https://github.com/brainn-co/xcribe/compare/v0.7.7...v0.7.8
[0.7.7]: https://github.com/brainn-co/xcribe/compare/v0.7.6...v0.7.7
[0.7.6]: https://github.com/brainn-co/xcribe/compare/v0.7.5...v0.7.6
[0.7.5]: https://github.com/brainn-co/xcribe/compare/v0.7.4...v0.7.5
[0.7.4]: https://github.com/brainn-co/xcribe/compare/v0.7.3...v0.7.4
[0.7.3]: https://github.com/brainn-co/xcribe/compare/v0.7.2...v0.7.3
[0.7.2]: https://github.com/brainn-co/xcribe/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/brainn-co/xcribe/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/brainn-co/xcribe/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/brainn-co/xcribe/compare/0.6.0...v0.6.1
[0.6.0]: https://github.com/brainn-co/xcribe/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/brainn-co/xcribe/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/brainn-co/xcribe/compare/0.3.0...0.4.0
