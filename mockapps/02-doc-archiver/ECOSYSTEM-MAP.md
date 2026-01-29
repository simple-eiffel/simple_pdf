# Doc Archiver - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_pdf | URL-to-PDF capture | ARCHIVE_ENGINE.capture_url |
| simple_http | URL validation, HTTP headers | URL_PROCESSOR.validate, get_headers |
| simple_sql | Metadata database (SQLite) | ARCHIVE_DATABASE.* |
| simple_hash | SHA-256 integrity checksums | ARCHIVE_VERIFIER.calculate_hash |
| simple_datetime | Timestamp management | ARCHIVE_RECORD.capture_time |
| simple_json | Manifest export, config | ARCHIVE_EXPORTER.to_json |
| simple_cli | Command-line interface | DOC_ARCHIVER_CLI.make |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_scheduler | Periodic capture scheduling | schedule command enabled |
| simple_smtp | Email notifications | Alert on verification failures |
| simple_file | File system operations | Large archive management |
| simple_compression | Archive compression | --compress flag enabled |
| simple_regex | URL pattern matching | Wildcard URL lists |
| simple_csv | CSV export format | --format csv |

## Integration Patterns

### simple_pdf Integration

**Purpose:** Capture URLs as PDF documents

**Usage:**
```eiffel
feature -- PDF Capture

    capture_url_to_pdf (a_url: STRING; a_output_path: STRING): BOOLEAN
            -- Capture URL as PDF, return success status
        local
            l_pdf: SIMPLE_PDF
            l_doc: SIMPLE_PDF_DOCUMENT
        do
            create l_pdf.make

            -- Apply archive-optimized settings
            l_pdf.set_page_size (config.page_size)
            l_pdf.set_orientation (config.orientation)
            l_pdf.set_margin_top (config.margin_top)
            l_pdf.set_margin_bottom (config.margin_bottom)
            l_pdf.set_margin_left (config.margin_left)
            l_pdf.set_margin_right (config.margin_right)

            -- Use Chrome for better JS rendering if available
            if config.use_chrome and chrome_available then
                l_pdf.use_chrome
            end

            -- Capture the URL
            l_doc := l_pdf.from_url (a_url)

            if l_doc.is_valid then
                Result := l_doc.save_to_file (a_output_path)
                if Result then
                    last_capture_size := l_doc.content_size
                end
            else
                last_error := l_doc.error_message
                Result := False
            end
        end
```

**Data flow:** URL -> simple_pdf.from_url -> SIMPLE_PDF_DOCUMENT -> file

### simple_http Integration

**Purpose:** Validate URLs and capture HTTP metadata

**Usage:**
```eiffel
feature -- URL Processing

    validate_and_get_metadata (a_url: STRING): TUPLE [valid: BOOLEAN; status: INTEGER; headers: STRING; content_type: STRING]
            -- Validate URL and get HTTP metadata
        local
            l_http: SIMPLE_HTTP
            l_response: SIMPLE_HTTP_RESPONSE
        do
            create l_http.make

            -- HEAD request to validate without downloading
            l_response := l_http.head (a_url)

            if l_response.is_success then
                Result := [True, l_response.status_code,
                          l_response.headers_as_json,
                          l_response.content_type]
            else
                Result := [False, l_response.status_code, "", ""]
                last_error := "HTTP " + l_response.status_code.out + ": " + l_response.status_message
            end
        end

    normalize_url (a_url: STRING): STRING
            -- Normalize URL for consistent storage
        local
            l_http: SIMPLE_HTTP
        do
            create l_http.make
            Result := l_http.normalize_url (a_url)
            -- Removes trailing slashes, lowercases domain, etc.
        end

    extract_domain (a_url: STRING): STRING
            -- Extract domain from URL
        local
            l_http: SIMPLE_HTTP
        do
            create l_http.make
            Result := l_http.parse_url (a_url).host
        end
```

**Data flow:** URL -> simple_http.head -> validation + metadata

### simple_sql Integration

**Purpose:** Persistent metadata storage in SQLite

