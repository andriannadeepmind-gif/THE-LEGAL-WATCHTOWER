# DELIVERABLE 2: WRITE SURFACE MAP
## Gate 2 - Write Authority Discovery

**Generated**: 2025-12-18
**Total Write Operations**: 2,238
**Files with Writes**: 63 unique files
**Exported Write Functions**: 11 (MUST reduce to 1)

---

## CRITICAL FINDING

**11 exported write/generate functions found** → Massive bypass attack surface!

**MUST REDUCE TO**: 1 single authority function

---

## EXPORTED WRITE FUNCTIONS (ALL BYPASS PATHS)

| Package | Function | File | Status |
|---------|----------|------|--------|
| `orchestrator.frbr` | `write-work-layer` | work-generator-omega.lisp | ⚠️ **DELETE EXPORT** |
| `orchestrator.frbr` | `write-expression-layer` | expression-generator-omega.lisp | ⚠️ **DELETE EXPORT** |
| `orchestrator.frbr` | `write-manifestation-layer` | manifestation-generator-omega.lisp | ⚠️ **DELETE EXPORT** |
| `orchestrator.frbr` | `write-format-layer` | format-generator-omega.lisp | ⚠️ **DELETE EXPORT** |
| `orchestrator.omega` | `write-work-layer` | (re-export from frbr) | ⚠️ **DELETE EXPORT** |
| `orchestrator.omega` | `write-expression-layer` | (re-export from frbr) | ⚠️ **DELETE EXPORT** |
| `orchestrator.spec` | `write-unified-article-file` | unified-frbr-generator.lisp | ✅ **KEEP** (make single authority) |
| `orchestrator.spec` | `write-rdf-file-safe` | unified-frbr-generator.lisp | ⚠️ **DELETE EXPORT** (utility function) |
| `orchestrator.spec` | `generate-unified-article-ttl` | unified-frbr-generator.lisp | ⚠️ **INTERNAL ONLY** |
| `orchestrator.spec` | `generate-corpus-manifest-ttl` | corpus-root-generator.lisp | 🔍 **INVESTIGATE** (corpus-level) |
| `orchestrator.spec` | `generate-hybrid-phase1-ttl` | hybrid-generator-phase1.lisp | ⚠️ **DELETE EXPORT** |

**Total bypass paths**: 10 (must eliminate)
**Legitimate authority**: 1 (`write-unified-article-file`)

---

## SUMMARY BY CATEGORY

| Category | Write Operations | Files | Bypass Risk |
|----------|------------------|-------|-------------|
| **CANONICAL_EMIT** | 104 | 3 | ⚠️ **HIGH - 10 bypass exports** |
| **PROVENANCE_EMIT** | 424 | 3 | ✅ Low (separate artifacts) |
| **OTHER** | 1,439 | ~40 | 🔍 Needs reclassification |
| **TESTS** | 137 | ~10 | ✅ None |
| **LOGS** | 116 | ~5 | ✅ None |
| **DEPLOYMENT** | 14 | 2 | ✅ None |
| **CACHE** | 3 | 2 | ✅ None |

---

## A) CANONICAL EMIT PATHS (CRITICAL)

### 1. INTENDED AUTHORITY (Keep but Fix)

**File**: `systems/orchestrator-omega-modules/unified-frbr-generator.lisp`
**Function**: `write-unified-article-file` (lines ~287-338)
**Exported**: ✅ YES (`orchestrator.spec` package)

**Current Implementation**:
```lisp
(defun write-unified-article-file (article-number title content output-dir
                                    &key (validate t) ...)  ; ← OPTIONAL validation!
  ...
  (when validate  ; ← Can be skipped!
    (validate-frbr-stack ...))
  ...
  (with-output-to-string (stream)
    (write-string (generate-unified-article-ttl ...) stream))  ; ← String concat, no ordering
  ...)
```

**Problems**:
1. `:validate` parameter is optional → can bypass validation
2. Uses string concatenation → no canonical ordering
3. No typed RDF API → invalid RDF possible
4. No SHACL/RDF syntax validation

