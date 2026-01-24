# S03-CONTRACTS: simple_pdf

**BACKWASH DOCUMENT** - Generated retroactively from existing implementation
**Date**: 2026-01-23
**Library**: simple_pdf
**Status**: Production

## SIMPLE_PDF Contracts

### make_with_engine
```eiffel
make_with_engine (a_engine: SIMPLE_PDF_ENGINE)
    ensure
        engine_set: engine = a_engine
```

### from_html
```eiffel
from_html (a_html: STRING): SIMPLE_PDF_DOCUMENT
    require
        html_not_empty: not a_html.is_empty
        engine_available: is_available
```

### from_file
```eiffel
from_file (a_path: STRING): SIMPLE_PDF_DOCUMENT
    require
        path_not_empty: not a_path.is_empty
        file_exists: (create {RAW_FILE}.make_with_name (a_path)).exists
        engine_available: is_available
```

### from_url
```eiffel
from_url (a_url: STRING): SIMPLE_PDF_DOCUMENT
    require
        url_not_empty: not a_url.is_empty
        engine_available: is_available
```

### set_orientation
```eiffel
set_orientation (a_orientation: STRING)
    require
        valid_orientation: a_orientation.same_string ("Portrait") or
                          a_orientation.same_string ("Landscape")
```

## SIMPLE_PDF_DOCUMENT Contracts

### make
```eiffel
make (a_content: MANAGED_POINTER; a_size: INTEGER)
    require
        size_positive: a_size > 0
    ensure
        content_set: content = a_content
        size_set: content_size = a_size
        is_valid: is_valid
```

### make_failed
```eiffel
make_failed (a_error: STRING)
    require
        error_not_empty: not a_error.is_empty
    ensure
        not_valid: not is_valid
        error_set: error_message /= Void
```

### save_to_file
```eiffel
save_to_file (a_path: STRING): BOOLEAN
    require
        path_not_empty: not a_path.is_empty
        is_valid: is_valid
        has_content: has_content
```
