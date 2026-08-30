# Security & Privilege Architecture for a Private Law-Firm Super-System (LAWMAX-Ω)

**Team:** SECURITY & PRIVILEGE (enterprise-grade, zero-trust)
**Scope:** exclusive-internal legal-AI for a Greek practice (EU/ECHR inside the Greek legal
order). Not a public SaaS. Architecture, trust boundaries, memory, verification, security,
operations — IN scope. Corpus volume/quality — OUT of scope.
**Purpose:** the complete security architecture that makes client confidentiality and legal
professional privilege **structurally**, not merely procedurally, enforced — such that the
default behavior of the system is *containment*, information flows only along typed, audited
channels, publication is fail-closed, and every human and machine action is tamper-evidently
recorded, including the actions of those who watch.

**Claim-status discipline (mandatory, per component):** every load-bearing claim carries exactly
one tag — **THEOREM** (machine-checked property of a formal object) / **DESIGN-ENTAILED** (follows
from the architecture if built as specified) / **IMPLEMENTED** (code exists in repo) /
**DEMONSTRATED** (shown once under controlled conditions) / **EMPIRICAL** (measured, holds within
sampled conditions) / **HYPOTHESIS** (plausible, untested) / **UNKNOWN**. Proof-checking is never
equated with correctness of a natural-language formalization. Model access is never equated with
idea inclusion. No trade-off is hidden as an engineering detail. Unresolved contradictions are
marked **[BLOCKING]** and do not silently downgrade.

**Relation to prior repo artifacts.** `deployment/LAWMAX-THREAT-MODEL.md` defines the *publication/
provenance* adversary (win condition: an adversary must break SHA-256/a signature or change the
published law itself). This document is the *internal-perimeter* complement: it defines the
adversary who is **inside** the firm — a compromised endpoint, a curious associate, a captured
model, a malicious dependency, a subpoena-driven insider — and the controls that keep matter
confidences and privilege intact against them. Where the two meet is the **Publication Gateway**
(§7), the single sanctioned crossing from private to public, specified here in full.

---

## 0. One-paragraph honest summary

The system is a **default-deny, compartmentalized enclave**. Every unit of privileged work lives in
a per-matter cryptographic compartment; nothing crosses a compartment boundary except through an
explicit, typed, human-or-policy-authorized **grant**, and every crossing is logged in a
tamper-evident ledger that also records the people and the machines that read it. There are exactly
**two** sanctioned egress paths out of the enclave — a model-inference gateway with per-data-class
posture, and the fail-closed Publication Gateway — and everything else is dropped by a default-deny
network and a mediated-syscall boundary. Ethical walls and conflicts screens are enforced as
**infrastructure predicates on the access path**, not as HR policy: a walled user's request for a
walled matter cannot be *served*, not merely *discouraged*. The strongest guarantees here are
**DESIGN-ENTAILED** (compartment isolation, default-deny egress, fail-closed publication) and a
narrow set are reducible to **THEOREM** (the publication predicate is false unless all gate
conditions hold; the grant algebra is monotone and non-transitive; the audit chain is
append-only). The irreducible residue is **EMPIRICAL and stated plainly**: side channels, a fully
compromised hypervisor/host, collusion at or above the dual-control threshold, and the fidelity of
DLP/privilege classifiers to actual privilege — none of these is provable to zero, all are
narrowable and independently auditable, and each is named as a residual risk with a named owner.

---

## 1. Design axioms (the security constitution — binding, non-negotiable)

These are the invariants the rest of the document instantiates. Each is stated as a target with a
status; violations are **[BLOCKING]**.

- **AX-1 · Default deny, everywhere.** Absence of an explicit allow is a deny — for network egress,
  cross-matter reads, publication, privilege escalation, and key use. No implicit path exists.
  *[DESIGN-ENTAILED]*
- **AX-2 · Confidentiality is the ground state.** All matter data, strategies, internal reasoning,
  model traces, proof objects, and memories are private by construction. Public is the rare,
  gated exception (§7), never a default or a side effect. *[DESIGN-ENTAILED]*
- **AX-3 · Structural over procedural.** Prefer designs that make a violation *impossible to
  express* over designs that *forbid* an expressible violation. An ethical wall is a predicate the
  access path evaluates, not a memo. (Directly instantiates the creator's supreme law: eliminate
  the error *class*, do not guard a wrong shape.) *[DESIGN-ENTAILED]*
- **AX-4 · No LLM on the trusted path.** No model output is authoritative. Models *propose*;
  deterministic, verifiable machinery *decides* what may be relied on, stored as authoritative, or
  published. Honest ignorance ("I do not know") over a guess. *[DESIGN-ENTAILED, consistent with
  repo axiom Θ13]*
- **AX-5 · Fail closed.** Every gate, on any error, ambiguity, missing evidence, expired credential,
  unreachable dependency, or unverifiable state, **denies** and emits an auditable refusal. There
  is no "fail open for availability." Availability is met by redundancy of the *deny-capable* path,
  never by weakening it. *[DESIGN-ENTAILED]*
- **AX-6 · Two-person integrity for irreversible/high-blast-radius acts.** Publication, key
  ceremonies, grant-policy changes, wall changes, retention/deletion of privileged data, and
  production model adoption require **dual control** (two distinct authenticated humans in distinct
  roles). No single principal — human or service — can effect them alone. *[DESIGN-ENTAILED]*
- **AX-7 · Everything is logged, including the watchers.** Every security-relevant event — human
  and machine, including reads of the audit log itself and actions by administrators — appends to a
  tamper-evident, externally-anchored ledger. There is no un-audited privileged action. *[DESIGN-
  ENTAILED]*
- **AX-8 · Explicit, typed information flow.** Data carries a classification and a matter label;
  every boundary crossing is a typed operation with a declared source class, sink class, and
  authority. Untyped movement of data does not exist as an API. *[DESIGN-ENTAILED]*
- **AX-9 · Minimize and name the trusted base.** The set of components whose compromise breaks a
  guarantee is enumerated per guarantee (its TCB). Guarantees are stated *modulo* their TCB, never
  absolutely. *[DESIGN-ENTAILED / honest-limit discipline]*
- **AX-10 · One seat per concept.** Each control has exactly one authoritative implementation
  (single point of policy decision, single audit sink, single egress broker). No wrappers, no
  duplicate enforcement seats — duplication is itself an attack surface and a drift source. *[repo
  law — "μία έδρα ανά έννοια"]*

**Contradiction watch (declared, not hidden):** AX-5 (fail closed) vs. requirement 5 (real
procedural deadlines are correctness requirements). A gate that fails closed can miss a court
deadline. This is **resolved, not waived**, in §9.4 (deadline-safe fail-closed: the *deny* is fast
and loud, escalates to a named human on a bounded timer, and the *fallback is a human filing by the
lawful traditional route* — never an automatic downgrade of the gate). It is **not [BLOCKING]**
because the resolution keeps the gate closed while preserving the lawful deadline path outside the
automated channel.

---

## 2. Trust boundaries, zones, and the reference monitor

### 2.1 Zone model (concentric, each a hard boundary)

