# DELIVERABLE 4: VALIDATION MAP
## Gate 4 - Validation Reality Check

**Generated**: 2025-12-18
**Total Validation Mentions**: 166
**Real Validators**: 1 (FRBR consistency validator)
**Placeholder Validators**: 1 (SHACL)
**Missing Validators**: 2 (RDF syntax, RDFC-1.0 canonicalization)

---

## CRITICAL FINDINGS

### 1. SHACL VALIDATION IS PLACEHOLDER
**File**: `systems/orchestrator-engine-sbcl/stages/validate-shacl.lisp:22-27`

```lisp
(defun validate-article-shacl (article)
  "Validate single article - PLACEHOLDER"
  (log:info "SHACL validation passed for Article ~D"   ; ← Logs "passed"
            (orchestrator.model:article-number article))
  (orchestrator.spec:transition article :reviewing)
  t)  ; ← ALWAYS RETURNS T (no actual validation!)
```

**Status**: ⚠️ **CRITICAL BLOCKER**

**Problems**:
- Function logs "passed" but does NO validation
- Always returns `t` (success)
- Performs state transition despite no checks
- Comment explicitly says "PLACEHOLDER"

**Impact**: **ZERO semantic validation** - invalid RDF passes through!

---

### 2. REAL FRBR VALIDATOR EXISTS
**File**: `systems/orchestrator-omega-modules/frbr-consistency-validator.lisp:23-49`

```lisp
(defun validate-frbr-stack (article-root work expression manifestation formats)
  "Validate complete FRBR stack for consistency

   Validation Strategy:
     - FAIL FAST: First error stops validation
     - COMPREHENSIVE: Checks all critical properties
     - DETERMINISTIC: Same input always produces same result"

  (validate-article-root article-root)
  (validate-work work article-root)
  (validate-expression expression work article-root)
  (validate-manifestation manifestation expression article-root)
  (validate-formats formats manifestation article-root)
  (validate-uri-chain article-root work expression manifestation formats)
  (validate-article-number-consistency article-root work expression manifestation formats)

  t)
```

**Status**: ✅ **REAL VALIDATOR**

**Features**:
- Fail-fast error handling
- 7 validation functions (comprehensive)
- URI pattern checks
- Article number consistency
- FRBR chain integrity
- Required slots validation
- ELI identifier compliance

**Current Usage**: Called by `unified-frbr-generator.lisp:106` **UNCONDITIONALLY**

---

## VALIDATION INVENTORY

### A) REAL VALIDATORS (IMPLEMENTED)

| Validator | File | Type | Coverage | Blocking | Status |
|-----------|------|------|----------|----------|--------|
| `validate-frbr-stack` | frbr-consistency-validator.lisp:23 | Structural | FRBR model integrity | ✅ YES (asserts) | ✅ REAL |
| `validate-article-root` | frbr-consistency-validator.lisp:55 | Structural | Article root slots | ✅ YES | ✅ REAL |
| `validate-work` | frbr-consistency-validator.lisp | Structural | Work layer | ✅ YES | ✅ REAL |
| `validate-expression` | frbr-consistency-validator.lisp | Structural | Expression layer | ✅ YES | ✅ REAL |
| `validate-manifestation` | frbr-consistency-validator.lisp | Structural | Manifestation layer | ✅ YES | ✅ REAL |
| `validate-formats` | frbr-consistency-validator.lisp | Structural | Format layer | ✅ YES | ✅ REAL |
| `validate-uri-chain` | frbr-consistency-validator.lisp | Semantic | URI consistency | ✅ YES | ✅ REAL |
| `validate-article-number-consistency` | frbr-consistency-validator.lisp | Semantic | Cross-layer numbers | ✅ YES | ✅ REAL |

**Total**: 8 real validators (all structural/semantic model checks)

**Invocation**: `unified-frbr-generator.lisp:106` calls `validate-frbr-stack` **UNCONDITIONALLY**

---

### B) PLACEHOLDER VALIDATORS (FAKE)

