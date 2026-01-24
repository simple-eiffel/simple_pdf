# 7S-05-SECURITY: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Threat Model

### Assets
1. Input HTML content (may contain sensitive data)
2. Generated PDF documents
3. Temporary files during conversion
4. User's file system

### Threat Actors
1. Malicious HTML content
2. Compromised URLs
3. Local attackers with file access

## Security Considerations

### Input Validation
- HTML content is passed to external tools as-is
- URLs are fetched by external tools
- File paths validated for existence

### Temporary File Handling
- Temp files created with UUID names (unpredictable)
- Temp files should be cleaned up after use
- Located in system temp directory

### External Process Execution
- wkhtmltopdf and Chrome executed via command line
- Arguments constructed from user input (paths, URLs)
- **Risk**: Command injection via malicious filenames
- **Mitigation**: Proper quoting in command construction

## Recommendations

1. Sanitize HTML input if from untrusted sources
2. Validate URLs before fetching
3. Use absolute paths to bundled executables
4. Clean up temporary files promptly
5. Run with least-privilege permissions

## Out of Scope
- PDF encryption (not supported)
- Digital signatures (not supported)
- Access control on generated files (OS level)
