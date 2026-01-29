# Report Engine - Ecosystem Integration

## simple_* Dependencies

### Required Libraries

| Library | Purpose | Integration Point |
|---------|---------|-------------------|
| simple_pdf | PDF generation from HTML | REPORT_ENGINE.generate_pdf |
| simple_chart | SVG chart generation | CHART_BUILDER.* |
| simple_json | JSON data input | DATA_SOURCE_JSON.load |
| simple_csv | CSV data input | DATA_SOURCE_CSV.load |
| simple_template | HTML template rendering | REPORT_TEMPLATE_MANAGER.render |
| simple_cli | Command-line interface | REPORT_ENGINE_CLI.make |

### Optional Libraries

| Library | Purpose | When Needed |
|---------|---------|-------------|
| simple_sql | Database data source | --sql-connection enabled |
| simple_markdown | Markdown text sections | Markdown content in templates |
| simple_datetime | Date formatting | All date operations |
| simple_decimal | Precise numeric formatting | Currency and percentage values |
| simple_i18n | Multi-language reports | Non-English locales |
| simple_smtp | Email report delivery | --email flag enabled |
| simple_scheduler | Scheduled report generation | daemon mode |

## Integration Patterns

### simple_pdf Integration

**Purpose:** Convert rendered HTML report to PDF document

**Usage:**
```eiffel
feature -- PDF Generation

    generate_pdf (a_html: STRING; a_config: REPORT_CONFIG): SIMPLE_PDF_DOCUMENT
            -- Generate PDF from HTML report content
        local
            l_pdf: SIMPLE_PDF
        do
            create l_pdf.make

            -- Apply report page settings
            l_pdf.set_page_size (a_config.page_size)
            l_pdf.set_orientation (a_config.orientation)
            l_pdf.set_margin_top (a_config.margin_top)
            l_pdf.set_margin_bottom (a_config.margin_bottom)
            l_pdf.set_margin_left (a_config.margin_left)
            l_pdf.set_margin_right (a_config.margin_right)

            -- Use Chrome for best CSS rendering if available
            if chrome_preferred and chrome_available then
                l_pdf.use_chrome
            end

            Result := l_pdf.from_html (a_html)
        end

    save_report (a_doc: SIMPLE_PDF_DOCUMENT; a_path: STRING): BOOLEAN
            -- Save generated report to file
        do
            if a_doc.is_valid then
                Result := a_doc.save_to_file (a_path)
            else
                last_error := a_doc.error_message
                Result := False
            end
        end
```

**Data flow:** HTML report -> simple_pdf.from_html -> PDF file

### simple_chart Integration

**Purpose:** Generate SVG charts from data for embedding in reports

**Usage:**
```eiffel
feature -- Chart Generation

    build_bar_chart (a_data: LIST [CHART_DATA_POINT]; a_config: CHART_CONFIG): STRING
            -- Generate bar chart SVG
        local
            l_chart: SIMPLE_CHART
            l_bar: SIMPLE_CHART_BAR
        do
            create l_chart.make
            create l_bar.make

            -- Configure chart
            l_bar.set_width (a_config.width)
            l_bar.set_height (a_config.height)
            l_bar.set_title (a_config.title)
            l_bar.set_colors (a_config.colors)

            -- Add data points
            across a_data as ic loop
                l_bar.add_bar (ic.item.label, ic.item.value)
            end

            -- Generate SVG
            Result := l_bar.to_svg
        end

    build_line_chart (a_series: LIST [CHART_SERIES]; a_config: CHART_CONFIG): STRING
            -- Generate line chart SVG
        local
            l_chart: SIMPLE_CHART
            l_line: SIMPLE_CHART_LINE
        do
            create l_chart.make
            create l_line.make

            l_line.set_width (a_config.width)
            l_line.set_height (a_config.height)
            l_line.set_title (a_config.title)

            across a_series as ic loop
                l_line.add_series (ic.item.name, ic.item.points)
            end

            Result := l_line.to_svg
        end

    build_pie_chart (a_data: LIST [CHART_DATA_POINT]; a_config: CHART_CONFIG): STRING
            -- Generate pie chart SVG
        local
            l_chart: SIMPLE_CHART
            l_pie: SIMPLE_CHART_PIE
        do
            create l_chart.make
            create l_pie.make

            l_pie.set_width (a_config.width)
            l_pie.set_height (a_config.height)
            l_pie.set_title (a_config.title)
            l_pie.set_colors (a_config.colors)

            across a_data as ic loop
                l_pie.add_slice (ic.item.label, ic.item.value)
            end

            Result := l_pie.to_svg
        end
```

