# Doc Archiver - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - Single URL capture | 3 days | simple_pdf, simple_hash, simple_sql |
| Phase 2 | Verification & Search | 2 days | Phase 1, simple_datetime |
| Phase 3 | Batch Processing & Export | 2 days | Phase 2, simple_http, simple_json |
| Phase 4 | Production Polish | 3 days | Phase 3, simple_cli |

**Total Estimated Effort:** 10 days

---

## Phase 1: MVP

### Objective

Demonstrate core value proposition: capture a single URL as PDF with metadata storage and hash verification. This proves the integration of simple_pdf, simple_sql, and simple_hash.

### Deliverables

1. **ARCHIVE_RECORD** - Data structure for archive metadata
2. **ARCHIVE_DATABASE** - SQLite storage layer
3. **ARCHIVE_ENGINE** - Core capture logic
4. **Basic CLI** - `capture --url https://example.com`
5. **Hash calculation** - SHA-256 on captured PDF

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create ARCHIVE_RECORD class | Holds all archive metadata with contracts |
| T1.2 | Create ARCHIVE_DATABASE class | Initialize SQLite, create tables |
| T1.3 | Implement database insert | Insert archive record, return ID |
| T1.4 | Create ARCHIVE_ENGINE class | Orchestrate URL -> PDF -> DB flow |
| T1.5 | Integrate simple_pdf capture | Capture URL to PDF file |
| T1.6 | Integrate simple_hash | Calculate SHA-256 of PDF |
| T1.7 | Create basic CLI entry point | Parse --url argument, execute capture |
| T1.8 | Create storage path logic | Organize files by date/domain |
| T1.9 | Integration test: URL to archive | End-to-end capture works |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Single URL | Valid URL | PDF created, DB record inserted |
| Hash recorded | Captured PDF | Correct SHA-256 in database |
| Path structure | Any capture | File at {year}/{month}/{domain}/{file}.pdf |
| Invalid URL | Malformed URL | Error message, no file created |
| Unreachable URL | 404 URL | Error logged, appropriate handling |
| Database query | After capture | Record retrievable by ID |

### Phase 1 ECF

```xml
<target name="doc_archiver_phase1">
    <root class="DOC_ARCHIVER_CLI" feature="make"/>
    <cluster name="src_core" location=".\src\core\"/>
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>
```

---

## Phase 2: Verification & Search

### Objective

Add integrity verification and basic search capabilities. Users can verify archives haven't been modified and find archives by URL or date.

### Deliverables

1. **ARCHIVE_VERIFIER** - Verify file hash matches database
2. **ARCHIVE_SEARCHER** - Query archives by criteria
3. **VERIFICATION_RESULT** - Verification outcome model
4. **verify command** - `verify --all` or `verify --url`
5. **search command** - `search --domain example.com`

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Create ARCHIVE_VERIFIER class | Compare stored hash to file hash |
| T2.2 | Create VERIFICATION_RESULT class | VALID, MODIFIED, MISSING states |
| T2.3 | Add verification_log table | Track all verification events |
| T2.4 | Implement verify command | Check single or all archives |
| T2.5 | Update archive status on verify | Set verification_status field |
| T2.6 | Create ARCHIVE_SEARCHER class | Query by domain, date, URL pattern |
| T2.7 | Implement search command | Full-text search in URLs/notes |
| T2.8 | Add list command | List archives with filters |
| T2.9 | Integrate simple_datetime | Parse date arguments, format output |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Verify valid | Unmodified archive | Status: VALID |
| Verify modified | Manually changed PDF | Status: MODIFIED, hash mismatch shown |
| Verify missing | Deleted PDF file | Status: MISSING |
| Search by domain | `--domain example.com` | All archives from that domain |
| Search by date | `--from 2026-01-01` | Archives since that date |
| Search full-text | `--query "legal"` | Archives with "legal" in URL/notes |

---

## Phase 3: Batch Processing & Export

### Objective

Scale to production usage: process URL lists, validate URLs before capture, export archives for external use.

### Deliverables

