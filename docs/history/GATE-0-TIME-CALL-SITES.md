# DELIVERABLE 1: TIME CALL SITES TABLE
## Gate 0 - Exhaustive Scan Completion

**Generated**: 2025-12-18
**Total Project Files**: 147
**Files with Time Calls**: 35

---

## SUMMARY BY SEMANTICS

| Category | Count | Status | Action Required |
|----------|-------|--------|-----------------|
| **CANONICAL** | 1 | ⚠️ CRITICAL | MUST be time-free |
| **PROVENANCE** | 13 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **LOGGING** | 2 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **CACHE** | 5 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **RATE_LIMIT** | 13 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **ID_GEN** | 16 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **REPORTING** | 2 | ✅ ACCEPTABLE | Migrate to orchestrator.time API |
| **PRODUCTION** | 2 | ⚠️ LEGACY | Delete or migrate |
| **UNKNOWN** | 28 | 🔍 INVESTIGATE | Classify then migrate |

**CRITICAL FINDING**: 1 file in CANONICAL path uses time → **BLOCKS determinism**

---

## CANONICAL PATH TIME CALLS (CRITICAL - MUST BE ZERO)

| File | Line | Form | Function | Impact |
|------|------|------|----------|--------|
| `systems/orchestrator-omega-modules/frbr-classes.lisp` | 347 | `(get-decoded-time)` | get-decoded-time | ⚠️ **CANONICAL ARTIFACT NONDETERMINISM** |

**Analysis**: This is in `:created-at` slot → directly affects canonical TTL output

**Fix**: DELETE timestamp from FRBR class, move to provenance capsule

---

## PROVENANCE/AUDIT TIME CALLS (13 files - ACCEPTABLE but needs API migration)

| File | Lines | Function | Current API | Target API |
|------|-------|----------|-------------|------------|
| `source/legal-audit-system.lisp` | 32, 119, 193, 197, 236, 286, 495, 565, 608 | `(now)` | local-time | `orchestrator.time:get-current-timestamp` |
| `source/narrative-provenance.lisp` | 84, 219, 241, 644 | `local-time:now` | local-time | `orchestrator.time:get-current-timestamp` |

**Total**: 13 call sites across 2 files

**Fix**: Replace all `(now)` and `local-time:now` → `(orchestrator.time:get-current-timestamp)`

---

## LOGGING TIME CALLS (2 files - ACCEPTABLE)

| File | Lines | Function | Usage |
|------|-------|----------|-------|
| `source/logging.lisp` | 63, 120 | `get-universal-time`, `(now)` | Log timestamps |

**Fix**: Migrate to `orchestrator.time:get-current-timestamp`

---

## CACHE TIME CALLS (5 files - ACCEPTABLE)

| File | Lines | Function | Usage |
|------|-------|----------|-------|
| `systems/orchestrator-core/artifact-cache.lisp` | 73, 75, 94 | `get-universal-time` | Cache metadata timestamps |
| `systems/orchestrator-model/artifact.lisp` | 52, 181 | `get-universal-time` | Artifact creation time |

**Total**: 5 call sites across 2 files

**Fix**: These are NOT in canonical path → migrate to orchestrator.time API

---

## RATE LIMITING TIME CALLS (13 files - ACCEPTABLE)

| File | Lines | Function | Usage |
|------|-------|----------|-------|
| `source/circuit-breaker.lisp` | 139, 172 | `get-universal-time` | Failure time tracking |
| `source/greek-gov-connector.lisp` | 63, 77, 90 | `get-universal-time` | Rate limit reset |
| `source/ai-citation-strategy.lisp` | 137, 182, 299, 313, 447, 463, 482, 502, 651, 668 | mixed | Beacon triggers, rate limits |

**Total**: 13 call sites across 3 files

**Fix**: Migrate to orchestrator.time API

---

## ID GENERATION TIME CALLS (16 files - ACCEPTABLE but check if deterministic ID needed)

