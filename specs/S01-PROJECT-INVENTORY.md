# S01-PROJECT-INVENTORY: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Project Structure

```
simple_pdf/
├── src/
│   ├── core/
│   │   ├── simple_pdf.e              # Main facade class
│   │   ├── simple_pdf_document.e     # PDF document container
│   │   ├── simple_pdf_engine.e       # Deferred engine base
│   │   ├── simple_pdf_engines.e      # Engine availability reporter
│   │   └── simple_pdf_reader.e       # Text extraction
│   ├── engines/
│   │   ├── simple_pdf_wkhtmltopdf.e  # wkhtmltopdf implementation
│   │   └── simple_pdf_chrome.e       # Chrome/Edge implementation
│   └── music/
│       ├── simple_pdf_music.e        # Music notation support
│       └── smufl_glyphs.e            # SMuFL glyph constants
├── bin/                              # Bundled Windows executables
│   ├── wkhtmltopdf.exe
│   ├── wkhtmltox.dll
│   ├── pdftotext.exe
│   └── [Poppler DLLs]
├── testing/
│   └── [test files]
├── docs/
│   └── index.html                    # API documentation
├── simple_pdf.ecf                    # Library configuration
├── README.md                         # User documentation
├── CHANGELOG.md                      # Version history
└── LICENSE                           # MIT License
```

## ECF Configuration

- **Library Target**: simple_pdf
- **Test Target**: simple_pdf_tests
- **UUID**: Unique per library
- **Dependencies**: simple_json, simple_uuid, simple_base64

## Build Artifacts

- EIFGENs/simple_pdf/ - Library compilation
- EIFGENs/simple_pdf_tests/ - Test compilation
