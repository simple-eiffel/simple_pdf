# S02-CLASS-CATALOG: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Class Hierarchy

```
ANY
├── SIMPLE_PDF                  # Main facade
├── SIMPLE_PDF_DOCUMENT         # PDF container
├── SIMPLE_PDF_ENGINE           # Deferred base
│   ├── SIMPLE_PDF_WKHTMLTOPDF  # wkhtmltopdf engine
│   └── SIMPLE_PDF_CHROME       # Chrome/Edge engine
├── SIMPLE_PDF_ENGINES          # Availability reporter
├── SIMPLE_PDF_READER           # Text extraction
├── SIMPLE_PDF_MUSIC            # Music notation
└── SMUFL_GLYPHS               # Glyph constants
```

## Class Descriptions

### SIMPLE_PDF (Facade)
Main entry point for PDF generation. Delegates to engine.
- **Creation**: `make`, `make_with_engine`
- **Purpose**: Unified API for all PDF operations

### SIMPLE_PDF_DOCUMENT
Represents a generated PDF with binary content.
- **Creation**: `make`, `make_from_file`, `make_failed`
- **Purpose**: Container for PDF data and metadata

### SIMPLE_PDF_ENGINE (Deferred)
Abstract base for rendering engines.
- **Purpose**: Define engine contract
- **Heirs**: SIMPLE_PDF_WKHTMLTOPDF, SIMPLE_PDF_CHROME

### SIMPLE_PDF_WKHTMLTOPDF
wkhtmltopdf-based rendering engine.
- **Creation**: `make`
- **Purpose**: Default PDF generation engine

### SIMPLE_PDF_CHROME
Chrome/Edge headless rendering engine.
- **Creation**: `make`
- **Purpose**: High-fidelity CSS3 rendering

### SIMPLE_PDF_READER
PDF text extraction using pdftotext.
- **Creation**: `make`
- **Purpose**: Extract text from existing PDFs

### SIMPLE_PDF_ENGINES
Engine availability reporter.
- **Purpose**: Check and report available engines

### SIMPLE_PDF_MUSIC
Music notation PDF support.
- **Purpose**: SMuFL glyph rendering for sheet music
