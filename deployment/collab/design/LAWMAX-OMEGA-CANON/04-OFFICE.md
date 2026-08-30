# 04 — THE OFFICE (whole pipeline, one discipline, one wall)

## 1. The wall (public/private separation — architectural, not policy)

- **PUBLIC surface (the only one):** already-public statutes, codified (ELI). Publishing
  them costs nothing (they were public) and demonstrates the codification asset.
- **PRIVATE (everything else):** case analysis, strategy, drafting, person research,
  client data, memory, calendars, billing — behind the wall. The wall is enforced by
  construction: the public emitter can only read the statute-code partition of L2;
  no other partition has a public egress path (no code path exists — not "forbidden",
  absent).

## 2. The full office cycle under the same trust discipline

Every step distinguishes *proposed (untrusted)* from *admitted (trusted, certified)*:

1. **Intake & conflicts check** — new matter → conflict scan against P5 (deterministic
   over the party graph) → engagement recorded in the journal chain.
2. **Appointments/calendar** — O4; court deadlines are DERIVED (procedural law-as-code +
   proof), personal appointments are plain data; the two are typed differently so a
   derived deadline can never be hand-edited silently.
3. **Case file assembly** — O3 ingestion; every exhibit gets {hash, provenance, reading
   proposals, confidence}; critical facts queue for human confirmation.
4. **Research** — O2 over L2 (never over the open web); gaps → honest UNKNOWN + what
   would close them; scouts may be tasked to bring a missing source THROUGH the gate.
5. **Analysis & strategy** — P4 exhaustion (moves × construals × characterizations),
   preclusion certificates, dominant line with certified weaknesses (O11).
6. **Drafting** — O7 candidates → certified content compiled by O12 into the court's
   schema; open-texture nodes structurally flagged.
7. **Filing & service** — checklist derived from procedural code; nothing files without
   the lawyer's sign-off; filed artifact hashed into P5.
8. **Hearing prep** — O9 simulation transcripts; examination plans anchored to confirmed
   facts only.
9. **Post-decision** — judgment ingested (O1/O3), realized-outcome loop closes
   pre-registered predictions (P5), deadlines for remedies derived (O4).
10. **Billing/παραστατικά** — deterministic ledger, hash-chained; every invoice line
    traceable to journal entries.
11. **Archive** — the matter's full replay bundle sealed in P5; re-derivable bit-for-bit.

## 3. Data protection, privilege & lawfulness (structural, minimal statement)

- **Privilege first (δικηγορικό απόρρητο):** no client or strategy datum reaches an
  external model API except through the inference-boundary gateway (BO-34) under the
  creator-set posture for its data class (on-prem / redacted / never). The gateway is the
  only egress seat.
- **The system's own regulatory posture:** GDPR records of processing + client consent
  for AI-assisted processing (BO-39); EU AI Act posture memo maintained; ingestion of
  public court decisions (which contain personal data) rests on a documented lawful
  basis and honors Greek anonymization practice for published decisions.
- **EU law is part of Greek law:** the World's first order includes the EU/ECHR layer
  (BO-35) — supremacy, direct effect, consistent interpretation as encoded meta-rules.

- O8 research: only lawfully public data, each datum carrying its lawful-access basis;
  a datum without that certificate cannot enter the case world (unrepresentable).
- Client data: private partition, provenance-sealed, erasure via typed erasure
  certificates (salted per-leaf commitments make deletion provable without breaking the
  Merkle history — see BO-25).
- Named-judge analytics: lawful in Greece (public decisions; no French-style Art. L10
  prohibition); still confined to search-ordering by the P4 invariance guard.

## 4. Continuity, modes & incidents

- **Continuity:** the authoritative chain replicates offsite through witness cosigning
  (RPO 0); documented RTO; a repeatable disaster-recovery drill is a standing proof
  artifact (BO-37). Losing a machine loses zero truth.
- **Modes:** FULL / DEGRADED (local models only) / MANUAL (no LLM — humans enter
  structured facts; the trusted spine runs at full guarantee). Typed states; every
  certificate names its mode.
- **Incidents:** a defective certified output triggers BO-38 — deterministic scan of
  every affected matter via P5 replay, recall/notification records, root cause fed to
  SEV. "Zero error" is the goal; the incident protocol is the honest backstop.
- **Cross-matter coherence:** before strategy election and drafting, the BO-36 guard
  scans all live matters for contradictory positions (blocking flag, creator override
  recorded).

## 5. Write discipline (universal)

Every durable write in the office — case files, calendars, ledgers, world updates — goes
through the single atomic writer seat (WAL, crash-refinement-proved; BO-13). A crash
mid-write leaves either the old state or the new state, never a torn file, anywhere in
the system.
