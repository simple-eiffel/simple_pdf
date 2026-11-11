# bin/: helper programs and their DLLs (Windows)

simple_pdf runs these programs as separate processes: `pdftotext.exe` (Poppler 24.08.0) and
`wkhtmltopdf.exe` (0.12.6). Windows loads a program's DLLs from the program's own folder first,
so their DLLs sit here beside them.

## The cairo set is mirrored, not owned

| DLL | Version | Owner |
|---|---|---|
| cairo.dll | 1.18.0 | simple_cairo |
| fontconfig-1.dll | 2.14.2 | simple_cairo |
| freetype.dll | 2.12.1 | simple_cairo |
| libexpat.dll | 2.6.3 | simple_cairo |
| libpng16.dll | 1.6.44 | simple_cairo |
| pixman-1-0.dll | 0.43.4 | simple_cairo |
| zlib.dll | 1.3.1 | simple_cairo |

These seven are byte-identical copies of `simple_cairo/runtime/windows/`, which owns them for
the whole simple_* fleet (BUILD_STANDARDS section 9: one version per DLL name). Larry's rule
is "the SAME version"; the fleet's reading is that no library carries its own copy. This folder
is a written, temporary exception to that reading:

- **Why:** `pdftotext.exe` loads `poppler.dll`, which imports freetype, zlib and libpng16, and
  `poppler-glib.dll` imports cairo. A helper program cannot reach the owner's folder: it is not
  beside the program, and SIMPLE_PROCESS cannot give a child process its own PATH.
- **Guard:** `test_bin_mirrors_the_owners_cairo_set` in simple_pdf's suite fails if any of these
  differs from the owner's copy, and names the file, both SHA-256 hashes and the owner.
- **To change one:** change simple_cairo's set first (its own pull request and gates), then copy
  it here. Never replace one of these from a Poppler download.
- **Removal:** [simple_pdf issue 1](https://github.com/simple-eiffel/simple_pdf/issues/1), when
  build staging (ec.sh option b, or simple_dll) puts the owner's set beside the helpers.

Proved 2026-11-11: with only System32 and Windows on PATH, `bin/pdftotext.exe` (24.08.0) starts
and extracts text, loading these copies (none of the seven exists in System32).
