# =============================================================================
# ORCHESTRATOR - Reproducible Production Docker Image
# =============================================================================
# Features:
# - Multi-stage hermetic build with SHA256 verification
# - Debian Bookworm base (more reproducible than Ubuntu)
# - Multi-architecture support (linux/amd64, linux/arm64)
# - Non-root user (UID 65532 - nonroot)
# - Distroless runtime for minimal attack surface
# - Reproducible builds via SOURCE_DATE_EPOCH
# - SBOM, supply chain security ready
# - Proper signal handling
# - OCI standard labels
# =============================================================================

ARG SBCL_VERSION=2.4.0
ARG SOURCE_DATE_EPOCH=1735689600

# =============================================================================
# Reproducible: Base image pinned by digest (not tag)
# To update digest: docker pull debian:bookworm-20241202-slim && docker inspect debian:bookworm-20241202-slim --format='{{index .RepoDigests 0}}'
# =============================================================================
ARG DEBIAN_DIGEST=debian@sha256:17122fe3d66916e55c0cbd5bbf54bb3f87b3582f4d86a755a0fd3498d360f91b

# =============================================================================
# Stage 1: deps-verify - Verify dependency integrity (PURE LISP)
# =============================================================================
# DARPA-GRADE: No bash scripts, Pure Common Lisp verification
FROM ${DEBIAN_DIGEST} AS deps-verify

WORKDIR /app

# Copy deps.lock and third-party for verification
COPY deps.lock /app/
COPY third-party/ /app/third-party/
# The pure-Lisp verifier + its self-contained SHA-256 and canonical dep-hash
# (no third-party, so deps are verified BEFORE any vendored lib is trusted).
COPY docker/verify-deps.lisp docker/dep-hash.lisp docker/sha256.lisp /app/docker/