```
Z0  AIR-GAP / OFFLINE ROOT        cold key ceremony, transparency-log root, offline backups
Z1  SECURE CORE (enclave)         matter compartments, memory kernel, proof objects, model traces
Z2  MEDIATION LAYER               Policy Decision Point, Grant Broker, Egress Broker, Audit Ledger
Z3  MODEL PLANE                   on-prem inference (isolated), redaction/DLP engines
Z4  PUBLICATION STAGING           publication gateway pipeline (write-once staging)
Z5  DMZ / EGRESS EDGE             model-inference gateway to external APIs (only if class permits)
Z6  PUBLIC                        published codified law/case-law + release receipts
ZH  HUMAN WORKPLANE              analyst/lawyer endpoints (thin, attested)
```

**Boundary rule (AX-1/AX-8):** every arrow between zones is a *named, typed channel* through Z2.
There is no Z1↔Z5, no ZH↔Z1 direct, no Z3↔Z6. Z1 talks only to Z2. Z2 is the sole zone that may
address the Audit Ledger for writes, the Grant Broker for decisions, and the Egress Broker for
outbound. *[DESIGN-ENTAILED]*

### 2.2 The reference monitor (single decision seat — AX-10)

- **Interface.** `decide(request) -> {ALLOW(obligations…) | DENY(reason, refusal-receipt)}`. Every
  privileged operation in the system routes through one **Policy Decision Point (PDP)**. The PDP is
  the only component authorized to answer "may this flow happen?" Enforcement is at **Policy
  Enforcement Points (PEP)** co-located with each resource (compartment store, egress broker,
  publication pipeline, key service, model plane).
- **Invariant (reference-monitor properties, classical):** *complete mediation* (no privileged
  path bypasses the PDP — enforced structurally: PEPs are the only holders of resource
  capabilities, and capabilities are unforgeable tokens the PDP mints), *tamper-resistance* (PDP
  runs in Z2 on attested hosts; its policy is signed and versioned), *verifiability* (PDP is small,
  deterministic, LLM-free, and its decisions are reproducible from `(request, policy-version,
  grant-set, wall-set, clock)`). *[DESIGN-ENTAILED; the determinism + LLM-free properties are
  what make decisions replayable and auditable]*
- **Failure mode.** PDP unreachable/ambiguous ⇒ PEP denies (AX-5). PDP compromise ⇒ full policy
  bypass (it is in the TCB of every guarantee; hence attested boot, signed policy, dual-control
  policy change, and PDP-decision mirroring to the audit ledger for out-of-band detection).
- **Verification.** (a) *Bypass test*: fuzz every resource API asserting no privileged effect
  occurs without a matching PDP `ALLOW` in the ledger (a decision→effect join with zero orphan
  effects). (b) *Determinism test*: replay recorded `(request, context)` tuples; decision must be
  bit-identical. (c) *Policy-diff review*: every policy version is a dual-controlled, signed diff
  with a human-readable rationale. *[verification is DESIGN-ENTAILED; passing it would be
  DEMONSTRATED]*

---

## 3. Zero-trust matter isolation (per-matter compartments)

### 3.1 The compartment as the unit of confidentiality

- **Definition.** A **matter compartment** `C_m` is the complete state of one legal matter:
  documents, facts, strategy notes, model prompts/traces for that matter, derived analyses, proof
  objects, memory entries, and its own data-encryption key `DEK_m`. `C_m` is the atom of
  isolation: nothing about matter *m* exists outside `C_m` except (i) a de-identified index entry
  used only by the conflicts engine (§4) and (ii) explicit grant records (§3.3).
- **Cryptographic realization.** Each `C_m` is encrypted at rest under a unique `DEK_m`; `DEK_m` is
  wrapped by a per-compartment key encryption key held in the KMS/HSM (§8) and released **only** on
  a PDP `ALLOW` that names the matter, the principal, and the purpose. Two matters never share a
  DEK. Deleting `DEK_m` (crypto-shred) renders `C_m` unrecoverable — the primitive behind lawful
  destruction and end-of-retention. *[DESIGN-ENTAILED]*
- **Compute isolation.** Work on `C_m` runs in a per-matter ephemeral execution context (isolated
  namespace/VM/enclave per active matter session) with no ambient authority: it can address only
  `C_m`'s store handle and the Z2 brokers. Cross-matter memory sharing at the process level does
  not exist — a session holds exactly one matter's DEK at a time. *[DESIGN-ENTAILED]*

- **Interface.**
  `open_matter(principal, matter_id, purpose) -> session_cap | DENY`
  `read(session_cap, object_id) / write(session_cap, object) / derive(...)` — all scoped to the
  session's single matter; any `object_id` outside the compartment resolves to DENY at the PEP,
  never a silent empty result (fail-closed, and *distinguishable* refusal so callers cannot infer
  existence by timing — §3.5).
- **Invariant I-ISO (isolation).** For principals `p` and matters `m ≠ n`: data of `C_n` is
  reachable in a session opened on `C_m` **iff** an active typed grant `n→m` exists and the PDP
  authorized it for `p`'s purpose. Absent that, information flow `C_n → C_m` is nil. *[DESIGN-
  ENTAILED; the DEK-per-matter + single-DEK-per-session construction is what makes it structural
  rather than checked]*
- **Failure modes & mitigations.**
  - *Shared cache/temp leakage* between compartment sessions → per-session ephemeral scratch,
    zeroized on close; no shared writable tmp; scratch encrypted under session-ephemeral key.
  - *Model plane as a cross-matter conduit* (a model that saw `C_n` answering about `C_m`) → the
    model plane is **stateless per request** and **per-matter-scoped**: no cross-matter context
    window, no shared vector index across matters (each matter has its own index under `DEK_m`), no
    fine-tuning on matter data that mixes matters (§6.4). *[DESIGN-ENTAILED; the "no shared index"
    is the load-bearing control — a shared RAG index is the classic silent cross-matter leak]*
  - *Memory kernel as a conduit* → memory entries are compartment-tagged and stored under `DEK_m`;
    cross-matter recall requires a grant (§3.3, §10). *[DESIGN-ENTAILED]*
- **Verification.** (a) *Isolation red-team*: automated prover attempts to read `C_n` from a
  `C_m` session across every API; expected result: DENY on all, zero data bytes returned.
  (b) *Crypto-shred test*: after `DEK_m` deletion, exhaustive scan proves no plaintext of `C_m`
  recoverable from stores, caches, backups (backups are also per-DEK — §8.5). (c) *Index-scope
  audit*: assert each vector/keyword index file decrypts under exactly one DEK. *[DESIGN-ENTAILED
  test plan]*

### 3.2 Classification & labeling (typed data — AX-8)

Every object carries an immutable, cryptographically-bound label:
`{matter_id, class ∈ {PRIVILEGED, WORK-PRODUCT, CLIENT-CONFIDENTIAL, INTERNAL, PUBLISHABLE-CANDIDATE,
PUBLIC}, provenance, retention-tag}`. The label is part of the object's authenticated bytes (signed/
MAC'd with the object), so relabeling is detectable and is itself a dual-controlled, audited
operation. Class governs which egress posture (§6) and which publication stage (§7) may ever touch
it. **PRIVILEGED never reaches Z5**; only `PUBLIC` (post-gateway) reaches Z6. *[DESIGN-ENTAILED]*

### 3.3 Cross-matter access: explicit typed grants only

- **Grant object.**
  `Grant{ id, from_matter, to_matter, scope(object-set | query-class), grant_type, granted_by[2],
  purpose, not_before, not_after, one_time?, revoked?, audit_ref }`.
  `grant_type ∈ {PRECEDENT-REUSE (de-identified only), CO-COUNSEL, CLIENT-CONSENTED-SHARE,
  CONFLICTS-CLEARED-MERGE, SUPERVISORY-REVIEW, LITIGATION-HOLD-EXPORT}`. Each type carries its own
  obligations (e.g. PRECEDENT-REUSE forces de-identification transform on read; CO-COUNSEL requires
  a recorded client authorization reference).
