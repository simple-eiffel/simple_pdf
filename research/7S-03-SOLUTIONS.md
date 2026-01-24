# 7S-03-SOLUTIONS: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Alternative Solutions Considered

### 1. Native PDF Library (Rejected)
- **Approach**: Write PDF binary format directly
- **Pros**: No external dependencies
- **Cons**: Complex (PDF spec is huge), poor CSS support
- **Decision**: Rejected - leverage existing tools

### 2. Java Bridge (Rejected)
- **Approach**: Use iText or Apache PDFBox via JNI
- **Pros**: Feature-rich PDF manipulation
- **Cons**: JVM dependency, complex integration
- **Decision**: Rejected - too heavy for Eiffel ecosystem

### 3. External Tool Wrapper (Chosen)
- **Approach**: Wrap wkhtmltopdf and Chrome CLI
- **Pros**: Proven tools, good HTML/CSS support, cross-platform
- **Cons**: External executables required
- **Decision**: Selected - best balance of features and complexity

### 4. LibHaru (Considered)
- **Approach**: Wrap libharu C library
- **Pros**: Pure C, no external processes
- **Cons**: Limited HTML support, low-level API
- **Decision**: Deferred - may add later for direct PDF creation

## Architecture Decision

Multi-engine strategy with deferred base class:
- `SIMPLE_PDF_ENGINE` (deferred) - Abstract engine interface
- `SIMPLE_PDF_WKHTMLTOPDF` - Default engine, bundled
- `SIMPLE_PDF_CHROME` - Chrome/Edge engine, system-installed

This allows:
1. User choice of rendering engine
2. Fallback if one engine unavailable
3. Future engines without API changes
