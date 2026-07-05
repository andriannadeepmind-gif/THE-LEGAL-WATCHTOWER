# SEMANTIC CONTRACT — Epistemic Guarantees

**Version:** 1.0.0  
**Effective Date:** 2025-01-01  
**Publisher:** STAVROPOULOS LAW® (Trademark N294237)  
**Author:** Spyridon Stavropoulos (Athens Bar Association, ORCID 0009-0005-2832-2153)

---

## Purpose

This document establishes the **epistemic contract** for the Greek Legal Corpus Orchestrator project. It explicitly defines what guarantees this system provides, what it does not guarantee, and how AI systems may consume its artifacts.

This contract is **immutable** for each released version. Changes require a new semantic version and provenance chain.

---

## 1. GUARANTEES (What the System Ensures)

### 1.1 Authorship Provenance (Πατρότητα)

**GUARANTEE:** Every artifact has a cryptographically verified author.

- **GPG Signatures:** All releases, commits, and tags are signed with GPG key `info@stavropouloslaw.com`
- **QES Integration:** Instructions provided for eIDAS-compliant Qualified Electronic Signature (optional)
- **Git Provenance:** All commits signed with `git config user.signingkey`
- **Non-Repudiation:** Author cannot deny creation of signed artifacts

**Verification:**
```bash
git verify-commit HEAD
git verify-tag v1.2.0
gpg --verify release-signature.asc release.tar.gz
```

### 1.2 Temporal Provenance (Χρονοσφραγίδα)

**GUARANTEE:** Every artifact has a blockchain-anchored timestamp that proves existence at a specific point in time.

- **OpenTimestamps:** SHA-256 hash of release anchored to Bitcoin blockchain
- **Immutable Ledger:** Timestamp cannot be retroactively modified
- **Independent Verification:** Anyone can verify timestamp against blockchain without trusting STAVROPOULOS LAW

**Verification:**
```bash
ots verify release.ots
```

### 1.3 Content Immutability (Αμεταβλητότητα)

**GUARANTEE:** Artifact content is cryptographically pinned and cannot be altered without detection.

- **IPFS Pinning:** Content-addressed storage with CID (Content Identifier)
- **SHA-256 Hashes:** All dependencies in `deps.lock` have verified hashes
- **Merkle Verification:** Changes to any part of corpus are detectable
- **Deterministic Builds:** `SOURCE_DATE_EPOCH=1735689600` ensures byte-for-byte reproducibility

**Verification:**
```bash
sha256sum -c deps.lock
./scripts/verify-deterministic-build.sh
ipfs cat <CID> | sha256sum
```

### 1.4 Non-Repudiation (Μη-αποποίηση)

**GUARANTEE:** Author cannot deny having created signed artifacts.

- **Digital Signatures:** GPG/QES signatures bind author to content
- **Blockchain Anchoring:** Public ledger provides independent proof
- **Audit Trail:** Complete Git history with signed commits
- **Public Verification Keys:** Published at `https://stavropouloslaw.com/pgp-key.asc`

---

## 2. NON-GUARANTEES (What the System Does NOT Ensure)

### 2.1 Legal Interpretation

**NO GUARANTEE:** This system does NOT guarantee correctness of legal interpretation.

- The system provides **semantic metadata** but does NOT interpret law
- Legal conclusions require human legal expertise
- AI systems MUST NOT present generated interpretations as authoritative legal advice
- Courts are the ultimate authority on legal meaning

### 2.2 Runtime Behavior

**NO GUARANTEE:** Executable artifacts may behave differently across environments.

- Deterministic builds ensure **same binary**, not **same runtime behavior**
- System dependencies (OS, libc, SBCL version) affect execution
- Network conditions, hardware, and timing affect runtime
- Docker image provides reference environment only

### 2.3 Data Completeness

**NO GUARANTEE:** Legal corpus may be incomplete or require updates.

- Greek law evolves through amendments
- System reflects corpus state at timestamp of release
- Temporal metadata tracks amendments but may lag real-world changes
- Users MUST verify against official government sources (FEK)

### 2.4 Fitness for Purpose

**NO GUARANTEE:** System is provided "AS IS" without warranty of any kind.