**Fix (Phase 4)**:
```lisp
(defun write-canonical-artifact (article-root work expression manifestation formats
                                  &key output-path)  ; ← NO :validate parameter
  "SINGLE WRITE AUTHORITY - NO BYPASSES POSSIBLE"

  ;; UNCONDITIONAL validation
  (validate-frbr-stack article-root work expression manifestation formats)
  (validate-article-shacl article-root)     ; ← Real SHACL (Phase 3)
  (validate-rdf-syntax article-root)        ; ← riot/rapper (Phase 3)

  ;; Build in canonical triple store (Phase 1)
  (let ((store (make-instance 'canonical-triple-store)))
    (populate-store-from-frbr store article-root work expression manifestation formats)

    ;; Emit canonical TTL (deterministic by construction)
    (let ((canonical-ttl (emit-turtle store)))

      ;; Hash + split artifacts (Phase 2)
      (hash-and-split-artifacts article-root canonical-ttl output-path))))
```

---

### 2. BYPASS PATHS (DELETE EXPORTS)

#### Path 1: `write-work-layer`
**File**: `systems/orchestrator-omega-modules/work-generator-omega.lisp`
**Exported**: ✅ YES (both `orchestrator.frbr` and `orchestrator.omega`)
**Lines**: Find with `rg "defun write-work-layer"`

**Bypass Mechanism**:
```lisp
(defun write-work-layer (work output-dir)
  (let ((output-path (merge-pathnames "work.ttl" output-dir)))
    (ensure-directories-exist output-path)
    (with-open-file (stream output-path :direction :output ...)
      (write-string (generate-work-ttl work) stream))))
```

**Action**: UNEXPORT from both packages

---

#### Path 2: `write-expression-layer`
**File**: `systems/orchestrator-omega-modules/expression-generator-omega.lisp`
**Exported**: ✅ YES (both packages)

**Action**: UNEXPORT

---

#### Path 3: `write-manifestation-layer`
**File**: `systems/orchestrator-omega-modules/manifestation-generator-omega.lisp` (inferred)
**Exported**: ✅ YES (`orchestrator.frbr`)

**Action**: UNEXPORT

---

#### Path 4: `write-format-layer`
**File**: `systems/orchestrator-omega-modules/format-generator-omega.lisp` (inferred)
**Exported**: ✅ YES (`orchestrator.frbr`)

**Action**: UNEXPORT

---

#### Path 5: `write-rdf-file-safe`
**File**: `systems/orchestrator-omega-modules/unified-frbr-generator.lisp`
**Exported**: ✅ YES (`orchestrator.spec`)

**Purpose**: Utility function for safe file writes

**Action**: MAKE INTERNAL (unexport), called only by single authority

---

#### Path 6: `generate-hybrid-phase1-ttl`
**File**: `systems/orchestrator-omega-modules/hybrid-generator-phase1.lisp`
**Exported**: ✅ YES (`orchestrator.spec`)

**Purpose**: Legacy hybrid generation

**Action**: UNEXPORT or DELETE entirely

---

#### Path 7: `write-article-root-layer`
**File**: `systems/orchestrator-omega-modules/article-root-generator-omega.lisp:190-196`
**Exported**: 🔍 **NEED TO CHECK** (not in grep results but exists in code)

```lisp
(defun write-article-root-layer (article output-dir)
  (ensure-directories-exist output-path)
  (with-open-file (stream output-path :direction :output :if-exists :supersede)
    (write-string (generate-article-root-ttl ...) stream)))
```

**Action**: Check if exported, if YES → UNEXPORT

---

#### Path 8: `write-prov-activity-layer`
**File**: `systems/orchestrator-omega-modules/prov-activity-generator-omega.lisp`
**Exported**: 🔍 **NEED TO CHECK**

**Note**: This might be PROVENANCE write, not CANONICAL → may be acceptable if goes to separate directory

---

### 3. GENERATE FUNCTIONS (Keep but Make Internal)

#### `generate-unified-article-ttl`
**File**: unified-frbr-generator.lisp
**Exported**: ✅ YES (duplicate export!)
**Purpose**: Builds TTL string from FRBR components

