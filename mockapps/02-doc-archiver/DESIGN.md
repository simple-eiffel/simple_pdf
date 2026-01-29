# Doc Archiver - Technical Design

## Architecture

### Component Overview

```
+-----------------------------------------------------------+
|                       Doc Archiver                         |
+-----------------------------------------------------------+
|  CLI Interface Layer                                       |
|    - Argument parsing (simple_cli)                         |
|    - Command routing (capture, verify, search, export)     |
|    - Output formatting (text, json, table)                 |
+-----------------------------------------------------------+
|  Business Logic Layer                                      |
|    - Archive engine (capture orchestration)                |
|    - Verification engine (hash validation)                 |
|    - Search engine (metadata queries)                      |
|    - Scheduler (periodic captures)                         |
+-----------------------------------------------------------+
|  Integrity Layer                                           |
|    - Hash calculation (SHA-256)                            |
|    - Timestamp management (UTC, precision)                 |
|    - Chain of custody (who, when, what)                    |
+-----------------------------------------------------------+
|  Storage Layer                                             |
|    - PDF file storage (organized by date/domain)           |
|    - SQLite metadata database (simple_sql)                 |
|    - Export formats (JSON manifest, CSV report)            |
+-----------------------------------------------------------+
|  Integration Layer                                         |
|    - simple_pdf (URL-to-PDF capture)                       |
|    - simple_http (URL validation, headers)                 |
|    - simple_hash (SHA-256 checksums)                       |
|    - simple_sql (metadata storage)                         |
+-----------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| DOC_ARCHIVER_CLI | Command-line interface | parse_args, route_command, format_output |
| ARCHIVE_ENGINE | Core capture orchestration | capture_url, capture_list, capture_file |
| ARCHIVE_RECORD | Single archive metadata | url, capture_time, hash, path, headers |
| ARCHIVE_DATABASE | SQLite persistence | insert, query, verify, export |
| ARCHIVE_VERIFIER | Integrity checking | verify_hash, verify_exists, verify_readable |
| ARCHIVE_SEARCHER | Query operations | by_url, by_date, by_domain, full_text |
| ARCHIVE_SCHEDULER | Periodic captures | add_schedule, remove_schedule, run_due |
| ARCHIVE_EXPORTER | Output generation | to_json, to_csv, to_manifest |
| ARCHIVE_CONFIG | Configuration | storage_path, database_path, retention |
| URL_PROCESSOR | URL handling | validate, normalize, extract_domain |

### Command Structure

```bash
doc-archiver <command> [options] [arguments]

Commands:
  capture      Archive URL(s) to PDF
  verify       Verify archive integrity
  search       Search archived documents
  list         List archives by criteria
  export       Export archive metadata
  schedule     Manage scheduled captures
  stats        Show archive statistics
  config       Configuration management

Capture Options:
  -u, --url URL          Single URL to capture
  -f, --file FILE        File containing URL list (one per line)
  -o, --output DIR       Output directory for PDFs
  --tag TAG              Add tag to captures
  --note TEXT            Add note to capture record
  --engine ENGINE        PDF engine (wkhtmltopdf, chrome)
  --wait SECONDS         Wait time for JS rendering

Verify Options:
  -a, --all              Verify all archives
  -u, --url URL          Verify specific URL
  --since DATE           Verify archives since date
  --fix                  Attempt to re-capture failed verifications

Search Options:
  -q, --query TEXT       Full-text search in URLs/notes
  -d, --domain DOMAIN    Filter by domain
  --from DATE            Archives from date
  --to DATE              Archives to date
  --tag TAG              Filter by tag

Export Options:
  --format FORMAT        Export format (json, csv, manifest)
  -o, --output FILE      Output file path
  --include-content      Include base64 PDF content

Global Options:
  -c, --config FILE      Configuration file
  -v, --verbose          Verbose output
  -q, --quiet            Suppress non-error output
  --json                 JSON output format
  --version              Show version
  --help                 Show help
```

### Data Flow

```
Input (URL or URL list)
       |
       v
  URL Validation (simple_http)
       |  (check accessible, get headers)
       v
  PDF Capture (simple_pdf)
       |
       v
  Hash Calculation (simple_hash)
       |
       v
  Metadata Assembly
       |  (URL, timestamp, hash, headers, tags)
       v
  Database Insert (simple_sql)
       |
       v
  File Storage (organized path)
       |
       v
  Output (confirmation + record ID)