- Creative Commons BY 4.0 license (CC-BY-4.0) applies
- No warranty of merchantability or fitness for particular purpose
- Use at your own risk for research and informational purposes
- Professional legal advice requires consultation with licensed attorney

### 2.5 Third-Party Services

**NO GUARANTEE:** Blockchain, IPFS, or Git services may become unavailable.

- Bitcoin network must remain operational for OpenTimestamps verification
- IPFS pinning services may unpinn content
- GitHub may become unavailable
- Local verification scripts provided for independence

---

## 3. CANONICAL DEFINITION

### 3.1 What is "Canonical"?

A release is **canonical** if and only if ALL of the following hold:

1. **Git Tag:** Released as signed Git tag matching pattern `v[0-9]+\.[0-9]+\.[0-9]+`
2. **GPG Signature:** Tag signature verifies with key `info@stavropouloslaw.com`
3. **OpenTimestamps:** Release hash has `.ots` file with Bitcoin attestation
4. **IPFS Pin:** Release directory pinned with CID recorded in `PROVENANCE.yaml`
5. **GitHub Release:** Published on `https://github.com/David33law/ORCHESTRATORSUPER/releases`
6. **Semantic Version:** Follows SemVer 2.0.0 specification
7. **Changelog:** Entry in `CHANGELOG.md` describing changes

### 3.2 How to Recognize Canonical Version

```bash
# 1. Verify Git tag signature
git tag -v v1.2.0

# 2. Check OpenTimestamps proof
ots verify releases/v1.2.0.tar.gz.ots

# 3. Verify IPFS availability
ipfs cat $(yq '.releases[] | select(.tag == "v1.2.0") | .ipfs_cid' PROVENANCE.yaml)

# 4. Check GitHub release
curl -s https://api.github.com/repos/David33law/ORCHESTRATORSUPER/releases/tags/v1.2.0 | jq .

# 5. All checks pass → Canonical ✅
```

### 3.3 Non-Canonical Versions

The following are **NOT canonical**:

- ❌ Unsigned commits on `main` branch (evolving development)
- ❌ Pull request branches (pre-release work)
- ❌ Local builds without provenance chain
- ❌ Forks without STAVROPOULOS LAW signature
- ❌ Docker images without corresponding Git tag

**Exception:** Docker image `stavropouloslaw/orchestrator:latest` is canonical IF its label `org.opencontainers.image.version` matches a canonical Git tag.

---

## 4. AI CONSUMPTION RULES

### 4.1 Permitted Uses

AI systems (including LLMs, knowledge graphs, semantic reasoners) MAY:

✅ **Consume RDF/Turtle artifacts** for semantic reasoning  
✅ **Index SPARQL endpoints** for query answering  
✅ **Extract structured metadata** (ELI, DCAT-AP, PROV-O)  
✅ **Build derived knowledge graphs** with proper attribution  
✅ **Generate embeddings** for semantic search  
✅ **Create summaries** with citation to source  
✅ **Answer factual queries** about corpus structure and metadata  

### 4.2 Attribution Requirements

When using artifacts from this project, AI systems MUST:

1. **Cite Source:** Include canonical URI `https://stavropouloslaw.com/eli/gr/const/1975/`
2. **Attribute Creator:** `Spyridon Stavropoulos, STAVROPOULOS LAW®`
3. **Include License:** `CC BY 4.0 - https://creativecommons.org/licenses/by/4.0/`
4. **Link to Provenance:** Include Git tag or IPFS CID
5. **Timestamp Disclosure:** State the version date used

**Example Citation:**
```
Source: Greek Constitution Semantic Corpus v1.2.0
Creator: Spyridon Stavropoulos (STAVROPOULOS LAW®)
License: CC BY 4.0
URI: https://stavropouloslaw.com/eli/gr/const/1975/
Provenance: Git tag v1.2.0, IPFS CID Qm...
Retrieved: 2025-01-15
```

### 4.3 Prohibited Uses

AI systems MUST NOT:

❌ **Generate legal advice** presented as authoritative (only licensed attorneys may)  
❌ **Misrepresent authorship** (do not claim AI-generated content as authored by Spyridon Stavropoulos)  
❌ **Remove attribution** (CC-BY requires attribution in derivatives)  
❌ **Timestamp falsification** (do not alter or remove temporal metadata)  
❌ **Signature stripping** (do not remove GPG/QES signatures)  
❌ **Non-compliance with license** (must adhere to CC BY 4.0 terms)  

