# Report Engine - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - Basic report with table | 3 days | simple_pdf, simple_json, simple_template |
| Phase 2 | Chart Integration | 3 days | Phase 1, simple_chart |
| Phase 3 | Multiple Data Sources & Formatting | 2 days | Phase 2, simple_csv, simple_decimal |
| Phase 4 | Production Polish | 2 days | Phase 3, simple_cli |

**Total Estimated Effort:** 10 days

---

## Phase 1: MVP

### Objective

Demonstrate core value proposition: generate a PDF report from JSON data using an HTML template with table rendering. This proves the integration of simple_pdf with simple_template and data binding.

### Deliverables

1. **REPORT_MODEL** - Report structure definition
2. **DATA_CONTEXT** - Data container for template binding
3. **DATA_TABLE** - Tabular data structure
4. **TABLE_BUILDER** - Generate HTML tables from data
5. **REPORT_TEMPLATE_MANAGER** - Template loading and rendering
6. **REPORT_ENGINE** - Core orchestration
7. **Basic CLI** - `generate --data data.json --template report.html --output report.pdf`

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create REPORT_MODEL class | Holds report structure with contracts |
| T1.2 | Create DATA_CONTEXT class | Container for template bindings |
| T1.3 | Create DATA_TABLE class | Rows, columns, headers |
| T1.4 | Create TABLE_BUILDER class | Generate HTML table from DATA_TABLE |
| T1.5 | Create REPORT_TEMPLATE_MANAGER | Load and cache templates |
| T1.6 | Integrate simple_template | Bind DATA_CONTEXT to template |
| T1.7 | Create REPORT_ENGINE class | Orchestrate data -> HTML -> PDF |
| T1.8 | Create basic CLI entry point | Parse arguments, execute generate |
| T1.9 | Create default report template | Professional report layout |
| T1.10 | Integration test: JSON to PDF report | End-to-end works |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Basic report | JSON with table data | PDF with formatted table |
| Multiple tables | JSON with 3 data arrays | PDF with 3 tables |
| Empty data | JSON with empty array | PDF with "No data" message |
| Missing binding | Template references missing data | Warning logged, graceful handling |
| Invalid JSON | Malformed JSON file | Error message, no PDF created |
| Template not found | Invalid template path | Error message, no PDF created |

### Phase 1 ECF

```xml
<target name="report_engine_phase1">
    <root class="REPORT_ENGINE_CLI" feature="make"/>
    <cluster name="src_core" location=".\src\core\"/>
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>
```

---

## Phase 2: Chart Integration

### Objective

Add data visualization: embed SVG charts in reports. This showcases simple_chart integration and positions Report Engine as a full BI tool alternative.

### Deliverables

1. **CHART_BUILDER** - Chart generation facade
2. **CHART_CONFIG** - Chart configuration model
3. **Bar chart support** - Categorical data visualization
4. **Line chart support** - Time series visualization
5. **Pie chart support** - Proportion visualization
6. **Chart embedding** - SVG in HTML template

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Create CHART_BUILDER class | Facade for chart generation |
| T2.2 | Create CHART_CONFIG class | Width, height, colors, title |
| T2.3 | Implement bar chart generation | Data -> SVG bar chart |
| T2.4 | Implement line chart generation | Series data -> SVG line chart |
| T2.5 | Implement pie chart generation | Proportion data -> SVG pie chart |
| T2.6 | Create chart template syntax | `{{chart:bar:sales_by_region}}` |
| T2.7 | Embed SVG in rendered HTML | Charts appear in PDF |
| T2.8 | Add chart configuration in JSON | Customize chart appearance |
| T2.9 | Create sample report with charts | Demonstrate all chart types |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Bar chart | 5 categories with values | SVG bar chart in PDF |
| Line chart | Time series data | SVG line chart in PDF |
| Pie chart | Proportion data | SVG pie chart in PDF |
| Multiple charts | 3 different charts | All rendered correctly |
| Chart colors | Custom color palette | Colors applied correctly |
| Chart sizing | Width/height config | Chart sized correctly |

---

## Phase 3: Multiple Data Sources & Formatting

### Objective

Add CSV support, value formatting (currency, dates, percentages), and calculated fields. Makes Report Engine practical for real business data.

### Deliverables