- **Algebra & invariants.**
  - **Non-transitive (I-GRANT-NT).** A grant `n→m` and `m→k` do **not** compose to `n→k`. Each edge
    is minted explicitly. Transitivity is the classic confused-deputy leak; it is *not expressible*
    in the grant algebra. *[THEOREM-able: the reachability relation is defined as the direct-edge
    set, not its transitive closure — provable that closure ≠ relation]*
  - **Non-ambient / non-amplifying.** A grant conveys ≤ the grantor's own access; scope is
    intersected, never unioned upward. *[DESIGN-ENTAILED]*
  - **Time-bounded & revocable.** Expired or revoked ⇒ PDP denies; revocation is effective on the
    next access and forces DEK re-wrap so cached capabilities die. *[DESIGN-ENTAILED]*
  - **Dual-controlled to create** for all types except SUPERVISORY-REVIEW within an already-shared
    team (still logged). *[DESIGN-ENTAILED, AX-6]*
  - **Conflicts-gated.** No grant is minted if it would breach an active ethical wall (§4); the
    Grant Broker calls the Conflicts engine as a hard precondition. *[DESIGN-ENTAILED]*
- **Interface.** `request_grant(...) -> pending`; `approve_grant(pending, approver2) -> Grant |
  DENY`; `revoke_grant(id, reason)`; `list_grants(matter) (audited read)`.
- **Failure modes.** Over-broad scope → scope must be an explicit object-set or a typed query-class,
  never `*`; a `*` scope is rejected at schema level. Stale grant after client withdraws consent →
  revocation + re-wrap; litigation-hold exports are copy-with-watermark-and-receipt, tracked as
  first-class exported objects.
- **Verification.** (a) *Transitivity test*: assert no 2-hop inference of access. (b) *Amplification
  test*: assert granted scope ⊆ grantor scope. (c) *Revocation latency test*: measure time from
  revoke to effective deny (target: next access; DEK re-wrap bounded). *[DESIGN-ENTAILED]*

### 3.4 The conflicts/index seam (necessary de-identified shared state)

To detect conflicts (§4) the system needs *some* cross-matter visibility — party names, adverse
parties, subject overlaps. This is the one deliberate, minimized shared surface. It stores **only**
de-identified/normalized conflict keys (party identifiers hashed with a firm-wide salt held in HSM,
plus coarse subject tags), **never** matter substance. Reads of it are audited; it cannot be used
to retrieve matter content (it holds none). This is named explicitly as a **residual shared
surface** with a named owner, because "zero shared state" is incompatible with "detect conflicts" —
an honest trade-off, not hidden. *[DESIGN-ENTAILED; the trade-off is declared per protocol]*

### 3.5 Existence-hiding (metadata confidentiality)

Whether matter *m* or client *X* exists is itself privileged. DENY responses are **uniform and
constant-time** with respect to existence: "not authorized" is indistinguishable from "does not
exist." Directory/enumeration APIs are per-principal filtered. *[DESIGN-ENTAILED; constant-time
DENY is EMPIRICAL to verify — timing side channels are narrowed, not proven zero, §12]*

---

## 4. Ethical walls / conflicts screens as enforced infrastructure

The Bar-law duty (Greek Code of Lawyers / Κώδικας Δικηγόρων conflict rules; EU professional-secrecy;
ECHR Art. 8 correspondence privilege) is realized as a **predicate on the access path**, not a
policy poster.

- **Wall object.** `Wall{ id, walled_principals[], walled_matters[]/client[], reason(conflict-ref),
  established_by[2], established_at, scope(bidirectional?), review_date }`. A wall says: principals
  in set `P` may not access matters in set `M`, and (bidirectional) work-product about `M` may not
  reach `P`.
- **Enforcement (I-WALL).** The PDP consults the active wall-set on **every** `open_matter`, every
  grant mint, every search, every model request, and every publication candidate. If a request
  would cross a wall, it is **DENY** — the request is *unservable*, not "logged and allowed."
  Screening is thus a runtime invariant: a screened lawyer literally cannot obtain a session
  capability for the conflicted matter, cannot see it in any listing, and cannot receive its
  work-product via a grant, a shared index, or a model answer. *[DESIGN-ENTAILED — this is AX-3 in
  its sharpest form: the conflict is structurally inexpressible for the walled principal]*
- **Automatic wall proposal.** On new-matter intake, the Conflicts engine (§3.4) runs against the
  de-identified index and **proposes** walls for human confirmation (dual-control to establish).
  Proposal is advisory (LLM/heuristic may assist proposal — Z3), but *establishment and enforcement
  are deterministic and human-authorized* (AX-4: no model on the trusted path; a model may surface
  a candidate conflict, it may never clear or impose a wall). *[DESIGN-ENTAILED]*
- **Failure modes.**
  - *Wall added after exposure* (lawyer already saw the matter) → wall records prior-access facts;
    an **exposure report** is generated for the ethics partner; the wall still blocks future access;
    remediation (e.g. withdrawal) is a human legal decision the system surfaces, never decides.
  - *Indirect leak via shared model context* → precluded by per-matter model scoping (§3.1, §6.4).
  - *Wall bypass via admin* → admins are subject to walls too (§5); wall changes are dual-controlled
    and audited; there is no "admin override" that silently pierces a wall (an emergency
    break-glass exists but is loud, time-boxed, dual-controlled, and post-reviewed — §5.4).
- **Verification.** (a) *Wall-crossing red-team*: for each wall, attempt access via every path
  (direct open, search, grant request, model query, publication candidate); expected DENY on all.
  (b) *Screen-completeness audit*: assert the PDP evaluates wall-set on 100% of privileged
  operations (the bypass test of §2.2 covers this). (c) *Exposure-report correctness*: seed a
  known prior access, add wall, assert report lists it. *[DESIGN-ENTAILED]*

**Honest limit.** Walls constrain the *system*. They cannot constrain a lawyer's own memory or
out-of-band conversation. The system enforces information walls in its own trust domain and produces
the audit trail that supports the firm's human screening obligations; it does not and cannot claim
to enforce the psychological wall. *[stated limit, not a claim of completeness]*

---

## 5. Insider threat model

The primary adversary for a private firm system is **the authorized insider**: a curious associate,
a departing lawyer exfiltrating a client book, a compromised admin credential, a coerced employee,
or an over-broad service account.

### 5.1 Roles & least privilege (RBAC × ABAC, matter-scoped)

Access = `role-permissions ∩ matter-grants ∩ ¬walls ∩ purpose ∩ posture`. Roles are coarse
capability bundles; actual reach is always the *intersection* with per-matter grants and walls — no
role conveys firm-wide matter access.

| Role | Can | Cannot (structurally) |
|---|---|---|
| Associate / Lawyer | open assigned matters; run analyses; request grants; draft publication candidates | read unassigned matters; approve own publication; change walls; use keys; read audit raw |
| Supervising Partner | above + supervisory-review grants within team; approve grants | pierce walls; unilaterally publish; alter audit; export client book |
| Ethics/Conflicts Partner | establish/lift walls (dual); read conflict index | read matter substance without its own grant |
| Publication Officer | operate Publication Gateway stages; give one of two publication approvals | approve alone; bypass DLP/redaction; self-approve authored content |
| Security/Platform Admin | operate infra, rotate keys (dual ceremony), manage nodes | read matter plaintext; read privileged content; alter audit ledger; pierce walls |
| Auditor / Compliance | read audit ledger; run affected-matter scans | write matters; change policy; publish |
| Records/Retention Officer | execute retention/legal-hold (dual) | read substance beyond labels; delete under hold |
| Service accounts (PDP, brokers, model plane) | narrowly scoped machine capabilities | interactive login; ambient authority; cross-role |