| Validator | File | Expected Behavior | Actual Behavior | Status |
|-----------|------|-------------------|-----------------|--------|
| `validate-article-shacl` | validate-shacl.lisp:22 | Validate RDF against SHACL shapes | ❌ Logs "passed", returns `t` | ⚠️ **PLACEHOLDER** |

**Total**: 1 placeholder

**Impact**: Semantic RDF validation = **ZERO**

---

### C) MISSING VALIDATORS (GAP ANALYSIS)

| Validator | Purpose | Required For | Priority |
|-----------|---------|--------------|----------|
| **RDF Syntax Validation** | Check Turtle syntax is valid | Canonical compiler | P0 (CRITICAL) |
| **RDFC-1.0 Canonicalization Check** | Verify canonical ordering | Determinism guarantee | P1 (HIGH) |
| **URI Validation** | Validate all URIs are well-formed | RDF compliance | P2 (MEDIUM) |
| **Literal Validation** | Check datatypes/languages valid | RDF compliance | P2 (MEDIUM) |
| **Provenance Binding Validation** | Verify hash binding exists | Split artifacts integrity | P1 (HIGH) |

**Total**: 5 missing validators

---

## BYPASS ANALYSIS

### 1. Optional Validation in Write Function

**File**: `unified-frbr-generator.lisp:290`

```lisp
(defun write-unified-article-file (article-number title content output-dir
                                    &key (validate t) ...)  ; ← OPTIONAL!
  ...
  (when validate  ; ← Can be bypassed by passing :validate nil
    (validate-frbr-stack article-root work expression manifestation formats))
  ...)
```

**Bypass Mechanism**:
```lisp
;; Caller can skip validation:
(write-unified-article-file 123 "Title" "Content" "/tmp/"
                           :validate nil)  ; ← Bypasses all validation!
```

**Status**: ⚠️ **BYPASS PATH**

**Fix (Phase 4)**: Remove `:validate` parameter → UNCONDITIONAL validation

---

### 2. No RDF Syntax Gate

**Current**: No validation that generated Turtle is syntactically valid

**Risk**: Generator could produce malformed TTL → downstream tools fail

**Example Failure Modes**:
- Unclosed literals: `"foo`
- Invalid URI characters: `<http://example.com/bad char>`
- Missing prefix declarations
- Unescaped quotes in literals

**Detection**: Load TTL into riot/rapper → syntax error

**Fix (Phase 3)**: Add RDF syntax validation gate

---

### 3. SHACL Placeholder Allows Invalid RDF

**Current**: SHACL validator always returns success

**Risk**: Semantic constraints NOT enforced

**Example Invalid RDF That Would Pass**:
- Missing required properties (`dct:title`, `eli:is_realized_by`)
- Wrong cardinality (multiple `eli:number` when spec says exactly 1)
- Invalid datatypes (`eli:number "123"@en` instead of `xsd:integer`)
- Circular references

**Detection**: Run pySHACL with shapes → validation report

**Fix (Phase 3)**: Replace placeholder with real pySHACL call

---

## VALIDATION COVERAGE MATRIX

| Layer | Structural | Semantic (FRBR) | Semantic (RDF) | Syntax | Status |
|-------|------------|-----------------|----------------|--------|--------|
| **Article Root** | ✅ validate-article-root | ✅ URI chain check | ❌ NO SHACL | ❌ NO syntax check | 50% |
| **Work** | ✅ validate-work | ✅ Consistency check | ❌ NO SHACL | ❌ NO syntax check | 50% |
| **Expression** | ✅ validate-expression | ✅ Consistency check | ❌ NO SHACL | ❌ NO syntax check | 50% |
| **Manifestation** | ✅ validate-manifestation | ✅ Consistency check | ❌ NO SHACL | ❌ NO syntax check | 50% |
| **Formats** | ✅ validate-formats | ✅ Consistency check | ❌ NO SHACL | ❌ NO syntax check | 50% |
| **Generated TTL** | N/A | N/A | ❌ NO SHACL | ❌ NO syntax check | **0%** |

**Overall Coverage**: 50% (structural only, NO semantic RDF validation, NO syntax validation)

---

## REAL vs ADVISORY VALIDATORS

