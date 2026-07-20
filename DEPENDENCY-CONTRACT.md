# Dependency Contract

## Overview

This document defines the dependency contract for the ORCHESTRATORSUPER project, ensuring 100% hermetic builds with explicit layer separation following Google monorepo patterns.

## Dependency Categories

### 1. Mandatory Dependencies (Core Runtime)

These dependencies are REQUIRED for production runtime and are vendored in `third-party/` with pinned versions:

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| `alexandria` | 20241012-git | General utilities | ✅ Vendored |
| `babel` | 20241012-git | UTF-8 encoding | ✅ Vendored |
| `bordeaux-threads` | v0.9.4 | Threading primitives | ✅ Vendored |
| `cffi` | 20250622-git | Foreign function interface | ✅ Vendored |
| `chipz` | 20230618-git | Decompression | ✅ Vendored |
| `chunga` | 20241012-git | HTTP utilities | ✅ Vendored |
| `cl+ssl` | 20250622-git | SSL/TLS support | ✅ Vendored |
| `cl-annot` | 20150608-git | Annotations | ✅ Vendored |
| `cl-base64` | 20201016-git | Base64 encoding | ✅ Vendored |
| `cl-libyaml` | 20201016-git | YAML parsing (low-level) | ✅ Vendored |
| `cl-ppcre` | 20250622-git | Regular expressions | ✅ Vendored |
| `cl-syntax` | 20150407-git | Syntax extensions | ✅ Vendored |
| `cl-yaml` | 20201016-git | YAML parsing | ✅ Vendored |
| `closer-mop` | v1.0.0 | MOP portability | ✅ Vendored |
| `closure-common` | 20181018-git | XML utilities | ✅ Vendored |
| `cxml` | 20250622-git | XML processing | ✅ Vendored |
| `cxml-stp` | 20200325-git | XML DOM | ✅ Vendored |
| `drakma` | v2.0.10 | HTTP client | ✅ Vendored |
| `fast-io` | 20221106-git | Fast I/O | ✅ Vendored |
| `flexi-streams` | 20241012-git | Flexible streams | ✅ Vendored |
| `global-vars` | 20141106-git | Global variables | ✅ Vendored |
| `introspect-environment` | 20241012-git | Environment introspection | ✅ Vendored |
| `ironclad` | v0.61 | Cryptography (SHA-256) | ✅ Vendored |
| `jonathan` | 20200925-git | JSON parsing | ✅ Vendored |
| `local-time` | 20250622-git | Time handling | ✅ Vendored |
| `log4cl` | v1.1.2 | Logging | ✅ Vendored |
| `lparallel` | v2.8.4 | Parallel execution | ✅ Vendored |
| `mgl-pax` | 20250622-git | Documentation | ✅ Vendored |
| `named-readtables` | 20250622-git | Reader macros | ✅ Vendored |
| `parse-number` | v1.8 | Number parsing | ✅ Vendored |
| `plexippus-xpath` | 20190521-git | XPath | ✅ Vendored |
| `puri` | 20201016-git | URI handling | ✅ Vendored |
| `serapeum` | 20251125-git | Extended utilities | ✅ Vendored |
| `split-sequence` | v2.0.1 | Sequence splitting | ✅ Vendored |
| `static-vectors` | v1.9.3 | Static memory | ✅ Vendored |
| `string-case` | 20241012-git | String matching | ✅ Vendored |
| `trivial-cltl2` | 20211230-git | CLTL2 compatibility | ✅ Vendored |
| `trivial-features` | 20250622-git | Feature detection | ✅ Vendored |
| `trivial-file-size` | 20241012-git | File size utilities | ✅ Vendored |
| `trivial-garbage` | 20231021-git | GC control | ✅ Vendored |
| `trivial-gray-streams` | 20241012-git | Stream protocols | ✅ Vendored |
| `trivial-macroexpand-all` | 20241012-git | Macro expansion | ✅ Vendored |
| `trivial-types` | 20120407-git | Type utilities | ✅ Vendored |
| `trivia` | 20241012-git | Pattern matching | ✅ Vendored |
| `usocket` | 0.8.8 | Socket abstraction | ✅ Vendored |
| `yason` | 20250622-git | JSON utilities | ✅ Vendored |

### 2. Test-Only Dependencies

These dependencies are ONLY loaded when running tests, NOT in production:

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| `fiveam` | v1.4.3 | Test framework | ✅ Vendored |

### 3. Tooling-Only Dependencies (Optional in Production)

These dependencies are for development/debugging and are optional in production:

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| `log4cl` | v1.1.2 | Enhanced logging (also used in model) | ✅ Vendored |

### 4. Missing Dependencies (Requires Manual Intervention)

