# 7S-04-SIMPLE-STAR: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## Ecosystem Position

```
FOUNDATION_API (core utilities: json, uuid, base64, validation, etc.)
       |
SERVICE_API (services: jwt, smtp, sql, cors, cache, websocket, pdf)
       |
APP_API (full application stack)
```

simple_pdf belongs to the **SERVICE_API** tier as a document generation service.

## Dependencies

| Library | Purpose | Required |
|---------|---------|----------|
| simple_json | Configuration handling | Yes |
| simple_uuid | Temp file naming | Yes |
| simple_base64 | Binary encoding | Yes |

## Integration Pattern

### Via SERVICE_API
```eiffel
class MY_SERVICE inherit SERVICE_API
feature
    generate_invoice
        local
            pdf: SIMPLE_PDF
        do
            create pdf.make
            doc := pdf.from_html (invoice_html)
            doc.save_to_file ("invoice.pdf")
        end
end
```

### Standalone
```xml
<library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
```

## Ecosystem Conventions Followed

1. **Naming**: `simple_pdf` prefix, `SIMPLE_PDF` main class
2. **Fluent API**: Method chaining for configuration
3. **DBC**: Preconditions, postconditions on all public features
4. **Void Safety**: Fully void-safe implementation
5. **SCOOP Compatible**: No threading issues
6. **Single Entry Point**: `SIMPLE_PDF` facade class
