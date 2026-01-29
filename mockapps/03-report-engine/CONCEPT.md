# Report Engine

## Executive Summary

Report Engine is a data-driven PDF report generator that transforms structured data (JSON, CSV, database queries) into professional, print-ready PDF reports with charts, tables, and rich formatting. Designed for business intelligence teams, data analysts, and SaaS platforms, it provides a CLI-first approach to scheduled report generation that integrates with existing data pipelines.

Unlike Power BI or Crystal Reports which require expensive licenses and complex setup, Report Engine operates as a self-hosted CLI tool that reads data from standard formats, applies HTML/CSS templates, embeds SVG charts from simple_chart, and outputs publication-quality PDF documents. Perfect for headless server deployment, cron-scheduled reports, and integration with ETL workflows.

Report Engine showcases the power of the simple_* ecosystem by combining simple_pdf for rendering, simple_chart for data visualization, simple_template for template composition, simple_json/simple_csv for data input, and simple_markdown for text formatting.

## Problem Statement

**The problem:** Organizations need to generate professional reports from data regularly - daily dashboards, weekly summaries, monthly analytics. Current solutions require expensive licenses (Power BI Pro: $10/user/month), cloud dependency, or significant development effort.

**Current solutions:**
- Power BI Report Builder - Requires Microsoft stack, cloud connectivity
- Crystal Reports - Legacy, expensive, complex
- Jasper Reports - Java-based, heavy infrastructure
- Custom development - Expensive, time-consuming
- Manual Excel/Word - Not scalable, inconsistent

**Our approach:** A CLI tool that reads data from JSON/CSV/SQL, applies HTML templates with embedded charts, and generates PDF reports. Runs on any server with cron/scheduler integration. Template-driven so non-developers can modify report layouts. Chart integration via simple_chart produces professional visualizations.

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| Primary | Data analysts generating recurring reports | Scheduled automation, data source flexibility |
| Primary | SaaS platforms embedding report functionality | API-like CLI, embedding capability, white-label |
| Secondary | Business intelligence teams | Dashboard-to-PDF, chart embedding |
| Secondary | DevOps engineers building report pipelines | CLI integration, scriptability, reliability |

## Value Proposition

**For** data teams and SaaS platforms
**Who** need automated professional PDF report generation
**Report Engine** provides CLI-first data-to-PDF transformation with charts and templates
**Unlike** enterprise BI tools requiring licenses and cloud connectivity
**We** offer self-hosted, template-driven report generation with ecosystem integration

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| Developer License | Single developer, unlimited reports | $499 one-time |
| Team License | Up to 10 users, same organization | $1,499 one-time |
| OEM License | Embed in third-party products, remove branding | $4,999/year |
| Enterprise | Unlimited users, priority support, custom templates | $9,999/year |

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Report generation time | <5 seconds for typical report | Benchmark with sample data |
| Chart rendering | <500ms per chart | Performance profiling |
| Template flexibility | 90% of layouts achievable | User testing |
| Data source support | JSON, CSV, SQL covered | Feature checklist |
| User satisfaction | >4.5/5 | Post-purchase survey |