**Usage:**
```eiffel
feature -- Database Operations

    insert_archive (a_record: ARCHIVE_RECORD): INTEGER
            -- Insert archive record, return ID
        local
            l_sql: SIMPLE_SQL
            l_stmt: SIMPLE_SQL_STATEMENT
        do
            l_sql := database_connection

            l_stmt := l_sql.prepare ("[
                INSERT INTO archives
                (url, url_normalized, domain, capture_time, capture_time_unix,
                 file_path, file_size, sha256_hash, http_status, http_headers,
                 content_type, page_title, tags, notes, captured_by,
                 engine_used, engine_version)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]")

            l_stmt.bind_text (1, a_record.url)
            l_stmt.bind_text (2, a_record.url_normalized)
            l_stmt.bind_text (3, a_record.domain)
            l_stmt.bind_text (4, a_record.capture_time_iso)
            l_stmt.bind_integer (5, a_record.capture_time_unix)
            l_stmt.bind_text (6, a_record.file_path)
            l_stmt.bind_integer (7, a_record.file_size)
            l_stmt.bind_text (8, a_record.sha256_hash)
            l_stmt.bind_integer (9, a_record.http_status)
            l_stmt.bind_text (10, a_record.http_headers_json)
            l_stmt.bind_text (11, a_record.content_type)
            l_stmt.bind_text (12, a_record.page_title)
            l_stmt.bind_text (13, a_record.tags_json)
            l_stmt.bind_text (14, a_record.notes)
            l_stmt.bind_text (15, a_record.captured_by)
            l_stmt.bind_text (16, a_record.engine_used)
            l_stmt.bind_text (17, a_record.engine_version)

            l_stmt.execute
            Result := l_sql.last_insert_rowid
        end

    query_by_domain (a_domain: STRING; a_limit: INTEGER): ARRAYED_LIST [ARCHIVE_RECORD]
            -- Query archives by domain
        local
            l_sql: SIMPLE_SQL
            l_stmt: SIMPLE_SQL_STATEMENT
        do
            create Result.make (a_limit)
            l_sql := database_connection

            l_stmt := l_sql.prepare ("[
                SELECT * FROM archives
                WHERE domain = ?
                ORDER BY capture_time_unix DESC
                LIMIT ?
            ]")
            l_stmt.bind_text (1, a_domain)
            l_stmt.bind_integer (2, a_limit)

            from l_stmt.start until l_stmt.after loop
                Result.extend (row_to_record (l_stmt.current_row))
                l_stmt.forth
            end
        end
```

**Data flow:** ARCHIVE_RECORD -> simple_sql -> SQLite database

### simple_hash Integration

**Purpose:** Calculate and verify SHA-256 checksums

**Usage:**
```eiffel
feature -- Integrity

    calculate_file_hash (a_path: STRING): STRING
            -- Calculate SHA-256 hash of file
        local
            l_hash: SIMPLE_HASH
            l_file: RAW_FILE
            l_content: MANAGED_POINTER
        do
            create l_hash.make
            create l_file.make_open_read (a_path)

            create l_content.make (l_file.count)
            l_file.read_to_managed_pointer (l_content, 0, l_file.count)
            l_file.close

            Result := l_hash.sha256_hex (pointer_to_string (l_content.item, l_file.count))
        end

    verify_archive (a_record: ARCHIVE_RECORD): VERIFICATION_RESULT
            -- Verify archive integrity
        local
            l_file: RAW_FILE
            l_actual_hash: STRING
        do
            create l_file.make_with_name (a_record.file_path)

            if not l_file.exists then
                create Result.make_missing (a_record.id)
            else
                l_actual_hash := calculate_file_hash (a_record.file_path)

                if l_actual_hash.same_string (a_record.sha256_hash) then
                    create Result.make_valid (a_record.id)
                else
                    create Result.make_modified (a_record.id, a_record.sha256_hash, l_actual_hash)
                end
            end

            log_verification (a_record.id, Result)
        end
```

**Data flow:** File path -> simple_hash.sha256_hex -> hash string -> compare

### simple_datetime Integration

**Purpose:** Precise timestamp management