**Invariant I-LP (least privilege / separation of duties):** no single role can (author ∧ approve)
publication, (change wall ∧ access walled matter), (administer infra ∧ read plaintext), or (act ∧
audit its own act). Admins run the boxes but **cannot read the content** — matter plaintext is only
decryptable via PDP-authorized DEK release tied to a matter-assigned principal + purpose, and admin
roles are not such principals. *[DESIGN-ENTAILED; the "admin cannot read plaintext" property rests
on KMS release policy (§8) — its TCB includes the KMS/HSM and the PDP]*

### 5.2 Dual control for sensitive operations (AX-6)

Enumerated dual-control operations, each requiring two distinct authenticated humans in distinct
roles, both recorded:

1. Publication release (Publication Officer + authoring lawyer/partner, neither self-approving §7).
2. Key ceremonies: generation, rotation, wrap-key export, HSM policy change (§8).
3. Grant-policy / wall-set changes.
4. Retention destruction and legal-hold placement/lift.
5. Production model adoption / model-plane config change (§6).
6. Break-glass emergency access (§5.4).
7. Audit-ledger administrative operations (compaction, anchor rotation — never edit).

**Interface.** `propose(op) -> ticket`; `co_authorize(ticket, principal2)` with liveness (both
approvals within a bounded window, distinct hardware tokens, distinct sessions). **Invariant:** the
effecting service holds a capability that is only minted on *two* valid distinct approvals; a single
approval yields no capability (fail-closed). *[DESIGN-ENTAILED]*

### 5.3 Tamper-evident audit of humans too (AX-7)

Every human action — logins, matter opens, reads, searches, drafts, grant requests/approvals, wall
views, exports, publication steps, **and reads of the audit log itself** — is an entry in the Audit
Ledger (§11). Administrators and auditors are *subjects* of the same ledger. There is no role whose
actions are invisible. Anomaly detection (mass reads, off-hours bulk export, first-access-then-
resign patterns) runs against the ledger and alerts the *dual* of the actor's chain (an admin
anomaly alerts security-independent auditors, and vice versa — §11.4). *[DESIGN-ENTAILED; anomaly
*detection quality* is EMPIRICAL]*

### 5.4 Break-glass (emergency access) — loud, not silent

Genuine emergencies (an incapacitated sole custodian of a matter, an imminent filing) get a
break-glass path: **dual-controlled, time-boxed (auto-expiring), scope-minimized, and maximally
loud** — it pages the ethics partner and security lead in real time, writes a high-severity ledger
event, and forces a mandatory post-hoc review with a written justification within N hours or the
involved principals' access is suspended. Break-glass never pierces an ethical wall (a wall breach
is a conflicts decision, not an emergency-ops decision). *[DESIGN-ENTAILED]*

### 5.5 Exfiltration resistance

- **No bulk export path** without Records-Officer dual control + watermarking + per-object receipts.
- **Egress DLP** (§6, §7) inspects any outbound content for matter labels/privilege markers.
- **Copy/print/screenshot** from the human workplane (ZH) are governed by endpoint posture
  (thin/attested clients, watermarked rendering, clipboard/print policy). *[DESIGN-ENTAILED;
  endpoint controls are EMPIRICAL — a determined insider with a camera is out of software scope, a
  stated limit]*
- **Departing-employee runbook:** immediate credential + token revocation, DEK re-wrap for their
  matters, grant revocation cascade, and a retrospective affected-matter access review (§10).

---

## 6. Egress control (default-deny; exactly two sanctioned paths)

### 6.1 The perimeter

Z1/Z3 have **no route to the internet.** Default-deny at network (no default gateway, deny-all
egress firewall, no DNS to public resolvers from core zones) *and* at the syscall/broker layer
(outbound is not an ambient capability — only the Egress Broker holds it). The **only** two
sanctioned egress channels:

1. **Model-Inference Gateway (§6.3)** — Z5 edge to *external* model APIs, usable **only** for data
   classes whose posture permits it, after redaction/minimization.
2. **Publication Gateway (§7)** — the only path to Z6 (public), fail-closed, for `PUBLIC`-class
   post-gateway artifacts only.

Everything else — telemetry, crash dumps, dependency fetches, package installs, model-weight
downloads, OS updates — goes through **brokered, allow-listed, logged** channels that are *not*
data-egress channels (they are inbound-supply channels, §6.5), and none may carry matter data.
*[DESIGN-ENTAILED]*

- **Invariant I-EGR.** For any byte `b` leaving Z1/Z3, there exists an Egress-Broker record with a
  PDP `ALLOW`, a declared data class, and (for class-restricted paths) a redaction attestation.
  No `ALLOW` ⇒ no byte leaves. *[DESIGN-ENTAILED]*
- **Failure mode.** Broker down ⇒ no egress (fail-closed; on-prem tier §6.6 keeps the firm working
  offline). Covert channels (DNS tunneling, timing) → core zones have no DNS egress and no direct
  sockets; the broker is the only speaker and it speaks only allow-listed protocols to allow-listed
  hosts with content inspection. *[DESIGN-ENTAILED; covert-channel elimination is EMPIRICAL — §12]*

### 6.2 Data-class egress posture matrix

| Class | On-prem model | External model API (Z5) | Publication (Z6) |
|---|---|---|---|
| PRIVILEGED | allow | **never** | never (must be transformed to PUBLISHABLE-CANDIDATE first) |
| WORK-PRODUCT | allow | **never** | never directly |
| CLIENT-CONFIDENTIAL | allow | **never** | never directly |
| INTERNAL | allow | only after DLP + minimization, if policy permits, no client identifiers | never directly |
| PUBLISHABLE-CANDIDATE | allow | only de-identified extract, if needed | only via §7 gateway |
| PUBLIC | allow | allow | already public |

**Load-bearing rule:** privileged/client/work-product data **never** transits an external API. If
external model capability is desired for such matters, it is available **only** via the on-prem
model tier (§6.6). This is the contractual+technical answer to "what leaves to external APIs":
*for privileged work, nothing.* *[DESIGN-ENTAILED]*

### 6.3 Model-Inference Gateway (per-class posture)

- **Interface.** `infer(request{class, matter_id, prompt, purpose}) -> completion | DENY`. The
  gateway (Z2 broker fronting Z3 on-prem and, only for permitted classes, Z5 external) selects the
  backend by class per the matrix, applies **input minimization/redaction** before any external
  call, strips matter labels from external payloads, and records the full request/response trace to
  the matter compartment (traces are privileged, stored under `DEK_m`).
- **Invariants.** (i) class→backend selection is deterministic and policy-signed; (ii) no external
  call for PRIVILEGED/WORK-PRODUCT/CLIENT-CONFIDENTIAL — *structurally*: the external backend
  capability is simply not in the gateway's routing table for those classes; (iii) every external
  call carries a redaction attestation. *[DESIGN-ENTAILED]*
