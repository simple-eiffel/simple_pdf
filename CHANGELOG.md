# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- 2026-11-23: `bin/libexpat.dll` is Expat 2.9.0 and `bin/libpng16.dll` is libpng 1.6.59, copied
  from simple_cairo 1.8.2 (2.6.3 and 1.6.44 before: 33 and 12 CVEs fixed since). poppler.dll's
  35 libpng imports are all exported. Removed `bin/expat.dll`, a second copy of Expat 2.6.3 that
  nothing in `bin/` imports. pdftocairo renders a page to PNG, wkhtmltopdf writes a PDF and
  pdftotext reads both, with only System32 on PATH; suite 14/0.
- 2026-11-22: `bin/freetype.dll` is FreeType 2.14.3, copied from simple_cairo 1.8.1 (2.12.1 had
  CVE-2025-27363). Poppler 24.08.0 imports nothing it lacks: poppler.dll's 17 functions,
  poppler-glib.dll's 6 and pdftocairo.exe's 6 are all exported. pdftotext reads text and
  pdftocairo renders a page with the new DLL; suite 14/0.

### Changed (the cairo set is simple_cairo's)
- 2026-11-11: the seven DLLs of the cairo set in `bin/` (cairo 1.18.0, fontconfig, freetype,
  expat, libpng, pixman, zlib) are now owned by simple_cairo (`simple_cairo/runtime/windows/`,
  simple_cairo PR 6), one version per DLL name across simple_*. `bin/` keeps byte-identical
  copies because its helper programs load DLLs from their own folder; see `bin/README.md` and
  issue 1 for their removal.
- New test `test_bin_mirrors_the_owners_cairo_set`: fails if a copy differs from the owner's,
  naming the file, both SHA-256 hashes and the owner.
- New test `test_cairo_text_reads_back_through_the_helper`: text drawn into a PDF by this
  process's cairo reads back through `pdftotext`. It fails on the old cairo 1.17.2, whose PDF
  output broke at the first page.
- The test runner now prints why a test failed.

### Fixed (a PDF with no text)
- 2026-10-30: every extract feature read pdftotext's output with `read_stream (count.max (1))`,
  which failed a precondition on the empty file a PDF without a text layer (scanned pages)
  leaves; they return empty text now. Test: `testing/fixtures/blank_page.pdf`.

### Added
- 2026-10-30: `SIMPLE_PDF_READER.extract_text_flowing`: text in reading order, decoded
  from UTF-8, with no page-break characters (`-enc UTF-8 -nopgbrk`), for prose readers
  such as simple_bible's ingest kits; `-layout` pads columns and `-raw` drops spaces
  some PDFs only imply.

### Fixed (process output)
- Tool output is returned as the raw bytes (`last_output_bytes`, simple_process
  1.1.0), not `to_string_8` of the now-decoded text, which failed above U+00FF
  and would have broken callers that decode it as UTF-8.


### Changed
- 2026-10-26: dropped the ISE `encoding` library from the ECF; nothing used it (clean build, 10 pass).
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