1. **URL_PROCESSOR** - URL validation and normalization
2. **ARCHIVE_EXPORTER** - JSON/CSV export
3. **Batch capture** - `capture --file urls.txt`
4. **HTTP metadata** - Capture HTTP headers
5. **Export command** - `export --format json`

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Create URL_PROCESSOR class | Validate, normalize, extract domain |
| T3.2 | Integrate simple_http | HEAD request for validation |
| T3.3 | Store HTTP metadata | Status code, headers, content-type |
| T3.4 | Implement batch capture | Read URL list from file |
| T3.5 | Add progress reporting | Show N/M completed |
| T3.6 | Create ARCHIVE_EXPORTER class | Generate JSON manifest |
| T3.7 | Implement export command | Export metadata as JSON or CSV |
| T3.8 | Add --tag and --note flags | Tag captures for organization |
| T3.9 | Add simple_csv integration | CSV export format |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| URL list | File with 10 URLs | 10 captures with progress |
| Invalid URLs | List with bad URL | Skip invalid, continue with valid |
| HTTP headers | Capture any URL | Headers stored as JSON in DB |
| JSON export | Export command | Valid JSON manifest file |
| CSV export | `--format csv` | CSV file with all fields |
| Tagged capture | `--tag legal` | Tag stored and searchable |

---

## Phase 4: Production Polish

### Objective

Prepare for release: full CLI implementation, configuration file support, statistics, and documentation.

### Deliverables

1. **Full CLI implementation** - All commands with help
2. **ARCHIVE_CONFIG** - Configuration file loading
3. **stats command** - Archive statistics
4. **Error handling hardening** - Graceful failures
5. **Documentation** - README, usage examples

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T4.1 | Create ARCHIVE_CONFIG class | Load/save JSON config |
| T4.2 | Implement config command | Show, set, reset |
| T4.3 | Implement stats command | Total archives, size, domains |
| T4.4 | Add --continue-on-error | Skip failures in batch |
| T4.5 | Add --quiet and --verbose | Appropriate output levels |
| T4.6 | Add --json output format | Machine-readable output |
| T4.7 | Comprehensive --help | All commands documented |
| T4.8 | Error message review | Clear, actionable messages |
| T4.9 | Create README.md | Installation, quick start |
| T4.10 | Create sample URL lists | Example input files |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| --help | `doc-archiver --help` | Full command listing |
| stats | `stats` | Archive count, total size, domains |
| config show | `config show` | Current configuration |
| JSON output | `list --json` | Valid JSON array |
| Quiet mode | --quiet capture | Only errors shown |

---

## ECF Target Structure

```xml
<!-- Library target (reusable core) -->
<target name="doc_archiver_lib">
    <description>Doc Archiver library (no CLI)</description>
    <cluster name="src" location=".\src\" recursive="true">
        <file_rule>
            <exclude>/cli$</exclude>
        </file_rule>
    </cluster>
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_http" location="$SIMPLE_EIFFEL/simple_http/simple_http.ecf"/>
    <library name="simple_sql" location="$SIMPLE_EIFFEL/simple_sql/simple_sql.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>

<!-- CLI executable target -->
<target name="doc_archiver" extends="doc_archiver_lib">
    <description>Doc Archiver CLI application</description>
    <root class="DOC_ARCHIVER_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <cluster name="cli" location=".\src\cli\"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
</target>

<!-- Test target -->
<target name="doc_archiver_tests" extends="doc_archiver_lib">
    <description>Doc Archiver test suite</description>
    <root class="TEST_APP" feature="make"/>
    <cluster name="tests" location=".\tests\" recursive="true"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
</target>
```

---

## Build Commands

```bash
# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config doc_archiver.ecf -target doc_archiver -finalize -c_compile

# Compile for development (workbench mode)
/d/prod/ec.sh -batch -config doc_archiver.ecf -target doc_archiver -c_compile

# Run tests
/d/prod/ec.sh -batch -config doc_archiver.ecf -target doc_archiver_tests -c_compile
./EIFGENs/doc_archiver_tests/W_code/doc_archiver.exe

# Run tests (finalized)
/d/prod/ec.sh -batch -config doc_archiver.ecf -target doc_archiver_tests -finalize -c_compile
./EIFGENs/doc_archiver_tests/F_code/doc_archiver.exe
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles clean | Zero errors, zero warnings | 100% |
| Tests pass | All test cases green | 100% |
| CLI functional | All commands work | 100% |
| Capture rate | Successful captures | >95% |
| Verification | Hash matches on valid files | 100% |
| Search speed | Query response time | <100ms |
| Documentation | README complete | Yes |

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| URL timeout | High | Low | Configurable timeout, retry logic |
| Large PDF files | Medium | Medium | Stream to disk, don't hold in memory |
| SQLite locking | Low | High | Use WAL mode, connection pooling |
| Chrome not available | Medium | Low | Fall back to wkhtmltopdf |
| Complex JS sites | High | Medium | Configurable wait time, Chrome engine |
| Disk space | Medium | High | Check before capture, warn user |
