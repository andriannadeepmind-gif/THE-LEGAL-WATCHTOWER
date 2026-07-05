# DELIVERABLE 3: HASH MAP
## Gate 3 - Hashing Reality Check

**Generated**: 2025-12-18
**Total Files with Hashing**: 73 project files
**Cryptographic Hash Implementations**: 2 (Blake3, SHA256)
**Placeholder Implementations**: 2 (sxhash, sxhash wrapper)

---

## CRITICAL FINDINGS

### 1. PLACEHOLDER HASH IN CANONICAL PIPELINE
**File**: `systems/orchestrator-engine-sbcl/stages/hash-artifacts.lisp:30`
```lisp
(hash (format nil "blake3:~A" (sxhash combined)))  ; ← NOT ACTUALLY BLAKE3!
```

**Status**: ⚠️ **BLOCKING** - Uses `sxhash` (non-cryptographic, implementation-dependent)

**Problems**:
- `sxhash` is NOT cryptographic
- `sxhash` is implementation-dependent (SBCL vs CCL different results)
- Hash is LOGGED but NEVER PERSISTED (line 32-33: only `log:info`)
- No manifest, no provenance binding
- String prefix "blake3:" is LIE (actually using sxhash)

**Impact**: ZERO integrity guarantee, non-deterministic across Lisp implementations

---

### 2. CORRECT BLAKE3 IMPLEMENTATION EXISTS
**File**: `source/semantic-authority.lisp:646-654`
```lisp
(defun compute-content-hash (assertion)
  "Compute BLAKE3 hash of content"
  (let ((content (format nil "~A~A~A"
                        (corpus-uri assertion)
                        (created-at assertion)
                        (qes-hash assertion))))
    (ironclad:byte-array-to-hex-string
     (ironclad:digest-sequence :blake3
                              (babel:string-to-octets content)))))
```

**Status**: ✅ **CORRECT** - Real Blake3 via ironclad library

**Features**:
- Uses `ironclad:digest-sequence :blake3`
- Converts to hex string for readability
- Computes Merkle root for blockchain binding (line 656-665)
- Has API: `compute-content-hash`, `compute-merkle-root`, `compute-authority-hash`

**Current Usage**: Authority assertions, semantic versioning, audit trails

**REUSE**: This should be THE implementation for Phase 2 hash binding

---

## HASH IMPLEMENTATIONS INVENTORY

### A) Cryptographic Hashing (CORRECT)

| File | Line | Algorithm | Function | Scope | Persistence | Status |
|------|------|-----------|----------|-------|-------------|--------|
| `source/semantic-authority.lisp` | 653 | Blake3 | `compute-content-hash` | Authority assertions | ✅ Persisted | ✅ CORRECT |
| `source/semantic-authority.lisp` | 663 | Blake3 | `compute-merkle-root` | Blockchain binding | ✅ Persisted | ✅ CORRECT |
| `source/legal-audit-system.lisp` | 260 | Blake3 | Audit entry hashing | Audit trails | ✅ Persisted | ✅ CORRECT |
| `source/legal-audit-system.lisp` | 458 | Blake3 | Audit trail verification | Audit integrity | ✅ Persisted | ✅ CORRECT |
| `source/ai-citation-strategy.lisp` | 771 | Blake3 | Citation hashing | Citation graphs | ✅ Persisted | ✅ CORRECT |
| `source/semantic-versioning-system.lisp` | 724 | SHA256 | Version diff hashing | Version control | ✅ Persisted | ✅ CORRECT |
| `source/semantic-versioning-system.lisp` | 737 | Blake3 | Semantic anchor hashing | Anchoring | ✅ Persisted | ✅ CORRECT |
| `source/version-control-system.lisp` | 328 | Blake3 | Commit hashing | VCS | ✅ Persisted | ✅ CORRECT |
| `source/eu-interop-layer.lisp` | 369, 482 | SHA256 | EU data exchange | Interop | ✅ Persisted | ✅ CORRECT |
| `source/orchestrator.lisp` | 807 | Blake3 | Corpus master hash | Corpus-level | ✅ Persisted | ✅ CORRECT |
| `systems/orchestrator-model/artifact.lisp` | 94 | Blake3 | Artifact content hash | Model | ✅ Persisted | ✅ CORRECT |
| `systems/orchestrator-ai-core/provenance-model.lisp` | 161 | (unspecified) | Provenance hashing | AI core | ✅ Persisted | ✅ CORRECT |
| `systems/orchestrator-ai-core/ingest-manifest.lisp` | 29 | Blake2/256 | Manifest hashing | AI ingest | ✅ Persisted | ✅ CORRECT |