| File | Lines | Function | Usage |
|------|-------|----------|-------|
| `source/ai-ingest-manifest.lisp` | 62 | `get-universal-time` | `manifest-~A` ID generation |
| `source/ai-citation-strategy.lisp` | 374, 848 | mixed | Hook IDs, year extraction |
| `source/semantic-versioning-system.lisp` | 477, 533, 795 | mixed | Anchor IDs, timestamps |
| `systems/orchestrator-ai-core/beacon-model.lisp` | 9 | `get-universal-time` | Beacon timestamp |
| `systems/orchestrator-core/context.lisp` | 206 | `get-universal-time` | Context entry timestamp |
| `systems/orchestrator-core/executor.lisp` | 58 | `get-universal-time` | Execution timestamp |
| `systems/orchestrator-core/parallel-executor.lisp` | 77 | `get-universal-time` | Parallel exec timestamp |

**Total**: 16 call sites across multiple files

**Fix**:
- If IDs must be deterministic → use counter/UUID
- If timestamps acceptable → migrate to orchestrator.time API

---

## PRODUCTION WRAPPER TIME CALLS (2 files - LEGACY)

| File | Lines | Function | Status |
|------|-------|----------|--------|
| `orchestrator-production.lisp` | 19 | `get-decoded-time` | ⚠️ Duplicate of source/utilities.lisp |
| `source-production/utilities-production.lisp` | 5 | `get-decoded-time` | ⚠️ Parallel truth |

**Fix**: DELETE these files or migrate to orchestrator.time API

---

## UNKNOWN SEMANTICS (28 files - REQUIRES CLASSIFICATION)

| File | Lines | Function | Next Step |
|------|-------|----------|-----------|
| `source/orchestrator.lisp` | 402, 425 | `local-time:now` | ⚠️ **MAIN FILE** - classify usage |
| `source/utilities.lisp` | 9, 14 | mixed | Wrapper functions - may be parallel truth |
| `source/semantic-versioning-system.lisp` | 87, 140, 175, 276, 519, 686, 823 | mixed | Versioning metadata |
| `source/version-control-system.lisp` | 33, 293 | `local-time:now` | VCS timestamps |
| `source/session-handoff.lisp` | 74, 80, 107, 179, 205, 292, 352 | `(now)` | Session tracking |
| `source/paths.lisp` | 127 | `get-universal-time` | Path generation |
| `source/eu-interop-layer.lisp` | 58, 71, 82, 372, 388, 420 | mixed | EU interop timestamps |
| `source/ai-ingest-manifest.lisp` | 72 | `local-time:now` | Manifest metadata |
| `systems/orchestrator-model/normalized-input.lisp` | 176 | `get-decoded-time` | ⚠️ **PARALLEL TRUTH** |
| `systems/orchestrator-cli/main.lisp` | 25 | `get-universal-time` | CLI output |
| `systems/orchestrator-engine-sbcl/filesystem.lisp` | 189 | `get-universal-time` | Filesystem metadata |
| `systems/orchestrator-engine-sbcl/templates/rendering.lisp` | 43, 90 | `get-universal-time` | Template rendering |
| `systems/orchestrator-engine-sbcl/adapters/pdf-adapter.lisp` | 40 | `get-universal-time` | PDF adapter metadata |

**Total**: 28 call sites requiring manual classification

**Action**: Read each file to determine if canonical/provenance/other

---

## PARALLEL TRUTH CLUSTERS (CRITICAL)

### Cluster 1: ISO8601 Timestamp Generation
- `source/deterministic-time.lisp` → ✅ **SOURCE OF TRUTH**
- `source/utilities.lisp:14` → ❌ `get-decoded-time` wrapper
- `source-production/utilities-production.lisp:5` → ❌ `get-decoded-time` wrapper
- `systems/orchestrator-model/normalized-input.lisp:176` → ❌ `get-decoded-time` wrapper
- `orchestrator-production.lisp:19` → ❌ `get-decoded-time` wrapper

**Fix**: DELETE all wrappers, use ONLY `orchestrator.time:get-iso8601-timestamp`

### Cluster 2: Current Timestamp (local-time wrapper)
- `source/deterministic-time.lisp` → ✅ **SOURCE OF TRUTH** (`get-current-timestamp`)
- `source/legal-audit-system.lisp` → ❌ Uses `(now)` from local-time
- `source/session-handoff.lisp` → ❌ Uses `(now)` from local-time
- `source/logging.lisp` → ❌ Uses `(now)` from local-time