1. **DATA_SOURCE_CSV** - CSV file loading
2. **REPORT_FORMATTER** - Number, date, currency formatting
3. **CALCULATION_ENGINE** - SUM, AVG, COUNT on data
4. **Data filtering** - Filter data before rendering
5. **Format specifiers** - `{{amount:currency}}`, `{{date:date}}`

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Create DATA_SOURCE_CSV class | Load CSV into DATA_TABLE |
| T3.2 | Integrate simple_csv | Parse CSV with headers |
| T3.3 | Create REPORT_FORMATTER class | Format numbers, dates, currencies |
| T3.4 | Integrate simple_decimal | Precise numeric formatting |
| T3.5 | Add format specifiers to template | `{{field:format}}` syntax |
| T3.6 | Create CALCULATION_ENGINE class | Aggregate functions on data |
| T3.7 | Add calculated fields to config | Define formulas in JSON config |
| T3.8 | Add data filtering | Filter before render |
| T3.9 | Support multiple data sources | Combine JSON and CSV in one report |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| CSV data | CSV file with headers | Data loaded correctly |
| Currency format | 1234.56 with USD | $1,234.56 in PDF |
| Date format | 2026-01-24 | Jan 24, 2026 in PDF |
| Percentage | 0.1234 | 12.34% in PDF |
| SUM calculation | Array of amounts | Correct sum displayed |
| Data filtering | Filter by region | Only matching rows shown |

---

## Phase 4: Production Polish

### Objective

Prepare for release: full CLI, configuration file support, validation, and documentation.

### Deliverables

1. **Full CLI implementation** - All commands with help
2. **REPORT_CONFIG** - Configuration file loading
3. **validate command** - Check template and data compatibility
4. **schema command** - Show expected data structure
5. **Documentation** - README, examples, template guide

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T4.1 | Create REPORT_CONFIG class | Load/save JSON config |
| T4.2 | Implement validate command | Check template variables vs data |
| T4.3 | Implement schema command | Generate expected JSON structure |
| T4.4 | Implement template list command | Show available templates |
| T4.5 | Add --format and --orientation | Page configuration |
| T4.6 | Add --title and --subtitle | Override report metadata |
| T4.7 | Comprehensive --help | All commands documented |
| T4.8 | Error message review | Clear, actionable messages |
| T4.9 | Create README.md | Installation, quick start |
| T4.10 | Create template guide | How to customize templates |
| T4.11 | Create sample reports | Sales report, dashboard, analytics |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| --help | `report-engine --help` | Full command listing |
| validate | Valid template + data | Validation passes |
| validate | Mismatched template | Errors listed |
| schema | Template file | Expected JSON structure |
| Config file | --config report.json | Settings applied |
| Title override | --title "Custom Title" | Title in PDF |

---

## ECF Target Structure

```xml
<!-- Library target (reusable core) -->
<target name="report_engine_lib">
    <description>Report Engine library (no CLI)</description>
    <cluster name="src" location=".\src\" recursive="true">
        <file_rule>
            <exclude>/cli$</exclude>
        </file_rule>
    </cluster>
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_chart" location="$SIMPLE_EIFFEL/simple_chart/simple_chart.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
    <library name="simple_decimal" location="$SIMPLE_EIFFEL/simple_decimal/simple_decimal.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>

<!-- CLI executable target -->
<target name="report_engine" extends="report_engine_lib">
    <description>Report Engine CLI application</description>
    <root class="REPORT_ENGINE_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <cluster name="cli" location=".\src\cli\"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
</target>

<!-- Test target -->
<target name="report_engine_tests" extends="report_engine_lib">
    <description>Report Engine test suite</description>
    <root class="TEST_APP" feature="make"/>
    <cluster name="tests" location=".\tests\" recursive="true"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
</target>
```

---

## Build Commands

```bash
# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config report_engine.ecf -target report_engine -finalize -c_compile

# Compile for development (workbench mode)
/d/prod/ec.sh -batch -config report_engine.ecf -target report_engine -c_compile

# Run tests
/d/prod/ec.sh -batch -config report_engine.ecf -target report_engine_tests -c_compile
./EIFGENs/report_engine_tests/W_code/report_engine.exe

# Run tests (finalized)
/d/prod/ec.sh -batch -config report_engine.ecf -target report_engine_tests -finalize -c_compile
./EIFGENs/report_engine_tests/F_code/report_engine.exe
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles clean | Zero errors, zero warnings | 100% |
| Tests pass | All test cases green | 100% |
| CLI functional | All commands work | 100% |
| Chart quality | Visual inspection | Professional appearance |
| Table rendering | Complex tables | Correct formatting |
| Performance | Report generation time | <5 seconds typical |
| Documentation | README + template guide | Complete |

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| simple_chart not ready | Medium | High | Use static SVG placeholders, iterate |
| Complex templates | High | Medium | Start simple, document limitations |
| Performance with large data | Medium | Medium | Add pagination, streaming |
| Chart sizing in PDF | Medium | Low | Configurable sizes, testing |
| Template syntax complexity | Medium | Medium | Use proven Mustache-like syntax |
| CSV encoding issues | High | Low | UTF-8 default, document requirements |