```

### Database Schema

```sql
-- Archives table
CREATE TABLE archives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    url_normalized TEXT NOT NULL,
    domain TEXT NOT NULL,
    capture_time TEXT NOT NULL,        -- ISO 8601 UTC
    capture_time_unix INTEGER NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    sha256_hash TEXT NOT NULL,
    http_status INTEGER,
    http_headers TEXT,                 -- JSON
    content_type TEXT,
    page_title TEXT,
    tags TEXT,                         -- JSON array
    notes TEXT,
    captured_by TEXT,                  -- Username/system
    engine_used TEXT,
    engine_version TEXT,
    verified_at TEXT,                  -- Last verification time
    verification_status TEXT,          -- VALID, MODIFIED, MISSING
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_url ON archives(url_normalized);
CREATE INDEX idx_domain ON archives(domain);
CREATE INDEX idx_capture_time ON archives(capture_time_unix);
CREATE INDEX idx_hash ON archives(sha256_hash);
CREATE INDEX idx_verification ON archives(verification_status);

-- Schedules table
CREATE TABLE schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    frequency TEXT NOT NULL,           -- daily, weekly, monthly
    next_run TEXT NOT NULL,
    last_run TEXT,
    enabled INTEGER DEFAULT 1,
    tags TEXT,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Verification log
CREATE TABLE verification_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    archive_id INTEGER NOT NULL,
    verified_at TEXT NOT NULL,
    status TEXT NOT NULL,              -- VALID, HASH_MISMATCH, FILE_MISSING
    expected_hash TEXT,
    actual_hash TEXT,
    FOREIGN KEY (archive_id) REFERENCES archives(id)
);
```

### Configuration Schema

```json
{
  "doc_archiver": {
    "storage": {
      "base_path": "./archives",
      "structure": "year/month/domain",
      "filename_format": "{timestamp}_{domain}_{hash_short}.pdf"
    },
    "database": {
      "path": "./archives/metadata.db",
      "backup_enabled": true,
      "backup_frequency": "daily"
    },
    "capture": {
      "default_engine": "wkhtmltopdf",
      "timeout": 30,
      "javascript_wait": 2,
      "page_size": "A4",
      "orientation": "portrait",
      "margins": {
        "top": "10mm",
        "bottom": "10mm",
        "left": "10mm",
        "right": "10mm"
      }
    },
    "integrity": {
      "hash_algorithm": "sha256",
      "verify_on_read": true,
      "verification_schedule": "weekly"
    },
    "retention": {
      "enabled": false,
      "max_age_days": 365,
      "keep_latest_per_url": 5
    },
    "logging": {
      "level": "info",
      "file": "./archives/doc-archiver.log"
    }
  }
}
```

### Archive Manifest Format

```json
{
  "manifest_version": "1.0",
  "generated_at": "2026-01-24T15:30:00Z",
  "generated_by": "Doc Archiver v1.0.0",
  "archive_count": 150,
  "archives": [
    {
      "id": 1,
      "url": "https://example.com/page",
      "capture_time": "2026-01-24T10:15:30Z",
      "file_path": "2026/01/example.com/20260124T101530_example.com_a1b2c3.pdf",
      "file_size": 245678,
      "sha256": "a1b2c3d4e5f6...",
      "http_status": 200,
      "page_title": "Example Page Title",
      "tags": ["legal", "evidence"],
      "verified": true,
      "verified_at": "2026-01-24T14:00:00Z"
    }
  ],
  "verification_summary": {
    "total": 150,
    "valid": 148,
    "modified": 1,
    "missing": 1
  }
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| URL unreachable | Log error, skip | "Warning: URL unreachable: {url} - {reason}" |
| Invalid URL | Reject, log | "Error: Invalid URL format: {url}" |
| PDF generation failed | Log error, retry once | "Error: PDF generation failed: {url} - {reason}" |
| Database error | Abort operation | "Error: Database operation failed: {reason}" |
| Hash mismatch | Flag in database | "Warning: Archive modified: {path} - hash mismatch" |
| File missing | Flag in database | "Error: Archive file missing: {path}" |
| Disk full | Abort with clear message | "Error: Insufficient disk space in {path}" |
| Permission denied | Abort | "Error: Cannot write to {path}: permission denied" |

## GUI/TUI Future Path

**CLI foundation enables:**
- TUI for interactive archive browsing and verification
- Web dashboard for search and management
- Electron app for desktop archive management

**Shared components between CLI/GUI:**
- ARCHIVE_ENGINE works for any interface
- ARCHIVE_DATABASE provides consistent storage
- ARCHIVE_VERIFIER used across all interfaces
- ARCHIVE_SEARCHER powers all search UIs

**What would change for TUI:**
- Add ARCHIVE_TUI_APP using simple_tui
- Interactive URL entry and capture
- Real-time capture progress
- Browse/search results with previews

**What would change for GUI:**
- Add web server using simple_http
- HTML/JS frontend for browser-based UI
- PDF preview embedding
- Drag-and-drop URL capture