**Action**: UNEXPORT (should be internal implementation detail)

---

#### `generate-corpus-manifest-ttl`
**File**: corpus-root-generator.lisp
**Exported**: ✅ YES
**Purpose**: Corpus-level manifest

**Action**: 🔍 **INVESTIGATE** - Is this separate from article canonical path? If yes, may keep export.

---

## B) PROVENANCE EMIT PATHS (Acceptable but Needs Separation)

### Files:
1. `source/narrative-provenance.lisp` (~300 write ops)
2. `source/legal-audit-system.lisp` (~100 write ops)
3. `systems/orchestrator-omega-modules/prov-activity-generator-omega.lisp` (~24 write ops)

**Status**: ✅ Acceptable (separate artifacts)

**Requirements**:
1. Must write to `output/provenance/` NOT `output/canonical/`
2. Must include hash binding triple to canonical artifact
3. Must use `orchestrator.time` API (Phase 0)

**Verification**:
```bash
rg "output/canonical" source/*provenance*.lisp source/*audit*.lisp
# → MUST return 0 matches
```

---

## C) WRITE AUTHORITY CONSOLIDATION PLAN

### Current State (BROKEN):

```
CANONICAL TTL CAN BE WRITTEN VIA:
├─ write-unified-article-file (intended authority, but has :validate bypass)
├─ write-work-layer (BYPASS #1)
├─ write-expression-layer (BYPASS #2)
├─ write-manifestation-layer (BYPASS #3)
├─ write-format-layer (BYPASS #4)
├─ write-article-root-layer (BYPASS #5 - suspected)
├─ write-rdf-file-safe (BYPASS #6 - utility)
├─ generate-hybrid-phase1-ttl (BYPASS #7)
├─ eli-ttl-generator.lisp functions (BYPASS #8+)
└─ Any code with (with-open-file ... :direction :output ...)

RESULT: **NO ENFORCEMENT, NO GUARANTEE**
```

### Target State (hardened target):

```
CANONICAL TTL CAN ONLY BE WRITTEN VIA:
└─ write-canonical-artifact (NEW NAME, refactored)
    ├─ UNCONDITIONAL FRBR validation
    ├─ UNCONDITIONAL SHACL validation (real, not placeholder)
    ├─ UNCONDITIONAL RDF syntax validation (riot)
    ├─ Canonical triple store (typed API, sorted)
    ├─ Blake3 hash
    └─ Split artifacts (canonical + provenance with binding)

ALL OTHER PATHS:
├─ Unexported → compilation error if called externally
├─ Internal generators (generate-*) → private implementation
└─ Provenance writes → separate directory, hash-bound

RESULT: **SINGLE AUTHORITY, GUARANTEED CORRECTNESS**
```

---

## GATE 2 ACCEPTANCE CRITERIA

### 1. Single Exported Write Function

```bash
# Check orchestrator.spec exports
rg "^[\s]*#:(write-|generate-)" systems/orchestrator-spec/package.lisp

# MUST show EXACTLY ONE write function (or ZERO if renamed package):
#   #:write-canonical-artifact
# OR (if keeping old name):
#   #:write-unified-article-file

# All generate-* functions MUST be unexported
```

### 2. No FRBR Package Write Exports

```bash
rg "^[\s]*#:write-" systems/orchestrator-omega-modules/frbr-package.lisp

# → MUST return 0 matches (all write-*-layer unexported)
```

### 3. No Omega Package Write Re-exports

```bash
rg "^[\s]*#:write-" systems/orchestrator-omega-modules/omega-package.lisp

# → MUST return 0 matches
```

### 4. No Optional Validation Parameters

```bash
rg "&key.*validate|:validate.*t\)" systems/orchestrator-omega-modules/

# → MUST return 0 matches in write functions
```

### 5. No Direct File Writes in Generators

```bash
rg "with-open-file.*:direction.*:output" \
   systems/orchestrator-omega-modules/*-generator*.lisp | \
   grep -v "^.*prov-activity"  # Exclude provenance writes

# → MUST return 0 matches (or only in single authority function)
```

