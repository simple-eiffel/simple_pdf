# 7S-02-STANDARDS: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Applicable Standards

### PDF Standards
- **PDF 1.4** - Base output format (via wkhtmltopdf)
- **PDF 1.7** - Extended format (via Chrome)

### HTML/CSS Standards
- **HTML5** - Input document format
- **CSS3** - Styling support (engine-dependent)

### Encoding Standards
- **UTF-8** - Input encoding
- **Base64** - Binary-to-text encoding for output

## Industry Best Practices

### Rendering Engines
1. **wkhtmltopdf** - Qt WebKit based, widely deployed
2. **Chrome Headless** - Modern CSS3/JavaScript support
3. **pdftotext (Poppler)** - Text extraction standard

### Page Dimensions
- **A4**: 210mm x 297mm (ISO 216)
- **Letter**: 8.5in x 11in (ANSI/ASME Y14.1)
- **Legal**: 8.5in x 14in (ANSI)

## Licensing Compliance

| Component | License | Bundled |
|-----------|---------|---------|
| wkhtmltopdf | LGPL v3 | Yes (Windows) |
| Poppler/pdftotext | GPL v2+ | Yes (Windows) |
| Chrome/Edge | Proprietary | No (system) |

## Ecosystem Integration

- Part of SERVICE_API layer in simple_* hierarchy
- Uses: simple_json, simple_uuid, simple_base64
- Used by: simple_service_api, simple_app_api