**Total**: 13 correct cryptographic hash implementations

---

### B) Placeholder/Weak Hashing (MUST FIX)

| File | Line | Algorithm | Function | Scope | Persistence | Status |
|------|------|-----------|----------|-------|-------------|--------|
| `systems/orchestrator-engine-sbcl/stages/hash-artifacts.lisp` | 30 | **sxhash** | `hash-article-artifacts` | **CANONICAL PIPELINE** | ❌ LOGGED ONLY | ⚠️ **CRITICAL** |
| `source/utilities.lisp` | 56 | sxhash | `hash-object` | Utility | ❌ N/A | ⚠️ Non-crypto |

**Total**: 2 placeholder implementations

**CRITICAL**: Line 30 in hash-artifacts.lisp is in CANONICAL PATH and uses sxhash!

---

### C) SHA256 Utility Function (Used in Canonical Path)

| File | Line | Function | Exports | Used By | Status |
|------|------|----------|---------|---------|--------|
| `systems/orchestrator-omega-modules/config-accessor.lisp` | 515-529 | `calculate-sha256-hash` | ✅ YES (orchestrator.spec) | Expression generator, hybrid generator, RDF generator | ✅ CORRECT implementation |

**Implementation**:
```lisp
(defun calculate-sha256-hash (text)
  "Calculate SHA-256 hash of text"
  (let* ((octets (babel:string-to-octets text :encoding :utf-8))
         (digest (ironclad:digest-sequence :sha256 octets)))
    (ironclad:byte-array-to-hex-string digest)))
```

**Usage in Canonical Path**:
- `expression-generator-omega.lisp:159` → Computes content hash for expressions
- `hybrid-generator-phase1.lisp:285` → Content hashing
- `generate-rdf.lisp:222, 245` → RDF content hashing
- `html-rdfa-generator.lisp:278, 305` → HTML metadata hashing

**Analysis**:
- ✅ Correct SHA256 implementation
- ✅ Uses ironclad library
- ⚠️ Used in canonical path BUT hash not bound to artifact
- ⚠️ Hash written to TTL as literal (not provenance binding)

**Example from expression-generator**:
```lisp
(let ((content-hash (orchestrator.spec:calculate-sha256-hash content)))
  (format s "    digest:sha256 \"~A\" ;~%" content-hash))  ; ← Hash IN canonical TTL!
```

**Problem**: Hash is INSIDE canonical artifact → affects canonicalization!
**Fix**: Move hash to provenance capsule (Phase 2)

---

## HASH BINDING ANALYSIS

### Current State:

**NONE** of the hashes are properly bound to canonical artifacts via provenance.

**What EXISTS**:
1. ✅ Blake3 implementation (semantic-authority.lisp)
2. ✅ SHA256 implementation (config-accessor.lisp)
3. ❌ hash-artifacts.lisp uses sxhash (placeholder)
4. ❌ Hashes computed but NOT bound to canonical TTL
5. ❌ No manifest linking canonical + provenance
6. ❌ No `ex:canonicalArtifactSHA256` triple

**What's MISSING**:
```turtle
# Provenance capsule should have:
<article-001-activity>
    ex:canonicalArtifactSHA256 "blake3:abc123..." ;  # ← MISSING!
    prov:generated <article-001.ttl> ;
    prov:endedAtTime "2025-12-18T23:00:00Z" .
```

**Verification Gap**:
```bash
# This should return the hash
blake3 output/canonical/article-001.ttl

# This should match
grep "ex:canonicalArtifactSHA256" output/provenance/article-001-prov.ttl

# Currently: BOTH return nothing (no split artifacts, no hash binding)
```

---

## HASH SCOPE ANALYSIS

### Canonical Artifacts (MUST be stable):

**Currently hashed**:
- Combined TTL + JSON-LD + HTML (hash-artifacts.lisp:26-30) ← **WRONG SCOPE**

**Should hash**:
- **ONLY canonical TTL** (not JSON-LD, not HTML)
- After canonical ordering (Phase 1)
- Before any provenance metadata added

**Reason**:
- JSON-LD/HTML are DERIVED from TTL → redundant
- Combined hash couples formats → changes if HTML template updates
- Canonical TTL is SOURCE OF TRUTH → hash only this

**Correct Scope**:
```lisp
(defun hash-canonical-artifact (article canonical-ttl)
  "Hash ONLY the canonical TTL (single source of truth)"
  (let* ((octets (babel:string-to-octets canonical-ttl :encoding :utf-8))
         (digest (ironclad:digest-sequence :blake3 octets)))
    (ironclad:byte-array-to-hex-string digest)))
```

---

