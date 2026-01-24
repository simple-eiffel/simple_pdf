# 7S-06-SIZING: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Complexity Assessment

### Source Files
| File | Lines | Complexity |
|------|-------|------------|
| simple_pdf.e | ~263 | Low - Facade |
| simple_pdf_document.e | ~147 | Low - Data object |
| simple_pdf_engine.e | ~50 | Low - Deferred base |
| simple_pdf_wkhtmltopdf.e | ~200 | Medium - CLI wrapper |
| simple_pdf_chrome.e | ~180 | Medium - CLI wrapper |
| simple_pdf_reader.e | ~100 | Low - Text extraction |
| simple_pdf_engines.e | ~80 | Low - Engine reporter |
| simple_pdf_music.e | ~150 | Medium - SMuFL support |
| smufl_glyphs.e | ~100 | Low - Constants |

**Total**: ~1,270 lines of Eiffel code

### Bundled Binaries (Windows)
| Binary | Size | Purpose |
|--------|------|---------|
| wkhtmltopdf.exe | ~40MB | PDF generation |
| wkhtmltox.dll | ~40MB | wkhtmltopdf library |
| pdftotext.exe | ~57KB | Text extraction |
| Poppler DLLs | ~22MB | pdftotext deps |
| **Total** | ~142MB | |

## Resource Usage

### Memory
- Low overhead in Eiffel layer
- External tools may use 100-500MB during conversion

### CPU
- Conversion is CPU-intensive (external process)
- Eiffel layer is minimal overhead

### Disk I/O
- Temporary files created during conversion
- Final PDF written to user-specified path

## Performance Estimates

| Operation | Typical Time |
|-----------|--------------|
| Simple HTML to PDF | 1-2 seconds |
| Complex HTML to PDF | 3-5 seconds |
| URL capture | 2-10 seconds (network) |
| Text extraction | <1 second |
