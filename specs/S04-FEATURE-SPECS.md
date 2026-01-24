# S04-FEATURE-SPECS: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## SIMPLE_PDF Features

### Creation
| Feature | Signature | Description |
|---------|-----------|-------------|
| make | `make` | Create with default wkhtmltopdf engine |
| make_with_engine | `make_with_engine (a_engine: SIMPLE_PDF_ENGINE)` | Create with specific engine |

### Conversion
| Feature | Signature | Description |
|---------|-----------|-------------|
| from_html | `from_html (a_html: STRING): SIMPLE_PDF_DOCUMENT` | Convert HTML string to PDF |
| from_file | `from_file (a_path: STRING): SIMPLE_PDF_DOCUMENT` | Convert HTML file to PDF |
| from_url | `from_url (a_url: STRING): SIMPLE_PDF_DOCUMENT` | Convert URL to PDF |

### Settings
| Feature | Signature | Description |
|---------|-----------|-------------|
| set_page_size | `set_page_size (a_size: STRING)` | Set page size (A4, Letter, etc.) |
| set_orientation | `set_orientation (a_orientation: STRING)` | Set Portrait or Landscape |
| set_margins | `set_margins (a_margin: STRING)` | Set all margins |
| set_margin_top | `set_margin_top (a_margin: STRING)` | Set top margin |
| set_margin_bottom | `set_margin_bottom (a_margin: STRING)` | Set bottom margin |
| set_margin_left | `set_margin_left (a_margin: STRING)` | Set left margin |
| set_margin_right | `set_margin_right (a_margin: STRING)` | Set right margin |

### Engine Management
| Feature | Signature | Description |
|---------|-----------|-------------|
| is_available | `is_available: BOOLEAN` | Check if engine is ready |
| use_wkhtmltopdf | `use_wkhtmltopdf` | Switch to wkhtmltopdf |
| use_chrome | `use_chrome` | Switch to Chrome/Edge |

### Fluent API
| Feature | Signature | Description |
|---------|-----------|-------------|
| page | `page (a_size: STRING): like Current` | Set page size, return self |
| portrait | `portrait: like Current` | Set portrait, return self |
| landscape | `landscape: like Current` | Set landscape, return self |
| margin_all | `margin_all (a_margin: STRING): like Current` | Set all margins, return self |
| with_wkhtmltopdf | `with_wkhtmltopdf: like Current` | Use wkhtmltopdf, return self |
| with_chrome | `with_chrome: like Current` | Use Chrome, return self |

## SIMPLE_PDF_DOCUMENT Features

### Access
| Feature | Signature | Description |
|---------|-----------|-------------|
| content | `content: detachable MANAGED_POINTER` | Binary PDF content |
| content_size | `content_size: INTEGER` | Size in bytes |
| is_valid | `is_valid: BOOLEAN` | Generation success |
| error_message | `error_message: detachable STRING` | Error if failed |

### Output
| Feature | Signature | Description |
|---------|-----------|-------------|
| save_to_file | `save_to_file (a_path: STRING): BOOLEAN` | Save PDF to file |
| as_base64 | `as_base64: STRING` | Get as Base64 string |
