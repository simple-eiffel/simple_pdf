# Invoice Forge - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI - Single invoice generation | 3 days | simple_pdf, simple_json, simple_template |
| Phase 2 | Batch Processing & CSV Import | 2 days | Phase 1, simple_csv |
| Phase 3 | Advanced Features | 3 days | Phase 2, simple_validation, simple_decimal |
| Phase 4 | Production Polish | 2 days | Phase 3, simple_cli refinement |

**Total Estimated Effort:** 10 days

---

## Phase 1: MVP

### Objective

Demonstrate core value proposition: generate a single PDF invoice from JSON input using an HTML template. This proves the integration of simple_pdf with template rendering.

### Deliverables

1. **INVOICE_MODEL** - Data structure for invoice
2. **INVOICE_LINE_ITEM** - Line item data structure
3. **INVOICE_CALCULATOR** - Basic calculations (subtotal, total)
4. **INVOICE_TEMPLATE_MANAGER** - Load and render templates
5. **INVOICE_FORGE_ENGINE** - Core generation logic
6. **Basic CLI** - `generate --input data.json --output invoice.pdf`

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Create INVOICE_MODEL class | Holds all invoice data with contracts |
| T1.2 | Create INVOICE_LINE_ITEM class | Quantity, price, description, tax code |
| T1.3 | Create INVOICE_CALCULATOR class | Calculate subtotal, tax, total |
| T1.4 | Create INVOICE_TEMPLATE_MANAGER class | Load template, substitute variables |
| T1.5 | Create INVOICE_FORGE_ENGINE class | Orchestrate JSON -> HTML -> PDF flow |
| T1.6 | Create basic CLI entry point | Parse --input and --output arguments |
| T1.7 | Create default HTML template | Professional invoice layout |
| T1.8 | Integration test: JSON to PDF | End-to-end generation works |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Single invoice | Valid JSON with 1 invoice | PDF file created, valid structure |
| Multiple line items | Invoice with 5 line items | All items rendered in PDF |
| Basic calculations | Known quantities/prices | Correct subtotal and total |
| Template substitution | Variables in template | All placeholders replaced |
| Invalid JSON | Malformed JSON file | Error message, no PDF created |
| Missing required field | JSON without invoice_number | Error message identifying field |

### Phase 1 ECF

```xml
<target name="invoice_forge_phase1">
    <root class="INVOICE_FORGE_CLI" feature="make"/>
    <cluster name="src_core" location=".\src\core\"/>
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>
```

---

## Phase 2: Batch Processing & CSV Import

### Objective

Scale to real-world usage: process hundreds of invoices from a single command, support CSV import for spreadsheet users.

### Deliverables

1. **INVOICE_BATCH_PROCESSOR** - Process multiple invoices
2. **INVOICE_CSV_IMPORTER** - Import from CSV files
3. **GENERATION_RESULT** - Track success/failure per invoice
4. **Manifest output** - JSON file with generation results
5. **Enhanced CLI** - Batch processing commands

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Create INVOICE_BATCH_PROCESSOR class | Process list of invoices sequentially |
| T2.2 | Create GENERATION_RESULT class | Track per-invoice success/error |
| T2.3 | Create INVOICE_CSV_IMPORTER class | Parse CSV, create INVOICE_MODEL list |
| T2.4 | Add manifest export | Write JSON manifest after batch |
| T2.5 | Add progress reporting | Show N/M completed during batch |
| T2.6 | Add --continue-on-error flag | Skip failed invoices, continue batch |
| T2.7 | Add CSV command-line support | `--input file.csv` works |
| T2.8 | Performance benchmark | Process 100 invoices in <60 seconds |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Batch of 10 | JSON with 10 invoices | 10 PDF files + manifest |
| CSV import | CSV with invoice data | Same output as JSON |
| Mixed success | 9 valid + 1 invalid | 9 PDFs + manifest with 1 error |
| Progress output | 100 invoices | Progress shown: 1/100, 2/100... |
| Manifest accuracy | Batch with errors | Manifest reflects exact results |

---

## Phase 3: Advanced Features

### Objective

Add enterprise features: multi-currency support, precise decimal math, data validation, discount handling, tax calculation.

### Deliverables