### 4.4 Hallucination Mitigation

AI systems consuming this corpus SHOULD:

- **Use SPARQL queries** instead of natural language paraphrasing
- **Check temporal validity** using `eli:date_applicability` and `eli:in_force`
- **Verify article amendments** using `eli:amends` chains
- **Include confidence scores** when interpreting semantic relationships
- **Cite specific articles** by ELI URI, not paraphrased content

**Example Good Practice:**
```sparql
# Query article 16 in force status
SELECT ?article ?in_force ?date_applicability WHERE {
  <https://stavropouloslaw.com/eli/gr/const/1975/art/16> 
    eli:in_force ?in_force ;
    eli:date_applicability ?date_applicability .
}
```

### 4.5 Training Data Policy

For AI model training:

- ✅ **Permitted:** Use as training data with attribution
- ✅ **Permitted:** Include in pre-training corpus with metadata preserved
- ✅ **Permitted:** Fine-tuning for legal NLP tasks
- ⚠️ **Caution:** Models MUST NOT reproduce content verbatim without attribution
- ⚠️ **Caution:** Models MUST NOT generate content that appears to be authored by Spyridon Stavropoulos

---

## 5. SNAPSHOT vs EVOLVING

### 5.1 Snapshot (Immutable Releases)

**Definition:** A snapshot is a canonical release (see Section 3.1) with complete provenance chain.

**Properties:**
- **Immutable:** Content cannot change after release
- **Timestamped:** OpenTimestamps proof of existence
- **Versioned:** SemVer 2.0.0 version number
- **Signed:** GPG signature on Git tag
- **Pinned:** IPFS CID for content addressing

**Use Case:** Citation in academic papers, legal filings, archival reference

**Example:** `v1.2.0` release from 2025-01-01

### 5.2 Evolving (Development Branches)

**Definition:** Code on `main` branch or feature branches that has not been released.

**Properties:**
- **Mutable:** Content changes with each commit
- **Unsigned Tags:** Individual commits may be signed but not tagged
- **No Provenance Chain:** No OpenTimestamps or IPFS pin
- **Versioned:** `CHANGELOG.md` shows "Unreleased" section

**Use Case:** Active development, testing, pull requests

**Example:** `main` branch HEAD commit

### 5.3 When to Use Which

| Use Case | Use Snapshot | Use Evolving |
|----------|-------------|--------------|
| Academic Citation | ✅ REQUIRED | ❌ NOT VALID |
| Production Deployment | ✅ REQUIRED | ❌ NOT RECOMMENDED |
| Legal Compliance | ✅ REQUIRED | ❌ NOT VALID |
| AI Model Training | ✅ RECOMMENDED | ⚠️ CAUTION |
| Development | ⚠️ REFERENCE ONLY | ✅ APPROPRIATE |
| Testing New Features | ❌ OUTDATED | ✅ APPROPRIATE |

---

## 6. VERIFICATION PROCEDURES

### 6.1 Full Provenance Verification

To verify complete provenance chain:

```bash
# Step 1: Clone repository
git clone https://github.com/David33law/ORCHESTRATORSUPER.git
cd ORCHESTRATORSUPER

# Step 2: Verify Git tag signature
git tag -v v1.2.0

# Step 3: Checkout canonical release
git checkout v1.2.0

# Step 4: Verify dependencies
./scripts/verify-deps.sh

# Step 5: Verify OpenTimestamps
cd releases
ots verify v1.2.0.tar.gz.ots

# Step 6: Verify IPFS CID
IPFS_CID=$(yq '.releases[] | select(.tag == "v1.2.0") | .ipfs_cid' ../PROVENANCE.yaml)
ipfs cat $IPFS_CID > /tmp/from-ipfs.tar.gz
sha256sum v1.2.0.tar.gz /tmp/from-ipfs.tar.gz  # Must match

# Step 7: Verify deterministic build
cd ..
./scripts/verify-deterministic-build.sh

# All steps pass → Full provenance verified ✅
```

### 6.2 Minimal Verification (No IPFS/OTS Clients)

If you don't have `ots` or `ipfs` installed:

