# 7S-01-SCOPE: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Problem Statement

Eiffel applications need to generate PDF documents from HTML content, files, or URLs. No existing Eiffel library provides this capability with multi-engine support and Design by Contract.

## Target Users

1. **Web Application Developers** - Generate PDF reports, invoices, receipts
2. **Document Processing Systems** - Convert HTML templates to PDF
3. **Music Notation Systems** - Generate PDF sheet music (SMuFL support)
4. **Archiving Systems** - Convert web pages to PDF for preservation

## Core Capabilities

1. **HTML-to-PDF Conversion** - Convert HTML strings to PDF documents
2. **File Conversion** - Convert HTML files to PDF
3. **URL Conversion** - Capture web pages as PDF
4. **Multi-Engine Support** - wkhtmltopdf (default) and Chrome/Edge
5. **Page Configuration** - Size, orientation, margins
6. **Text Extraction** - Extract text from existing PDFs (pdftotext)
7. **Base64 Output** - For embedding in web responses

## Out of Scope

- PDF editing or manipulation
- PDF form filling
- PDF signing or encryption
- Direct PDF composition (use HTML intermediate)
- Image-only PDF generation

## Success Criteria

1. Generate valid PDF from HTML in under 5 seconds
2. Support A4, Letter, Legal page sizes
3. Both portrait and landscape orientation
4. Customizable margins (mm, in, cm units)
5. Cross-platform engine detection (Windows, Linux, macOS)