- **Failure mode.** Redaction uncertain ⇒ route to on-prem or DENY, never send raw externally
  (fail-closed). External backend returns unexpected content ⇒ treated as untrusted input, never
  written as authoritative (AX-4).
- **Verification.** (a) Payload-capture test on the Z5 wire asserting zero privileged-class bytes,
  zero client identifiers, matter labels stripped. (b) Routing-table audit: privileged classes have
  no external route. (c) Redaction-attestation completeness on all external calls. *[DESIGN-
  ENTAILED]*

### 6.4 Model-as-conduit controls (the subtle egress)

A model is an egress channel if it *remembers*. Controls: **no training/fine-tuning on matter data
that crosses matters** (per-matter adapters at most, stored under `DEK_m`, never merged into a
shared base without a de-identification + dual-control gateway); **no shared context window across
matters**; **no shared vector index** (§3.1); external APIs are used **stateless, no-retention** —
enforced contractually (zero-retention/no-training addenda, §6.7) *and* technically (only
non-privileged, de-identified payloads ever reach them, so even a contract breach leaks nothing
privileged). *[DESIGN-ENTAILED; the technical control is primary because it does not rely on the
vendor honoring the contract]*

### 6.5 Inbound supply channels (not data egress)

Dependency mirrors, model-weight registries, OS/security updates are pulled through an **inbound
proxy** into a quarantine zone, verified (§13), and promoted — they never carry outbound matter
data, and the core zones never reach the internet to fetch them (a broker does, into quarantine).
*[DESIGN-ENTAILED]*

### 6.6 On-prem model tiers (so privileged work needs no external API)

- **Tier A — fully on-prem, air-gappable:** open-weight models run inside Z3 on firm hardware, no
  external calls, usable for **all** classes including PRIVILEGED. This is the default for
  privileged reasoning. *[DESIGN-ENTAILED]*
- **Tier B — on-prem via private endpoint with contractual + network isolation** (e.g. a dedicated
  tenant with zero-retention, in-region, VPC-isolated): usable for INTERNAL/PUBLISHABLE-CANDIDATE
  after DLP, **never** PRIVILEGED.
- **Tier C — public external API:** only PUBLIC or explicitly-cleared de-identified extracts.
- Model choice is a *capability decision, not a cost decision* (per binding condition 4): the
  firm may run many models on-prem in parallel (adversarial-critic ensembles, §11.4) without
  budget constraint. *[DESIGN-ENTAILED]*

### 6.7 Vendor / model risk (contractual + technical)

For any external model/vendor touched at all: **technical mitigations rank above contractual** —
(1) only de-identified/non-privileged payloads ever leave (so breach impact is bounded by
construction); (2) zero-retention, no-training, in-region, sub-processor-disclosed contractual
addenda; (3) provider attestation (SOC2/ISO/EU data-residency) verified, not assumed; (4) a
**data-processing inventory** listing every external endpoint, what class it may see, and the legal
basis. The honest position: *contracts are enforced after the fact; the architecture ensures there
is nothing privileged to leak in the first place.* *[DESIGN-ENTAILED; vendor honoring contract is
UNKNOWN and therefore not relied upon]*

---

## 7. The fail-closed PUBLICATION GATEWAY (full detail)

The single sanctioned crossing private→public. **Nothing becomes public except a `PUBLIC`-class
artifact minted by this gateway; the gateway mints one only when every stage passes.** This is the
sharpest instance of AX-3/AX-5 and connects to the repo's provenance threat model (release receipts).

### 7.1 Master invariant

- **I-PUB (publication predicate).** `may_publish(artifact) = privilege_cleared ∧ dlp_clean ∧
  redaction_verified ∧ authority_valid ∧ human_approved(2 distinct) ∧ receipt_minted`. Publication
  occurs **iff** the conjunction holds. Any stage FAIL/ABSTAIN/ERROR ⇒ `may_publish = false` ⇒ no
  publication, and a **refusal receipt** is emitted. *[THEOREM-able: the predicate is a monotone
  conjunction; the publisher's only write-to-Z6 capability is minted solely by the gateway on the
  full conjunction — provable that no path publishes without all conjuncts. This mirrors the repo's
  "23-gate" pattern and Θ13/fail-closed axioms.]*
- **Staging is write-once (Z4).** Candidates flow through append-only staging; no stage can be
  skipped or reordered; each stage's output is signed and fed as the next stage's authenticated
  input (a hash chain), so a bypass is detectable. *[DESIGN-ENTAILED]*

### 7.2 The pipeline (ordered, fail-closed at each stage)

