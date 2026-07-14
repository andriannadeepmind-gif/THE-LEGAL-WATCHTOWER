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

COPY tests/ /app/tests/
COPY docker/run-standalone-test.lisp docker/sha256.lisp docker/dep-hash.lisp /app/docker/

# Each script (sb-ext:exit 1 on failure) fails the build if any check fails.
# The four *-authority/time FiveAM suites are now gated too: run-standalone-test
# loads :fiveam and each file ends with (sb-ext:exit (if (fiveam:run! …) 0 1)).
# NOT listed (by design): comparison-test is a diagnostic that needs a Python
# reference fixture absent from this stage. Everything else under tests/ is gated.
RUN set -e; \
    for t in source-profile review-queue legal-references anomaly-detection \
             legal-qa corpus-fingerprint layout-extraction article-identity \
             ast-gate greek-nlp orthography citation-authority \
             reasoning-authority corpus-intelligence document-fetch \
             source-materialize clean-output source-detect proof-carrying mcp-server \
             mcp-live-resolver legal-id-registry legal-id-routing fek-article-header article-number-fidelity repeal-polish \
             pdf-column-reflow fek-rubric fek-noise amended-split isokratis-amended clean-json-format greek-homoglyph seam-detector deps-hash \
             amendment-extractor amendment-accuracy amendment-consolidation-e2e autonomy-consolidation amendment-backtest \
             consolidation-bridge consolidation-engine auto-consolidate static-site \
             ai-corpus-dump ai-ingest-manifest akoma-ntoso-emitter codification-validation \
             consolidation-feed corpus-diff corpus-eu-links corpus-provenance corpus-search \
             corpus-service corpus-sparql dsanet-chrome fek-html-parser fek-ingestion \
             government-source parliament-html-wiring constitution-crawler fek-discovery fek-backtest-report amendment-routing amendment-state ingestion-daemon ingestion-e2e isokratis-parser \
             legislation-ingestion multi-corpus-service review-service shacl-validator \
             hash-authority write-authority time-unified blockchain-authority release-authority \
             merkle-authority kernel-conformance artifact-census release-vector-conformance \
             tsr-crypto-verify transparency-log capability-registry capability-api cockpit legal-eval casegrammar greek-morphology seat-integrity legal-identity canonical-serialization version-graph graph-import-parity legal-authority-receipt as-known-e2e temporal-semantics \
             escape-sequences turtle-nil-omit corpus-identity semantic-validity \
             cross-language-verifier; do \
      echo "=== running $t-test.lisp ==="; \
      sbcl --script /app/docker/run-standalone-test.lisp "/app/tests/$t-test.lisp"; \
    done

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
FROM builder AS verifier-conformance

COPY tests/ /app/tests/
COPY docker/run-standalone-test.lisp /app/docker/

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
COPY --from=builder /app/orchestrator.core /app/orchestrator.core
# Το παγωμένο manifest ταυτοτήτων συστατικών ταξιδεύει ΜΑΖΙ με το εκτελέσιμο
COPY --from=builder /app/component-manifest.sexp /app/component-manifest.sexp

# Copy essential runtime files
COPY --from=builder /app/configs/ /app/configs/
COPY --from=builder /app/deployment/data/ /app/deployment/data/
COPY --from=builder /app/deployment/knowledge/ /app/deployment/knowledge/
COPY --from=builder /app/deployment/self/ /app/deployment/self/
# Public verifier assets + PCL-1 spec — published into the static site by
# --emit-site so the advertised /verify/ and spec URLs actually resolve.
COPY --from=builder /app/deployment/verify/ /app/deployment/verify/
COPY --from=builder /app/deployment/PROOF-CARRYING-LAW.md /app/deployment/PROOF-CARRYING-LAW.md
COPY --from=builder /app/input/ /app/input/
COPY docker/entrypoint.lisp /app/entrypoint.lisp
COPY docker/sbom.json /app/sbom.json

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