### Blocking Validators (ERROR on failure):

| Validator | Enforcement | Example Failure |
|-----------|-------------|-----------------|
| `validate-article-root` | ✅ Throws error | Missing article-number → error |
| `validate-work` | ✅ Throws error | Invalid Work URI → error |
| `validate-uri-chain` | ✅ Throws error | Broken FRBR chain → error |
| `validate-article-number-consistency` | ✅ Throws error | Article numbers don't match → error |

**Count**: 8 blocking validators (all FRBR structural checks)

### Advisory Validators (WARNING only):

**Count**: 0 (none exist - all validators are blocking)

### Placeholder Validators (FAKE blocking):

| Validator | Claims | Reality |
|-----------|--------|---------|
| `validate-article-shacl` | "SHACL validation" | ❌ Always returns `t`, no validation |

---

## MISSING VALIDATION GAPS

### Gap 1: SHACL Shapes Missing
**File**: `deployment/shapes/legal-shapes.ttl`

**Status**: 🔍 **NEED TO CHECK** if file exists and has real shapes

**Required Shapes**:
```turtle
# Should validate:
- eli:LegalResource has required properties
- eli:number is xsd:integer with cardinality 1
- eli:is_realized_by points to eli:LegalExpression
- prov:Activity has required timestamps
- All URIs use approved URI schemes
```

**Action**: Check if shapes file exists and is comprehensive

---

### Gap 2: RDF Syntax Validation
**Tool**: Apache Jena `riot` or `rapper` (Raptor RDF)

**Current**: ❌ Not implemented

**Required**:
```lisp
(defun validate-rdf-syntax (ttl-string)
  "Validate Turtle syntax using riot"
  (let ((temp-file (write-to-temp-file ttl-string)))
    (uiop:run-program (list "riot" "--validate" temp-file)
                      :output :string
                      :error-output :string
                      :ignore-error-status nil)))  ; ← Throws if invalid
```

**Integration**: Call in Phase 4 write authority gate

---

### Gap 3: Canonicalization Verification
**Tool**: RDFC-1.0 canonical form checker

**Current**: ❌ Not implemented

**Required**:
- Verify triples are sorted by SPO
- Verify Unicode NFC normalization
- Verify canonical prefix ordering
- Verify deterministic blank node labels

**Implementation**: Property-based tests in Phase 5

---

### Gap 4: URI Validation
**Current**: Partial (validates URI patterns in frbr-consistency-validator)

**Missing**:
- Well-formed URI syntax (RFC 3986)
- HTTP/HTTPS scheme validation
- ELI namespace compliance
- Reserved character escaping

**Fix**: Integrate with `canonical-uris.lisp:validate-uri` (already exists!)

**File**: `source/canonical-uris.lisp:210-227`
```lisp
(defun validate-uri (uri-string)
  "Validate URI syntax and scheme"
  ...)

(defun assert-canonical-uri (uri-string)
  "Assert URI is in canonical form"
  ...)
```

**Action**: Ensure FRBR validator calls these functions

---

### Gap 5: Provenance Binding Validation
**Current**: ❌ Not implemented

**Required**: Verify provenance capsule has hash binding to canonical

```lisp
(defun validate-provenance-binding (canonical-file provenance-file)
  "Validate provenance capsule binds to canonical via hash"
  (let* ((canonical-ttl (read-file-string canonical-file))
         (expected-hash (hash-canonical-artifact canonical-ttl))
         (provenance-ttl (read-file-string provenance-file))
         (bound-hash (extract-hash-from-provenance provenance-ttl)))

    (unless (string= expected-hash bound-hash)
      (error "Provenance binding invalid: hash mismatch"))))
```

**Integration**: Phase 2 acceptance criteria

---

## GATE 4 ACCEPTANCE CRITERIA

### 1. No Placeholder Validators

```bash
rg "PLACEHOLDER|always.*t\)|log.*passed" \
   systems/orchestrator-engine-sbcl/stages/validate-shacl.lisp

# → MUST return 0 matches after Phase 3
```

### 2. Real SHACL Validation