**Stage 0 — Intake & scope binding.** A candidate is a `PUBLISHABLE-CANDIDATE`-class object with a
declared publication purpose (e.g. "codified statute X as of date D," "anonymized case-law
digest"). Bound to originating matter(s) for audit; the *content to be published must be
public-by-nature* (law text, case-law) — client substance is never a publication candidate. A
candidate that carries client facts is rejected at intake. *[DESIGN-ENTAILED]*

**Stage 1 — Privilege review.** Deterministic + human. Checks: no privileged content, no
work-product, no client identifiers, no confidential strategy, no attorney mental impressions. The
**privilege classifier** (may use models for *proposal/flagging* only, Z3) produces candidate
findings; a **named human privilege reviewer** adjudicates. FAIL/uncertain ⇒ stop.
*Invariant:* a model may raise a privilege flag but may never clear one (AX-4). *[DESIGN-ENTAILED;
classifier recall vs. actual privilege is EMPIRICAL — see §7.6 honest limit]*

**Stage 2 — Confidentiality / DLP scan.** Independent engine scans for: names/PII, client
identifiers, matter numbers, internal markings, secrets/keys, quasi-identifiers enabling
re-identification (k-anonymity/linkage check against the de-identified index), and any label ≠
`PUBLIC`/`PUBLISHABLE-CANDIDATE`. Any hit ⇒ FAIL (fail-closed). DLP is **independent** of the
privilege classifier (defense in depth, distinct implementations, AX-10 respected because they
decide *different* predicates). *[DESIGN-ENTAILED]*

**Stage 3 — Redaction with verification.** If redaction is required, a redaction transform produces
a redacted artifact, then a **separate verifier** re-scans the *output* and proves the targeted
content is absent (not merely visually hidden — actual byte removal, no hidden layers/metadata/
change-history; documents are flattened and re-serialized). **Redaction is verified by
re-detection, not asserted by the redactor** (author≠checker). Residual-detection FAIL ⇒ stop.
*Invariant I-RED:* published bytes contain none of the flagged spans, confirmed by an independent
re-scan of the exact bytes to be released. *[DESIGN-ENTAILED; "no hidden layer" is verifiable
structurally; adversarial steganographic residue is EMPIRICAL — §12]*

**Stage 4 — Authority validation.** The substantive-correctness gate for legal publications: the
published statement must be bound to authentic source (ΦΕΚ/official gazette, court record) with the
provenance chain the repo threat model requires (content-addressed id, in-force-at-date, source
binding). This validates *authenticity and currency of the legal authority*, **not** the truth of
the underlying law (honest limit: we prove binding to the source, not that the source is correct —
consistent with `LAWMAX-THREAT-MODEL.md §4`). FAIL (stale, unbound, mismatched authority) ⇒ stop.
*[DESIGN-ENTAILED; the source-binding proof is IMPLEMENTED-in-spirit per repo provenance artifacts,
status IMPLEMENTED for the provenance mechanism, DESIGN-ENTAILED for the gateway wiring]*

**Stage 5 — Named human approval (dual control).** Two distinct authenticated humans in distinct
roles (e.g. authoring partner + publication officer), **neither may approve content they authored**
(no self-approval). Each sees the *exact bytes to be released* and the full stage-evidence bundle
(privilege finding, DLP report, redaction verification, authority proof). Approval is a signed
statement over the artifact hash. Single approval ⇒ no release. *[DESIGN-ENTAILED, AX-6]*

**Stage 6 — Immutable signed release receipt.** On full conjunction, mint a release receipt:
`Receipt{ artifact_hash, canonical_bytes_ref, source_authority_binding, stage_evidence_hashes,
approvers[2], timestamp(RFC-3161 multi-TSA anchored), signature(release key, HSM), prev_receipt_root
(transparency chain) }`. The receipt is appended to a **public transparency log** (append-only,
externally anchored) so any third party can later verify *what* was published, *when*, *by whom*,
and *bound to which authority* — and cannot be shown a different history (split-view resistance,
per repo Θ5/Θ2). Only now is the artifact written to Z6. *[DESIGN-ENTAILED; ties into IMPLEMENTED
provenance/receipt machinery in repo]*

### 7.3 Interface

```
submit_candidate(obj, purpose) -> candidate_id
run_stage(candidate_id, stage) -> {PASS(evidence) | FAIL(reason) | ABSTAIN}   # ABSTAIN == FAIL
approve(candidate_id, approver) -> needs_second | released(receipt)           # dual, non-self
status(candidate_id) -> stage-vector + evidence bundle
recall(receipt_id, reason, dual-auth) -> recall_notice                        # §7.5
```

### 7.4 Failure modes

- Any stage error/timeout/dependency-down ⇒ FAIL, no publication, refusal receipt (AX-5).
- Attempt to reorder/skip stages ⇒ impossible: each stage consumes the prior stage's signed output;
  publisher capability requires the Stage-6 receipt which requires the full chain.
- Approver = author ⇒ rejected (SoD). Two approvals from same role ⇒ rejected.
- Model-proposed "clear" ⇒ never dispositive; only human clears (AX-4).

### 7.5 Recall procedure (published-in-error)

Public artifacts can be wrong or contain a missed leak. **Recall** is a first-class, dual-controlled
operation: (1) mint an **append-only recall notice** into the transparency log referencing the bad
receipt (the original is *never* deleted — append-only history, repo Θ2; you cannot un-publish
cryptographically, so you *supersede and annotate*); (2) issue corrected artifact via the full
gateway if applicable; (3) trigger the incident-response affected-matter scan (§9/§10) to assess
exposure and legal-notification duties; (4) propagate takedown requests to any downstream mirrors
(best-effort — the honest limit: once public and mirrored, technical recall is not guaranteed; the
receipt/transparency mechanism ensures the *record of recall* is authoritative even if a copy
persists). *[DESIGN-ENTAILED; completeness of downstream takedown is UNKNOWN and stated as such]*

### 7.6 Honest limits of the gateway (no hidden trade-offs)

- Privilege/DLP classifiers have non-zero false-negative rates against *actual* privilege — a
  natural-language judgment. **Mitigation, not elimination:** (a) mandatory human privilege review
  (a human, not the classifier, is the clearing authority); (b) publish-only-public-by-nature-
  content policy at intake (client substance is never a candidate, shrinking the leak surface to
  quasi-identifiers); (c) defense-in-depth (privilege ∧ DLP ∧ redaction-reverify are independent);
  (d) recall + transparency for the residual. The claim is **"leak probability is driven low and
  every residual is auditable and recallable," not "zero leak"** — proof-checking the pipeline
  predicate is *not* the same as the natural-language judgment "this contains no privilege" being
  correct. *[EMPIRICAL residual, explicitly not equated with the THEOREM about the predicate]*

---

## 8. Key management

### 8.1 Hierarchy & seats (AX-10: one KMS seat)

```
Offline Root of Trust (Z0, air-gapped, M-of-N split, HSM)     — never online
  └─ Domain/Signing Roots (release key, audit-anchor key, policy-signing key)  — HSM, online-guarded
      └─ Key-Encryption Keys (per-compartment KEK)              — HSM
          └─ Data-Encryption Keys (DEK_m, per matter)           — wrapped, released per PDP ALLOW
      └─ Transport/session-ephemeral keys                        — short-lived, memory-only
```

- **Storage.** All long-lived private keys in HSM (FIPS-validated); DEKs never exist in plaintext
  outside an authorized session's memory; released only on PDP `ALLOW` naming matter+principal+
  purpose. *[DESIGN-ENTAILED]*
- **Invariant I-KEY.** Matter plaintext is decryptable **iff** the HSM releases `DEK_m`, which
  happens **iff** PDP authorized a matter-assigned principal for a purpose. Admins/infra roles are
  not such principals ⇒ *admins cannot read plaintext* (the §5.1 property). *[DESIGN-ENTAILED; TCB
  = HSM + PDP]*

### 8.2 Ceremonies & lifecycle

Generation, rotation, wrap-export, destruction are **dual-controlled ceremonies** (AX-6), scripted,
witnessed, and logged to the ledger. Rotation is scheduled and on-demand (post-incident). Key
**revocation** cascades: revoke → re-wrap affected DEKs → invalidate cached capabilities.
Crypto-shred (§3.1) is DEK destruction for lawful data destruction/retention expiry. *[DESIGN-
ENTAILED; see repo `LAWMAX-KEY-LIFECYCLE-SPEC` lineage / `keys/` dir]*

### 8.3 Signing keys separation

Release key (Publication receipts), audit-anchor key (ledger), and policy-signing key (PDP policy)
are **distinct**, in distinct HSM slots, with distinct dual-control quorums. Compromise of one does
not forge the others. Signing is HSM-resident (key never leaves). *[DESIGN-ENTAILED]*

### 8.4 Failure modes

Key compromise ⇒ rotate + re-wrap + affected-matter scan (§10) + transparency note if a signing key
(so verifiers learn the trust change out-of-band — repo Θ9). HSM unavailable ⇒ fail-closed (no
decryption, no signing, no publication) with the offline backup ceremony as recovery. Lost quorum
member ⇒ M-of-N tolerates up to N−M losses; below quorum ⇒ documented recovery from Z0 root.
*[DESIGN-ENTAILED]*

### 8.5 Backups (also compartmented)

Backups are per-DEK encrypted (a backup is ciphertext + wrapped keys), stored offline (Z0), so a
backup theft yields nothing without HSM-held wrap keys, and crypto-shred also renders backups
unrecoverable (no plaintext backup escapes retention/deletion policy). *[DESIGN-ENTAILED]*

### 8.6 Verification

(a) *Admin-cannot-read test*: an infra-admin credential attempts matter decryption end-to-end;
expected: HSM refuses DEK release (no matter-principal binding). (b) *Signing-isolation test*:
attempt to sign a receipt with the audit key / policy key; expected: wrong-slot refusal. (c)
*Crypto-shred test*: post-DEK-destruction plaintext-recovery attempt across live+backup stores
returns nothing. *[DESIGN-ENTAILED test plan]*

---

## 9. Incident response (including affected-matter scan)

### 9.1 Detection sources

Ledger anomaly detectors (§5.3/§11.4), PEP DENY spikes, egress-broker alerts, HSM refusals,
gateway refusal clusters, integrity-check failures on the ledger anchor, EDR on endpoints. All feed
a single **incident queue** (AX-10 one seat). *[DESIGN-ENTAILED]*

### 9.2 Severity & fail-closed containment

On credible incident: **contain first, investigate second, fail closed.** Containment primitives:
suspend suspect principals/tokens, revoke grants, re-wrap affected DEKs (invalidates cached caps),
freeze publication (gateway to hard-DENY), isolate suspect nodes. Because the ground state is deny,
containment is *tightening an already-closed system*, not scrambling to close it. *[DESIGN-ENTAILED]*

### 9.3 Affected-matter scan (the privilege-specific IR step)

- **Interface.** `affected_matter_scan(indicator{principal|key|node|time-window|artifact}) ->
  {matters_touched, objects_read/exported, grants_used, publications_affected, walls_implicated,
  legal_notification_candidates}`.
- **Mechanism.** Because every access is a typed ledger entry keyed by matter+principal+object+time,
  the scan is a *deterministic query over the append-only ledger*, not a forensic guess: it returns
  the exact set of matters and objects an indicator touched. This directly supports the firm's
  breach-notification and client-duty analysis (which clients' confidences were exposed?). *[DESIGN-
  ENTAILED; completeness rests on complete mediation §2.2 — if every access is logged, the scan is
  complete; that is the payoff of AX-7]*
- **Output feeds** the human decision on GDPR/Bar notification duties (the system surfaces the
  exposure set; humans decide legal notification — AX-4).

### 9.4 Deadline-safe fail-closed (resolving the §1 contradiction)

When a fail-closed gate blocks work near a procedural deadline: the DENY is immediate and pages a
named responsible human (partner + ops) on a bounded timer; the human resolves via the *lawful
traditional route* (manual filing, direct authority) — the system **never auto-downgrades a gate to
meet a deadline.** The deadline is protected by *human fallback outside the automated path*, not by
weakening the control. Deadline tracking itself is a monitored, redundant, alert-heavy subsystem so
gate-blocks surface with margin. *[DESIGN-ENTAILED; this is the explicit, non-hidden trade-off]*

### 9.5 Post-incident

Full timeline from the ledger, root-cause, control-gap closure **at its seat** (not a patch —
repo law: eliminate the class), dual-controlled remediation, and a written incident record appended
to the ledger. Recall (§7.5) if publications were affected. *[DESIGN-ENTAILED]*

---

## 10. Memory & data-lifecycle security (cross-cutting)

The system's memory kernel (repo `LAWMAX-MEMORY-KERNEL-SPEC`) is a confidentiality surface: it
persists reasoning and recall across sessions. Controls: **every memory entry is matter-tagged and
stored under `DEK_m`**; cross-matter recall requires a grant (§3.3); memory is subject to walls
(§4), retention (crypto-shred on expiry), and legal hold; memory reads are ledgered. "Firm-wide"
memory (e.g. reusable de-identified legal reasoning patterns) lives only as **de-identified,
matter-stripped** entries produced through a de-identification gate analogous to §7 (dual-control
to promote a pattern from matter-scoped to firm-scoped). *[DESIGN-ENTAILED; the de-identification
promotion gate is the memory analogue of the Publication Gateway — same fail-closed shape]*

---

## 11. The audit story (who watched the watchers)

### 11.1 The ledger (AX-7, one seat)

A single append-only, tamper-evident **Audit Ledger**: hash-chained entries (each entry commits to
the prior root), periodically **anchored externally** (RFC-3161 multi-TSA + append-only transparency
log, reusing the repo's provenance/CT machinery) so that even an insider with ledger write access
cannot rewrite history without breaking the external anchor (split-view resistance, repo Θ2/Θ5).
Entries are structured: `{ts, principal, role, action, matter?, object?, decision, pdp_ref,
prev_root}`. *[DESIGN-ENTAILED; the append-only + external-anchor property is IMPLEMENTED-in-kind by
the repo's release/anchor mechanism]*

### 11.2 Invariants

- **I-AUD-1 (append-only).** No entry is edited or deleted; corrections are new entries. Provable
  from the hash-chain + external anchor: an altered past entry breaks all subsequent roots and the
  anchored root. *[THEOREM-able for the chain; the *external anchor* reduces trust to "not all TSAs
  collude," an EMPIRICAL assumption stated in repo §4]*
- **I-AUD-2 (completeness).** Every privileged action has an entry (guaranteed by complete mediation
  §2.2 — the PEP writes the ledger entry in the same atomic step that performs the effect; no
  effect without entry). *[DESIGN-ENTAILED]*
- **I-AUD-3 (watchers watched).** Auditor and admin reads/actions on the ledger are themselves
  entries. *[DESIGN-ENTAILED]*

### 11.3 Separation of the audit function

The **Auditor/Compliance role is organizationally and technically separate** from the
Security/Platform Admin role (SoD, §5.1): admins run the infrastructure but cannot alter the ledger
(it is append-only + externally anchored, and admin ledger-ops are dual-controlled and logged);
auditors read the ledger but cannot change infra or policy. Neither can silently act on the other's
domain. *[DESIGN-ENTAILED]*

### 11.4 Who watches the watchers (the recursion, terminated honestly)

The regress "who audits the auditor?" is terminated by **three independent, cross-checking
mechanisms** rather than an infinite tower:

1. **Cryptographic anchoring beats all insiders.** The external transparency log + multi-TSA anchor
   means *no internal role* (admin, auditor, even a colluding pair) can rewrite history undetectably
   — a third party (client, court, opposing verifier) can detect divergence. Trust reduces to
   "not all independent external TSAs/log-witnesses collude," an out-of-band assumption, **not** an
   internal role. *[DESIGN-ENTAILED; residual is the TSA-collusion EMPIRICAL assumption, repo §4]*
2. **Mutual surveillance across the SoD split.** Admin anomalies alert auditors; auditor anomalies
   alert admins/security; each chain's actions are visible to the other. Collusion must span the
   *entire* SoD boundary to be silent. *[DESIGN-ENTAILED]*
3. **Adversarial-critic ensemble (repo protocol [0047]).** Independent critic agents/processes with
   fresh context (no access to the implementer's reasoning) continuously replay ledger-derived
   decisions and hunt for mediocrity/silent-fallback/tamper. This is the repo's internal-adversary
   discipline applied to the audit function itself. *[DESIGN-ENTAILED; critics are LLM-assisted and
   thus advisory — AX-4 — they *flag*, humans + crypto *decide*]*

**Honest terminus.** The regress does not reach mathematical zero: a coalition that (a) controls the
dual-control quorum, (b) spans the full SoD boundary, and (c) suborns a majority of independent
external anchors could in principle rewrite history. The architecture makes that coalition **large,
cross-institutional, and externally detectable**, and names it as the residual. That is the honest
ceiling of "who watches the watchers," stated, not concealed. *[EMPIRICAL/UNKNOWN residual,
explicitly declared]*

### 11.5 Verification of the audit story

(a) *Tamper test*: mutate a past ledger entry; assert chain + anchor verification fails and alerts.
(b) *Orphan-effect test* (from §2.2): assert zero privileged effects lack a ledger entry.
(c) *Watcher-visibility test*: perform an auditor read and an admin op; assert both appear as
entries. (d) *Anchor-liveness test*: assert periodic external anchoring succeeds and gaps alert.
*[DESIGN-ENTAILED test plan]*

---

## 12. Residual risks (named, owned, not hidden — the honest ledger of limits)

| # | Residual risk | Status | Why it cannot be zero | Mitigation / narrowing | Owner |
|---|---|---|---|---|---|
| R1 | Privilege/DLP false negatives (missed leak in publication) | EMPIRICAL | NL judgment ≠ decidable predicate | human privilege review + public-by-nature-only intake + defense-in-depth + recall | Ethics Partner |
| R2 | Side/covert channels (timing, cache, µarch), steganographic redaction residue | EMPIRICAL | physics of shared hardware | per-matter isolation, no shared index, flatten+reserialize+reverify, constant-time DENY | Security Lead |
| R3 | Full host/hypervisor/HSM-firmware compromise | UNKNOWN | below our TCB floor | attested boot, FIPS HSM, air-gapped root, minimized TCB (AX-9) | Platform Admin |
| R4 | Collusion at/above dual-control threshold across full SoD | EMPIRICAL | any k-of-n has a k-coalition | distinct roles/tokens/quorums, external anchoring, ensemble critics | Managing Partner |
| R5 | External TSA/transparency-witness total collusion | EMPIRICAL | trust must terminate somewhere out-of-band | ≥3 independent TSAs + independent log witnesses | Security Lead |
| R6 | Vendor contract breach (external API retains data) | UNKNOWN | cannot verify vendor internals | only de-identified/non-privileged ever leaves ⇒ breach impact bounded (§6.7) | DPO |
| R7 | Endpoint/human exfil (camera, memory, coercion) | EMPIRICAL | outside software trust domain | attested thin clients, watermarking, least-privilege, monitoring, departing-employee runbook | Security Lead |
| R8 | Formalization gap: proven predicate ≠ correct legal judgment | THEOREM-vs-validation | verification ≠ validation | claim-status discipline; human authority on substance (AX-4) | Ethics Partner |
| R9 | Downstream takedown after recall not guaranteed | UNKNOWN | public copies persist | authoritative recall record via transparency log; best-effort mirror takedown | Publication Officer |

No residual is silently downgraded; each has a named owner and a narrowing plan. None is
**[BLOCKING]** given the stated mitigations, except that R8 permanently caps every *substantive*
supremacy claim to "superiority under a declared interpretive profile and declared facts," never
"provably correct law." *[honest limit, per binding claim-status discipline]*

---

## 13. Supply chain (moved here for adjacency to residuals; full controls)

*(Egress/inbound-supply plumbing is §6.5; this is the trust content.)*

- **Model weights.** Signed provenance (publisher signature + hash), SBOM-equivalent model card
  (training-data class, license, eval results), **eval-before-adopt** in an isolated sandbox
  (capability + safety + leakage evals; a model that memorizes/regurgitates fails), dual-control
  production adoption (AX-6), pinned versions, reproducible deployment. A weight blob is quarantined
  (§6.5) until verified. *[DESIGN-ENTAILED; the repo already practices pinned deps + provenance —
  `deps.lock`, `PROVENANCE.yaml`, hermetic build — status IMPLEMENTED for the code supply chain,
  DESIGN-ENTAILED for the model-weight extension]*
- **Dependencies.** SBOM for every build, signed provenance (SLSA-style), pinned + hash-locked
  (`deps.lock`), vulnerability scanning, hermetic/reproducible builds (repo `MANUAL-STEPS-HERMETIC`,
  `Dockerfile` hermetic pattern), no un-pinned pulls, no build-time internet in core. *[IMPLEMENTED
  in repo for the Lisp/build supply chain; DESIGN-ENTAILED for continuous enforcement]*
- **Updates.** Staged (quarantine→eval→canary→dual-control promote), signed, rollback-capable, with
  a signed changelog entry in the ledger. No auto-update into production without the gate. *[DESIGN-
  ENTAILED]*
- **Invariant I-SUP.** Nothing runs in Z1/Z3 whose provenance signature + hash + eval-pass +
  dual-control-adoption record is not present. Unverified artifact ⇒ does not execute (fail-closed).
  *[DESIGN-ENTAILED]*
- **Verification.** (a) reproduce build from source, bit-compare. (b) verify every running
  artifact's signature/hash against the pinned manifest. (c) attempt to run an unsigned/unevaluated
  weight ⇒ refused. *[DESIGN-ENTAILED; (a) IMPLEMENTED per hermetic build]*

---

## 14. Verification & assurance summary (how we know, per control)

Every control above lists interface / invariant / failure-mode / verification. Aggregate assurance
strata (mirroring `formal-boundaries.md`):

- **THEOREM-reducible (machine-checkable formal objects):** grant algebra non-transitivity &
  non-amplification (I-GRANT-NT); publication predicate = monotone conjunction, false unless all
  conjuncts (I-PUB); audit chain append-only (I-AUD-1); reference-monitor determinism. *These are
  the load-bearing safety properties and are worth formalizing in Lean/Coq against the actual PDP/
  gateway/ledger code paths.* Status today: **DESIGN-ENTAILED**, targeted for **THEOREM**.
- **DESIGN-ENTAILED (holds if built to spec):** compartment isolation, default-deny egress, wall
  enforcement, dual control, KMS admin-cannot-read, IR affected-matter completeness, supply-chain
  gating. Verified by the red-team/bypass/replay test suites named per section; passing → **
  DEMONSTRATED**; continuous passing in production → **EMPIRICAL**.
- **IMPLEMENTED (code exists in repo):** hermetic build, pinned deps, provenance/receipt +
  multi-TSA anchoring machinery, content-addressed identity, no-LLM-on-trusted-path axiom.
- **EMPIRICAL / UNKNOWN residuals:** §12 table — narrowed, owned, never equated with the theorems.

**The one discipline that governs all claims:** a green test suite or a checked Lean proof about the
*publication predicate* is **not** the proposition "no privilege will ever leak" — the former is a
THEOREM about a formal object, the latter is an EMPIRICAL claim about natural-language privilege
judgments made by humans and classifiers. This document keeps those two permanently distinct, per
the binding claim-status protocol. *[meta-invariant]*

---

## 15. What is BLOCKING vs. resolved

- **Resolved (declared trade-offs, not hidden):** fail-closed vs. deadlines (§1, §9.4); zero-shared-
  state vs. conflicts detection (§3.4); external-model capability vs. privilege (§6.2/§6.6 — on-prem
  tier removes the conflict for privileged work).
- **Permanent honest ceilings (not BLOCKING, but capping supremacy claims):** formalization gap R8;
  side-channel/host-compromise floor R2/R3; out-of-band anchor trust R5. Every supremacy claim the
  larger program makes must be stamped with these.
- **[BLOCKING] if built otherwise:** any shared cross-matter model index (§3.1); any external-API
  route for privileged classes (§6.2); any single-approval publication or single-control key
  ceremony (§7.5/§8.2); any un-anchored or editable audit ledger (§11); any admin path to matter
  plaintext (§8.1). These are the invariants whose violation collapses the whole confidentiality
  claim and therefore must be enforced structurally, not by policy.

---

*End of report. Every control states interface, invariant, failure mode, and verification method;
every claim carries a status tag; every residual is named with an owner; no trade-off is hidden as
an engineering detail; unresolved items are marked. The two guarantees that make this a private
privileged system rather than a hardened public one are: (1) exactly two sanctioned egress paths,
both fail-closed, with privileged data structurally barred from external APIs; and (2) an
append-only, externally-anchored audit that binds humans and machines alike — so that the watchers
are watched by cryptography no insider coalition short of the named residual can defeat.*
