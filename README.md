<p align="center">
  <img src="docs/images/logo.svg" alt="simple_pdf logo" width="400">
</p>

# simple_pdf

**[Documentation](https://simple-eiffel.github.io/simple_pdf/)** | **[GitHub](https://github.com/simple-eiffel/simple_pdf)**

PDF generation library for Eiffel with multi-engine support. Convert HTML, files, or URLs to PDF with bundled executables.

## Overview

`simple_pdf` provides HTML-to-PDF conversion using multiple rendering engines:

- **wkhtmltopdf** (default) - Qt WebKit based, good compatibility, bundled
- **Chrome/Edge** - Headless browser, best CSS support
- **pdftotext** - Text extraction from existing PDFs (Poppler)

Windows binaries are bundled. Linux and macOS automatically detect system-installed tools.

## Cross-Platform Support

`simple_pdf` automatically detects PDF tools based on your platform:

| Platform | Tool Detection |
|----------|----------------|
| **Windows** | Bundled in `bin/` folder, or Program Files |
| **Linux** | `/usr/bin/`, `/usr/local/bin/`, snap |
| **macOS** | Homebrew (`/opt/homebrew/`, `/usr/local/`), Applications |

### Linux/macOS Installation

Install the required tools via your package manager:

**Ubuntu/Debian:**
```bash
sudo apt install wkhtmltopdf poppler-utils
# Chrome/Chromium optional but recommended for best CSS support
```

**macOS (Homebrew):**
```bash
brew install wkhtmltopdf poppler
```

The library automatically searches common installation paths - no configuration needed.

## API Integration

`simple_pdf` is part of the `simple_*` API hierarchy:

```
FOUNDATION_API (core utilities: json, uuid, base64, validation, etc.)
       ↑
SERVICE_API (services: jwt, smtp, sql, cors, cache, websocket, pdf)
       ↑
APP_API (full application stack)
```

### Using via SERVICE_API or APP_API

If your project uses `simple_service_api` or `simple_app_api`, you automatically have access to `simple_pdf` - no additional ECF entry needed:

```eiffel
class MY_WEB_SERVICE

inherit
    SERVICE_API  -- or APP_API

feature
    generate_report
        local
            pdf: SIMPLE_PDF
            doc: SIMPLE_PDF_DOCUMENT
        do
            create pdf.make
            doc := pdf.from_html (build_report_html)
            if doc.is_valid then
                doc.save_to_file ("report.pdf")
            end
        end
end
```

### Standalone Installation

For projects that only need PDF functionality:

1. Clone the repository
2. Set environment variable (one-time setup for all simple_* libraries): `SIMPLE_EIFFEL=D:\prod`
3. Add to your ECF:

```xml
<library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
```

## Dependencies

| Library | Purpose |
|---------|---------|
| [simple_json](https://github.com/simple-eiffel/simple_json) | JSON support |
| [simple_uuid](https://github.com/simple-eiffel/simple_uuid) | Temp file naming |
| [simple_base64](https://github.com/simple-eiffel/simple_base64) | Base64 encoding |

All dependencies are resolved via `$SIMPLE_EIFFEL`.

## Quick Start

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
do
    -- Generate PDF from HTML
    create pdf.make
    doc := pdf.from_html ("<h1>Hello World</h1>")
    doc.save_to_file ("output.pdf")
end
```

## Fluent API

`simple_pdf` supports a fluent API for concise, chainable configuration:

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
do
    create pdf.make
    doc := pdf.page ("Letter").landscape.margin_all ("1in").from_html (report_html)
    doc.save_to_file ("report.pdf")
end
```

### Fluent API Reference

| Feature | Description |
|---------|-------------|
| `page (size)` | Set page size (A4, Letter, Legal) |
| `portrait` | Set portrait orientation |
| `landscape` | Set landscape orientation |
| `margin_all (margin)` | Set all margins |
| `margin_top/bottom/left/right (margin)` | Set individual margins |
| `margins (top, bottom, left, right)` | Set all four margins at once |
| `with_wkhtmltopdf` | Switch to wkhtmltopdf engine |
| `with_chrome` | Switch to Chrome engine |

### Fluent API Examples

**Basic report with Letter size, landscape:**
```eiffel
create pdf.make
doc := pdf.page ("Letter").landscape.from_html (report_html)
doc.save_to_file ("report.pdf")
```

**Website capture with custom margins:**
```eiffel
create pdf.make
doc := pdf.page ("A4").portrait.margin_all ("15mm").from_url ("https://example.com")
```

**Using Chrome for complex CSS:**
```eiffel
create pdf.make
doc := pdf.with_chrome.page ("Letter").margins ("1in", "1in", "0.75in", "0.75in").from_html (styled_html)
```

**Document with different top/bottom margins:**
```eiffel
create pdf.make
doc := pdf.page ("A4").margin_top ("30mm").margin_bottom ("20mm").margin_left ("25mm").margin_right ("25mm").from_file ("template.html")
```

**Quick A4 portrait (defaults):**
```eiffel
create pdf.make
doc := pdf.from_html ("<h1>Simple PDF</h1>")  -- Uses A4 portrait by default
```

### Comparison

**Traditional (5 lines):**
```eiffel
create pdf.make
pdf.set_page_size ("Letter")
pdf.set_orientation ("Landscape")
pdf.set_margin_top ("25mm")
pdf.set_margin_bottom ("25mm")
doc := pdf.from_url ("https://example.com")
```

**Fluent (2 lines):**
```eiffel
create pdf.make
doc := pdf.page ("Letter").landscape.margins ("25mm", "25mm", "20mm", "20mm").from_url ("https://example.com")
```

## Converting HTML to PDF

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
    html: STRING
do
    create pdf.make

    html := "[
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: Arial; margin: 40px; }
                h1 { color: #333; }
            </style>
        </head>
        <body>
            <h1>My Report</h1>
            <p>Generated by simple_pdf</p>
        </body>
        </html>
    ]"

    doc := pdf.from_html (html)
    if doc.is_valid then
        doc.save_to_file ("report.pdf")
    end
end
```

## Converting URLs to PDF

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
do
    create pdf.make
    pdf.set_page_size ("Letter")
    pdf.set_orientation ("Landscape")

    doc := pdf.from_url ("https://example.com")
    if doc.is_valid then
        doc.save_to_file ("website.pdf")
    end
end
```

## Using Chrome for Best CSS Support

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
do
    -- Chrome/Edge provides best CSS rendering
    create pdf.make_with_engine (create {SIMPLE_PDF_CHROME})

    doc := pdf.from_html (complex_css_html)
    doc.save_to_file ("styled.pdf")
end
```

## Extracting Text from PDFs

```eiffel
local
    reader: SIMPLE_PDF_READER
    text: STRING
do
    create reader.make
    if reader.is_available then
        text := reader.extract_text ("document.pdf")
        print (text)

        -- Or extract specific pages
        text := reader.extract_page ("document.pdf", 1)
        text := reader.extract_pages ("document.pdf", 1, 5)
    end
end
```

## Checking Engine Availability

```eiffel
local
    engines: SIMPLE_PDF_ENGINES
do
    create engines
    print (engines.report)

    -- Output:
    -- PDF Engine Availability Report
    -- =============================
    -- wkhtmltopdf: AVAILABLE (D:\prod\simple_pdf/bin/wkhtmltopdf.exe)
    -- Chrome/Edge: AVAILABLE (C:/Program Files/Microsoft/Edge/Application/msedge.exe)
    -- Default engine: wkhtmltopdf
end
```

## Page Settings

```eiffel
local
    pdf: SIMPLE_PDF
do
    create pdf.make

    -- Page size: A4, Letter, Legal, etc.
    pdf.set_page_size ("A4")

    -- Orientation
    pdf.set_orientation ("Portrait")  -- or "Landscape"

    -- Margins (supports mm, in, cm)
    pdf.set_margins ("10mm")                 -- All margins
    pdf.set_margin_top ("25mm")
    pdf.set_margin_bottom ("25mm")
    pdf.set_margin_left ("20mm")
    pdf.set_margin_right ("20mm")
end
```

## Working with PDF Documents

```eiffel
local
    pdf: SIMPLE_PDF
    doc: SIMPLE_PDF_DOCUMENT
do
    create pdf.make
    doc := pdf.from_html ("<h1>Test</h1>")

    if doc.is_valid then
        -- Save to file
        doc.save_to_file ("output.pdf")

        -- Get raw bytes
        if attached doc.content as bytes then
            -- Use bytes directly
        end

        -- Get as base64 (for embedding)
        print (doc.as_base64)
    else
        -- Handle error
        if attached doc.error_message as err then
            print ("Error: " + err)
        end
    end
end
```

## Engine Switching

```eiffel
local
    pdf: SIMPLE_PDF
do
    create pdf.make  -- Uses wkhtmltopdf by default

    -- Switch to Chrome
    pdf.use_chrome

    -- Switch back to wkhtmltopdf
    pdf.use_wkhtmltopdf
end
```

## Architecture

```
SIMPLE_PDF_ENGINE (deferred)
    |-- SIMPLE_PDF_WKHTMLTOPDF (default)
    |-- SIMPLE_PDF_CHROME

SIMPLE_PDF (main API - delegates to engine)
SIMPLE_PDF_DOCUMENT (result object)
SIMPLE_PDF_READER (text extraction)
SIMPLE_PDF_ENGINES (availability reporter)
```

## Bundled Binaries

The `bin/` folder contains Windows executables (total ~142MB):

| Binary | Version | Size | Purpose |
|--------|---------|------|---------|
| wkhtmltopdf.exe | 0.12.6 | ~40MB | PDF generation |
| wkhtmltox.dll | 0.12.6 | ~40MB | wkhtmltopdf library |
| pdftotext.exe | 24.08.0 | ~57KB | Text extraction |
| Poppler DLLs | 24.08.0 | ~22MB | pdftotext dependencies |

### Binary Sources

| Component | Source | License | Download |
|-----------|--------|---------|----------|
| wkhtmltopdf | [wkhtmltopdf.org](https://wkhtmltopdf.org/) | LGPL v3 | [GitHub Releases](https://github.com/wkhtmltopdf/packaging/releases) |
| Poppler (pdftotext) | [freedesktop.org](https://poppler.freedesktop.org/) | GPL v2+ | [poppler-windows](https://github.com/oschwartz10612/poppler-windows/releases) |

### Updating Binaries

**wkhtmltopdf:**
1. Download latest from [wkhtmltopdf releases](https://github.com/wkhtmltopdf/packaging/releases)
2. Extract `wkhtmltopdf.exe`, `wkhtmltox.dll`, `wkhtmltoimage.exe`
3. Replace files in `bin/`

**Poppler (pdftotext):**
1. Download latest from [poppler-windows releases](https://github.com/oschwartz10612/poppler-windows/releases)
2. Extract the `Library/bin/` contents
3. Replace `pdftotext.exe` and DLLs in `bin/`

**Note:** wkhtmltopdf 0.12.6 (2020) is the final release. The project is no longer actively maintained but remains stable and widely used.

## API Summary

### Creation
- `make` - Create with default wkhtmltopdf engine
- `make_with_engine (engine)` - Create with specific engine

### Conversion
- `from_html (html): SIMPLE_PDF_DOCUMENT` - Convert HTML string
- `from_file (path): SIMPLE_PDF_DOCUMENT` - Convert HTML file
- `from_url (url): SIMPLE_PDF_DOCUMENT` - Convert URL

### Settings
- `set_page_size (size)` - A4, Letter, Legal, etc.
- `set_orientation (orientation)` - Portrait or Landscape
- `set_margins (margin)` - All margins at once
- `set_margin_top/bottom/left/right (margin)` - Individual margins

### Engine Management
- `is_available: BOOLEAN` - Check if engine is ready
- `use_wkhtmltopdf` - Switch to wkhtmltopdf
- `use_chrome` - Switch to Chrome/Edge

### Text Extraction (SIMPLE_PDF_READER)
- `extract_text (path): STRING` - Full document
- `extract_page (path, page): STRING` - Single page
- `extract_pages (path, first, last): STRING` - Page range
- `extract_text_raw (path): STRING` - Without layout preservation

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