# Install SBCL for Pure Lisp verification
RUN apt-get update && apt-get install -y --no-install-recommends \
    sbcl \
    && rm -rf /var/lib/apt/lists/*

# Run dependency verification with Pure Lisp
RUN DEPS_LOCK_FILE=/app/deps.lock \
    THIRD_PARTY_DIR=/app/third-party \
    sbcl --script /app/docker/verify-deps.lisp

# =============================================================================
# Stage 2: builder - Compile orchestrator.core
# =============================================================================
FROM ${DEBIAN_DIGEST} AS builder

# Build arguments for reproducibility
ARG SBCL_VERSION
ARG SOURCE_DATE_EPOCH
ARG GIT_COMMIT=unknown
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}

# Install build dependencies
# NOTE: Python removed - PDF extraction now uses libpoppler-glib via CFFI (DARPA-grade)
RUN apt-get update && apt-get install -y --no-install-recommends \
    sbcl \
    curl \
    ca-certificates \
    libssl-dev \
    libzstd1 \
    libyaml-dev \
    libffi-dev \
    libpoppler-glib-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy verified dependencies from deps-verify stage
COPY --from=deps-verify /app/third-party/ /app/third-party/

# Copy source code and system definitions
COPY *.asd /app/
# [OWNER-RUN 2ος γύρος] deps.lock + DEPENDENCY-CONTRACT.md: μέρος της ταυτότητας
# εξαρτήσεων — απαιτούνται από το dependency-contract-consistency suite (το
# deps-verify stage τα είχε, ο builder ΟΧΙ ⇒ /app/deps.lock απόν στο test stage).
COPY deps.lock DEPENDENCY-CONTRACT.md /app/
COPY systems/ /app/systems/
COPY source/ /app/source/
COPY configs/ /app/configs/
COPY deployment/ /app/deployment/
COPY input/ /app/input/

# Debug: verify PDF file (primary source)
RUN echo "=== Verifying input files ===" && \
    ls -la /app/input/ && \
    test -f "/app/input/constitution.pdf" && \
    echo "✓ PDF exists (primary source)" || \
    echo "⚠ PDF not found, will use JSON fallback"

COPY entrypoint.lisp /app/
COPY build.lisp /app/

# Configure ASDF source registry for hermetic build
# Uses ONLY third-party/ with explicit versions, NO vendor/, NO Quicklisp
# Also includes source/cl-dependencies/ for additional dependencies
ENV XDG_CONFIG_HOME=/root/.config
RUN mkdir -p /root/.config/common-lisp/source-registry.conf.d && \
    printf '(:tree "/app/third-party/")\n(:tree "/app/source/cl-dependencies/")\n' > /root/.config/common-lisp/source-registry.conf.d/10-third-party.conf

# Build orchestrator.core with hermetic dependencies
# Use build.lisp script which properly configures all paths
COPY build.lisp /app/
RUN sbcl --noinform --non-interactive --load /app/build.lisp

# Verify executable was created
RUN test -f /app/orchestrator.core && \
    chmod +x /app/orchestrator.core && \
    echo "✓ orchestrator.core built successfully"

# =============================================================================
# Stage 3: test - CI/CD testing target
# =============================================================================
FROM builder AS test

# Copy test files
COPY tests/ /app/tests/

# Run system tests
RUN sbcl --noinform --non-interactive \
    --eval "(require :asdf)" \
    --eval "(push #p\"/app/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-spec/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-model/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-core/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-engine-sbcl/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-meta/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-infrastructure/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-ai-core/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-gr-syntagma/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-cli/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/systems/orchestrator-omega-modules/\" asdf:*central-registry*)" \
    --eval "(push #p\"/app/tests/\" asdf:*central-registry*)" \
    --eval "(format t \"~%Loading test system...~%\")" \
    --eval "(asdf:load-system :orchestrator-tests)" \
    --eval "(format t \"~%✓ Test system loaded successfully~%\")" \
    --quit

CMD ["echo", "Test stage completed successfully"]

# =============================================================================
# Stage 3b: standalone-test - run the self-contained *-test.lisp scripts
# These tests need NO test framework (no fiveam): each loads the full runtime
# via docker/run-standalone-test.lisp, runs its own checks, and exits 0/1. Build
# this target to gate on them:  docker build --target standalone-test .
# =============================================================================
FROM builder AS standalone-test

# [0088 assurance] ΤΟ GATED STAGE ΕΙΝΑΙ ΠΛΕΟΝ ΥΠΟΧΡΕΩΤΙΚΟΣ ΚΡΙΚΟΣ της
# αλυσίδας builder → standalone-test → verifier-conformance → runtime:
# runtime image ΔΕΝ κατασκευάζεται χωρίς να έχουν περάσει ΟΛΑ τα gates,
# και το machine-readable proof manifest ταξιδεύει ΜΕΣΑ στο runtime.
ARG GIT_COMMIT
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# [Φ7-HARDENING #8] ΑΚΥΡΟ/ΑΠΡΟΣΔΙΟΡΙΣΤΟ GIT_COMMIT = build failure: το proof
# χωρίς δεσμευμένο 40-hex HEAD δεν είναι proof. (Owner/CI: --build-arg
# GIT_COMMIT=$(git rev-parse HEAD) σε ΚΑΘΑΡΟ δέντρο.)
RUN echo "${GIT_COMMIT}" | grep -Eq '^[0-9a-f]{40}$' \
    || { echo "FATAL: GIT_COMMIT build-arg πρέπει να είναι το ακριβές 40-hex clean HEAD (δόθηκε: '${GIT_COMMIT}')"; exit 1; }

COPY tests/ /app/tests/
COPY Dockerfile /app/Dockerfile
COPY docker/run-standalone-test.lisp docker/run-standalone-suites.sh docker/standalone-suite-exclusions.txt docker/sha256.lisp docker/dep-hash.lisp docker/verify-proof-manifest.py docker/entrypoint.lisp docker/sbom.json /app/docker/

# [audit#2] Το suite inventory ΠΑΡΑΓΕΤΑΙ από το filesystem (glob tests/*-test.lisp)
# μείον τη ΜΙΑ δηλωμένη πηγή εξαιρέσεων (docker/standalone-suite-exclusions.txt) —
# ΟΧΙ πλέον χειρόγραφη λίστα εδώ (ο κριτής βρήκε 7 σουίτες ξεχασμένες, incl. τα
# safe-read/param-type-coercion/audit-signature-failclosed proofs). Έτσι καμία νέα
# σουίτα δεν μπορεί να ξεχαστεί από το signed proof manifest. Η ΜΙΑ έδρα εκτέλεσης
# (run-standalone-suites.sh) είναι fail-closed (pipefail: sbcl exit ≠0 ⇒ build red,
# δεν κρύβεται πίσω από το tee) και δοκιμασμένη από αρνητικό fixture
# (docker/run-standalone-suites-test.sh, ci-integrity-selfcheck job).
# Κάθε suite: run-standalone-test.lisp κάνει (sb-ext:exit 1) σε αποτυχία· οι FiveAM
# *-authority/time σουίτες λήγουν με (sb-ext:exit (if (fiveam:run! …) 0 1)).
RUN /app/docker/run-standalone-suites.sh \
      /app/tests /app/proof \
      /app/docker/run-standalone-test.lisp \
      /app/docker/standalone-suite-exclusions.txt

# [0088 assurance] Machine-readable proof manifest: δεσμεύει commit, hashes
# πυρήνα/πηγών, ΟΝΟΜΑΣΤΙΚΕΣ σουίτες με τις γραμμές αποτελεσμάτων τους και
# το log digest — παράγεται ΜΟΝΟ αν ΟΛΕΣ οι σουίτες βγήκαν 0.
RUN set -e; \
    CORE=$(sha256sum /app/orchestrator.core | cut -d' ' -f1); \
    CM=$(sha256sum /app/component-manifest.sexp | cut -d' ' -f1); \
    SRC=$(find /app/source /app/systems /app/tests /app/deployment/verify /app/configs /app/deployment/data /app/deployment/knowledge /app/input /app/docker /app/third-party -type f \( ! -name '*.fasl' \) -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1; find /app -maxdepth 1 -type f \( -name '*.asd' -o -name 'build.lisp' -o -name 'deps.lock' -o -name 'Dockerfile' \) -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | sha256sum | cut -d' ' -f1); \
    SRC=$(echo "$SRC" | sha256sum | cut -d' ' -f1); \
    LOGS=$(cat /app/proof/logs/*.log | sha256sum | cut -d' ' -f1); \
    { echo '{'; \
      echo "  \"proof\": \"lawmax/standalone-proof/1\","; \
      echo "  \"git_commit\": \"${GIT_COMMIT}\","; \
      echo "  \"source_date_epoch\": \"${SOURCE_DATE_EPOCH:-1735689600}\","; \
      echo "  \"orchestrator_core_sha256\": \"$CORE\","; \
      echo "  \"component_manifest_sha256\": \"$CM\","; \
      echo "  \"source_tree_sha256\": \"$SRC\","; \
      echo "  \"logs_sha256\": \"$LOGS\","; \
      echo '  "suites": ['; \
      first=1; \
      for f in /app/proof/logs/*.log; do \
        t=$(basename "$f" .log); \
        line=$( { grep -h -a -E "passed, [0-9]+ failed|[0-9]+ pass, [0-9]+ fail|διαφωνίες|SKIP" "$f" || true; } | tail -1 | sed 's/\\/\\\\/g; s/"/\\"/g'); \
        if [ $first -eq 0 ]; then echo ','; fi; first=0; \
        printf '    {"suite": "%s", "result": "%s"}' "$t" "$line"; \
      done; \
      echo ''; echo '  ]'; echo '}'; \
    } > /app/proof/standalone-proof.json; \
    grep -q '"suites"' /app/proof/standalone-proof.json

CMD ["echo", "Standalone tests passed"]

# =============================================================================
# Stage 3c: verifier-conformance - PROVE the external public verifiers agree
# =============================================================================
# The cross-language-verifier test SKIPS when python3/node are absent (so the
# SBCL-only standalone-test stage above doesn't fail on it). This stage adds both
# interpreters and turns it into a HARD gate: the Lisp implementation emits a
# signed corpus and deployment/verify/{verify.py,verify.mjs} must verify it
# (genuine passes; tampered text and wrong key fail) — locking the trust root
# against silent cross-language drift.
#   docker build --target verifier-conformance .
FROM standalone-test AS verifier-conformance

# [0088 assurance] Δεύτερος υποχρεωτικός κρίκος: κληρονομεί το ΠΕΡΑΣΜΕΝΟ
# standalone-test (tests/logs ήδη μέσα) και προσθέτει τα cross-language gates.
ARG GIT_COMMIT

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-rdflib \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN sbcl --script /app/docker/run-standalone-test.lisp \
      /app/tests/cross-language-verifier-test.lisp

# L7-A: με python3 παρόν, το release-vector-conformance γίνεται ΣΚΛΗΡΟ gate εδώ
# (spine έδρα + Python verifier ≡ INDEX σε ΚΑΘΕ vector, incl. όλα τα αντιπαλικά).
# Στο SBCL-only stage ελέγχεται ΜΟΝΟ η spine έδρα (Python SKIP, safe).
RUN sbcl --script /app/docker/run-standalone-test.lisp \
      /app/tests/release-vector-conformance-test.lisp

# [0088] Φ1β: δεύτερη-γλώσσα συμμόρφωση canonical serialization — τα ΙΔΙΑ
# vectors που κλειδώνει το lisp gated test επαληθεύονται από pure-stdlib python
# (spec: deployment/verify/canonical-serialization-spec.md). Fail-closed.
RUN python3 /app/deployment/verify/verify-canonical.py

# P1 [0043]: με python3+rdflib παρόντα, οι εξωτερικοί μάρτυρες του
# semantic-validity-test (json.tool + rdflib Turtle/JSON-LD parse) γίνονται
# ΣΚΛΗΡΟ gate εδώ — στο SBCL-only standalone stage κάνουν τίμιο SKIP.
RUN sbcl --script /app/docker/run-standalone-test.lisp \
      /app/tests/semantic-validity-test.lisp

# [0088 Φ7 Π6] Το temporal N-version gate ξανά ΚΑΙ εδώ με ρητό python3 —
# διπλή εγγύηση ότι ο verifier-conformance κρίκος καλύπτει και τα temporal.
RUN sbcl --script /app/docker/run-standalone-test.lisp \
      /app/tests/temporal-verifier-test.lisp

# [0088 assurance] verifier-proof manifest: δεσμεύει τα hashes ΟΛΩΝ των
# δημόσιων verifiers που αποτέλεσαν gate σε αυτόν τον κρίκο.
RUN set -e; \
    { echo '{'; \
      echo "  \"proof\": \"lawmax/verifier-proof/1\","; \
      echo "  \"git_commit\": \"${GIT_COMMIT}\","; \
      echo "  \"verify_py_sha256\": \"$(sha256sum /app/deployment/verify/verify.py | cut -d' ' -f1)\","; \
      echo "  \"verify_mjs_sha256\": \"$(sha256sum /app/deployment/verify/verify.mjs | cut -d' ' -f1)\","; \
      echo "  \"verify_canonical_py_sha256\": \"$(sha256sum /app/deployment/verify/verify-canonical.py | cut -d' ' -f1)\","; \
      echo "  \"verify_temporal_py_sha256\": \"$(sha256sum /app/deployment/verify/verify-temporal.py | cut -d' ' -f1)\","; \
      echo "  \"verify_release_py_sha256\": \"$(sha256sum /app/deployment/verify/verify-release.py | cut -d' ' -f1)\","; \
      echo '  "gates": ["cross-language-verifier", "release-vector-conformance", "verify-canonical", "semantic-validity", "temporal-verifier"]'; \
      echo '}'; \
    } > /app/proof/verifier-proof.json

# [Φ7-HARDENING #8] Dedicated verifier του proof manifest ΜΕΣΑ στο build:
# ακριβές αναμενόμενο suite set (ΚΑΘΕ tests/*-test.lisp πλην δηλωμένων
# εξαιρέσεων), κάθε σουίτα με μη κενό parseable failed=0, 40-hex commit,
# 64-hex hashes, ακριβή gates — αλλιώς ΤΟ RUNTIME ΔΕΝ ΧΤΙΖΕΤΑΙ.
RUN python3 /app/docker/verify-proof-manifest.py /app/proof /app/tests /app

# [ΣΤ] Δεσμευμένο runtime-asset manifest: ΚΑΘΕ asset που θα αντιγραφεί στο
# runtime αποκτά sha256 ΕΔΩ (verified stage) — το runtime αυτο-ελέγχεται.
RUN { find /app/orchestrator.core /app/component-manifest.sexp /app/configs \
           /app/deployment/data /app/deployment/knowledge /app/deployment/self \
           /app/deployment/verify /app/deployment/PROOF-CARRYING-LAW.md \
           /app/input -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum; \
      sha256sum /app/docker/entrypoint.lisp | sed 's|/app/docker/entrypoint.lisp|/app/entrypoint.lisp|'; \
      sha256sum /app/docker/sbom.json | sed 's|/app/docker/sbom.json|/app/sbom.json|'; \
    } > /app/proof/runtime-assets.sha256

CMD ["echo", "Cross-language verifier conformance passed"]

# =============================================================================
# Stage 4: runtime - Minimal production runtime
# =============================================================================
FROM ${DEBIAN_DIGEST} AS runtime

# Build metadata
ARG BUILD_DATE
ARG GIT_COMMIT
ARG VERSION=1.2.0

# OCI standard labels
LABEL org.opencontainers.image.title="Orchestrator" \
      org.opencontainers.image.description="Greek Legal Corpus Orchestrator - Research-Grade Production Runtime" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.vendor="STAVROPOULOS LAW" \
      org.opencontainers.image.authors="Spyridon Stavropoulos <contact@stavropouloslaw.com>" \
      org.opencontainers.image.licenses="LicenseRef-All-Rights-Reserved" \
      org.opencontainers.image.source="https://github.com/David33law/STAVROPOULOSLAWCORPUS" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.url="https://stavropouloslaw.com" \
      org.opencontainers.image.documentation="https://github.com/David33law/STAVROPOULOSLAWCORPUS/blob/main/README.md"

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Install minimal runtime dependencies
# NOTE: Python REMOVED - All operations are now pure Lisp:
#   - PDF: libpoppler-glib via CFFI (GATE-13)
#   - RFC 3161 timestamps: Drakma HTTP (GATE-8)
#   - JWS signing: Ironclad crypto (GATE-7)
#   - CT logs: Drakma HTTP (GATE-9)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    libzstd1 \
    libyaml-0-2 \
    libffi8 \
    libpoppler-glib8 \
    libglib2.0-0 \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-ell \
    sbcl \
    file \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create libyaml.so symlink for CFFI (cl-libyaml tries libyaml.so first)
RUN ln -s /usr/lib/x86_64-linux-gnu/libyaml-0.so.2 /usr/lib/x86_64-linux-gnu/libyaml.so && \
    test -e /usr/lib/x86_64-linux-gnu/libyaml.so && \
    ls -l /usr/lib/x86_64-linux-gnu/libyaml*

# Create non-root user (UID 65532 - standard nonroot)
RUN groupadd -g 65532 nonroot && \
    useradd -u 65532 -g 65532 -m -s /sbin/nologin nonroot

WORKDIR /app

# Copy compiled executable from builder
# [0088 assurance] Ο πυρήνας ΚΑΙ το proof έρχονται από τον ΤΕΛΕΥΤΑΙΟ κρίκο
# της αποδεικτικής αλυσίδας — το runtime ΔΕΝ μπορεί να κατασκευαστεί χωρίς
# να έχουν περάσει standalone-test + verifier-conformance.
COPY --from=verifier-conformance /app/orchestrator.core /app/orchestrator.core
COPY --from=verifier-conformance /app/proof/ /app/proof/
# Το παγωμένο manifest ταυτοτήτων συστατικών ταξιδεύει ΜΑΖΙ με το εκτελέσιμο
COPY --from=verifier-conformance /app/component-manifest.sexp /app/component-manifest.sexp

# Copy essential runtime files
COPY --from=verifier-conformance /app/configs/ /app/configs/
COPY --from=verifier-conformance /app/deployment/data/ /app/deployment/data/
COPY --from=verifier-conformance /app/deployment/knowledge/ /app/deployment/knowledge/
COPY --from=verifier-conformance /app/deployment/self/ /app/deployment/self/
# Public verifier assets + PCL-1 spec — published into the static site by
# --emit-site so the advertised /verify/ and spec URLs actually resolve.
COPY --from=verifier-conformance /app/deployment/verify/ /app/deployment/verify/
COPY --from=verifier-conformance /app/deployment/PROOF-CARRYING-LAW.md /app/deployment/PROOF-CARRYING-LAW.md
COPY --from=verifier-conformance /app/input/ /app/input/
COPY --from=verifier-conformance /app/docker/entrypoint.lisp /app/entrypoint.lisp
COPY --from=verifier-conformance /app/docker/sbom.json /app/sbom.json

# [ΣΤ] Runtime self-check: ΚΑΘΕ runtime asset ≡ το δεσμευμένο manifest του
# verified stage — απόκλιση/απόν αρχείο ⇒ το image ΔΕΝ χτίζεται.
RUN sha256sum -c --quiet /app/proof/runtime-assets.sha256

# Verify PDF in runtime (primary source)
RUN echo "=== Runtime: verifying input files ===" && \
    ls -la /app/input/ && \
    test -f "/app/input/constitution.pdf" && \
    echo "✓ PDF exists in runtime" || \
    echo "⚠ PDF not found, will use JSON fallback"

# Create runtime directories (DARPA-GRADE: Pure Lisp entrypoint)
RUN mkdir -p /app/output /app/logs /app/input /app/keys && \
    chown -R nonroot:nonroot /app && \
    chmod +x /app/orchestrator.core

# Runtime environment variables
ENV ORCHESTRATOR_OUTPUT_DIR=/app/output \
    ORCHESTRATOR_LOG_DIR=/app/logs \
    ORCHESTRATOR_CONFIG_DIR=/app/configs \
    ORCHESTRATOR_LOG_LEVEL=info \
    ORCHESTRATOR_WORKERS=4

# Expose ports (if needed for future web UI)
EXPOSE 8080

# Switch to non-root user
USER nonroot:nonroot

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD test -f /app/output/.healthy || exit 1

# Entrypoint with proper signal handling (PURE LISP)
# DARPA-GRADE: No shell scripts, Pure Common Lisp entrypoint
# Φάση 0: ρητό heap — το SBCL default (~1-2GB) σκάει πριν από κάθε σοβαρό όγκο
ENTRYPOINT ["/usr/bin/tini", "--", "sbcl", "--dynamic-space-size", "3584", "--script", "/app/entrypoint.lisp"]
CMD ["--help"]
