# Invoice Forge - Technical Design

## Architecture

### Component Overview

```
+-----------------------------------------------------------+
|                      Invoice Forge                         |
+-----------------------------------------------------------+
|  CLI Interface Layer                                       |
|    - Argument parsing (simple_cli)                         |
|    - Command routing (generate, validate, preview)         |
|    - Output formatting (text, json, quiet)                 |
+-----------------------------------------------------------+
|  Business Logic Layer                                      |
|    - Invoice model (line items, taxes, discounts)          |
|    - Currency handling (rates, formatting)                 |
|    - Calculation engine (subtotals, totals, tax)           |
|    - Batch orchestration (parallel processing)             |
+-----------------------------------------------------------+
|  Template Layer                                            |
|    - Template loading and caching                          |
|    - Variable substitution (simple_template)               |
|    - Partial composition (header, footer, items)           |
|    - Localization support (dates, numbers)                 |
+-----------------------------------------------------------+
|  Integration Layer                                         |
|    - simple_pdf (HTML-to-PDF rendering)                    |
|    - simple_json (data input/output)                       |
|    - simple_csv (bulk data import)                         |
|    - simple_validation (data validation)                   |
+-----------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| INVOICE_FORGE_CLI | Command-line interface | parse_args, route_command, format_output |
| INVOICE_FORGE_ENGINE | Core orchestration | generate_batch, validate_data, preview_invoice |
| INVOICE_MODEL | Invoice data structure | line_items, tax_rates, discounts, currency |
| INVOICE_LINE_ITEM | Single line item | description, quantity, unit_price, tax_code |
| INVOICE_CALCULATOR | Financial calculations | subtotal, tax_amount, discount_amount, total |
| INVOICE_TEMPLATE_MANAGER | Template handling | load_template, render, cache |
| INVOICE_CURRENCY | Currency operations | convert, format, get_symbol |
| INVOICE_VALIDATOR | Data validation | validate_invoice, validate_line_item |
| INVOICE_BATCH_PROCESSOR | Batch operations | process_batch, parallel_generate |
| INVOICE_CONFIG | Configuration | load, save, validate, defaults |

### Command Structure

```bash
invoice-forge <command> [options] [arguments]

Commands:
  generate     Generate PDF invoice(s) from data file
  validate     Validate invoice data without generating
  preview      Generate HTML preview (no PDF)
  template     Template management (list, create, validate)
  config       Configuration management

Generate Options:
  -i, --input FILE       Input data file (JSON or CSV)
  -o, --output DIR       Output directory for PDFs
  -t, --template NAME    Template name or path
  --format FORMAT        Output format (pdf, html, both)
  --parallel N           Parallel workers (default: 4)
  --continue-on-error    Don't stop on individual invoice errors

Validate Options:
  -i, --input FILE       Input data file to validate
  --strict               Enable strict validation mode
  --report FILE          Write validation report to file

Template Options:
  list                   List available templates
  create NAME            Create new template from default
  validate FILE          Validate template syntax

Global Options:
  -c, --config FILE      Configuration file path
  --currency CODE        Default currency (USD, EUR, GBP, etc.)
  --locale CODE          Locale for formatting (en-US, de-DE, etc.)
  -v, --verbose          Verbose output
  -q, --quiet            Suppress non-error output
  --version              Show version
  --help                 Show help
```

### Data Flow

```
Input (JSON/CSV)
       |
       v
  Validation -----> Error Report (if invalid)
       |
       v
  Data Parsing
       |
       v
  Calculation Engine
       |  (subtotals, taxes, discounts, totals)
       v
  Template Binding
       |  (merge data with HTML template)
       v
  HTML Rendering (simple_template)
       |
       v
  PDF Generation (simple_pdf)
       |
       v
  Output (PDF files + manifest)
```

### Configuration Schema

```json
{
  "invoice_forge": {
    "defaults": {
      "currency": "USD",
      "locale": "en-US",
      "template": "professional",
      "page_size": "Letter",
      "orientation": "portrait"
    },
    "paths": {
      "templates": "./templates",
      "output": "./invoices",
      "temp": "./temp"
    },
    "company": {
      "name": "Your Company Name",
      "address": ["123 Main Street", "City, State 12345"],
      "phone": "+1 (555) 123-4567",
      "email": "billing@example.com",
      "logo": "./assets/logo.png"
    },
    "tax": {
      "default_rate": 0.0,
      "rates": {
        "standard": 0.20,
        "reduced": 0.05,
        "zero": 0.0
      }
    },
    "numbering": {
      "prefix": "INV-",
      "padding": 6,
      "next": 1
    },
    "pdf": {
      "engine": "wkhtmltopdf",
      "margins": {
        "top": "20mm",
        "bottom": "20mm",
        "left": "15mm",
        "right": "15mm"
      }
    },
    "parallel": {
      "workers": 4,
      "batch_size": 100
    }
  }
}
```

### Input Data Schema (JSON)

```json
{
  "invoices": [
    {
      "invoice_number": "INV-000001",
      "date": "2026-01-24",
      "due_date": "2026-02-23",
      "customer": {
        "name": "Acme Corporation",
        "address": ["456 Oak Avenue", "Suite 100", "Business City, BC 54321"],
        "email": "accounts@acme.com",
        "tax_id": "12-3456789"
      },
      "currency": "USD",
      "line_items": [
        {
          "description": "Professional Services - January 2026",
          "quantity": 40,
          "unit": "hours",
          "unit_price": 150.00,
          "tax_code": "standard"
        },
        {
          "description": "Software License",
          "quantity": 1,
          "unit_price": 499.00,
          "tax_code": "zero"
        }
      ],
      "discount": {
        "type": "percentage",
        "value": 10,
        "reason": "Volume discount"
      },
      "notes": "Payment terms: Net 30",
      "payment_info": {
        "bank_name": "First National Bank",
        "account": "****1234",
        "routing": "****5678"
      }
    }
  ]
}
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| Invalid input file | Abort with details | "Error: Cannot parse input file: {path}. {details}" |
| Missing required field | Skip invoice, log error | "Warning: Invoice {id} missing required field '{field}'" |
| Invalid currency | Use default, warn | "Warning: Unknown currency '{code}', using default" |
| Template not found | Abort | "Error: Template '{name}' not found in {path}" |
| PDF generation failure | Skip invoice, log error | "Error: PDF generation failed for {id}: {reason}" |
| Disk write failure | Abort | "Error: Cannot write to {path}: {reason}" |
| Calculation error | Skip invoice, log error | "Error: Calculation failed for {id}: {details}" |

## GUI/TUI Future Path

**CLI foundation enables:**
- TUI for interactive invoice preview and template selection using simple_tui
- Template designer GUI that generates HTML templates
- Web dashboard for invoice management and batch scheduling
- API server mode for integration with web applications

**Shared components between CLI/GUI:**
- INVOICE_MODEL and all business logic classes remain unchanged
- INVOICE_TEMPLATE_MANAGER works for both CLI and GUI rendering
- INVOICE_CALCULATOR provides consistent financial calculations
- Configuration loading and validation shared across interfaces

**What would change for TUI:**
- Add INVOICE_TUI_APP class using simple_tui
- Interactive template browser with preview
- Real-time validation feedback
- Progress display for batch operations

**What would change for GUI:**
- Add INVOICE_GUI_APP class (future simple_gui if created)
- Template designer with WYSIWYG editing
- Customer database integration
- Invoice history and search
