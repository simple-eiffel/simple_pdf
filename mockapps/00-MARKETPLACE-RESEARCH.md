# Marketplace Research: simple_pdf

**Generated:** 2026-01-24
**Library:** simple_pdf
**Status:** Production

## Library Profile

### Core Capabilities

| Capability | Description | Business Value |
|------------|-------------|----------------|
| HTML-to-PDF Conversion | Convert HTML strings, files, or URLs to PDF | Generate branded documents from templates |
| Multi-Engine Support | wkhtmltopdf (bundled) and Chrome/Edge | Flexibility for different CSS/rendering needs |
| Page Configuration | Size (A4/Letter/Legal), orientation, margins | Professional document formatting |
| Text Extraction | Extract text from existing PDFs via pdftotext | PDF content analysis and indexing |
| Base64 Output | Return PDF as Base64-encoded string | Embed in web responses and APIs |
| Fluent API | Chainable configuration methods | Rapid development and clean code |

### API Surface

| Feature | Type | Use Case |
|---------|------|----------|
| `from_html` | Command | Convert HTML string to PDF |
| `from_file` | Command | Convert HTML file to PDF |
| `from_url` | Command | Capture web page as PDF |
| `page/portrait/landscape` | Fluent | Configure page settings |
| `margin_all/margins` | Fluent | Set document margins |
| `save_to_file` | Command | Write PDF to disk |
| `as_base64` | Query | Get PDF as Base64 string |
| `extract_text` | Query | Get text content from PDF |
| `extract_pages` | Query | Get text from page range |

### Existing Dependencies

| simple_* Library | Purpose in this library |
|------------------|------------------------|
| simple_json | JSON configuration support |
| simple_uuid | Unique temp file naming |
| simple_base64 | Base64 encoding for output |
| simple_process | External tool execution |

### Integration Points

- **Input formats:** HTML strings, HTML files, URLs
- **Output formats:** PDF files, Base64-encoded strings, binary content
- **Data flow:** HTML/URL -> Engine (wkhtmltopdf/Chrome) -> PDF binary -> File/Base64

---

## Marketplace Analysis

### Industry Applications

| Industry | Application | Pain Point Solved |
|----------|-------------|-------------------|
| Finance/Accounting | Invoice/receipt generation | Manual PDF creation is slow, error-prone |
| Legal | Contract document automation | Hours spent formatting legal documents |
| E-commerce | Order confirmations, packing slips | Need automated customer-facing PDFs |
| Healthcare | Patient reports, lab results | Compliance-ready PDF archiving |
| Insurance | Policy documents, claims | High-volume document generation |
| Education | Certificates, transcripts | Batch document creation |
| Consulting | Proposals, reports | Professional branded documents |
| Government | Forms, notices, archiving | Long-term preservation requirements |

### Commercial Products (Competitors/Inspirations)