## PERSISTENCE ANALYSIS

| Implementation | Persisted? | Where? | Verification |
|----------------|------------|--------|--------------|
| hash-artifacts.lisp (sxhash) | ❌ NO | Only logged | log:info only (line 32) |
| semantic-authority.lisp (Blake3) | ✅ YES | Authority TTL | Written to RDF |
| config-accessor.lisp (SHA256) | ⚠️ PARTIAL | Inside canonical TTL | Written but IN artifact (not separate) |
| legal-audit-system.lisp (Blake3) | ✅ YES | Audit trail | Persisted to audit log |
| semantic-versioning.lisp (Blake3/SHA256) | ✅ YES | Version metadata | Persisted to version RDF |

**Critical Gap**: hash-artifacts.lisp (CANONICAL PIPELINE) → hash computed but **NEVER WRITTEN**

**Fix (Phase 2)**:
```lisp
(defun hash-and-split-artifacts (article canonical-ttl output-path)
  "Hash canonical TTL and write split artifacts"
  (let ((hash (hash-canonical-artifact article canonical-ttl)))

    ;; Write canonical artifact (NO provenance, NO hash)
    (write-canonical-ttl canonical-ttl
                        (merge-pathnames "canonical/article-001.ttl" output-path))

    ;; Write provenance capsule WITH hash binding
    (write-provenance-capsule article hash
                             (merge-pathnames "provenance/article-001-prov.ttl" output-path))

    ;; Return hash for verification
    hash))
```

---

## STABILITY ASSUMPTIONS

### Current Assumptions (IMPLICIT):

1. **sxhash is deterministic** (hash-artifacts.lisp:30)
   - ❌ **FALSE**: sxhash is implementation-dependent
   - SBCL vs CCL → different values
   - Non-cryptographic → collision-prone

2. **Combined hash is stable** (hash-artifacts.lisp:26-29)
   - ❌ **FALSE**: Hashes TTL+JSON-LD+HTML concatenation
   - If HTML template changes → hash changes
   - If JSON-LD serialization changes → hash changes
   - Coupling across formats

3. **Hash in canonical TTL is acceptable** (expression-generator:159-165)
   - ❌ **FALSE**: Hash written as `digest:sha256 "..."` IN artifact
   - Affects canonical ordering
   - Provenance metadata leaks into canonical layer

4. **No hash binding needed** (current state)
   - ❌ **FALSE**: Provenance MUST bind to canonical via hash
   - Without binding → no proof canonical + provenance are paired

---

## ALGORITHM COMPARISON

| Algorithm | Security | Speed | Collision Resistance | Determinism | Use Case |
|-----------|----------|-------|---------------------|-------------|----------|
| **Blake3** | High | Very Fast | Excellent | ✅ Yes (cross-platform) | ✅ **RECOMMENDED** for canonical artifacts |
| **SHA256** | High | Fast | Excellent | ✅ Yes (cross-platform) | ✅ Acceptable (widely supported) |
| **Blake2/256** | High | Very Fast | Excellent | ✅ Yes | ✅ Good alternative |
| **sxhash** | ❌ None | Very Fast | ❌ Poor | ❌ **NO** (impl-dependent) | ❌ **NEVER** for canonical |

**Recommendation**: Use Blake3 for all canonical artifact hashing (Phase 2)

---

## GATE 3 ACCEPTANCE CRITERIA

### 1. No sxhash in Canonical Path

```bash
rg "sxhash" systems/orchestrator-engine-sbcl/stages/hash-artifacts.lisp

# → MUST return 0 matches after Phase 2
```

### 2. All Hashes Use ironclad

```bash
rg "(sxhash|md5|crc)" --type lisp source/ systems/ | \
  grep -v third-party | grep -v "ironclad"

# → MUST return 0 matches (or only comments/strings)
```

### 3. Hash Binding Exists in Provenance

```bash
rg "ex:canonicalArtifactSHA256|ex:canonicalArtifactBlake3" \
   systems/orchestrator-omega-modules/prov-activity-generator-omega.lisp

# → MUST have matches (hash binding triple)
```

### 4. Canonical TTL Has NO Hash Metadata

```bash
rg "digest:sha256|digest:blake3|ex:contentHash" \
   output/canonical/*.ttl

# → MUST return 0 matches (hashes go to provenance only)
```

### 5. Hash Verification Works

```bash
# Compute hash of canonical artifact
blake3 output/canonical/article-001.ttl

# Extract hash from provenance
grep "ex:canonicalArtifactBlake3" output/provenance/article-001-prov.ttl | \
  cut -d'"' -f2

# MUST match byte-for-byte
```

---

