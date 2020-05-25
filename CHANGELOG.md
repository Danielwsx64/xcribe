# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2020-05-23

## Added

-   Validate configuration before generate documentation
-   Handle parsing errors and exceptions and print it friendly
-   Requests are ordered by path to avoid big diffs btw docs
-   Write a message with output file path

## Fixed

-   Use success requests to build Swagger parameter and request body examples

## Enhancements

-   Xcribe documentation

## [0.5.0] - 2020-05-12

## Added

-   Automatic publish to hex.pm.

## [0.4.0] - 2020-05-11

### Added

-   New "tags" parameter to operations object in Swagger format.
-   Add changelog and Makefile.

[Unreleased]: https://github.com/brainn-co/xcribe/compa...master

[0.6.0]: https://github.com/brainn-co/xcribe/compare/0.5.0...0.6.0

[0.5.0]: https://github.com/brainn-co/xcribe/compare/0.4.0...0.5.0

[0.4.0]: https://github.com/brainn-co/xcribe/compare/0.3.0...0.4.0