1. **INVOICE_CURRENCY** - Currency conversion and formatting
2. **INVOICE_VALIDATOR** - Comprehensive data validation
3. **INVOICE_DISCOUNT** - Percentage and fixed discounts
4. **INVOICE_TAX_CALCULATOR** - Multiple tax rates
5. **INVOICE_CONFIG** - Configuration file support
6. **Enhanced templates** - Support for multi-currency, discounts

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Create INVOICE_CURRENCY class | Format, convert, get symbol |
| T3.2 | Integrate simple_decimal | Precise financial calculations |
| T3.3 | Create INVOICE_VALIDATOR class | Validate all fields with rules |
| T3.4 | Add validate command | `validate --input data.json` |
| T3.5 | Create INVOICE_DISCOUNT class | Percentage and fixed discounts |
| T3.6 | Create INVOICE_TAX_CALCULATOR class | Multiple tax rates per line item |
| T3.7 | Create INVOICE_CONFIG class | Load/save configuration |
| T3.8 | Add --config flag | Use configuration file |
| T3.9 | Enhanced template variables | Discount line, tax breakdown |
| T3.10 | Localization support | Date/number formatting per locale |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Multi-currency | EUR invoice | EUR symbol, European formatting |
| Percentage discount | 10% discount | Correct discount calculation |
| Fixed discount | $50 discount | Correct deduction |
| Multiple tax rates | Items with different rates | Correct per-item and total tax |
| Validation errors | Invalid data | Detailed error report |
| Config file | Custom config | Settings applied correctly |

---

## Phase 4: Production Polish

### Objective

Prepare for release: comprehensive error handling, help documentation, performance optimization, packaging.

### Deliverables

1. **Full CLI implementation** - All commands with help
2. **Error handling hardening** - Graceful failures
3. **Template management** - List, create, validate templates
4. **Performance optimization** - Parallel processing
5. **Documentation** - README, usage examples
6. **Packaging** - Release binary with templates

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T4.1 | Implement template command | list, create, validate subcommands |
| T4.2 | Implement config command | show, set, reset subcommands |
| T4.3 | Add parallel processing | --parallel N workers |
| T4.4 | Add --quiet and --verbose flags | Appropriate output levels |
| T4.5 | Comprehensive --help | All commands documented |
| T4.6 | Error message review | Clear, actionable messages |
| T4.7 | Create README.md | Installation, quick start, examples |
| T4.8 | Create sample data | Example JSON/CSV files |
| T4.9 | Create additional templates | Modern, classic, minimal |
| T4.10 | Final performance tuning | 100+ invoices/minute target |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| --help | `invoice-forge --help` | Full command listing |
| --version | `invoice-forge --version` | Version number |
| template list | `template list` | Available templates shown |
| Parallel speedup | 100 invoices, --parallel 4 | Faster than sequential |
| Quiet mode | --quiet flag | Only errors shown |
| Verbose mode | --verbose flag | Debug information shown |

---

## ECF Target Structure

```xml
<!-- Library target (reusable core) -->
<target name="invoice_forge_lib">
    <description>Invoice Forge library (no CLI)</description>
    <cluster name="src" location=".\src\" recursive="true">
        <file_rule>
            <exclude>/cli$</exclude>
        </file_rule>
    </cluster>
    <!-- All dependencies except simple_cli -->
    <library name="simple_pdf" location="$SIMPLE_EIFFEL/simple_pdf/simple_pdf.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
    <library name="simple_validation" location="$SIMPLE_EIFFEL/simple_validation/simple_validation.ecf"/>
    <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
    <library name="simple_decimal" location="$SIMPLE_EIFFEL/simple_decimal/simple_decimal.ecf"/>
    <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
</target>

<!-- CLI executable target -->
<target name="invoice_forge" extends="invoice_forge_lib">
    <description>Invoice Forge CLI application</description>
    <root class="INVOICE_FORGE_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <cluster name="cli" location=".\src\cli\"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
</target>

<!-- Test target -->
<target name="invoice_forge_tests" extends="invoice_forge_lib">
    <description>Invoice Forge test suite</description>
    <root class="TEST_APP" feature="make"/>
    <cluster name="tests" location=".\tests\" recursive="true"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
</target>
```

---

## Build Commands

```bash
# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config invoice_forge.ecf -target invoice_forge -finalize -c_compile

# Compile for development (workbench mode)
/d/prod/ec.sh -batch -config invoice_forge.ecf -target invoice_forge -c_compile

# Run tests
/d/prod/ec.sh -batch -config invoice_forge.ecf -target invoice_forge_tests -c_compile
./EIFGENs/invoice_forge_tests/W_code/invoice_forge.exe

# Run tests (finalized)
/d/prod/ec.sh -batch -config invoice_forge.ecf -target invoice_forge_tests -finalize -c_compile
./EIFGENs/invoice_forge_tests/F_code/invoice_forge.exe
```

---

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles clean | Zero errors, zero warnings | 100% |
| Tests pass | All test cases green | 100% |
| CLI functional | All commands work | 100% |
| Performance | Invoices per minute | 100+ |
| Documentation | README complete, examples work | Yes |
| User experience | Time from install to first invoice | <15 min |
| Error messages | Clear, actionable | Reviewed |
| Template quality | Professional appearance | 3+ templates |

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| simple_template not ready | Low | High | Use simple string substitution as fallback |
| Performance issues | Medium | Medium | Profile early, optimize hot paths |
| Template complexity | Medium | Low | Start with simple templates, iterate |
| Currency edge cases | Medium | Medium | Use simple_decimal, extensive testing |
| CSV format variations | High | Low | Document expected format, provide examples |