```bash
# Check SHACL validator calls pySHACL
rg "pySHACL|pyshacl|run-program.*shacl" \
   systems/orchestrator-engine-sbcl/stages/validate-shacl.lisp

# → MUST have matches (subprocess call)
```

### 3. RDF Syntax Validation Exists

```bash
rg "riot.*--validate|rapper.*--check" \
   systems/orchestrator-omega-modules/

# → MUST have matches in write authority gate
```

### 4. No Optional Validation Parameters

```bash
rg "&key.*validate|:validate" \
   systems/orchestrator-omega-modules/unified-frbr-generator.lisp

# → MUST return 0 matches in write functions
```

### 5. All Validators Are Blocking

```bash
# Check validators throw errors (not warnings)
rg "warn|log:warn" systems/orchestrator-omega-modules/frbr-consistency-validator.lisp

# → MUST return 0 matches (use error/assert only)
```

---

## VALIDATION CALL GRAPH

### Current Flow:

```
write-unified-article-file
  ├─ (when validate ...) ← OPTIONAL!
  │   └─ validate-frbr-stack ✅ REAL
  │       ├─ validate-article-root ✅
  │       ├─ validate-work ✅
  │       ├─ validate-expression ✅
  │       ├─ validate-manifestation ✅
  │       ├─ validate-formats ✅
  │       ├─ validate-uri-chain ✅
  │       └─ validate-article-number-consistency ✅
  │
  └─ (generate TTL) → write to disk
       └─ NO SHACL ❌
       └─ NO RDF syntax validation ❌
```

### Target Flow (Phase 3 + 4):

```
write-canonical-artifact
  ├─ validate-frbr-stack ✅ UNCONDITIONAL
  │   └─ (all 8 sub-validators)
  │
  ├─ validate-article-shacl ✅ REAL (pySHACL)
  │   └─ Semantic RDF constraints
  │
  ├─ validate-rdf-syntax ✅ NEW (riot)
  │   └─ Turtle syntax check
  │
  ├─ canonical-triple-store (Phase 1)
  │   ├─ mk-uri (validates URIs) ✅
  │   ├─ mk-lit (validates literals) ✅
  │   └─ emit-turtle (canonical ordering) ✅
  │
  └─ write with split artifacts (Phase 2)
      ├─ Hash canonical TTL ✅
      └─ Bind provenance ✅
```

---

## MIGRATION PLAN (Phase 3)

### Step 1: Replace SHACL Placeholder (2-3 hours)

**File**: `systems/orchestrator-engine-sbcl/stages/validate-shacl.lisp`

**Current** (lines 22-27): DELETE ENTIRE FUNCTION

**New**:
```lisp
(defun validate-article-shacl (article)
  "Validate single article with REAL pySHACL"
  (let* ((ttl-string (orchestrator.model:article-rdf-turtle article))
         (data-file (write-to-temp-file ttl-string))
         (shapes-file "deployment/shapes/legal-shapes.ttl"))

    ;; Call pySHACL via python-integration.lisp (REUSE existing!)
    (let ((result (orchestrator.python:validate-with-shacl
                   data-file :shapes-file shapes-file)))

      (if result
          (progn
            (log:info "Article ~D: SHACL validation PASSED"
                      (orchestrator.model:article-number article))
            (orchestrator.spec:transition article :reviewing)
            t)
          (error "Article ~D: SHACL validation FAILED - see validation report"
                 (orchestrator.model:article-number article))))))
```

**Reuse**: `source/python-integration.lisp:211-260` already has `validate-with-shacl`!

---

### Step 2: Add RDF Syntax Validation (1-2 hours)

**File**: Create `validate-rdf-syntax` function in `unified-frbr-generator.lisp`

```lisp
(defun validate-rdf-syntax (ttl-string)
  "Validate Turtle syntax using Apache Jena riot"
  (let ((temp-file (write-to-temp-file ttl-string)))

    (handler-case
        (uiop:run-program (list "riot" "--validate" temp-file)
                          :output :string
                          :error-output :string
                          :ignore-error-status nil)  ; Throws on error

      (uiop:subprocess-error (e)
        (error "RDF syntax validation FAILED:~%~A"
               (uiop:subprocess-error-stderr e))))))
```