| Product | Price Point | Key Features | Gap We Could Fill |
|---------|-------------|--------------|-------------------|
| [CraftMyPDF](https://craftmypdf.com/) | $29-199/mo | Template editor, Zapier integration | CLI-first, self-hosted, no SaaS lock-in |
| [DocRaptor](https://docraptor.com/) | $15-299/mo | PrinceXML engine, accessibility | Open source alternative, local execution |
| [PDF Generator API](https://pdfgeneratorapi.com/) | $49-499/mo | WYSIWYG editor, high-volume | No cloud dependency, Eiffel ecosystem |
| [Carbone](https://carbone.io) | Open source | Template-based, multi-format | Eiffel-native, DBC contracts |
| [Docmosis](https://www.docmosis.com/) | Enterprise | Self-hosted option, templates | Simpler API, smaller footprint |
| [maaslalani/invoice](https://github.com/maaslalani/invoice) | Free | CLI invoice generator | Enterprise features, ecosystem integration |

### Workflow Integration Points

| Workflow | Where This Library Fits | Value Added |
|----------|-------------------------|-------------|
| Order-to-Cash | Invoice generation step | Automated PDF invoices from order data |
| Quote-to-Contract | Document generation | Generate contracts from templates |
| Report Automation | Output rendering | Convert HTML reports to PDF |
| Web Archiving | Page preservation | Capture URLs as archival PDFs |
| Compliance | Audit trail documents | Generate immutable PDF records |
| Marketing | Collateral generation | Branded materials from templates |

### Target User Personas

| Persona | Role | Need | Willingness to Pay |
|---------|------|------|-------------------|
| DevOps Dave | DevOps Engineer | Batch document generation pipeline | HIGH - saves infrastructure costs |
| Accountant Amy | Finance Manager | Automated invoice/receipt system | HIGH - saves hours weekly |
| Legal Lou | Contract Administrator | Document assembly from templates | HIGH - reduces legal costs |
| Archivist Anna | Records Manager | Web page preservation to PDF | MEDIUM - compliance requirement |
| Developer Dan | Backend Developer | PDF generation in Eiffel stack | MEDIUM - ecosystem integration |

---

## Mock App Candidates

### Candidate 1: Invoice Forge

**One-liner:** Batch invoice/receipt PDF generator with template support and multi-currency handling

**Target market:** Small-to-medium businesses, freelancers, accounting departments

**Revenue model:** One-time license ($299), Enterprise support ($999/yr)

**Ecosystem leverage:**
- simple_pdf (core PDF generation)
- simple_json (invoice data input)
- simple_csv (bulk data import)
- simple_template (HTML template rendering)
- simple_validation (data validation)
- simple_cli (command-line interface)

**CLI-first value:**
- Batch processing thousands of invoices overnight
- Integration with cron/scheduler for recurring invoices
- Pipeline integration (stdin/stdout for data)
- Scriptable for DevOps automation

**GUI/TUI potential:**
- TUI for template preview and selection
- GUI for template designer
- Web dashboard for invoice management

**Viability:** HIGH - Direct competitor analysis shows $29-499/mo SaaS pricing; CLI self-hosted alternative fills market gap

---

### Candidate 2: Doc Archiver

**One-liner:** Enterprise web archiving and document preservation tool with PDF/A compliance

**Target market:** Legal firms, government agencies, compliance teams, research institutions

**Revenue model:** Per-seat license ($149/seat), Enterprise ($2999/yr unlimited)

**Ecosystem leverage:**
- simple_pdf (URL-to-PDF conversion)
- simple_http (URL fetching and validation)
- simple_sql (archive metadata storage)
- simple_hash (document integrity checksums)
- simple_datetime (timestamp management)
- simple_cli (command-line interface)
- simple_json (metadata export)

**CLI-first value:**
- Scheduled archiving of URL lists
- Batch processing of web pages
- Chain with wget/curl for link discovery
- Integration with compliance workflows

**GUI/TUI potential:**
- TUI for archive browsing
- GUI for visual archive management
- Web interface for search/retrieval

**Viability:** HIGH - ArchiveBox (open source) has 20K+ GitHub stars; enterprise need for self-hosted, auditable archiving

---

### Candidate 3: Report Engine

**One-liner:** Data-driven PDF report generator with charts, tables, and template composition

**Target market:** Business intelligence teams, data analysts, SaaS platforms needing report exports

**Revenue model:** Developer license ($499), OEM license ($4999/yr)

**Ecosystem leverage:**
- simple_pdf (PDF generation)
- simple_chart (SVG chart generation for embedding)
- simple_json (data input)
- simple_csv (tabular data import)
- simple_template (report templates)
- simple_markdown (markdown-to-HTML conversion)
- simple_cli (command-line interface)

**CLI-first value:**
- Scheduled report generation (daily/weekly/monthly)
- Pipeline: database -> JSON -> report -> email
- Integration with BI tools and ETL pipelines
- Headless server deployment

**GUI/TUI potential:**
- TUI for report preview
- GUI for template designer
- Web dashboard for report scheduling

**Viability:** HIGH - Power BI Report Builder adoption shows demand; gap exists for self-hosted, embeddable solutions

---

## Selection Rationale

These three Mock Apps were selected based on:

1. **Market Validation** - Each addresses a proven market with commercial competitors charging $29-499/month
2. **Ecosystem Synergy** - Each leverages 5+ simple_* libraries, demonstrating ecosystem integration
3. **CLI-First Architecture** - All three are batch/automation oriented, perfect for CLI
4. **Revenue Potential** - Enterprise pricing models are established ($149-4999/yr)
5. **Technical Feasibility** - simple_pdf already provides core capabilities; apps add orchestration

**Alternative concepts considered but not selected:**
- Certificate Generator (too narrow, subset of Invoice Forge)
- Email-to-PDF (requires email integration beyond scope)
- Form Filler (requires PDF manipulation, out of scope for simple_pdf)

---

## Sources

- [CraftMyPDF - Best PDF Generation APIs](https://craftmypdf.com/blog/best-pdf-generation-apis/)
- [DocRaptor - HTML to PDF API](https://docraptor.com/)
- [PDF Generator API](https://pdfgeneratorapi.com/)
- [Carbone - Open Source Report Generator](https://carbone.io)
- [Docmosis - Document Generation](https://www.docmosis.com/)
- [maaslalani/invoice - CLI Invoice Generator](https://github.com/maaslalani/invoice)
- [ArchiveBox - Self-hosted Web Archiving](https://archivebox.io/)
- [Power BI Report Builder](https://www.phdata.io/blog/what-is-power-bi-report-builder/)
- [Expensify - Expense Tracking](https://www.expensify.com/)
- [Ironclad - Contract Automation](https://ironcladapp.com/)
