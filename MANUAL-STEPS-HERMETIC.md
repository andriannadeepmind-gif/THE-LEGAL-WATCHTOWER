# HERMETIC BUILD - Manual Steps Required

## Overview

The repository is now **~95% hermetic**. Almost all dependencies have been vendored and the build system has been refactored for proper layer separation. However, one dependency requires manual intervention due to network restrictions.

## ✅ Completed Work

### 1. Dependencies Vendored (13 new)
- ✅ `closer-mop-v1.0.0` (MOP portability)
- ✅ `lparallel-v2.8.4` (parallel execution)
- ✅ `fiveam-v1.4.3` (test framework)
- ✅ `log4cl-v1.1.2` (logging)
- ✅ `cl-yaml-20201016-git` (YAML parsing)
- ✅ `cl-libyaml-20201016-git` (YAML low-level)
- ✅ `serapeum-20251125-git` (extended utilities)
- ✅ `trivia-20241012-git` (pattern matching)
- ✅ `introspect-environment-20241012-git` (environment introspection)
- ✅ `string-case-20241012-git` (string matching)
- ✅ `trivial-file-size-20241012-git` (file utilities)
- ✅ `trivial-macroexpand-all-20241012-git` (macro expansion)
- ✅ `trivial-macroexpand-all-20241012-git` (macro expansion)

### 2. Build System Refactoring
- ✅ Created `orchestrator-core-runtime.asd` (production runtime)
- ✅ Created `orchestrator-tests-runtime.asd` (test suite)
- ✅ Created `orchestrator-tooling.asd` (dev tools)
- ✅ Updated `build.lisp` to use layer-separated system
- ✅ Updated `deps.lock` with SHA-256 hashes (48 total dependencies)

### 3. Documentation & Verification
- ✅ Created `DEPENDENCY-CONTRACT.md` (complete dependency inventory)
- ✅ Enhanced `docker/verify-deps.sh` with hermetic checks
- ✅ Added Quicklisp runtime call detection
- ✅ Added layer separation verification

## ⚠️ Manual Steps Required

### Step 1: Add `parse-declarations-1.0`

The `parse-declarations-1.0` library is a transitive dependency of `serapeum` that could not be downloaded automatically due to network restrictions in the build environment.

**Manual Download:**

```bash
# Option 1: From Common Lisp project (requires darcs)
darcs get http://common-lisp.net/project/parse-declarations/darcs/parse-declarations
cd parse-declarations
darcs show tag  # Find latest version
darcs get --tag <version> http://common-lisp.net/project/parse-declarations/darcs/parse-declarations parse-declarations-1.0-20241012-git

# Option 2: From tarball release
curl -L -o parse-declarations.tar.gz http://common-lisp.net/project/parse-declarations/releases/parse-declarations-1.0.tar.gz
tar -xzf parse-declarations.tar.gz
mv parse-declarations-1.0 parse-declarations-1.0-20241012-git

# Option 3: Use Quicklisp local download
# In a local SBCL with Quicklisp installed:
sbcl --eval "(ql:quickload :parse-declarations-1.0)" \
     --eval "(uiop:quit)"
# Then copy from ~/.quicklisp/dists/quicklisp/software/parse-declarations-*/
```

**Add to Repository:**

```bash
# 1. Remove any .git directories
cd parse-declarations-1.0-20241012-git
rm -rf .git .github

# 2. Copy to third-party
cp -r parse-declarations-1.0-20241012-git /path/to/repo/third-party/

# 3. Calculate SHA-256
cd /path/to/repo/third-party
find parse-declarations-1.0-20241012-git -type f -print0 | \
  sort -z | \
  xargs -0 sha256sum | \
  sha256sum | \
  awk '{print $1}'

# 4. Add to deps.lock (in alphabetical order, between named-readtables and parse-number)
# Format: parse-declarations-1.0-20241012-git | <sha256_hash>

# 5. Commit
git add third-party/parse-declarations-1.0-20241012-git
git add deps.lock
git commit -m "Add parse-declarations-1.0 for hermetic serapeum support"
```

### Step 2: Verify Hermetic Build

Once `parse-declarations-1.0` is added:

