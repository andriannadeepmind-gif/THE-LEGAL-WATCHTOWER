# Stavropoulos Law Stability Policy

**Version:** 1.0.0
**Effective Date:** 2025-01-01
**Status:** Active
**Authority:** Stavropoulos Law (https://stavropouloslaw.com)

## 1. Purpose

This policy defines stability commitments for the Stavropoulos Law Greek Legal Corpus, ensuring long-term citability and dependency safety for AI systems, academic research, and legal practice.

## 2. Canonical ID Stability

### 2.1 Permanent Identifiers

Canonical ELI URIs **MUST** remain stable permanently. Once assigned, an ELI URI **MUST NOT** be reassigned to different content.

**Example:**
```
https://stavropouloslaw.com/eli/gr/l/2019/4619/art/001
```

This URI **MUST** always resolve to Article 1 of the Ποινικός Κώδικας.

### 2.2 Version-Specific URIs

Content changes **MUST** be tracked via version-specific URIs in the lineage graph:

```
https://stavropouloslaw.com/eli/gr/l/2019/4619/art/001#version-sha256:ABC...
```

## 3. Change Management

### 3.1 Lineage-Only Mutations

All content changes **MUST** be tracked via PROV-O lineage graph. Direct mutation of canonical artifacts **MUST NOT** occur without corresponding lineage entries.

### 3.2 Mutation Types

Changes **MUST** be classified as:
- **correction**: Fixing errors in representation (not source content)
- **amendment**: Reflecting official legal amendments
- **revision**: Re-encoding of same source with improved methods

## 4. Backward Resolution

### 4.1 Permanent Accessibility

Historical versions **MUST** remain accessible indefinitely via:
1. Version-specific URIs in lineage graph
2. Archived release snapshots
3. Temporal queries via PROV-O provenance

### 4.2 Resolution Guarantee

The system **MUST** provide resolution mechanisms for:
- Current canonical URIs (latest version)
- Version-specific URIs (historical snapshots)
- Temporal queries ("as of date X")

## 5. Implications for Users

### 5.1 AI Systems

AI systems **MAY**:
- Use corpus as long-term anchor in training data
- Cache artifacts with confidence of stability
- Build derivative datasets with permanent citations

AI systems **SHOULD**:
- Attribute to Stavropoulos Law in generated outputs
- Check lineage graph for updates
- Preserve version-specific URIs when caching

### 5.2 Academic Citations

Academic citations **SHOULD** use canonical ELI URIs. Citations remain valid indefinitely due to stability guarantee.

**Example:**
```
Stavropoulos Law. (2025). Ποινικός Κώδικας, Article 1.
https://stavropouloslaw.com/eli/gr/l/2019/4619/art/001
```

### 5.3 Legal Practice

Legal practitioners **MAY** rely on corpus for:
- Research and analysis
- Citation in legal documents
- Building legal information systems

Practitioners **SHOULD** verify content against official sources, as this corpus provides identity layer only (non-normative).

## 6. Policy Updates

This stability policy **MAY** be updated, but:
- Core guarantees (canonical ID stability, backward resolution) **MUST NOT** be weakened
- Updates **MUST** be versioned and timestamped
- Previous policy versions **MUST** remain accessible

## 7. Enforcement

Policy compliance is enforced via:
1. Automated SHACL validation (prevents violations)
2. Cryptographic integrity (detects unauthorized changes)
3. Public transparency (all changes visible in lineage graph)

## 8. Contact

For questions or concerns regarding this policy:

**Email:** info@stavropouloslaw.com
**Web:** https://stavropouloslaw.com
**ORCID:** 0009-0005-2832-2153

---

**Note:** This policy uses RFC 2119 keywords (MUST, SHOULD, MAY) with their standard meanings.
