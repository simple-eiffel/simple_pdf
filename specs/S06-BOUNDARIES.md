# S06-BOUNDARIES: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## System Boundaries

### External Interfaces

```
+-------------------+
|   SIMPLE_PDF      |
|   (Eiffel API)    |
+--------+----------+
         |
         v
+--------+----------+     +------------------+
| SIMPLE_PDF_ENGINE |---->| wkhtmltopdf.exe  |
| (Process Wrapper) |     +------------------+
+--------+----------+     +------------------+
         |--------------->| msedge.exe       |
         |                +------------------+
         |                +------------------+
         +--------------->| pdftotext.exe    |
                          +------------------+
```

### Input Boundaries

| Input | Source | Validation |
|-------|--------|------------|
| HTML String | Caller | Not empty |
| HTML File Path | Caller | File exists |
| URL | Caller | Not empty |
| Page Size | Caller | Valid size name |
| Orientation | Caller | Portrait/Landscape |
| Margins | Caller | Valid units |

### Output Boundaries

| Output | Target | Format |
|--------|--------|--------|
| PDF Document | Caller | SIMPLE_PDF_DOCUMENT |
| PDF File | File System | Binary PDF |
| Base64 | Caller | STRING |
| Text | Caller | STRING |

## Dependency Boundaries

### Required Libraries
- simple_json - JSON configuration
- simple_uuid - Temp file naming
- simple_base64 - Binary encoding

### Optional System Components
- Chrome/Edge browser (for Chrome engine)
- System fonts (for rendering)

## Trust Boundaries

### Trusted
- Eiffel application code
- Bundled executables (verified)

### Untrusted
- User-provided HTML content
- User-provided URLs
- External websites
