# bin/: helper programs and their DLLs (Windows)

simple_pdf runs these programs as separate processes: `pdftotext.exe` (Poppler 24.08.0) and
`wkhtmltopdf.exe` (0.12.6). Windows loads a program's DLLs from the program's own folder first,
so their DLLs sit here beside them.

## The cairo set is mirrored, not owned

| DLL | Version | Owner |
|---|---|---|
| cairo.dll | 1.18.0 | simple_cairo |
| fontconfig-1.dll | 2.14.2 | simple_cairo |
| freetype.dll | 2.14.3 | simple_cairo |
| libexpat.dll | 2.9.0 | simple_cairo |
| libpng16.dll | 1.6.59 | simple_cairo |
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

## curl and xz: owned here, for Poppler

| DLL | Version | Source | Imported by |
|---|---|---|---|
| libcurl.dll | 8.23.0 (build 8.23.0_10) | curl.se official Windows build, `libcurl-x64.dll` renamed | poppler.dll (6 functions: curl_easy_init, _setopt, _perform, _getinfo, _reset, _cleanup) |
| liblzma.dll | 5.8.3 | conda-forge `liblzma-5.8.3-hfd05255_1` | tiff.dll (6 lzma_ functions) |

- **Why curl.se's build:** it carries its own TLS (LibreSSL 4.4.1), libssh2 1.11.1, libpsl 0.23.3,
  nghttp2, brotli and zstd inside one DLL that imports only Windows' own. conda-forge's libcurl
  from 8.21.0 build 2 on needs libpsl, which needs ICU (about 35 MB more). simple_showcase ships the
  same build as `libcurl-x64.dll`, so the fleet has one curl. Larry's choice, 2026-11-25.
- **Why renamed:** poppler.dll imports `libcurl.dll` by name; the exports are curl's stable C API.
- **Provenance:** zip SHA-256 `7157104332c15c80edba0359446584cb317c63f4c3cf5e569b76ecad5aa0e197`,
  matching the hash curl.se/windows publishes. liblzma package SHA-256
  `d36c4a1e1f80fd08e18a407e03622ff2f34dfdd022da6488ad19603dea19e6d5`.
- **Licenses:** `licenses/curl/` (curl and each library built into it), `licenses/xz/`.
- **Gone since 2026-11-25:** `libssh2.dll` 1.11.0 and `libcrypto-3-x64.dll` (OpenSSL 3.3.2), which
  only the old libcurl loaded; `libtiff.dll` and `libzstd.dll`, which nothing here imports.

Proved 2026-11-25 with only System32 and Windows on PATH: pdftotext reads text, pdftocairo renders
a page to PNG, wkhtmltopdf writes a PDF; loading poppler.dll from this folder loads
`libcurl/8.23.0 LibreSSL/4.4.1 ... libssh2/1.11.1` and `liblzma 5.8.3`, and neither libssh2.dll nor
libcrypto-3-x64.dll.

## The TIFF stack: owned here, for Poppler

| DLL | Version | conda-forge package (win-64) | Imported by |
|---|---|---|---|
| tiff.dll | 4.7.2 | `libtiff-4.7.2-hddd6eee_3` | poppler.dll (5 functions) |
| zstd.dll | 1.6.0 | `zstd-1.6.0-h49982e4_0` | tiff.dll (15) |
| deflate.dll | 1.26 | `libdeflate-1.26-h1a1d4e4_0` | tiff.dll (7) |
| Lerc.dll | 4.3.0 | `lerc-4.3.0-hd936e49_0` | tiff.dll (3) |
| jpeg8.dll | libjpeg-turbo 3.2.1 | `libjpeg-turbo-3.2.1-hfd05255_0` | poppler.dll (19 by ordinal), tiff.dll (25 by ordinal) |

- **Why together:** libtiff 4.7.2 build 3 (2026-11-25) is the first conda-forge build on zstd 1.6,
  so the whole stack moved in one step. Each package's SHA-256 matched the one conda-forge's API
  publishes for it.
- **Ordinals:** poppler.dll and tiff.dll import jpeg8.dll by ordinal number, not by name. The 135
  exports of 3.2.1 keep every ordinal of 3.0.0, checked one by one before the swap. Check again
  whenever jpeg8.dll changes.
- **zlib:** these import zlib.dll by name only; it stays the cairo set's copy (see above).
- **Licenses:** `licenses/libtiff/`, `licenses/zstd/`, `licenses/libdeflate/`, `licenses/lerc/`,
  `licenses/libjpeg-turbo/`.
- **Mirrors:** simple_graphviz and simple_spec_viz carry byte-identical copies of tiff.dll and
  everything it imports (libgd.dll there imports tiff). Change them here first, then copy.
