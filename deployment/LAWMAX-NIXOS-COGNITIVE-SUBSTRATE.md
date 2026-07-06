# LAWMAX — NIXOS COGNITIVE SUBSTRATE
**Nix/NixOS as the deterministic body, genome, laboratory and rollback mechanism of the Institution — NOT deployment tooling.**
Companion of `LAWMAX-OMEGA-PLAN.md` (trust spine) and `LAWMAX-AUTODIDACTIC-LOOP.md` (learning brain).
Blocked until CONSCIOUSNESS AUDIT v1 = PASS-CANDIDATE (see repo audit §13).

## What NixOS is, in this architecture

| Substrate property | Cognitive meaning for LAWMAX |
|---|---|
| reproducible builds | a learned self can ALWAYS be rebuilt — learning is never anecdotal |
| derivation hashes | build identity = part of the SELF ontology, answerable by `--os-self` |
| flake-locked deps | the genome is pinned; no silent drift of SBCL/libraries |
| rollback generations | «αναίρεση» is an atomic OS operation, not a plan in a document |
| isolated experiments | candidate selves CANNOT touch the stable self — by construction |
| content-addressed store | ten candidates cost one build + ten bundles; unchanged = shared |
| checks as build invariant | a self that fails the plenary cannot even BE built/deployed |
| systemd timers | the nightly loop fires without a human and without a chatbot |

Nix is what makes it SAFE to let the autodidactic loop run unattended:
the creator signs proofs in the morning, not promises.

## Current state (from repo audit §10–11)

Nix in repo: **zero** (no flake, no nix/). Docker: strong (multi-stage,
deps-verify with locked hashes, source-less nonroot runtime, SBOM, cosign).
**Host: the creator's machine IS NixOS** (Windows/Docker Desktop era ended) —
Nix is native; no installer, no WSL. The transition still goes THROUGH the
Docker workflow: it stays operational until the Nix image is proven equivalent.

## NixOS-native staged ingestion (LEVEL 0–8 — the operative ladder)

- **L0 — existing Docker workflow on the NixOS host:** Docker + flakes enabled
  declaratively; clone; `docker compose build`; run `--gates` / `--mirror` /
  `--trace-last-conclusion`; run the unchanged audit when available.
- **L1 — flake skeleton, no logic change:** `flake.nix`, `nix/`, devShell,
  checks wrappers. Cognition untouched.
- **L2 — audit pinning:** unchanged CONSCIOUSNESS AUDIT committed under
  `deployment/verify/consciousness-audit/`; manifest with SHA-256;
  `nix flake check` verifies the audit hash BEFORE running it.
- **L3 — env-config refactor:** `LAWMAX_STATE_DIR / OUTPUT_DIR / DEPLOYMENT_DIR /
  CORPUS_DIR / CONFIG_DIR / LOG_DIR / TRACE_PROFILE / PROPOSAL_DIRS` replace
  hardcoded `/app`. Path/config only, zero cognitive change, 18/18 identical.
- **L4 — Nix-built OCI image:** `dockerTools.buildLayeredImage` → `docker load`
  → byte-parity of gate output vs Dockerfile image. Dockerfile retires only
  after proven equivalence.
- **L5 — native package:** `nix run .#lawmax -- --gates` / `-- --mirror`.
- **L6 — NixOS module:** `services.lawmax.enable`, lawmax user/group, dirs and
  trace profile declared by service config, hardening with the SBCL MDWE caveat.
- **L7 — selfstudy timer:** `lawmax-selfstudy.service/.timer` — trigger only,
  no automatic adoption ever.
- **L8 — candidate legal minds:** stable untouched; candidate derivations;
  shadow testing; stable-vs-candidate comparison; morning approval queue;
  rollback target per adoption.

The N-phases below give the build detail for these levels (L1≈N1, L4≈N3,
L5≈N2, L6≈N5, L7≈N8, L8≈N7/N9/N10); ordering authority is the LEVEL ladder.

## Phases

**N0 — Repo audit & audit hash pinning.** Done/ongoing: `LAWMAX-OMEGA-PLUS-REPO-AUDIT.md`;
audit script must land in `deployment/verify/consciousness-audit/` with SHA-256
pinned in the component manifest. Prerequisite refactor: replace hardcoded `/app`
with `LAWMAX_STATE_DIR / LAWMAX_OUTPUT_DIR / LAWMAX_LOG_DIR / LAWMAX_CORPUS_DIR /
LAWMAX_CONFIG_DIR / LAWMAX_TRACE_PROFILE / LAWMAX_PROPOSAL_DIRS / LAWMAX_RUNTIME_MODE /
LAWMAX_BUILD_ID / LAWMAX_DERIVATION / LAWMAX_GIT_COMMIT` (seat: `source/paths.lisp`,
`source/config.lisp` — path plumbing only, zero logic change, gates prove it).

**N1 — flake.nix without changing logic.** Outputs:
`packages.lawmax`, `apps.lawmax`, `checks.gates`, `checks.consciousness-audit`,
`checks.redteam`, `devShells.default`, `nixosModules.lawmax`.
Files: `flake.nix`, `flake.lock`, `nix/packages/lawmax.nix`, `nix/modules/lawmax.nix`,
`nix/checks/{gates,consciousness-audit,redteam}.nix`, `nix/devshell.nix`.
Rule: every check WRAPS the existing binary gates — no parallel test suite, ever.