**Data flow:** Data points -> SIMPLE_CHART -> SVG string -> embed in HTML

### simple_json Integration

**Purpose:** Load structured data from JSON files

**Usage:**
```eiffel
feature -- JSON Data Source

    load_json_data (a_path: STRING): DATA_CONTEXT
            -- Load data from JSON file
        local
            l_json: SIMPLE_JSON
            l_root: JSON_VALUE
        do
            create l_json.make
            create Result.make

            l_root := l_json.parse_file (a_path)

            if attached l_root then
                -- Extract metadata
                if attached {JSON_OBJECT} l_root.item ("metadata") as l_meta then
                    Result.set_metadata (json_object_to_table (l_meta))
                end

                -- Extract each data section
                across l_root.current_keys as ic loop
                    if attached l_root.item (ic.item) as l_value then
                        Result.add_binding (ic.item, json_to_data (l_value))
                    end
                end
            else
                last_error := "Failed to parse JSON: " + l_json.last_error
            end
        end

    json_array_to_table (a_array: JSON_ARRAY): DATA_TABLE
            -- Convert JSON array to data table (for tables/charts)
        local
            l_row: DATA_ROW
        do
            create Result.make (a_array.count)

            across a_array as ic loop
                if attached {JSON_OBJECT} ic.item as l_obj then
                    l_row := json_object_to_row (l_obj)
                    Result.add_row (l_row)
                end
            end
        end
```

**Data flow:** JSON file -> SIMPLE_JSON.parse -> DATA_CONTEXT

### simple_csv Integration

**Purpose:** Load tabular data from CSV files

**Usage:**
```eiffel
feature -- CSV Data Source

    load_csv_data (a_path: STRING; a_config: CSV_CONFIG): DATA_TABLE
            -- Load data from CSV file
        local
            l_csv: SIMPLE_CSV
            l_reader: SIMPLE_CSV_READER
            l_row: DATA_ROW
        do
            create l_csv.make
            create Result.make (1000)

            l_reader := l_csv.open_file (a_path)

            -- Set headers
            Result.set_headers (l_reader.headers)

            -- Load rows
            from l_reader.start until l_reader.after loop
                l_row := csv_row_to_data_row (l_reader.current_row, l_reader.headers)
                Result.add_row (l_row)
                l_reader.forth
            end

            l_reader.close
        end

    csv_row_to_data_row (a_values: LIST [STRING]; a_headers: LIST [STRING]): DATA_ROW
            -- Convert CSV row to typed data row
        local
            i: INTEGER
        do
            create Result.make (a_headers.count)

            from i := 1 until i > a_headers.count loop
                Result.put (parse_value (a_values.i_th (i)), a_headers.i_th (i))
                i := i + 1
            end
        end
```

**Data flow:** CSV file -> SIMPLE_CSV_READER -> DATA_TABLE

### simple_template Integration

**Purpose:** Render HTML templates with data bindings

**Usage:**
```eiffel
feature -- Template Rendering

    render_report (a_template: STRING; a_context: DATA_CONTEXT): STRING
            -- Render report template with data
        local
            l_template: SIMPLE_TEMPLATE
            l_template_ctx: SIMPLE_TEMPLATE_CONTEXT
        do
            create l_template.make
            create l_template_ctx.make

            -- Bind metadata
            l_template_ctx.put_string (a_context.title, "title")
            l_template_ctx.put_string (a_context.subtitle, "subtitle")
            l_template_ctx.put_string (a_context.date, "date")

            -- Bind data sections
            across a_context.bindings as ic loop
                l_template_ctx.put_object (ic.item.data, ic.item.name)
            end

            -- Bind generated charts
            across a_context.charts as ic loop
                l_template_ctx.put_string (ic.item.svg, ic.item.name + "_svg")
            end

            -- Bind formatted tables
            across a_context.tables as ic loop
                l_template_ctx.put_string (ic.item.html, ic.item.name + "_html")
            end

            Result := l_template.render (a_template, l_template_ctx)
        end

    render_table_html (a_table: DATA_TABLE; a_columns: LIST [COLUMN_CONFIG]): STRING
            -- Render data table as HTML
        local
            l_builder: TABLE_BUILDER
        do
            create l_builder.make

            l_builder.set_css_class ("data-table")

            -- Add headers
            across a_columns as ic loop
                l_builder.add_header (ic.item.header)
            end

            -- Add rows
            across a_table.rows as row_cursor loop
                l_builder.start_row
                across a_columns as col_cursor loop
                    l_builder.add_cell (
                        format_value (row_cursor.item.get (col_cursor.item.field),
                                     col_cursor.item.format)
                    )
                end
                l_builder.end_row
            end

            Result := l_builder.to_html
        end
```

