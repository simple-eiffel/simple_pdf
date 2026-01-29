# Doc Archiver

## Executive Summary

Doc Archiver is an enterprise-grade web archiving and document preservation tool that captures web pages and HTML documents as PDF archives with full metadata, integrity checksums, and audit trails. Designed for legal firms, government agencies, compliance teams, and research institutions, it provides self-hosted, auditable document preservation that meets regulatory requirements.

Unlike cloud-based archiving services that raise data sovereignty concerns, Doc Archiver runs entirely on-premises, stores archives locally or on network storage, and provides cryptographic proof of capture time and document integrity. The tool supports scheduled archiving, URL list processing, and integration with compliance workflows.

Doc Archiver leverages the simple_* ecosystem extensively: simple_pdf for URL-to-PDF conversion, simple_http for URL validation, simple_sql for metadata storage, simple_hash for integrity checksums, and simple_datetime for precise timestamps.

## Problem Statement

**The problem:** Organizations need to preserve web content for legal discovery, regulatory compliance, research citation, or historical record. Web pages change or disappear; screenshots lack text searchability; manual saving is inconsistent and undocumented.

**Current solutions:**
- Archive.org (Wayback Machine) - Public, no control over timing, no legal standing
- ArchiveBox - Requires Docker, complex setup, no enterprise support
- Screenshot tools - Not searchable, no metadata, no chain of custody
- Browser save - Inconsistent, no automation, no integrity proof
- Enterprise solutions (Preservica) - $10K+ annual cost, complex implementation

**Our approach:** A CLI-first tool that accepts URLs or URL lists, captures pages as searchable PDFs, records comprehensive metadata (capture time, SHA-256 hash, source URL, HTTP headers), stores in SQLite database, and provides verification commands to prove document authenticity. Runs locally, no cloud dependency, court-admissible output.

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| Primary | Legal teams preserving evidence | Chain of custody, court admissibility, batch processing |
| Primary | Compliance officers | Regulatory archive requirements, audit trails |
| Secondary | Research institutions | Citation preservation, reproducibility |
| Secondary | Government agencies | Records management, FOIA compliance |
| Secondary | IT departments | Website backup, disaster recovery |

## Value Proposition

**For** legal, compliance, and research professionals
**Who** need to preserve web content with provable authenticity
**Doc Archiver** provides self-hosted PDF archiving with cryptographic integrity verification
**Unlike** cloud archiving services with data sovereignty concerns
**We** offer on-premises operation, full audit trails, and court-admissible output

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| Professional | Single user, unlimited archives | $149 one-time |
| Team | Up to 10 users, shared database | $499 one-time |
| Enterprise | Unlimited users, priority support, API access | $2,999/year |
| Government | Special licensing for public sector | Custom pricing |

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Capture success rate | >95% | Successful captures / attempted |
| Capture time | <10 seconds per page | Average capture duration |
| Database query time | <100ms | Metadata lookup speed |
| Hash verification | 100% match rate | Verification success on valid archives |
| User adoption | <30 min to first archive | Time from install to working system |
