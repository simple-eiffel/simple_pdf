# Mock Apps Summary: simple_pdf

## Generated: 2026-01-24

## Library Analyzed

- **Library:** simple_pdf
- **Core capability:** HTML-to-PDF conversion with multi-engine support (wkhtmltopdf, Chrome/Edge)
- **Ecosystem position:** SERVICE_API layer - foundational service for document generation workflows

## Mock Apps Designed

### 1. Invoice Forge

- **Purpose:** Batch invoice/receipt PDF generator with template support and multi-currency handling
- **Target:** Small-to-medium businesses, accounting departments, freelancers
- **Ecosystem:** simple_pdf, simple_json, simple_csv, simple_template, simple_validation, simple_cli
- **Pricing:** $299-999 (one-time/annual)
- **Status:** Design complete

### 2. Doc Archiver

- **Purpose:** Enterprise web archiving and document preservation tool with cryptographic integrity verification
- **Target:** Legal firms, government agencies, compliance teams, research institutions
- **Ecosystem:** simple_pdf, simple_http, simple_sql, simple_hash, simple_datetime, simple_json, simple_cli
- **Pricing:** $149-2999 (per-seat/annual)
- **Status:** Design complete

### 3. Report Engine

- **Purpose:** Data-driven PDF report generator with embedded charts, tables, and template composition
- **Target:** BI teams, data analysts, SaaS platforms needing report exports
- **Ecosystem:** simple_pdf, simple_chart, simple_json, simple_csv, simple_template, simple_cli
- **Pricing:** $499-9999 (developer/OEM)
- **Status:** Design complete

## Ecosystem Coverage

| simple_* Library | Used In |
|------------------|---------|
| simple_pdf | All 3 apps (core) |
| simple_json | All 3 apps (data I/O) |
| simple_cli | All 3 apps (CLI interface) |
| simple_template | Invoice Forge, Report Engine |
| simple_csv | Invoice Forge, Report Engine |
| simple_validation | Invoice Forge |
| simple_datetime | Doc Archiver, Report Engine |
| simple_hash | Doc Archiver |
| simple_sql | Doc Archiver |
| simple_http | Doc Archiver |
| simple_chart | Report Engine |
| simple_decimal | Invoice Forge, Report Engine |

**Total unique libraries leveraged:** 12

## Market Validation

Each Mock App addresses a proven market with existing commercial competitors:

| Mock App | Competitors | Price Points | Gap Filled |
|----------|-------------|--------------|------------|
| Invoice Forge | CraftMyPDF, Wave, FreshBooks | $29-499/mo SaaS | Self-hosted, one-time purchase |
| Doc Archiver | ArchiveBox, Preservica, Archive-It | $0-10K+/yr | Enterprise features, local control |
| Report Engine | Power BI, Crystal Reports, Jasper | $10+/user/mo | CLI-first, no license, ecosystem |

## Build Effort Summary

| Mock App | Estimated Effort | Phases |
|----------|------------------|--------|
| Invoice Forge | 10 days | 4 phases |
| Doc Archiver | 10 days | 4 phases |
| Report Engine | 10 days | 4 phases |

## Next Steps

1. **Select Mock App for implementation** - Based on Larry's priority and market demand
2. **Create app directory** - `d:\prod\invoice_forge\` (or chosen app)
3. **Initialize ECF configuration** - Based on ECOSYSTEM-MAP.md
4. **Implement Phase 1 (MVP)** - Following BUILD-PLAN.md tasks
5. **Run /eiffel.verify** - Contract validation during implementation

## Recommended Implementation Order

1. **Invoice Forge** - Most straightforward, validates template + PDF integration
2. **Report Engine** - Builds on Invoice Forge patterns, adds simple_chart
3. **Doc Archiver** - More complex infrastructure (SQL, HTTP, hashing)

## Files Generated

```
d:\prod\simple_pdf\mockapps\
    |-- 00-MARKETPLACE-RESEARCH.md
    |-- 01-invoice-forge\
    |   |-- CONCEPT.md
    |   |-- DESIGN.md
    |   |-- BUILD-PLAN.md
    |   +-- ECOSYSTEM-MAP.md
    |-- 02-doc-archiver\
    |   |-- CONCEPT.md
    |   |-- DESIGN.md
    |   |-- BUILD-PLAN.md
    |   +-- ECOSYSTEM-MAP.md
    |-- 03-report-engine\
    |   |-- CONCEPT.md
    |   |-- DESIGN.md
    |   |-- BUILD-PLAN.md
    |   +-- ECOSYSTEM-MAP.md
    +-- SUMMARY.md
```

---

## Sources

### PDF Generation Market Research
- [CraftMyPDF - Best PDF Generation APIs](https://craftmypdf.com/blog/best-pdf-generation-apis/)
- [DocRaptor - HTML to PDF API](https://docraptor.com/)
- [PDF Generator API](https://pdfgeneratorapi.com/)
- [Carbone - Open Source Report Generator](https://carbone.io)
- [Docmosis - Document Generation](https://www.docmosis.com/)

### Invoice Automation
- [maaslalani/invoice - CLI Invoice Generator](https://github.com/maaslalani/invoice)
- [Expensify - Expense Tracking](https://www.expensify.com/)
- [Zenceipt - Receipt Processing](https://zenceipt.com/)

### Web Archiving
- [ArchiveBox - Self-hosted Web Archiving](https://archivebox.io/)
- [Preservica - Enterprise Digital Preservation](https://preservica.com/)
- [ABBYY Document Archiving](https://www.abbyy.com/)

### Report Generation
- [Power BI Report Builder](https://www.phdata.io/blog/what-is-power-bi-report-builder/)
- [Piktochart - AI Report Generator](https://piktochart.com/ai-report-generator/)

### Contract Automation
- [Ironclad - Contract Lifecycle Management](https://ironcladapp.com/)
- [Gavel - Legal Document Automation](https://www.gavel.io/)