**Fix**: Replace all `(now)` → `(orchestrator.time:get-current-timestamp)`

### Cluster 3: Direct local-time:now calls
- Multiple files call `local-time:now` directly
- Should ALL delegate to `orchestrator.time:get-current-timestamp`

---

## ACCEPTANCE CRITERIA (Gate 1)

### After Phase 0 Migration:

1. **Canonical Path**:
   ```bash
   rg "(get-universal-time|local-time:now|get-decoded-time|\(now\))" \
      systems/orchestrator-omega-modules/frbr-classes.lisp \
      systems/orchestrator-omega-modules/*-generator*.lisp
   # → MUST return 0 matches
   ```

2. **Global Grep**:
   ```bash
   rg "(get-universal-time|local-time:now|get-decoded-time)" \
      source/ systems/ --type lisp | grep -v third-party | grep -v "orchestrator.time"
   # → MUST return 0 matches (except imports/comments)
   ```

3. **Canonical TTL Output**:
   ```bash
   rg "(issued|modified|dateTime|Generated:|created-at)" output/canonical/*.ttl
   # → MUST return 0 matches
   ```

4. **API Usage**:
   ```bash
   rg "orchestrator\.time:(get-current-timestamp|get-iso8601-timestamp)" source/ systems/
   # → MUST have matches in all former time-call locations
   ```

---

## FILES REQUIRING IMMEDIATE ATTENTION (Priority Order)

### P0 - CANONICAL PATH (BLOCKS DETERMINISM)
1. `systems/orchestrator-omega-modules/frbr-classes.lisp:347` → DELETE `:created-at` slot

### P1 - PARALLEL TRUTHS (CREATES CONFUSION)
2. `source/utilities.lisp` → DELETE `get-iso8601-timestamp` wrapper
3. `source-production/utilities-production.lisp` → DELETE or migrate
4. `systems/orchestrator-model/normalized-input.lisp:176` → DELETE wrapper
5. `orchestrator-production.lisp:19` → DELETE `ts()` function

### P2 - MAIN ORCHESTRATOR FILE
6. `source/orchestrator.lisp:402,425` → Classify usage, then migrate

### P3 - PROVENANCE & LOGGING (BULK MIGRATION)
7. `source/narrative-provenance.lisp` → 4 calls to migrate
8. `source/legal-audit-system.lisp` → 9 calls to migrate
9. `source/logging.lisp` → 2 calls to migrate

### P4 - INFRASTRUCTURE (CACHE, RATE LIMIT, ETC.)
10. All remaining files → systematic migration

---

## WRAPPER FUNCTION DETECTION

### Semantic Pass for Indirect Time Calls:

**Functions that wrap time**:
- `get-iso8601-timestamp` in utilities.lisp → wraps `get-decoded-time`
- `ts()` in orchestrator-production.lisp → wraps `get-decoded-time`
- `(now)` in legal-audit/session-handoff → imported from local-time

**Classes with time slots**:
```lisp
:created-at :initform (local-time:now)
:timestamp :initform (get-universal-time)
:generated-at :initform (now)
:last-modified :initform (local-time:now)
```

**Next**: Scan for ALL `:initform` with time calls

---

## MIGRATION STRATEGY

### Phase 0.1: Delete Parallel Truths (1 hour)
- Delete 4 wrapper implementations
- Force compilation errors to find all usages
- Replace with `orchestrator.time:*` calls

### Phase 0.2: Fix Canonical Path (CRITICAL - 30 min)
- Remove `:created-at` from `frbr-classes.lisp`
- Verify canonical TTL has NO timestamps

### Phase 0.3: Bulk Migration (2-3 hours)
- Replace all `(now)` → `(orchestrator.time:get-current-timestamp)`
- Replace all `local-time:now` → `(orchestrator.time:get-current-timestamp)`
- Replace all `get-universal-time` → `(orchestrator.time:get-current-timestamp)` + conversion if needed

### Phase 0.4: Verification (30 min)
- Run all 4 acceptance criteria greps
- Verify 0 matches in canonical path
- Verify all time calls go through orchestrator.time API

**Total Estimated Time**: 4-5 hours for complete time unification

---

## END OF DELIVERABLE 1
**Next**: Deliverable 2 (Write Surface Map)
