# Report Engine - Technical Design

## Architecture

### Component Overview

```
+-----------------------------------------------------------+
|                      Report Engine                         |
+-----------------------------------------------------------+
|  CLI Interface Layer                                       |
|    - Argument parsing (simple_cli)                         |
|    - Command routing (generate, preview, template)         |
|    - Output formatting (progress, errors)                  |
+-----------------------------------------------------------+
|  Report Composition Layer                                  |
|    - Report model (sections, elements, layout)             |
|    - Template binding (data -> HTML)                       |
|    - Section assembly (header, body, footer)               |
+-----------------------------------------------------------+
|  Data Processing Layer                                     |
|    - Data source abstraction (JSON, CSV, SQL)              |
|    - Data transformation (filtering, aggregation)          |
|    - Calculated fields (formulas, summaries)               |
+-----------------------------------------------------------+
|  Visualization Layer                                       |
|    - Chart generation (simple_chart -> SVG)                |
|    - Table rendering (data -> HTML tables)                 |
|    - Formatting (numbers, dates, currencies)               |
+-----------------------------------------------------------+
|  Integration Layer                                         |
|    - simple_pdf (HTML -> PDF rendering)                    |
|    - simple_chart (data visualization)                     |
|    - simple_template (template engine)                     |
|    - simple_json / simple_csv (data input)                 |
+-----------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| REPORT_ENGINE_CLI | Command-line interface | parse_args, route_command, format_output |
| REPORT_ENGINE | Core orchestration | generate, preview, validate |
| REPORT_MODEL | Report structure | sections, data_bindings, metadata |
| REPORT_SECTION | Report section | type (header/body/footer), content, layout |
| REPORT_ELEMENT | Content element | chart, table, text, image |
| DATA_SOURCE | Abstract data source | load, query, transform |
| DATA_SOURCE_JSON | JSON file source | parse, navigate, filter |
| DATA_SOURCE_CSV | CSV file source | parse, column access, aggregation |
| DATA_SOURCE_SQL | Database source | connect, query, transform |
| CHART_BUILDER | Chart generation | bar, line, pie, area from data |
| TABLE_BUILDER | Table generation | data -> HTML table with styling |
| REPORT_TEMPLATE_MANAGER | Template handling | load, render, cache |
| REPORT_FORMATTER | Value formatting | numbers, dates, currencies |
| REPORT_CONFIG | Configuration | settings, defaults, templates |

### Command Structure

```bash
report-engine <command> [options] [arguments]

Commands:
  generate     Generate PDF report from data and template
  preview      Generate HTML preview (no PDF)
  validate     Validate template and data structure
  template     Template management (list, create, info)
  schema       Show expected data schema for template

Generate Options:
  -d, --data FILE        Data file (JSON or CSV)
  -t, --template NAME    Template name or path
  -o, --output FILE      Output PDF file path
  -c, --config FILE      Report configuration file
  --title TEXT           Report title override
  --subtitle TEXT        Report subtitle override
  --date DATE            Report date override (default: today)
  --format FORMAT        Page format (A4, Letter, Legal)
  --orientation ORI      Portrait or Landscape

Data Options:
  --json FILE            JSON data file
  --csv FILE             CSV data file
  --sql-file FILE        SQL query file
  --sql-connection STR   Database connection string

Chart Options:
  --chart-theme THEME    Chart color theme
  --chart-width WIDTH    Default chart width (px)
  --chart-height HEIGHT  Default chart height (px)

Global Options:
  -v, --verbose          Verbose output
  -q, --quiet            Suppress non-error output
  --version              Show version
  --help                 Show help
```

### Data Flow

```
Data Source (JSON/CSV/SQL)
       |
       v
  Data Loading
       |  (parse, validate structure)
       v
  Data Transformation
       |  (filter, aggregate, calculate)
       v
  Report Model Assembly
       |  (bind data to sections/elements)
       v
  Chart Generation (simple_chart)
       |  (data -> SVG)
       v
  Template Rendering (simple_template)
       |  (model + template -> HTML)
       v
  PDF Generation (simple_pdf)
       |
       v
  Output (PDF file)