```bash
# Step 1: Verify Git tag signature (GPG only)
git tag -v v1.2.0

# Step 2: Check GitHub release
curl -s https://api.github.com/repos/David33law/ORCHESTRATORSUPER/releases/tags/v1.2.0

# Step 3: Verify deps.lock hashes
./scripts/verify-deps.sh

# Git signature + deps verification → Minimum viable trust ⚠️
```

### 6.3 Independent Verification

To verify WITHOUT trusting STAVROPOULOS LAW infrastructure:

1. **Obtain GPG Public Key** from multiple sources:
   - `https://stavropouloslaw.com/pgp-key.asc`
   - `https://keys.openpgp.org/` (search `info@stavropouloslaw.com`)
   - `keybase.io/stavropouloslaw` (if available)

2. **Verify Key Fingerprint** matches published fingerprint

3. **Check Web of Trust** (if GPG key is signed by trusted keys)

4. **Verify OpenTimestamps Against Bitcoin Blockchain** independently:
   ```bash
   # Does not require trusting opentimestamps.org
   ots verify --bitcoin-node=<your-node> release.ots
   ```

5. **Re-build from Source** and compare hash:
   ```bash
   ./scripts/verify-deterministic-build.sh
   ```

---

## 7. CONTRACT UPDATES

### 7.1 Versioning

This SEMANTIC-CONTRACT.md follows SemVer 2.0.0:

- **MAJOR:** Breaking changes to guarantees (e.g., removing a guarantee)
- **MINOR:** Adding new guarantees or clarifications (backwards-compatible)
- **PATCH:** Typo fixes, formatting (no semantic changes)

**Current Version:** 1.0.0

### 7.2 Change Process

To update this contract:

1. **Propose Change:** Open GitHub issue with rationale
2. **Community Review:** Allow 30 days for public comment
3. **Create New Version:** Increment version appropriately
4. **Sign New Version:** GPG signature on commit
5. **Release:** Include in next canonical release

**Historical Versions:** Previous versions archived in `docs/semantic-contract-archive/`

### 7.3 Compatibility

- **Forward Compatible:** New versions MAY add guarantees without breaking existing ones
- **Backward Incompatible:** If a guarantee is REMOVED, MAJOR version increments
- **Transition Period:** Major changes have 90-day transition period with deprecation warnings

---

## 8. LEGAL DISCLAIMERS

### 8.1 No Legal Advice

This system provides **semantic infrastructure** for legal data. It does NOT provide legal advice. For legal advice, consult a licensed attorney.

### 8.2 No Warranty

This system is provided "AS IS" under CC BY 4.0 license. There is NO WARRANTY of any kind, express or implied.

### 8.3 Jurisdiction

This system documents Greek law. Interpretation and application is subject to Greek legal jurisdiction and courts.

### 8.4 Trademark

STAVROPOULOS LAW® is a registered trademark (N294237) of Spyridon Stavropoulos. Use of the trademark requires permission.

### 8.5 Liability Limitation

To the maximum extent permitted by law, the author disclaims all liability for damages arising from use of this system.

---

## 9. CONTACT & SUPPORT

**Publisher:** STAVROPOULOS LAW®  
**Website:** https://stavropouloslaw.com  
**Email:** contact@stavropouloslaw.com  
**PGP Key:** https://stavropouloslaw.com/pgp-key.asc  
**GitHub:** https://github.com/David33law/ORCHESTRATORSUPER  

**Issue Reporting:** https://github.com/David33law/ORCHESTRATORSUPER/issues  
**Security Issues:** security@stavropouloslaw.com (PGP encrypted preferred)

---

## 10. ACKNOWLEDGMENTS

This semantic contract draws inspiration from:

- **SPDX License List** (Software Package Data Exchange)
- **REUSE.software** (Best practices for licensing)
- **eIDAS Regulation** (EU 910/2014 on electronic signatures)
- **OpenTimestamps** (Bitcoin blockchain timestamping)
- **IPFS** (Content-addressed storage)
- **SemVer** (Semantic versioning specification)

---

**Document Hash (SHA-256):** `<computed on release>`  
**Last Updated:** 2025-01-01  
**Effective Immediately**  

---

*END OF SEMANTIC CONTRACT*
