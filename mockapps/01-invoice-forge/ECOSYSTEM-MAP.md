# Invoice Forge - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_pdf | Core PDF generation from HTML | INVOICE_FORGE_ENGINE.generate_pdf |
| simple_json | JSON data input/output | INVOICE_FORGE_ENGINE.load_data, export_manifest |
| simple_csv | Bulk CSV data import | INVOICE_FORGE_ENGINE.import_csv |
| simple_template | HTML template rendering | INVOICE_TEMPLATE_MANAGER.render |
| simple_validation | Data validation rules | INVOICE_VALIDATOR.validate_invoice |
| simple_cli | Command-line interface | INVOICE_FORGE_CLI.make |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_smtp | Email invoice delivery | --email flag enabled |
| simple_sql | Invoice history storage | --database flag enabled |
| simple_i18n | Multi-language templates | Non-English locales |
| simple_hash | Document integrity checksums | --checksum flag enabled |
| simple_datetime | Date/time formatting | All date operations |
| simple_decimal | Precise financial math | Currency calculations |

## Integration Patterns

### simple_pdf Integration

**Purpose:** Convert rendered HTML invoice to PDF document

**Usage:**
```eiffel
feature -- PDF Generation

    generate_pdf (a_html: STRING; a_output_path: STRING): BOOLEAN
            -- Generate PDF from HTML invoice content
        local
            l_pdf: SIMPLE_PDF
            l_doc: SIMPLE_PDF_DOCUMENT
        do
            create l_pdf.make

            -- Apply page settings from config
            l_pdf.set_page_size (config.page_size)
            l_pdf.set_orientation (config.orientation)
            l_pdf.set_margin_top (config.margin_top)
            l_pdf.set_margin_bottom (config.margin_bottom)
            l_pdf.set_margin_left (config.margin_left)
            l_pdf.set_margin_right (config.margin_right)

            -- Select engine based on config
            if config.use_chrome then
                l_pdf.use_chrome
            end

            -- Generate PDF
            l_doc := l_pdf.from_html (a_html)

            if l_doc.is_valid then
                Result := l_doc.save_to_file (a_output_path)
            else
                last_error := l_doc.error_message
                Result := False
            end
        end
```

**Data flow:** Invoice HTML -> simple_pdf.from_html -> SIMPLE_PDF_DOCUMENT -> save_to_file

### simple_json Integration

**Purpose:** Parse input data and generate output manifests

**Usage:**
```eiffel
feature -- Data Loading

    load_invoice_data (a_path: STRING): ARRAYED_LIST [INVOICE_MODEL]
            -- Load invoices from JSON file
        local
            l_json: SIMPLE_JSON
            l_parser: SIMPLE_JSON_PARSER
            l_array: JSON_ARRAY
            l_invoice: INVOICE_MODEL
        do
            create Result.make (100)
            create l_json.make

            if attached l_json.parse_file (a_path) as l_root then
                if attached {JSON_ARRAY} l_root.item ("invoices") as l_invoices then
                    across l_invoices as ic loop
                        if attached {JSON_OBJECT} ic.item as l_obj then
                            l_invoice := parse_invoice_object (l_obj)
                            Result.extend (l_invoice)
                        end
                    end
                end
            else
                last_error := "Failed to parse JSON: " + l_json.last_error
            end
        end

    export_manifest (a_results: LIST [GENERATION_RESULT]; a_path: STRING)
            -- Export generation results as JSON manifest
        local
            l_json: SIMPLE_JSON
            l_array: JSON_ARRAY
            l_obj: JSON_OBJECT
        do
            create l_json.make
            create l_array.make (a_results.count)

            across a_results as ic loop
                create l_obj.make
                l_obj.put_string (ic.item.invoice_number, "invoice_number")
                l_obj.put_string (ic.item.output_path, "output_path")
                l_obj.put_boolean (ic.item.success, "success")
                if attached ic.item.error as l_err then
                    l_obj.put_string (l_err, "error")
                end
                l_array.add (l_obj)
            end

            l_json.save_to_file (l_array, a_path)
        end
```

**Data flow:** JSON file -> SIMPLE_JSON.parse_file -> INVOICE_MODEL list

### simple_csv Integration

**Purpose:** Import bulk invoice data from CSV exports

**Usage:**
```eiffel
feature -- CSV Import

    import_from_csv (a_path: STRING): ARRAYED_LIST [INVOICE_MODEL]
            -- Import invoices from CSV file
        local
            l_csv: SIMPLE_CSV
            l_reader: SIMPLE_CSV_READER
            l_invoice: INVOICE_MODEL
            l_headers: ARRAYED_LIST [STRING]
        do
            create Result.make (1000)
            create l_csv.make

            l_reader := l_csv.open_file (a_path)
            l_headers := l_reader.headers

            from l_reader.start until l_reader.after loop
                l_invoice := row_to_invoice (l_reader.current_row, l_headers)
                Result.extend (l_invoice)
                l_reader.forth
            end

            l_reader.close
        end
```

**Data flow:** CSV file -> SIMPLE_CSV_READER -> rows -> INVOICE_MODEL list

### simple_template Integration

**Purpose:** Merge invoice data with HTML templates