_None._ [audit#14] `parse-declarations-1.0` is now vendored under `third-party/` and
pinned in `deps.lock` (SHA-256) — the earlier "manual addition required" note was stale.
Machine-checked by `tests/dependency-contract-consistency-test.lisp`: any dependency
listed in this section that is actually present in `deps.lock` fails the gate (no
doc/lock contradiction). Additional infrastructure runtime deps now pinned: `ieee-floats`,
`uuid-20231021`.

## Layer Separation

### System Hierarchy

```
orchestrator-core-runtime.asd         ← PRODUCTION BUILD USES THIS
├── orchestrator-spec.asd
├── orchestrator-model.asd
├── orchestrator-core.asd
├── orchestrator-engine-sbcl.asd
├── orchestrator-omega.asd
├── orchestrator-meta.asd
├── orchestrator-cli.asd
├── orchestrator-gr-syntagma.asd
├── orchestrator-ai-core.asd
└── orchestrator-infrastructure.asd

orchestrator-tests-runtime.asd        ← TEST BUILD USES THIS
├── orchestrator-core-runtime
├── orchestrator-tests.asd
└── fiveam

orchestrator-tooling.asd              ← DEV TOOLING
├── orchestrator-core-runtime
└── log4cl (for enhanced dev logging)
```

## Build Configuration

### Production Build (Dockerfile)

```dockerfile
# Build orchestrator-core-runtime with hermetic dependencies (CORE ONLY)
RUN sbcl --noinform --non-interactive \
    --eval "(require :asdf)" \
    --eval "(asdf:load-system :orchestrator-core-runtime)" \
    --eval "(sb-ext:save-lisp-and-die '/app/orchestrator.core' ...)"
```

### Test Build

```lisp
(asdf:load-system :orchestrator-tests-runtime)
(orchestrator-tests:run-all-tests)
```

### Development Build

```lisp
(asdf:load-system :orchestrator-tooling)
;; Enhanced logging and dev tools available
```

## Dependency Lock File (`deps.lock`)

All dependencies have SHA-256 hashes in `deps.lock` for integrity verification:

```
# Format: name | sha256(directory)
closer-mop-v1.0.0 | 6acbc9435c6826ec809349cfd6667d8729117457aa0dd7d9f5af7333f5c9db50
fiveam-v1.4.3 | 65148fadf8300b21c6ca8e8ed22123889c6b4dee0450cf349daf98eccc2cd751
...
```

## Verification Criteria

### ✅ Criterion 1: All dependencies vendored

```bash
# Check that every :depends-on entry exists in third-party/
grep -r ":depends-on" *.asd | \
  sed 's/#://g' | \
  grep -oE '\b[a-z][a-z0-9-]+\b' | \
  sort -u | \
  while read dep; do
    if [ ! -d "third-party/"*"$dep"* ]; then
      echo "❌ MISSING: $dep"
    fi
  done
```

### ✅ Criterion 2: Hermetic build without network

```bash
# Build must pass with NO network access
docker build --network=none .
```

### ✅ Criterion 3: Layer separation enforced

```bash
# Core runtime must NOT load test dependencies
sbcl --eval "(asdf:load-system :orchestrator-core-runtime)" \
     --eval "(when (find-package :fiveam) (error 'Test framework loaded in production!'))"
```

### ✅ Criterion 4: No Quicklisp runtime calls

```bash
# Search for prohibited Quicklisp calls
grep -r "ql:quickload" source/ systems/ && echo "❌ FAIL: Quicklisp runtime call found" || echo "✅ PASS: No Quicklisp calls"
```

### ✅ Criterion 5: deps.lock integrity

```bash
# Verify all entries in deps.lock exist and hashes match
docker/verify-deps.sh
```

## ASDF Source Registry Configuration

The system uses ASDF source registry for hermetic builds:

```lisp
;; In Dockerfile or build environment
(:tree "/app/third-party/")
(:tree "/app/source/cl-dependencies/")
```

NO Quicklisp, NO `vendor/local-projects`, NO `-master` versions.

## Mandatory Build Steps

1. **Dependency Verification** (Stage 1 in Dockerfile)
   ```bash
   docker/verify-deps.sh
   ```

2. **Core Build** (Stage 2 in Dockerfile)
   ```bash
   sbcl --load build.lisp
   ```

3. **Test Build** (Stage 3 in Dockerfile - Optional)
   ```bash
   sbcl --eval "(asdf:load-system :orchestrator-tests-runtime)"
   ```

## Compliance Checklist

- [x] All runtime dependencies vendored in `third-party/`
- [x] All dependencies have SHA-256 hashes in `deps.lock`
- [x] Layer-separated `.asd` files created
- [x] Production build loads ONLY `orchestrator-core-runtime`
- [x] Test framework (`fiveam`) NOT loaded in production
- [x] `docker build --network=none` supported
- [x] Full verification passes (`parse-declarations-1.0` now vendored + pinned in `deps.lock`)
- [x] No Quicklisp runtime calls in source code
- [x] ASDF source registry configured for hermetic builds

## References

- **Google Monorepo Hermetic Build**: https://bazel.build/basics/hermeticity
- **ASDF Manual**: https://asdf.common-lisp.dev/asdf.html
- **Reproducible Builds**: https://reproducible-builds.org/

## Maintenance

When adding a new dependency:

1. Vendor it in `third-party/{name}-{version}/`
2. Calculate SHA-256: `find third-party/{name}-{version} -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum`
3. Add entry to `deps.lock` in alphabetical order
4. Determine category: runtime, test-only, or tooling
5. Add to appropriate `.asd` file
6. Run `docker/verify-deps.sh` to verify
7. Test `docker build --network=none` passes

## Security

All dependencies are pinned to specific versions with SHA-256 verification to prevent supply chain attacks. The `deps.lock` file MUST be updated whenever dependencies change, and verified before each build.