**Data flow:** Template + DATA_CONTEXT -> SIMPLE_TEMPLATE.render -> HTML

### simple_cli Integration

**Purpose:** Command-line argument parsing and execution

**Usage:**
```eiffel
class REPORT_ENGINE_CLI

inherit
    SIMPLE_CLI_APPLICATION

create
    make

feature {NONE} -- Initialization

    make
        do
            create cli.make ("report-engine", "Data-driven PDF report generator")

            -- Add commands
            cli.add_command (create {GENERATE_COMMAND}.make)
            cli.add_command (create {PREVIEW_COMMAND}.make)
            cli.add_command (create {VALIDATE_COMMAND}.make)
            cli.add_command (create {TEMPLATE_COMMAND}.make)
            cli.add_command (create {SCHEMA_COMMAND}.make)

            -- Data options
            cli.add_option (create {FILE_OPTION}.make ("data", "d", "Data file"))
            cli.add_option (create {FILE_OPTION}.make ("json", Void, "JSON data file"))
            cli.add_option (create {FILE_OPTION}.make ("csv", Void, "CSV data file"))

            -- Output options
            cli.add_option (create {FILE_OPTION}.make ("template", "t", "Template name"))
            cli.add_option (create {FILE_OPTION}.make ("output", "o", "Output file"))
            cli.add_option (create {FILE_OPTION}.make ("config", "c", "Config file"))

            -- Global options
            cli.add_flag ("verbose", "v", "Verbose output")
            cli.add_flag ("quiet", "q", "Suppress non-error output")

            cli.execute (arguments)
        end
```

**Data flow:** Command-line args -> SIMPLE_CLI -> command routing

## Dependency Graph

```
report_engine
    |
    +-- simple_pdf (required)
    |   +-- simple_json
    |   +-- simple_uuid
    |   +-- simple_base64
    |   +-- simple_process
    |
    +-- simple_chart (required)
    |   +-- simple_json (for data)
    |
    +-- simple_json (required)
    |
    +-- simple_csv (required)
    |
    +-- simple_template (required)
    |   +-- simple_json
    |
    +-- simple_cli (required)
    |   +-- simple_json
    |
    +-- simple_datetime (required)
    |
    +-- simple_decimal (required)
    |
    +-- simple_sql (optional)
    |   +-- SQLite3
    |
    +-- simple_markdown (optional)
    |
    +-- simple_smtp (optional)
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
        name="report_engine"
        uuid="550E8400-E29B-41D4-A716-446655440003">

    <target name="report_engine">
        <description>Report Engine - Data-driven PDF report generator</description>
        <root class="REPORT_ENGINE_CLI" feature="make"/>

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
        <library name="simple_chart" location="$SIMPLE_EIFFEL/simple_chart/simple_chart.ecf"/>
        <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
        <library name="simple_csv" location="$SIMPLE_EIFFEL/simple_csv/simple_csv.ecf"/>
        <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
        <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
        <library name="simple_datetime" location="$SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf"/>
        <library name="simple_decimal" location="$SIMPLE_EIFFEL/simple_decimal/simple_decimal.ecf"/>

        <!-- ISE libraries -->
        <library name="base" location="$ISE_LIBRARY/library/base/base.ecf"/>
        <library name="time" location="$ISE_LIBRARY/library/time/time.ecf"/>
    </target>

    <target name="report_engine_tests" extends="report_engine">
        <description>Report Engine test suite</description>
        <root class="TEST_APP" feature="make"/>

        <cluster name="tests" location=".\tests\" recursive="true"/>

        <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    </target>

</system>
```