## MIGRATION PLAN (Phase 2 Integration)

### Step 1: Replace sxhash with Blake3 (1 hour)

**File**: `systems/orchestrator-engine-sbcl/stages/hash-artifacts.lisp`

**Current**:
```lisp
(hash (format nil "blake3:~A" (sxhash combined)))  ; ← LINE 30: DELETE
```

**New**:
```lisp
(hash (orchestrator.authority:compute-content-hash canonical-ttl))  ; ← REUSE existing
```

**OR create dedicated function**:
```lisp
(defun hash-canonical-artifact (canonical-ttl)
  "Hash canonical TTL using Blake3"
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :blake3
                            (babel:string-to-octets canonical-ttl :encoding :utf-8))))
```

---

### Step 2: Change Hash Scope (30 min)

**Current**: Hashes combined TTL+JSON-LD+HTML
**New**: Hash ONLY canonical TTL

```lisp
;; DELETE
(let* ((combined (concatenate 'string
                              (or (article-rdf-turtle article) "")
                              (or (article-json-ld article) "")
                              (or (article-html article) "")))

;; REPLACE WITH
(let* ((canonical-ttl (article-rdf-turtle article)))
```

---

### Step 3: Persist Hash (1 hour)

**Current**: Only logs hash
**New**: Store in article model + write to provenance

```lisp
(defun hash-article-artifacts (article canonical-ttl)
  (let ((hash (hash-canonical-artifact canonical-ttl)))

    ;; Store in model
    (setf (orchestrator.model:article-hash article) hash)

    ;; Return for split artifacts
    hash))
```

---

### Step 4: Add Hash Binding to Provenance (2 hours)

**File**: Create `write-provenance-capsule` function

```lisp
(defun write-provenance-capsule (article hash output-path)
  "Write provenance capsule with hash binding to canonical"
  (with-open-file (stream output-path :direction :output :if-exists :supersede)
    (format stream "# Provenance Capsule~%")
    (format stream "# Binds to canonical artifact via hash~%~%")

    ;; Prefixes
    (write-prefixes stream)

    ;; Provenance activity
    (format stream "<~A-activity>~%" (article-uri article))
    (format stream "    a prov:Activity ;~%")
    (format stream "    prov:generated <~A> ;~%" (article-uri article))
    (format stream "    prov:endedAtTime \"~A\"^^xsd:dateTime ;~%"
            (orchestrator.time:get-iso8601-timestamp))

    ;; HASH BINDING (CRITICAL)
    (format stream "    ex:canonicalArtifactBlake3 \"~A\" ;~%" hash)
    (format stream "    prov:wasAssociatedWith <~A> .~%" (orchestrator.uris:get-identity-uri))
    (format stream "~%")))
```

---

### Step 5: Remove Hash from Canonical TTL (1 hour)

**Files to fix**:
- `expression-generator-omega.lisp:159-165` → Remove digest:sha256 literal
- `hybrid-generator-phase1.lisp:285-294` → Remove hash from canonical
- `html-rdfa-generator.lisp:278, 305` → Remove from HTML metadata (keep in HTML, remove from canonical TTL)

**Principle**: Hash metadata goes to PROVENANCE capsule, NOT canonical artifact

---

### Step 6: Add Verification Function (1 hour)

```lisp
(defun verify-canonical-artifact (canonical-file provenance-file)
  "Verify canonical artifact matches hash in provenance"
  (let* ((canonical-content (uiop:read-file-string canonical-file))
         (computed-hash (hash-canonical-artifact canonical-content))
         (provenance-content (uiop:read-file-string provenance-file))
         (bound-hash (extract-hash-from-provenance provenance-content)))

    (if (string= computed-hash bound-hash)
        (log:info "✓ Canonical artifact verified: ~A" canonical-file)
        (error "✗ Hash mismatch! Canonical artifact may be corrupted"))))
```

**Total Estimated Time**: 6-7 hours for complete hash migration

---

## REUSE MATRIX

| Existing Component | File | Reuse In Phase 2 |
|-------------------|------|------------------|
| `compute-content-hash` | semantic-authority.lisp:646 | ✅ Hash canonical TTL |
| `compute-merkle-root` | semantic-authority.lisp:656 | ✅ Blockchain binding |
| `calculate-sha256-hash` | config-accessor.lisp:515 | ❌ Replace with Blake3 OR keep for backward compat |
| Audit trail hashing | legal-audit-system.lisp:260 | ✅ Keep as-is (audit separate from canonical) |

**Principle**: REUSE semantic-authority.lisp Blake3 implementation, don't create new

---

## END OF DELIVERABLE 3

**Next**: Deliverable 4 (Validation Map)
