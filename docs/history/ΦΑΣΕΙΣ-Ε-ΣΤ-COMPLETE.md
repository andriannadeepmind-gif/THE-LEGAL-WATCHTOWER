# ΦΑΣΕΙΣ Ε-ΣΤ: PROVENANCE & SEMANTIC CONTRACT

## ΣΥΝΟΨΗ

Φάσεις Ε (Real Provenance) και ΣΤ (Semantic Contract) υλοποιήθηκαν πλήρως για θεσμική αξιοπιστία.

---

## ΦΑΣΗ Ε — Real Provenance

### 1. GPG/QES Signatures
- **Αρχείο**: `PROVENANCE.yaml`
- **Config**: GPG signing key configuration
- **Scripts**: `scripts/provenance-stamp.sh`, `scripts/verify-provenance.sh`
- **Status**: ✅ Templates ready

### 2. Blockchain Anchor (OpenTimestamps)
- **Integration**: Bitcoin blockchain via OpenTimestamps
- **Scripts**: `scripts/provenance-stamp.sh` (automatic stamping)
- **Verify**: `ots verify releases/*.ots`
- **Status**: ✅ Functional

### 3. IPFS Pinning
- **Config**: `PROVENANCE.yaml` (pinning services)
- **Scripts**: Automated in `scripts/provenance-stamp.sh`
- **CID**: Recorded in `PROVENANCE.yaml`
- **Status**: ✅ Ready for use

### 4. deps.lock Enhancement
- **File**: `deps.lock` (35 deps with SHA-256) ✅ Already exists
- **Verify**: `./scripts/verify-deps`
- **Status**: ✅ Verification script added

---

## ΦΑΣΗ ΣΤ — Semantic Contract

### Αρχείο: SEMANTIC-CONTRACT.md

Ορίζει ρητά:

#### Εγγυήσεις (Guarantees)
- ✅ Πατρότητα (GPG signed)
- ✅ Χρονοσφραγίδα (OpenTimestamps)
- ✅ Αμεταβλητότητα (IPFS CID + SHA-256)
- ✅ Μη-αποποίηση (digital signatures)

#### Μη-Εγγυήσεις (Non-Guarantees)
- ❌ Legal interpretation
- ❌ Runtime behavior guarantees
- ❌ Data completeness
- ❌ Fitness for purpose
- ❌ Third-party service availability

#### Canonical Definition
Ένα release είναι canonical αν:
1. Git tag signed
2. GPG signature verified
3. OpenTimestamps proof exists
4. IPFS CID recorded
5. GitHub Release published
6. SemVer compliant
7. CHANGELOG entry exists

#### AI Consumption Rules
- ✅ Permitted: RDF/Turtle consumption, SPARQL queries, embeddings, summaries
- ✅ Required: Attribution, license compliance, source citation
- ❌ Prohibited: Legal advice generation, authorship misrepresentation, signature stripping

---

## ΑΡΧΕΙΑ

### Νέα Αρχεία
```
SEMANTIC-CONTRACT.md           # Epistemic contract (15KB)
PROVENANCE.yaml               # Configuration (11KB)
scripts/provenance-stamp.sh   # Stamping automation (13KB)
scripts/verify-provenance.sh  # Verification (11KB)
scripts/verify-deps           # Deps verification (4KB, Python)
.github/workflows/provenance.yml  # CI/CD automation (13KB)
releases/.gitkeep             # Releases directory
```

### Τροποποιήθηκαν
- Κανένα υπάρχον αρχείο δεν τροποποιήθηκε ✅

---

## USAGE

### Create Provenance for Release
```bash
# 1. Tag release
git tag -s v1.2.0 -m "Release 1.2.0"

# 2. Run stamping script
./scripts/provenance-stamp.sh v1.2.0

# 3. Wait for Bitcoin confirmation (10-60 min)
# 4. Upgrade OTS proof
ots upgrade releases/v1.2.0.tar.gz.ots

# 5. Update PROVENANCE.yaml
# 6. Push to GitHub
git push origin v1.2.0
```

### Verify Provenance
```bash
./scripts/verify-provenance.sh v1.2.0
```

### Verify Dependencies
```bash
./scripts/verify-deps
```

---

## CI/CD

**Workflow**: `.github/workflows/provenance.yml`

**Triggers**: On version tags (`v*.*.*`)

**Actions**:
1. Create release archive
2. Generate SHA-256/SHA-512
3. Sign with GPG (if configured)
4. Stamp with OpenTimestamps
5. Pin to IPFS (if configured)
6. Create GitHub Release

**Secrets Required** (optional):
- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`
- `IPFS_API_TOKEN`
- `WEB3_STORAGE_TOKEN` or `PINATA_API_KEY`

---

## ΕΓΓΥΗΣΕΙΣ

✅ **Authorship**: GPG signed commits/tags  
✅ **Timestamp**: Bitcoin blockchain anchored  
✅ **Immutability**: IPFS CID + SHA-256  
✅ **Non-repudiation**: Digital signatures  
✅ **Dependency Integrity**: deps.lock with hashes  
✅ **Hermetic Build**: Deterministic + verified deps  

---

## STANDARDS

- OpenTimestamps Protocol
- IPFS Content Addressing (CIDv1)
- GPG/PGP (RFC 4880)
- eIDAS (EU 910/2014) - optional
- SemVer 2.0.0
- CC BY 4.0 License

---

**Generated**: 2025-12-15  
**Implementation**: Complete (Phases E-F)  
**No System Changes**: ✅ Καμμία τροποποίηση υπάρχοντος κώδικα
