# S07-SPEC-SUMMARY: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Executive Summary

simple_pdf provides HTML-to-PDF conversion for Eiffel applications through a multi-engine architecture supporting wkhtmltopdf and Chrome/Edge.

## Key Specifications

### Architecture
- **Pattern**: Facade with Strategy (engine selection)
- **Main Class**: SIMPLE_PDF
- **Engine Base**: SIMPLE_PDF_ENGINE (deferred)
- **Result Container**: SIMPLE_PDF_DOCUMENT

### API Design
- **Fluent API**: Method chaining for configuration
- **Engine Agnostic**: Same API for all engines
- **Error Handling**: is_valid/error_message pattern

### Features
1. HTML string to PDF
2. HTML file to PDF
3. URL to PDF
4. Page configuration (size, orientation, margins)
5. Engine switching (wkhtmltopdf, Chrome)
6. Text extraction from existing PDFs
7. Base64 output for web embedding

### Dependencies
- simple_json (configuration)
- simple_uuid (temp file naming)
- simple_base64 (binary encoding)

### Platform Support
- Windows: Full (bundled executables)
- Linux: Requires package installation
- macOS: Requires Homebrew installation

## Contract Highlights

- Engine must be available before conversion
- HTML/file/URL must not be empty
- Valid orientations: Portrait, Landscape
- Document validity indicates success/failure

## Performance Targets

| Operation | Target |
|-----------|--------|
| Simple HTML | <2 seconds |
| Complex HTML | <5 seconds |
| URL capture | <10 seconds |
