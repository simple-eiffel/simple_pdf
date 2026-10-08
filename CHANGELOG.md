# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed (process output)
- Tool output is returned as the raw bytes (`last_output_bytes`, simple_process
  1.1.0), not `to_string_8` of the now-decoded text, which failed above U+00FF
  and would have broken callers that decode it as UTF-8.


### Changed
- Testing config updates, AutoTest fixes, .gitignore cleanup
- Add SCOOP capability, migrate to simple_process
- Migrate to simple_testing library
- Remove redundant attached checks, update docs
- Add fluent API examples for common use cases
- Add binary version info, sources, licenses, and update instructions
- Add fluent API for chainable configuration
- Add API Integration section to README and docs
- Fix corrupted README.md encoding
- Add documentation and US Constitution demo test

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Core functionality implemented
- Test suite with comprehensive coverage
- Documentation and examples

[Unreleased]: https://github.com/simple-eiffel/simple_pdf/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/simple-eiffel/simple_pdf/releases/tag/v1.0.0