```

### Report Configuration Schema

```json
{
  "report_engine": {
    "report": {
      "title": "Monthly Sales Report",
      "subtitle": "January 2026",
      "author": "Analytics Team",
      "date_format": "MMMM YYYY",
      "logo": "./assets/logo.png"
    },
    "page": {
      "size": "Letter",
      "orientation": "portrait",
      "margins": {
        "top": "25mm",
        "bottom": "25mm",
        "left": "20mm",
        "right": "20mm"
      }
    },
    "data": {
      "source": "data/monthly_sales.json",
      "filters": [
        {"field": "region", "operator": "in", "value": ["North", "South"]}
      ],
      "calculations": [
        {"name": "total_revenue", "formula": "SUM(sales.amount)"},
        {"name": "avg_order", "formula": "AVG(sales.amount)"}
      ]
    },
    "sections": [
      {
        "type": "header",
        "template": "partials/header.html"
      },
      {
        "type": "summary",
        "template": "partials/summary.html",
        "data_binding": "summary"
      },
      {
        "type": "chart",
        "chart_type": "bar",
        "data_binding": "sales_by_region",
        "title": "Sales by Region",
        "x_field": "region",
        "y_field": "amount"
      },
      {
        "type": "table",
        "data_binding": "sales_details",
        "columns": [
          {"field": "date", "header": "Date", "format": "date"},
          {"field": "product", "header": "Product"},
          {"field": "amount", "header": "Amount", "format": "currency"}
        ]
      },
      {
        "type": "footer",
        "template": "partials/footer.html"
      }
    ],
    "charts": {
      "theme": "professional",
      "default_width": 600,
      "default_height": 400,
      "colors": ["#3498db", "#2ecc71", "#e74c3c", "#f39c12", "#9b59b6"]
    },
    "formatting": {
      "currency": "USD",
      "currency_symbol": "$",
      "decimal_places": 2,
      "date_format": "YYYY-MM-DD",
      "number_locale": "en-US"
    }
  }
}
```

### Data Input Schema (JSON)

```json
{
  "metadata": {
    "generated_at": "2026-01-24T10:00:00Z",
    "source": "ERP System",
    "period": "January 2026"
  },
  "summary": {
    "total_revenue": 1250000.00,
    "total_orders": 3420,
    "avg_order_value": 365.50,
    "growth_rate": 12.5
  },
  "sales_by_region": [
    {"region": "North", "amount": 450000},
    {"region": "South", "amount": 380000},
    {"region": "East", "amount": 220000},
    {"region": "West", "amount": 200000}
  ],
  "sales_by_product": [
    {"product": "Widget A", "units": 1200, "revenue": 360000},
    {"product": "Widget B", "units": 800, "revenue": 280000},
    {"product": "Service X", "units": 500, "revenue": 250000}
  ],
  "sales_details": [
    {"date": "2026-01-15", "product": "Widget A", "customer": "Acme Corp", "amount": 15000},
    {"date": "2026-01-16", "product": "Widget B", "customer": "GlobalTech", "amount": 8500}
  ]
}
```

### HTML Template Example

```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .header { border-bottom: 2px solid #333; padding-bottom: 20px; }
        .logo { float: right; width: 120px; }
        .title { font-size: 24px; color: #333; }
        .subtitle { font-size: 14px; color: #666; }
        .summary-box { background: #f5f5f5; padding: 15px; margin: 20px 0; }
        .summary-item { display: inline-block; width: 23%; text-align: center; }
        .summary-value { font-size: 28px; font-weight: bold; color: #2c3e50; }
        .summary-label { font-size: 12px; color: #7f8c8d; }
        .chart-container { margin: 20px 0; page-break-inside: avoid; }
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th { background: #3498db; color: white; padding: 10px; }
        .data-table td { padding: 8px; border-bottom: 1px solid #ddd; }
        .data-table tr:nth-child(even) { background: #f9f9f9; }
        .footer { margin-top: 30px; font-size: 10px; color: #999; }
    </style>
</head>
<body>
    <div class="header">
        <img src="{{logo}}" class="logo" alt="Logo">
        <div class="title">{{title}}</div>
        <div class="subtitle">{{subtitle}} | Generated: {{date}}</div>
    </div>

    <div class="summary-box">
        {{#each summary_items}}
        <div class="summary-item">
            <div class="summary-value">{{value}}</div>
            <div class="summary-label">{{label}}</div>
        </div>
        {{/each}}
    </div>

    <div class="chart-container">
        <h3>{{chart_title}}</h3>
        {{chart_svg}}
    </div>

    <h3>Detailed Data</h3>
    <table class="data-table">
        <thead>
            <tr>
                {{#each columns}}
                <th>{{header}}</th>
                {{/each}}
            </tr>
        </thead>
        <tbody>
            {{#each rows}}
            <tr>
                {{#each cells}}
                <td>{{value}}</td>
                {{/each}}
            </tr>
            {{/each}}
        </tbody>
    </table>

    <div class="footer">
        <p>Report ID: {{report_id}} | Page {{page_number}} of {{total_pages}}</p>
        <p>Generated by Report Engine | {{company_name}}</p>
    </div>
</body>
</html>
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Data file not found | Abort | "Error: Data file not found: {path}" |
| Invalid JSON/CSV | Abort with details | "Error: Cannot parse data file: {details}" |
| Template not found | Abort | "Error: Template not found: {name}" |
| Template syntax error | Abort with line | "Error: Template syntax error at line {n}: {details}" |
| Missing data binding | Warning, skip section | "Warning: No data for binding '{name}', skipping section" |
| Chart generation failed | Warning, placeholder | "Warning: Chart failed for '{name}': {reason}" |
| PDF generation failed | Abort | "Error: PDF generation failed: {reason}" |
| Invalid field reference | Warning, empty value | "Warning: Field '{field}' not found in data" |

## GUI/TUI Future Path

**CLI foundation enables:**
- TUI for interactive report preview and template editing
- Web-based template designer
- Dashboard for scheduled report management
- API server for programmatic access

**Shared components between CLI/GUI:**
- REPORT_MODEL and all data processing classes unchanged
- CHART_BUILDER works for any interface
- TABLE_BUILDER produces HTML usable anywhere
- REPORT_FORMATTER provides consistent value formatting

**What would change for TUI:**
- Add REPORT_TUI_APP using simple_tui
- Interactive data source selection
- Real-time preview with chart rendering
- Template variable inspection

**What would change for GUI:**
- Web server using simple_http
- Template designer with drag-and-drop
- Data source configuration UI
- Report scheduling calendar