**N2 — Native Nix package.** SBCL pinned; ASDF systems declared; third-party from
the existing locked `third-party/` (deps.lock hashes become fixed-output
derivations); knowledge packs content-addressed into the closure or supplied as
runtime corpus; `save-lisp-and-die` inside the sandbox (component-manifest
freezing already happens in `build.lisp` — carries over); binary exposes
`LAWMAX_BUILD_ID`/`LAWMAX_DERIVATION` in `--mirror`.

**N3 — OCI image via `dockerTools.buildImage`** (transitional PRIMARY target).
Same `docker run --rm -v …output -v …deployment orchestrator:latest --gates` UX
on Windows/Docker Desktop. Dockerfile retires ONLY after byte-level gate parity
(18/18 identical output) between Dockerfile image and dockerTools image.

**N4 — Nix checks as invariants.** `nix flake check` = plenary + hash-pinned
audit + redteam. A red gate is a failed BUILD, not a failed test report.

**N5 — NixOS module `services.lawmax`.**
```nix
services.lawmax = {
  enable = true;  package = pkgs.lawmax;
  user = "lawmax"; group = "lawmax";
  traceProfile = "legal-critical";
  stateDir = "/var/lib/lawmax";  outputDir = "/var/lib/lawmax/output";
  corpusDir = "/var/lib/lawmax/corpus/current";  configDir = "/etc/lawmax";
  proposalDirs = [ "/var/lib/lawmax/proposals" "/var/lib/lawmax/output/proposals" ];
  requireTraceForTrustedOutput = true;
  requireHumanApprovalForLegalCriticalAdoption = true;
};
```
systemd hardening:
```
NoNewPrivileges=true  ProtectSystem=strict  ProtectHome=true
PrivateTmp=true  PrivateDevices=true  CapabilityBoundingSet=
RestrictSUIDSGID=true  LockPersonality=true
ReadWritePaths=/var/lib/lawmax /var/log/lawmax
ReadOnlyPaths=/nix/store /etc/lawmax
SystemCallFilter=@system-service
MemoryDenyWriteExecute=false
```
**`MemoryDenyWriteExecute=false` is deliberate:** SBCL images need
writable+executable heap (runtime compilation); `MDWE=true` = service never
starts. Compensation: strict filesystem protection, syscall filter, empty
capability set, dedicated user, path allowlists. Harden progressively; every
step verified by running the plenary UNDER the unit.

**N6 — OS self-awareness.** `--os-self`, `--runtime-identity`, `--build-identity`,
`--current-generation`, `--service-status`, `--allowed-paths`, `--rollback-target`,
`--audit-status` — live substrate data flowing into the EXISTING mirror/self-model
seat (extends SELF ontology; data, never prose, never hardcoded).

**N7 — Candidate self derivations.** A learning bundle (from the autodidactic
loop) + stable source = candidate derivation. Candidate object (per repo audit
§17): id, parent-stable-id, proposal-id, derivation hash, corpus snapshot,
changed modules, tests, improvements, regressions, decision, rollback target.
Store sharing makes N candidates ≈ cost of 1 + N bundles.

**N8 — Nightly autodidactic runner as systemd timer.** `lawmax-selfstudy.timer`
fires `--self-study-night` (the mission from the loop doc §3). The timer is a
trigger, not intelligence. Pre-NixOS equivalent: host scheduler invoking the
same command in the Docker container — same runner, same outputs.

**N9 — Stable-vs-candidate tournament.** Parallel hermetic evaluation of the
candidate ecology on the named benchmark set (Ω plan §10 + blind matters);
scores → decisions (ADOPTABLE/REJECTED/QUARANTINED/REQUIRES-HUMAN/RETRY-LATER)
through the SAME `can-adopt`.

**N10 — Human approval queue → generation.** Signature applies the winning
candidate: new NixOS generation (or new OCI tag pre-NixOS), rollback target
recorded in the adoption ledger; `--rollback` = substrate operation.

## Acceptance per phase

- N1/N2: `nix build .#lawmax` && `nix run .#lawmax -- --gates` → 18/18.
- N3: dockerTools image passes 18/18 on the creator's machine, byte-parity with Dockerfile image.
- N4: `nix flake check` fails when any gate/audit fails (verified with a deliberate red).
- N5: plenary green under the hardened unit; write outside allowlist = EPERM (tested).
- N6: `--os-self` values change when derivation/generation changes (live, not baked).
- N7–N10: one full loop: bundle → candidate build → tournament → queue → signature → generation → rollback drill (rollback executed and verified once, deliberately).

## Non-negotiables of the substrate

Nix is candidate-self substrate, not deployment. Timer is trigger, not
intelligence. Checks wrap existing gates, never fork them. The stable self is
immutable during experiments. Rollback is drilled, not assumed. And nothing in
this file starts before the unchanged audit says PASS-CANDIDATE.