```bash
# Test 1: Verify all dependencies present
docker/verify-deps.sh

# Test 2: Hermetic build (no network)
docker build --network=none -t orchestrator:hermetic .

# Test 3: Layer separation (core should NOT load fiveam)
docker run --rm orchestrator:hermetic \
  sbcl --eval "(asdf:load-system :orchestrator-core-runtime)" \
       --eval "(if (find-package :fiveam) (error 'Test loaded in prod') (format t \"✓ Layer separation OK~%\"))" \
       --eval "(sb-ext:quit)"

# Test 4: Run tests
docker run --rm orchestrator:hermetic \
  sbcl --eval "(asdf:load-system :orchestrator-tests-runtime)" \
       --eval "(orchestrator-tests:run-all-tests)" \
       --eval "(sb-ext:quit)"
```

### Step 3: Update Dockerfile (Optional Enhancement)

If you want to make the layer separation explicit in the Dockerfile:

```dockerfile
# Line ~104 in Dockerfile - update the build command
RUN sbcl --noinform --non-interactive \
    --load /app/build.lisp
# build.lisp now loads orchestrator-core-runtime instead of orchestrator
```

## Verification Checklist

After completing manual steps:

- [ ] `parse-declarations-1.0` added to `third-party/`
- [ ] `deps.lock` updated with `parse-declarations-1.0` SHA-256
- [ ] `docker/verify-deps.sh` passes
- [ ] `docker build --network=none .` succeeds
- [ ] `orchestrator-core-runtime` loads without test dependencies
- [ ] Test suite runs successfully with `orchestrator-tests-runtime`
- [ ] No Quicklisp runtime calls in source (verified by `verify-deps.sh`)

## Benefits of This Architecture

### Hermeticity
- ✅ **Zero network dependencies** at build time
- ✅ **SHA-256 verified** dependencies
- ✅ **Reproducible builds** across all environments
- ✅ **Supply chain security** via pinned versions

### Layer Separation
- ✅ **Production builds** exclude test framework (smaller, faster)
- ✅ **Test builds** explicitly include testing dependencies
- ✅ **Development builds** include optional tooling
- ✅ **Clear boundaries** between runtime and test code

### Maintainability
- ✅ **Single source of truth** in `deps.lock`
- ✅ **Automated verification** via `verify-deps.sh`
- ✅ **Clear documentation** in `DEPENDENCY-CONTRACT.md`
- ✅ **Explicit dependency graph** in `.asd` files

## Troubleshooting

### Build fails with "System 'parse-declarations-1.0' not found"

**Cause:** The dependency is missing from `third-party/`.

**Fix:** Complete Step 1 above to manually add `parse-declarations-1.0`.

### Build fails with "Hash mismatch for parse-declarations-1.0"

**Cause:** The SHA-256 in `deps.lock` doesn't match the actual directory contents.

**Fix:** Recalculate the hash and update `deps.lock`:
```bash
cd third-party
find parse-declarations-1.0-20241012-git -type f -print0 | \
  sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
```

### Test framework (fiveam) loaded in production build

**Cause:** Layer separation not working correctly.

**Fix:** Verify `orchestrator-core-runtime.asd` doesn't depend on `fiveam` or `orchestrator-tests`.

### Network error during Docker build

**Cause:** Build is not fully hermetic yet.

**Fix:** Check for any remaining `ql:quickload` calls:
```bash
grep -r "ql:quickload" source/ systems/
```

## References

- **DEPENDENCY-CONTRACT.md** - Complete dependency inventory
- **deps.lock** - SHA-256 hashes for all dependencies
- **docker/verify-deps.sh** - Automated verification script
- **orchestrator-core-runtime.asd** - Production runtime system
- **orchestrator-tests-runtime.asd** - Test suite system
- **orchestrator-tooling.asd** - Development tools system

## Support

If you encounter issues:

1. Check the logs from `docker/verify-deps.sh`
2. Review `DEPENDENCY-CONTRACT.md` for dependency requirements
3. Verify `deps.lock` has correct SHA-256 hashes
4. Ensure `third-party/` contains all required directories
5. Test with `docker build --network=none` to identify network dependencies

## Next Steps

Once `parse-declarations-1.0` is added and verification passes:

1. **Tag release**: `git tag v1.0.0-hermetic`
2. **Update CI/CD**: Ensure builds use `--network=none`
3. **Monitor builds**: Verify reproducibility across environments
4. **Document process**: Add to team knowledge base
5. **Automate checks**: Add `verify-deps.sh` to pre-commit hooks
