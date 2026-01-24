# S05-CONSTRAINTS: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Technical Constraints

### External Dependencies
1. **wkhtmltopdf** - Required for default engine
   - Windows: Bundled in bin/
   - Linux/macOS: Must be installed via package manager

2. **Chrome/Edge** - Optional for Chrome engine
   - System-installed browser required
   - Detected in standard installation paths

3. **pdftotext** - Required for text extraction
   - Windows: Bundled in bin/
   - Linux/macOS: Install via poppler-utils

### Platform Constraints

| Platform | Engine Detection |
|----------|-----------------|
| Windows | Bundled bin/, Program Files |
| Linux | /usr/bin, /usr/local/bin, snap |
| macOS | Homebrew paths, Applications |

### Memory Constraints
- PDF generation is external process
- Eiffel layer has minimal memory footprint
- External tools may use 100-500MB during conversion

### File System Constraints
- Temporary files created during conversion
- Write access required to output directory
- Temp directory must be writable

## API Constraints

### Page Sizes
Valid values: A4, Letter, Legal, A3, A5, B4, B5

### Orientations
Valid values: Portrait, Landscape

### Margin Units
Supported: mm, in, cm, px

## Invariants

### SIMPLE_PDF
- Engine must be attached at all times
- Page size and orientation always have valid defaults

### SIMPLE_PDF_DOCUMENT
- If is_valid, content must be attached
- If not is_valid, error_message should be attached
