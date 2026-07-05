# Docker Build Known Issues

## Missing Dependency: closer-mop

### Problem
The orchestrator-spec system requires `closer-mop` as a dependency, but it is not available in:
- `/third-party/` directory (hermetic dependencies)
- `/source/cl-dependencies/closer-mop/` exists but is EMPTY

###  Impact
Cannot build orchestrator.core executable in Docker. Build fails with:
```
Component #:CLOSER-MOP not found, required by #<SYSTEM "orchestrator-spec">
```

### Solutions (Pick One)

#### Option 1: Add closer-mop to third-party/
```bash
# Download closer-mop and add to third-party/
# Update deps.lock with SHA256 hash
# Rebuild Docker image
```

#### Option 2: Populate source/cl-dependencies/closer-mop/
```bash
# Git submodule or copy closer-mop source
# Ensure ASDF can find it via source-registry
```

#### Option 3: Remove closer-mop dependency
```lisp
# Modify orchestrator-spec.asd to not depend on closer-mop
# Refactor code to not use MOP features
```

### Temporary Workaround
For now, the Docker infrastructure is ready but the build stage cannot complete.
All other infrastructure pieces (deps verification, SBOM, entrypoint, security hardening) are implemented and working.