**Usage:**
```eiffel
feature -- Timestamps

    current_capture_time: ARCHIVE_TIMESTAMP
            -- Get current time for capture record
        local
            l_datetime: SIMPLE_DATETIME
        do
            create l_datetime.make_now_utc

            create Result.make (
                l_datetime.to_iso8601,      -- "2026-01-24T15:30:00Z"
                l_datetime.to_unix_timestamp -- 1737732600
            )
        end

    parse_date_argument (a_date: STRING): SIMPLE_DATETIME
            -- Parse user-provided date argument
        local
            l_parser: SIMPLE_DATETIME_PARSER
        do
            create l_parser.make
            Result := l_parser.parse (a_date)

            if not Result.is_valid then
                last_error := "Invalid date format: " + a_date + " (expected: YYYY-MM-DD)"
            end
        end
```

**Data flow:** Current time -> simple_datetime -> ISO + Unix formats

### simple_cli Integration

**Purpose:** Command-line argument parsing and execution

**Usage:**
```eiffel
class DOC_ARCHIVER_CLI

inherit
    SIMPLE_CLI_APPLICATION

create
    make

feature {NONE} -- Initialization

    make
        do
            create cli.make ("doc-archiver", "Enterprise web archiving tool")

            -- Add commands
            cli.add_command (create {CAPTURE_COMMAND}.make)
            cli.add_command (create {VERIFY_COMMAND}.make)
            cli.add_command (create {SEARCH_COMMAND}.make)
            cli.add_command (create {LIST_COMMAND}.make)
            cli.add_command (create {EXPORT_COMMAND}.make)
            cli.add_command (create {SCHEDULE_COMMAND}.make)
            cli.add_command (create {STATS_COMMAND}.make)
            cli.add_command (create {CONFIG_COMMAND}.make)

            -- Global options
            cli.add_option (create {FILE_OPTION}.make ("config", "c", "Configuration file"))
            cli.add_flag ("verbose", "v", "Verbose output")
            cli.add_flag ("quiet", "q", "Suppress non-error output")
            cli.add_flag ("json", Void, "JSON output format")

            -- Run
            cli.execute (arguments)
        end
```

**Data flow:** Command-line args -> SIMPLE_CLI -> command routing

## Dependency Graph

```
doc_archiver
    |
    +-- simple_pdf (required)
    |   +-- simple_json
    |   +-- simple_uuid
    |   +-- simple_base64
    |   +-- simple_process
    |
    +-- simple_http (required)
    |   +-- simple_json
    |
    +-- simple_sql (required)
    |   +-- SQLite3 (C library)
    |
    +-- simple_hash (required)
    |
    +-- simple_datetime (required)
    |
    +-- simple_json (required)
    |
    +-- simple_cli (required)
    |   +-- simple_json
    |
    +-- simple_scheduler (optional)
    |   +-- simple_datetime
    |
    +-- simple_smtp (optional)
    |   +-- simple_json
    |
    +-- simple_compression (optional)
    |
    +-- simple_csv (optional)
    |
    +-- ISE base (required)
```

## ECF Configuration

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-22-0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-22-0
                            http://www.eiffel.com/developers/xml/configuration-1-22-0.xsd"
        name="doc_archiver"
        uuid="550E8400-E29B-41D4-A716-446655440002">

    <target name="doc_archiver">
        <description>Doc Archiver - Enterprise web archiving tool</description>
        <root class="DOC_ARCHIVER_CLI" feature="make"/>

        <option warning="warning" syntax="standard" manifest_array_type="mismatch_warning">
            <assertions precondition="true" postcondition="true"
                       check="true" invariant="true"/>
        </option>

        <setting name="console_application" value="true"/>
        <setting name="dead_code_removal" value="all"/>

        <capability>
            <concurrency support="none"/>
            <void_safety support="all"/>
        </capability>

        <!-- Source clusters -->
        <cluster name="src" location=".\src\" recursive="true"/>

        <!-- Required simple_* libraries -->
        <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
        <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
        <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
        <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <target name="doc_archiver_tests" extends="doc_archiver">
        <description>Doc Archiver test suite</description>
        <root class="TEST_APP" feature="make"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```