**Dependencies**: Apache Jena `riot` binary must be installed

---

### Step 3: Integrate Validators into Write Authority (1 hour)

**File**: `unified-frbr-generator.lisp` (Phase 4 refactor)

```lisp
(defun write-canonical-artifact (article-root work expression manifestation formats
                                  &key output-path)
  "SINGLE WRITE AUTHORITY - UNCONDITIONAL VALIDATION"

  ;; UNCONDITIONAL FRBR validation
  (validate-frbr-stack article-root work expression manifestation formats)

  ;; Build canonical store (Phase 1)
  (let* ((store (make-instance 'canonical-triple-store))
         (canonical-ttl (populate-and-emit store ...)))

    ;; UNCONDITIONAL RDF syntax validation
    (validate-rdf-syntax canonical-ttl)

    ;; UNCONDITIONAL SHACL validation
    ;; (write to temp file first since validate-article-shacl expects model object)
    (validate-article-shacl-from-ttl canonical-ttl)

    ;; Hash + split (Phase 2)
    (hash-and-split-artifacts article-root canonical-ttl output-path)))
```

---

### Step 4: Create/Verify SHACL Shapes (2-3 hours)

**File**: `deployment/shapes/legal-shapes.ttl`

**Required Shapes**:
```turtle
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

# Shape for Article Root
:ArticleShape
    a sh:NodeShape ;
    sh:targetClass eli:LegalResource ;
    sh:property [
        sh:path eli:number ;
        sh:datatype xsd:integer ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
    ] ;
    sh:property [
        sh:path eli:title ;
        sh:datatype rdf:langString ;
        sh:minCount 1 ;
    ] ;
    sh:property [
        sh:path eli:is_realized_by ;
        sh:class eli:LegalExpression ;
        sh:minCount 1 ;
    ] .

# Shape for Work
:WorkShape
    a sh:NodeShape ;
    sh:targetClass eli:Work ;
    sh:property [
        sh:path eli:realizes ;
        sh:class eli:LegalResource ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
    ] .

# Shape for PROV-O Activity
:ActivityShape
    a sh:NodeShape ;
    sh:targetClass prov:Activity ;
    sh:property [
        sh:path prov:endedAtTime ;
        sh:datatype xsd:dateTime ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
    ] ;
    sh:property [
        sh:path prov:generated ;
        sh:minCount 1 ;
    ] .
```

**Action**: Create comprehensive shapes for ALL FRBR layers + PROV-O

---

### Step 5: Remove :validate Parameter (30 min)

**File**: `unified-frbr-generator.lisp:290`

**DELETE**:
```lisp
&key (validate t)  ; ← DELETE THIS
...
(when validate     ; ← DELETE THIS
  (validate-frbr-stack ...))
```

**REPLACE WITH**:
```lisp
;; NO OPTIONAL PARAMETER - validation is ALWAYS enforced
(validate-frbr-stack article-root work expression manifestation formats)
```

**Total Estimated Time**: 7-10 hours for complete validation migration

---

## TESTING STRATEGY

### Positive Tests (Must Pass):
1. Valid FRBR stack → all validators pass
2. Correct Turtle syntax → riot validates
3. Shapes-compliant RDF → pySHACL validates

### Negative Tests (Must Fail):
1. Missing article-number → FRBR validator throws
2. Invalid Turtle (unclosed literal) → riot throws
3. Wrong cardinality (multiple eli:number) → pySHACL fails
4. Broken FRBR chain → URI validator throws
5. Invalid URI syntax → mk-uri throws

### Integration Tests:
1. Full pipeline with valid article → produces canonical + provenance
2. Full pipeline with invalid article → FAILS at first validator
3. Attempt to bypass validation → compilation error (unexported)

---

## END OF DELIVERABLE 4

**All 4 Gate 0 Deliverables Complete**:
1. ✅ Time Call Sites Table
2. ✅ Write Surface Map
3. ✅ Hash Map
4. ✅ Validation Map

**Next**: Commit all deliverables, then revise migration plan v3.0 with complete facts