---

## FILES REQUIRING DETAILED READ

### Priority 0 (CRITICAL - BYPASS VERIFICATION):
1. ✅ `work-generator-omega.lisp` - Confirmed export
2. ✅ `expression-generator-omega.lisp` - Confirmed export
3. 🔍 `manifestation-generator-omega.lisp` - Inferred, need to verify exists
4. 🔍 `format-generator-omega.lisp` - Inferred, need to verify exists
5. 🔍 `article-root-generator-omega.lisp` - Has write function, check if exported
6. ✅ `hybrid-generator-phase1.lisp` - Confirmed export

### Priority 1 (PACKAGE VERIFICATION):
7. ✅ `frbr-package.lisp` - Confirmed 4 write exports
8. ✅ `omega-package.lisp` - Confirmed 2 write re-exports
9. ✅ `orchestrator-spec/package.lisp` - Confirmed 7 exports (includes duplicates)

### Priority 2 (CORPUS-LEVEL FUNCTIONS):
10. 🔍 `corpus-root-generator.lisp` - Is generate-corpus-manifest-ttl separate concern?

---

## MIGRATION PHASES

### Phase 4.1: Audit All Exports (1 hour)
- Read all 6 generator files
- Confirm which functions are actually exported
- Check for any `write-*` or `generate-*-ttl` we missed
- Document exact line numbers

### Phase 4.2: UNEXPORT Bypass Paths (30 min)
- Edit `frbr-package.lisp`: Remove 4 exports
- Edit `omega-package.lisp`: Remove 2 re-exports
- Edit `orchestrator-spec/package.lisp`: Remove 6 bypass exports, keep 1
- Force recompilation

### Phase 4.3: Fix Call Sites (2-3 hours)
- Grep for all calls to bypassed functions
- Refactor to use single authority
- May need intermediate adapters during migration

### Phase 4.4: Consolidate Authority (3-4 hours)
- Refactor `write-unified-article-file` → `write-canonical-artifact`
- Remove `:validate` parameter
- Integrate canonical-triple-store (Phase 1)
- Integrate split artifacts + hash (Phase 2)
- Add real validation gates (Phase 3)

### Phase 4.5: Delete Bypass Implementations (1 hour)
- Keep `generate-*` functions (internal use for building data)
- Delete `write-*-layer` function bodies
- Keep only single `write-canonical-artifact`
- Separation: GENERATE (pure, builds data) vs EMIT (side-effect, writes files)

### Phase 4.6: Verification (1 hour)
- Run all 5 acceptance criteria
- Attempt external call to bypassed function → compilation error
- Integration test: full pipeline
- Performance baseline

**Total Estimated Time**: 9-11 hours for complete write authority unification

---

## DISCOVERED PATTERNS

### Pattern 1: Layer-by-Layer Write Functions
```lisp
;; ANTI-PATTERN: Each FRBR layer has own write function
write-article-root-layer
write-work-layer
write-expression-layer
write-manifestation-layer
write-format-layer
```

**Why bad**:
- Each can bypass validation
- Each uses different TTL generation approach
- No guarantee of canonical ordering across layers
- No atomic write (files written separately)

**Fix**: Single unified write that composes ALL layers

---

### Pattern 2: Utility Function Exports
```lisp
;; ANTI-PATTERN: Low-level write utilities exported
write-rdf-file-safe
```

**Why bad**:
- Allows external code to write RDF without validation
- Intended as internal helper, but exported

**Fix**: Unexport all utilities, keep internal-only

---

### Pattern 3: Generate vs Write Confusion
```lisp
;; UNCLEAR: Does "generate" mean build data or write file?
generate-hybrid-phase1-ttl  ; ← Actually writes to disk!
generate-unified-article-ttl  ; ← Just builds string (good)
```

**Why bad**: Naming suggests pure function but has side effects

**Fix**: Strict naming convention:
- `generate-*` = pure, returns data
- `write-*` = side-effect, writes to disk
- Only ONE `write-*` function exported

---

## END OF DELIVERABLE 2

**Next**: Deliverable 3 (Hash Map)