**Usage:**
```eiffel
feature -- Template Rendering

    render_invoice (a_invoice: INVOICE_MODEL; a_template: STRING): STRING
            -- Render invoice data into HTML template
        local
            l_template: SIMPLE_TEMPLATE
            l_context: SIMPLE_TEMPLATE_CONTEXT
        do
            create l_template.make
            create l_context.make

            -- Bind invoice data
            l_context.put_string (a_invoice.invoice_number, "invoice_number")
            l_context.put_string (a_invoice.date.formatted, "date")
            l_context.put_string (a_invoice.due_date.formatted, "due_date")

            -- Bind customer data
            l_context.put_string (a_invoice.customer.name, "customer_name")
            l_context.put_list (a_invoice.customer.address, "customer_address")

            -- Bind line items
            l_context.put_list (line_items_to_list (a_invoice.line_items), "line_items")

            -- Bind totals
            l_context.put_string (format_currency (a_invoice.subtotal), "subtotal")
            l_context.put_string (format_currency (a_invoice.tax_amount), "tax_amount")
            l_context.put_string (format_currency (a_invoice.total), "total")

            -- Bind company info from config
            l_context.put_string (config.company.name, "company_name")
            l_context.put_list (config.company.address, "company_address")

            Result := l_template.render (a_template, l_context)
        end
```

**Data flow:** Template + INVOICE_MODEL -> SIMPLE_TEMPLATE.render -> HTML string

### simple_validation Integration

**Purpose:** Validate invoice data before processing

**Usage:**
```eiffel
feature -- Validation

    validate_invoice (a_invoice: INVOICE_MODEL): VALIDATION_RESULT
            -- Validate invoice data
        local
            l_validator: SIMPLE_VALIDATOR
            l_rules: ARRAYED_LIST [VALIDATION_RULE]
        do
            create l_validator.make
            create l_rules.make (20)

            -- Required fields
            l_rules.extend (create {REQUIRED_RULE}.make ("invoice_number"))
            l_rules.extend (create {REQUIRED_RULE}.make ("date"))
            l_rules.extend (create {REQUIRED_RULE}.make ("customer.name"))

            -- Format rules
            l_rules.extend (create {DATE_FORMAT_RULE}.make ("date", "YYYY-MM-DD"))
            l_rules.extend (create {DATE_FORMAT_RULE}.make ("due_date", "YYYY-MM-DD"))

            -- Business rules
            l_rules.extend (create {POSITIVE_NUMBER_RULE}.make ("line_items[].quantity"))
            l_rules.extend (create {POSITIVE_NUMBER_RULE}.make ("line_items[].unit_price"))
            l_rules.extend (create {NOT_EMPTY_LIST_RULE}.make ("line_items"))

            -- Custom rule: due_date must be after date
            l_rules.extend (create {DATE_AFTER_RULE}.make ("due_date", "date"))

            Result := l_validator.validate (invoice_to_json (a_invoice), l_rules)
        end
```

**Data flow:** INVOICE_MODEL -> validation rules -> VALIDATION_RESULT

### simple_cli Integration

**Purpose:** Command-line argument parsing and execution

**Usage:**
```eiffel
class INVOICE_FORGE_CLI

inherit
    SIMPLE_CLI_APPLICATION

create
    make

feature {NONE} -- Initialization

    make
        do
            create cli.make ("invoice-forge", "Batch invoice PDF generator")

            -- Add commands
            cli.add_command (create {GENERATE_COMMAND}.make)
            cli.add_command (create {VALIDATE_COMMAND}.make)
            cli.add_command (create {PREVIEW_COMMAND}.make)
            cli.add_command (create {TEMPLATE_COMMAND}.make)
            cli.add_command (create {CONFIG_COMMAND}.make)

            -- Global options
            cli.add_option (create {FILE_OPTION}.make ("config", "c", "Configuration file"))
            cli.add_option (create {STRING_OPTION}.make ("currency", Void, "Default currency"))
            cli.add_option (create {STRING_OPTION}.make ("locale", Void, "Locale for formatting"))
            cli.add_flag ("verbose", "v", "Verbose output")
            cli.add_flag ("quiet", "q", "Suppress non-error output")

            -- Run
            cli.execute (arguments)
        end
```

**Data flow:** Command-line args -> SIMPLE_CLI -> command routing -> execution

## Dependency Graph

```
invoice_forge
    |
    +-- simple_pdf (required)
    |   +-- simple_json
    |   +-- simple_uuid
    |   +-- simple_base64
    |   +-- simple_process
    |
    +-- simple_json (required)
    |
    +-- simple_csv (required)
    |
    +-- simple_template (required)
    |   +-- simple_json
    |
    +-- simple_validation (required)
    |   +-- simple_json
    |
    +-- simple_cli (required)
    |   +-- simple_json
    |
    +-- simple_datetime (required)
    |
    +-- simple_decimal (required)
    |
    +-- simple_smtp (optional)
    |   +-- simple_json
    |
    +-- simple_sql (optional)
    |   +-- simple_json
    |
    +-- simple_hash (optional)
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
        name="invoice_forge"
        uuid="550E8400-E29B-41D4-A716-446655440001">

    <target name="invoice_forge">
        <description>Invoice Forge - Batch invoice PDF generator</description>
        <root class="INVOICE_FORGE_CLI" feature="make"/>

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
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
        <library name="simple_validation" location="$SIMPLE_EIFFEL/simple_validation/simple_validation.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_decimal" location="$SIMPLE_EIFFEL/simple_decimal/simple_decimal.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <target name="invoice_forge_tests" extends="invoice_forge">
        <description>Invoice Forge test suite</description>
        <root class="TEST_APP" feature="make"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```
