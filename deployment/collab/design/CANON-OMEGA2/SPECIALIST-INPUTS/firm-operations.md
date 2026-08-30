# OMEGA-2 — FIRM OPERATIONS SPECIFICATION

**System:** LAWMAX-Ω — internal legal operations core, Greek practice (EU/ECHR law inside the Greek order)
**Scope of this document:** what the system must *do* operationally, expressed as requirements each carrying acceptance tests. Corpus volume/quality out of scope; architecture, interfaces, trust boundaries, memory, verification, security, operations, self-improvement in scope.
**Author perspective:** managing partner + senior litigators + head clerk.
**Date:** 2026-08-28

---

## 0. Reading protocol — claim-status discipline

Every substantive claim below carries exactly one tag:

- **THEOREM** — provable from stated axioms/definitions.
- **DESIGN-ENTAILED** — follows necessarily from a design choice we commit to here (true *if the design is built as written*; not yet built).
- **IMPLEMENTED** — code exists in the repo now. (This document asserts **no** IMPLEMENTED claims; it is a specification. Absence of IMPLEMENTED tags is deliberate and honest.)
- **DEMONSTRATED** — shown working on a concrete instance/test.
- **EMPIRICAL** — supported by observed data.
- **HYPOTHESIS** — plausible, unproven, may be false.
- **UNKNOWN** — we do not know; the system must say so rather than guess.

Two equivocations are banned throughout and flagged wherever they would tempt us:
1. **Proof-checking ≠ correctness of the natural-language formalization.** A green proof of "the deadline is 2026-09-15" says nothing about whether "2026-09-15" is the *right* legal answer; it only says our arithmetic over our formal inputs is internally consistent. The formalization gap is a named, first-class residual, never hidden.
2. **Model access ≠ idea inclusion.** Having every code/case-law text in the corpus does not mean the relevant *idea* (the winning argument, the disqualifying conflict) was considered. Retrieval recall is a separate, measured quantity.

**Acceptance-test convention.** Each test is written as `GIVEN / WHEN / THEN` plus a **fail-closed obligation**: what the system must do when it *cannot* satisfy the THEN. In this domain, degrading to silence or to a confident guess is a defect; degrading to a loud, blocking "I do not know / human required" is correct behavior.

**Global invariant (DESIGN-ENTAILED).** No component on the correctness-critical path (conflicts, deadlines, prescription, filing validity, privilege gating) may rely on an LLM's free-form judgment as its authority. LLMs may draft, propose, retrieve, and explain; the *decision* is taken by deterministic rule engines over typed facts, or is escalated to a named human. "Honest ignorance" (τίμια άγνοια) is a required output state, not a failure mode.

---

## 1. Conflicts checking — intake-time and continuous

### 1.1 What it must do

Greek grounding: Κώδικας Δικηγόρων (Ν. 4194/2013) and the Κώδικας Δεοντολογίας του Δικηγορικού Λειτουργήματος — duty of loyalty (πίστη), prohibition on acting against a current or former client where the mandates are connected, professional secrecy (Άρθρο 38 ν.4194/2013, εχεμύθεια). The system encodes conflict as a **graph-reachability and adversity property over parties, matters, and information barriers**, not as a keyword match.

**R-CONF-1 (DESIGN-ENTAILED) — Canonical party identity.** Every person/entity is resolved to a stable canonical identity node before any conflict check. Identity resolution must handle: Greek name transliteration variants, ΑΦΜ/tax-ID, ΓΕΜΗ company number, former names, corporate groups (parent/subsidiary/UBO chains), and role changes over time (a witness in matter A who becomes an opposing party in matter B).

**R-CONF-2 (DESIGN-ENTAILED) — Adversity model.** For any two matters the system computes the relationship of each party pair on a typed lattice: {same-side, adverse, adverse-affiliate, former-adverse, related-non-adverse, unrelated}. A conflict candidate is any pair where the firm would simultaneously (or successively, within secrecy duties) owe duties to parties standing in an adverse or adverse-affiliate relation.

**R-CONF-3 (DESIGN-ENTAILED) — Two temporal modes.**
- *Intake-time*: blocking gate. No matter is opened, no engagement letter issued, no privileged information ingested until the check returns CLEAR or a documented waiver/ethical-wall decision exists.
- *Continuous*: every new party added to any live matter re-runs the check against the entire live and closed matter graph; every corporate-structure update (new subsidiary, merger, acquisition of a client by an adverse party) triggers re-evaluation. Conflicts are *emergent*: a clean intake can become conflicted six months later when the counterparty is acquired.

**R-CONF-4 (DESIGN-ENTAILED) — Information barriers (Chinese walls / ethical screens).** When a conflict is resolved by screening rather than declining, the barrier is a *technical access-control fact*, not a memo. The system enforces it: screened personnel are denied access to the walled matter's documents, memories, model traces, and even the *existence* metadata where required. A barrier that exists only on paper is treated as a non-barrier by the risk model.

**R-CONF-5 (DESIGN-ENTAILED) — Positional / issue conflicts surfaced, not auto-blocked.** The system flags when the firm is about to argue a legal proposition it is simultaneously contesting elsewhere before overlapping fora (see §8, institutional consistency). This is advisory-blocking: it stops the workflow for a partner decision; it does not silently resolve.

### 1.2 Acceptance tests

**AT-CONF-1 (name-variant defeat).**
GIVEN party "Γεώργιος Παπαδόπουλος, ΑΦΜ 012345678" is adverse in matter A; WHEN intake opens matter B with client "G. Papadopoulos" (transliterated, no ΑΦΜ) who is in fact the same person; THEN the intake gate returns CONFLICT-CANDIDATE and blocks.
Fail-closed: if identity resolution confidence is below threshold, return AMBIGUOUS-IDENTITY → human clearance required (never auto-CLEAR).

**AT-CONF-2 (emergent conflict via M&A).**
GIVEN clean matters A (client X) and B (client Y, currently unrelated); WHEN a corporate-registry update records that Y acquired the counterparty in A; THEN within one continuous-scan cycle the system raises CONFLICT and notifies the responsible partners of both matters.
Fail-closed: if the registry feed is stale beyond SLA, the system marks conflict status STALE and blocks *new* privileged actions on A and B until refreshed.

**AT-CONF-3 (barrier enforcement is real).**
GIVEN screened lawyer L is walled off matter A; WHEN L queries the system for any A document, memory, or model trace; THEN access is denied AND the denial is logged AND the query does not leak A's existence beyond what L is entitled to see.
Fail-closed: an access-control evaluation error denies (default-deny), never permits.

**AT-CONF-4 (former-client secrecy).**
GIVEN former client Z (matter closed); WHEN the firm is asked to act adverse to Z in a *connected* matter; THEN the system flags FORMER-CLIENT-CONFLICT with the connection basis (shared confidential information domain), for partner + client-consent decision.

**AT-CONF-5 (no false CLEAR under partial data).**
GIVEN a party with incomplete identifiers; WHEN a conflict check runs; THEN the result is at worst AMBIGUOUS, never CLEAR, if any identity edge is unresolved.
This is the load-bearing invariant: **the system never returns CLEAR on incomplete evidence** (DESIGN-ENTAILED). A CLEAR is a positive assertion requiring complete identity closure.

### 1.3 Residual (honest)

**UNKNOWN:** whether two matters are "connected" in the secrecy sense is a legal judgment the engine cannot fully decide. The engine's job is *recall* — surface every candidate — and route the connection judgment to a human. Claiming the engine "decides conflicts" would be the banned model-access≠idea-inclusion equivocation.

---

## 2. Deadline / prescription control — correctness-critical machinery

This is the single highest-consequence subsystem. A missed προθεσμία is malpractice with near-strict liability. It is specified as **deterministic date algebra over a versioned rule base**, with an LLM strictly forbidden on the computation path.

### 2.1 Greek procedural realities the machine must encode

- **Υπολογισμός προθεσμιών (ΚΠολΔ 144–151):** the *dies a quo* (day of the triggering event/service) is not counted; the term expires at the end of the last day; if the last day is a holiday/Saturday/Sunday the term extends to the next working day (ΚΠολΔ 144 §2). Terms in months/years expire on the corresponding date of the last month.
- **Δικαστικές διακοπές (ΚΠολΔ 147 §7):** procedural terms are **suspended 1–31 August**; the machine must model suspension windows, not merely holidays.
- **Ένδικα μέσα** with their distinct clocks:
  - *Έφεση* (appeal, ΚΠολΔ 518): 30 days from service of the decision for a party resident in Greece; 60 days if resident abroad or of unknown residence; absent service, the long-stop of **two years from publication** of the decision.
  - *Αναίρεση* (cassation to Άρειος Πάγος, ΚΠολΔ 564): 30 days from service (90 if abroad/unknown), two-year long-stop absent service.
  - *Ανακοπή ερημοδικίας, τριτανακοπή, αναψηλάφηση* — each its own trigger and term.
  - Criminal (ΚΠΔ) and administrative (Κώδικας Διοικητικής Δικονομίας; ΠΔ 18/1989 for ΣτΕ) have separate regimes; the rule base is *codified per procedure family*, never averaged.
- **Παραγραφή (limitation, Αστικός Κώδικας):** general 20-year (ΑΚ 249), 5-year for periodic/professional claims (ΑΚ 250), plus special limitations across statutes; interruption (διακοπή, ΑΚ 260–270) and suspension (αναστολή) events reset or pause the clock.
- **Service/επίδοση mechanics** determine the trigger instant; electronic service and the presumptions attached to it must be modeled.

### 2.2 What it must do

**R-DL-1 (DESIGN-ENTAILED) — Deterministic engine, no LLM on path.** All computations are performed by a pure, total function `deadline(procedure_family, trigger_event, trigger_date, party_residence, service_mode, decision_publication_date, calendar_version, rule_version) → {due_datetime, chain_of_reasoning, rule_citations}`. Same inputs → same output, forever (referential transparency). The LLM may *explain* the output in prose but its prose is never the authority.

**R-DL-2 (DESIGN-ENTAILED) — Versioned, dated rule base.** Every procedural rule carries an effective-date interval and a citation to the statute/article. Computing a deadline for an event in 2019 uses the rules in force in 2019, not today's. Rule changes are diffs with provenance, never in-place edits.

**R-DL-3 (DESIGN-ENTAILED) — Calendar authority.** Greek official holidays, judicial vacation windows, and any court-specific closures are a signed, versioned data set. The engine records *which* calendar version it used. An unknown future holiday (e.g., a not-yet-declared closure) is an explicit UNKNOWN that widens the safety margin, not a silent assumption.

**R-DL-4 (DESIGN-ENTAILED) — Defense-in-depth: two independent computations.** Each deadline is computed by two independently authored implementations (or one engine + one differently-structured cross-check) and must agree. Disagreement is a BLOCKING incident, not a tie-break. This makes a whole *class* of arithmetic error structurally visible rather than merely discouraged.

**R-DL-5 (DESIGN-ENTAILED) — Conservative rounding toward safety.** Wherever ambiguity exists (which service date controls, whether a term is 30 or 60 days), the system surfaces *all* candidate deadlines and escalates the *earliest* as the operative one until a human resolves the ambiguity. It never picks the later date to buy time.

**R-DL-6 (DESIGN-ENTAILED) — Escalation ladder with humans in the loop.** Every live deadline has: an owner (lawyer), a supervising partner, and an escalation clock. Reminders fire at defined offsets (e.g., T-30, T-14, T-7, T-3, T-1, T-morning-of) and *escalate up the hierarchy* if not acknowledged. Acknowledgement is an explicit act, logged. Silence never satisfies a deadline.

**R-DL-7 (DESIGN-ENTAILED) — No deadline exists without a trigger fact.** A deadline is created only from a recorded, sourced trigger event (a served decision, a filed action). Orphan or hand-typed deadlines are permitted but flagged UNVERIFIED-TRIGGER and cannot be silently cleared.

### 2.3 Acceptance tests

**AT-DL-1 (August suspension).**
GIVEN a 30-day έφεση term triggered by service on 2026-07-25; WHEN the engine computes the due date; THEN days 1–31 August are excluded and the due date reflects the ΚΠολΔ 147 §7 suspension, with the rule citation in the reasoning chain.

**AT-DL-2 (last-day-is-holiday rollover).**
GIVEN a term expiring on a Sunday or on 28 October (national holiday); WHEN computed; THEN it rolls to the next working day per ΚΠολΔ 144 §2.

**AT-DL-3 (residence-dependent term).**
GIVEN a party of unknown residence and no proof of service; WHEN computing the έφεση deadline; THEN the engine returns the 60-day term AND the two-year-from-publication long-stop, flags which controls, and escalates the earlier operative date.

**AT-DL-4 (retroactive rule version).**
GIVEN a trigger event dated before a statutory amendment to a term; WHEN computed; THEN the engine uses the rule version in force at the trigger date, cited by effective interval.

**AT-DL-5 (dual-engine disagreement blocks).**
GIVEN two independent computations return different due dates; WHEN reconciled; THEN the system raises a BLOCKING incident, notifies the partner, and treats the *earlier* date as operative pending resolution. No deadline is ever silently reconciled to one engine.

**AT-DL-6 (acknowledgement, not silence).**
GIVEN a T-7 reminder fires; WHEN the owner does not acknowledge within the ack window; THEN escalation proceeds to the supervising partner, then to the managing partner, logged at each step.

**AT-DL-7 (limitation interruption).**
GIVEN a claim under a 5-year ΑΚ 250 limitation with a recorded interruption event (ΑΚ 260); WHEN computed; THEN the clock restarts from the interruption, with provenance for the interrupting act.

**AT-DL-8 (formalization-gap honesty).**
GIVEN the engine returns a green, internally consistent deadline; THEN the output *explicitly states* that this is arithmetic over the recorded formal inputs and is not a warranty that the legal characterization (which procedure family, which trigger) is correct — that characterization is a separately-owned human judgment.
This test enforces the ban on proof-checking≠correctness. (DESIGN-ENTAILED)

### 2.4 Residual (honest)

**UNKNOWN / formalization gap:** the mapping from messy reality ("what exactly was served, on whom, when, and does it start the έφεση or the αναίρεση clock?") to the engine's typed inputs is a legal act performed by a human. The engine guarantees *correct computation given correct inputs*; it cannot guarantee *correct inputs*. This gap is the dominant residual malpractice risk and is stated, not buried. The dual-engine and conservative-earliest rules mitigate arithmetic error but do **not** close the characterization gap.

---

## 3. Evidence lifecycle — intake, custody, authenticity, expert reports, witnesses

### 3.1 What it must do

**R-EV-1 (DESIGN-ENTAILED) — Immutable chain of custody.** Every evidentiary item has an append-only custody ledger: who received it, from whom, when, in what form (original / certified copy / digital), where stored, every access and transfer. The ledger is cryptographically chained (each entry commits to the prior), so tampering is detectable, not merely discouraged (eliminates the error class rather than policing it).

**R-EV-2 (DESIGN-ENTAILED) — Authenticity and integrity fixed at intake.** Digital evidence is hashed at the moment of intake; the hash and acquisition metadata are sealed. Any later copy is verifiable against the sealed hash. For originals/physical items, intake records the physical descriptor and photographs.

**R-EV-3 (DESIGN-ENTAILED) — Authenticity-challenge readiness (προσβολή γνησιότητας).** For each item the system maintains the evidentiary predicate needed to defend authenticity in court: source, acquisition method, custody continuity, and (for documents) the basis on which γνησιότητα is asserted. When authenticity is challenged, the system produces the full custody proof as a bundle.

**R-EV-4 (DESIGN-ENTAILED) — Πραγματογνωμοσύνη (expert opinion, ΚΠολΔ 368–392) lifecycle.** The system tracks: appointment of the πραγματογνώμονας, the questions posed (τα τιθέμενα ερωτήματα), deadlines for the report, the report itself with version and integrity seal, and the firm's τεχνικοί σύμβουλοι (technical advisors, ΚΠολΔ 391–392) responses. Expert independence and any conflict of the expert are checked (§1 machinery reused, single seat).

**R-EV-5 (DESIGN-ENTAILED) — Witness statement lifecycle.** Statements (ένορκες βεβαιώσεις, witness prep notes) are versioned; privileged prep material is segregated from disclosable statements by classification at creation; the system tracks whether a statement was taken with proper notice (κλήτευση) where required, since a defect can render it inadmissible.

**R-EV-6 (DESIGN-ENTAILED) — Privilege and work-product classification at ingest.** Every evidentiary and quasi-evidentiary item is classified on intake: client-confidential, privileged work-product, disclosable, third-party-confidential. Classification drives access and drives the Publication/Disclosure Gateway (§ cross-cut). Unclassified items are quarantined, not defaulted to disclosable.

### 3.2 Acceptance tests

**AT-EV-1 (tamper-evidence).**
GIVEN a sealed digital exhibit; WHEN any byte of the stored copy changes; THEN verification against the sealed hash fails and the item is flagged INTEGRITY-BROKEN and cannot be presented as authentic until reconciled.

**AT-EV-2 (custody gap detection).**
GIVEN a custody ledger with a missing transfer entry (item moved without a record); WHEN a custody audit runs; THEN the gap is reported as a CUSTODY-DISCONTINUITY that must be explained before the item is relied upon.

**AT-EV-3 (challenge bundle).**
GIVEN an authenticity challenge on document D; WHEN the litigator requests the defense bundle; THEN the system emits source, acquisition, unbroken custody chain, and hash provenance in one export.
Fail-closed: if the chain has a discontinuity, the bundle *says so* rather than presenting a clean-looking but false record.

**AT-EV-4 (expert deadline + independence).**
GIVEN an appointed πραγματογνώμονας; WHEN the report term approaches; THEN the deadline subsystem (§2) governs it; AND the conflict subsystem (§1) has cleared the expert's independence; AND the questions posed are locked and versioned.

**AT-EV-5 (witness notice defect).**
GIVEN an ένορκη βεβαίωση taken where κλήτευση of the opposing party was required; WHEN notice cannot be evidenced; THEN the statement is flagged POSSIBLY-INADMISSIBLE with the defect basis, not filed silently.

**AT-EV-6 (quarantine of unclassified).**
GIVEN an item ingested without classification; THEN it is inaccessible for external use and blocked at the Disclosure Gateway until classified by an authorized human.

---

## 4. Drafting & review chains — who reviews what, versioning, sign-off, house style

### 4.1 What it must do

**R-DR-1 (DESIGN-ENTAILED) — Every draft has a lineage.** Content-addressed, fully versioned; every version records author (human or AI-assisted, distinctly labeled), timestamp, parent version, and the change. Nothing overwrites; history is append-only. AI-generated text is *marked as such internally* until a human adopts it (see identity/authorship note below).

**R-DR-2 (DESIGN-ENTAILED) — Role-typed review chain.** Each document type has a mandatory review graph: e.g., pleading → drafting lawyer → senior litigator review → partner sign-off; regulatory advice → subject partner + conflicts recheck. The chain is enforced: a document cannot reach FILED/SENT state without the required signatures in order.

**R-DR-3 (DESIGN-ENTAILED) — Partner sign-off is a cryptographic, non-repudiable act** tied to a specific version hash. Signing version N does not carry to version N+1; any post-signature change re-opens the gate. This eliminates the "partner approved an earlier draft, the filed one differed" error class structurally.

**R-DR-4 (DESIGN-ENTAILED) — House style as an executable check, not a wish.** Citation format (Greek legal citation conventions, ΦΕΚ references, case citations), terminology consistency, formatting, and prohibited-language rules are machine-checkable and run on every version. Violations are surfaced to the drafter; they do not silently auto-correct legal substance.

**R-DR-5 (DESIGN-ENTAILED) — No LLM adoption without human authorship.** AI-drafted content carries a provenance flag. A human must explicitly adopt it (an authorship act) before it becomes firm work product. The firm's external artifacts never bear AI attribution; internally, provenance is fully tracked. (This mirrors the creator's repo law: no AI trailer in outputs, full internal traceability.)

**R-DR-6 (DESIGN-ENTAILED) — Consistency hooks.** On finalization, the draft's asserted legal positions are extracted and checked against the institutional position ledger (§8).

### 4.2 Acceptance tests

**AT-DR-1 (post-signature change re-opens gate).**
GIVEN partner signed version 7; WHEN anyone edits to version 8; THEN version 8 is UNSIGNED and cannot be filed until re-signed; the signature on v7 remains valid for v7 only.

**AT-DR-2 (review order enforced).**
GIVEN a pleading requiring senior-then-partner review; WHEN a drafter attempts to route straight to filing; THEN the system blocks with MISSING-REVIEW(senior).

**AT-DR-3 (house-style gate).**
GIVEN a draft with a malformed ΦΕΚ citation; WHEN the style check runs; THEN the defect is flagged pre-filing. Substance is never auto-altered.

**AT-DR-4 (AI provenance).**
GIVEN AI-assisted text; WHEN it appears in a draft; THEN it is internally flagged AI-DRAFT until a named human adopts it; the external filed artifact carries no AI marking and the adoption is logged.

**AT-DR-5 (lineage completeness).**
GIVEN any filed document; WHEN audited; THEN a complete unbroken version lineage from first draft to filed version is reconstructable, with each signature bound to its exact version hash.

---

## 5. Filing mechanics & e-filing realities

### 5.1 Greek realities

E-filing runs over national systems (ΟΣΔΔΥ-ΠΠ for civil/criminal case management; ηλεκτρονική κατάθεση δικογράφων via the courts' portals and the Ολομέλεια των Δικηγορικών Συλλόγων infrastructure; solon-type platforms). Realities the system must absorb: platform downtime, format/PDF-signature requirements (qualified electronic signature / ψηφιακή υπογραφή), fee/παράβολο and ένσημο (stamp/contribution) prerequisites, court-specific quirks, filing-receipt (αριθμός κατάθεσης / receipt) as the proof of timely filing, and the interaction between the e-filing timestamp and the deadline clock.

### 5.2 What it must do

**R-FIL-1 (DESIGN-ENTAILED) — Filing is a transaction with a receipt, or it did not happen.** A filing is COMPLETE only when the platform's filing receipt (αριθμός/timestamp) is captured and stored against the matter and deadline. No receipt → status is ATTEMPTED, and the deadline remains OPEN and escalating.

**R-FIL-2 (DESIGN-ENTAILED) — Pre-flight checklist gate.** Before submission the system verifies: correct court/procedure, required qualified signature present and valid, παράβολο/fees paid with proof, page/format/attachment requirements met, and partner sign-off (§4) on the exact bytes being filed. Any failure blocks.

**R-FIL-3 (DESIGN-ENTAILED) — Downtime is a modeled hazard.** Platform availability is monitored. When the e-filing system is down near a deadline, the system (a) escalates immediately, (b) preserves evidence of the outage (timestamps, error captures) to support any εκπρόθεσμο/force-majeure argument, and (c) surfaces the physical/alternative filing fallback where procedurally available. It never assumes "we'll file later."

**R-FIL-4 (DESIGN-ENTAILED) — Filing timestamp reconciles with the deadline engine.** The captured receipt timestamp is written back to close the deadline only if it precedes the operative due datetime; otherwise the deadline is recorded as MISSED/LATE with the delta, and the incident process starts. No optimistic closing.

**R-FIL-5 (DESIGN-ENTAILED) — Idempotent submission.** Retries after ambiguous network failures must not create duplicate filings; the system reconciles by checking for an existing receipt before re-submitting.

### 5.3 Acceptance tests

**AT-FIL-1 (no receipt, deadline stays open).**
GIVEN a submission that returns no receipt; THEN status = ATTEMPTED and the deadline continues escalating; it is never marked satisfied.

**AT-FIL-2 (pre-flight blocks unsigned/unpaid).**
GIVEN a filing missing the παράβολο proof or a valid qualified signature; THEN submission is blocked with the specific missing prerequisite.

**AT-FIL-3 (outage evidence preserved).**
GIVEN platform downtime at T-1 day; THEN the outage is timestamped and captured, the partner is paged, the deadline is flagged AT-RISK, and any lawful fallback is surfaced.

**AT-FIL-4 (late filing detected, not hidden).**
GIVEN a receipt timestamp after the operative due datetime; THEN the deadline is recorded LATE with the exact delta and an incident opens.

**AT-FIL-5 (no duplicate on retry).**
GIVEN an ambiguous submission failure; WHEN retried; THEN the system checks for an existing receipt and does not double-file.

---

## 6. Hearing support — prep bundles, real-time constraints, courtroom recording

### 6.1 Greek realities

Courtroom recording: hearings are documented by the official πρακτικά (minutes); audio/φωνοληψία and any broadcast are tightly restricted — recording or televising requires court permission and is generally prohibited for parties (constitutional δημοσιότητα principle, Άρθρο 93 Συντ.; statutory restrictions, e.g. Ν. 3090/2002 and court-president discretion). The system must **not** enable or assume any impermissible recording. Real-time in-court AI assistance is constrained by what is permitted to be brought and used and by the prohibition on transmitting privileged data over insecure channels.

### 6.2 What it must do

**R-HR-1 (DESIGN-ENTAILED) — Prep bundle assembly.** For each hearing the system assembles a bundle: pleadings, the operative deadlines, evidence index with custody status, witness/expert materials, authority list (statutes/case-law relied on) with pinpoint citations, and the firm's consistency check (§8). The bundle is version-locked to the hearing date.

**R-HR-2 (DESIGN-ENTAILED) — Recording compliance is enforced, default-deny.** The system will not capture, transcribe, or store any courtroom audio/video unless a recorded court permission fact exists for that hearing. Absent permission, in-court capture features are disabled. This is a hard gate, not a policy note.

**R-HR-3 (DESIGN-ENTAILED) — Real-time support within lawful bounds.** Any in-hearing assistance (retrieving an authority, checking a fact) operates over pre-loaded, screened materials on secured devices; it does not transmit privileged data over insecure links and does not perform prohibited recording. Latency/availability targets are correctness requirements (an authority that arrives after the judge has moved on is a defect), pursued only via lawful means.

**R-HR-4 (DESIGN-ENTAILED) — Post-hearing capture from the official record.** The system ingests outcomes from the official πρακτικά and any served decision, which then feed the deadline engine (new ένδικα-μέσα clocks start).

### 6.3 Acceptance tests

**AT-HR-1 (recording default-deny).**
GIVEN a hearing with no recorded court permission; WHEN any capture feature is invoked; THEN it is refused and the refusal logged.

**AT-HR-2 (bundle version-lock).**
GIVEN a hearing date; THEN the prep bundle is frozen to specific document versions and lists every authority with pinpoint citation and its consistency status.

**AT-HR-3 (real-time authority within latency target, lawfully).**
GIVEN an in-hearing authority lookup over pre-loaded materials; THEN it returns within the stated latency target over a secured channel; if it cannot (no secure channel, item not pre-loaded), it returns UNAVAILABLE rather than routing privileged data unsafely.

**AT-HR-4 (outcome → new clocks).**
GIVEN a served decision post-hearing; THEN the ένδικα-μέσα deadlines are created from the service trigger per §2.

---

## 7. Institutional consistency — the firm must not argue X and not-X

### 7.1 What it must do

**R-IC-1 (DESIGN-ENTAILED) — Position ledger.** Every legal proposition the firm asserts in a filing or formal advice is extracted into a structured position ledger: the proposition, the matter, the client, the forum, the judges (where known), the date, and the direction (asserting P vs asserting ¬P).

**R-IC-2 (DESIGN-ENTAILED) — Contradiction detection.** On any new assertion, the system checks the ledger for direct or near contradictions, weighted by exposure: same forum, overlapping panel of judges, same statutory question. High-exposure contradictions are BLOCKING pending partner decision; a firm may sometimes legitimately argue differently for different clients, but that must be a *conscious, recorded* decision, never an accident.

**R-IC-3 (DESIGN-ENTAILED) — Judge/forum exposure map.** The system models where and before whom the firm has taken positions, so it can warn "you are about to argue ¬P before a panel that heard you argue P last term."

**R-IC-4 (DESIGN-ENTAILED) — Unresolved contradictions stay BLOCKING.** Per the claim-status discipline, a detected contradiction does not silently resolve; it blocks until a partner records a rationale (distinguishable clients, distinguishable facts, changed law) or reconciles the positions.

### 7.2 Acceptance tests

**AT-IC-1 (same-judge contradiction blocks).**
GIVEN the firm argued proposition P before Judge/panel J; WHEN a new filing before J asserts ¬P on the same question; THEN the system BLOCKS and requires a recorded partner rationale.

**AT-IC-2 (cross-matter, cross-client warning).**
GIVEN P asserted for client A and ¬P being drafted for client B; THEN the system warns with the exposure delta (forum overlap, judge overlap) before finalization.

**AT-IC-3 (no silent resolution).**
GIVEN an unresolved contradiction; THEN it remains BLOCKING; there is no path where the workflow proceeds without either reconciliation or a recorded, authorized decision to diverge.

**AT-IC-4 (recall honesty).**
GIVEN the ledger extraction may miss an implicitly-asserted position; THEN the system reports its extraction as recall-bounded (some positions may be un-extracted) — model access to all filings ≠ inclusion of every implicit proposition. (Enforces the banned equivocation.)

---

## 8. Client-objective management — winning the motion vs serving the client

### 8.1 What it must do

**R-CO-1 (DESIGN-ENTAILED) — Explicit client utility model.** Each client/matter carries a recorded utility profile: cost sensitivity, speed/urgency, risk tolerance, relationship value, reputational constraints, and the client's *actual objective* (which may be "settle quietly and preserve the commercial relationship," not "win the interlocutory motion"). This is captured from the client, versioned, and owned by the responsible partner — never inferred by an LLM and acted on as fact.

**R-CO-2 (DESIGN-ENTAILED) — Recommendation-to-objective alignment check.** Before a significant tactical step (aggressive motion, public filing, escalation), the system checks the step against the recorded objective and flags misalignment: "this maximizes litigation win-probability but conflicts with the recorded objective of relationship preservation / cost containment." It surfaces the trade-off; it never hides it as an engineering/tactics detail.

**R-CO-3 (DESIGN-ENTAILED) — Trade-offs are shown, not resolved silently.** Cost/speed/risk/relationship trade-offs are presented as an explicit frontier to the partner and, where appropriate, the client. The system does not collapse the multi-objective decision into a single "optimal" move on its own authority.

**R-CO-4 (DESIGN-ENTAILED) — Informed-consent and instruction trail.** Material strategic decisions record the client's informed instruction. Acting beyond instruction is blocked/flagged.

### 8.2 Acceptance tests

**AT-CO-1 (misalignment surfaced).**
GIVEN recorded objective = "preserve relationship, minimize public exposure"; WHEN a public, aggressive filing is proposed; THEN the system flags the objective conflict for partner/client decision before action.

**AT-CO-2 (trade-off frontier, not a hidden pick).**
GIVEN a choice between a fast expensive route and a slow cheap route; THEN both are presented with their cost/speed/risk/relationship consequences; the system does not silently choose.

**AT-CO-3 (no LLM-inferred objective as fact).**
GIVEN no human-recorded objective; THEN the system treats the objective as UNKNOWN and requires capture; it does not fabricate a utility profile and act on it.

**AT-CO-4 (beyond-instruction block).**
GIVEN a step exceeding recorded client instruction; THEN it is blocked/flagged for explicit instruction.

---

## 9. Failure catalogue of real firms → required control

Each notorious failure mode mapped to a control above and to the structural property that makes the error *hard* rather than merely *forbidden*. (All DESIGN-ENTAILED.)

| # | Real-firm failure | Mechanism of the disaster | Required control | Structural property |
|---|---|---|---|---|
| F1 | **Missed procedural deadline** (έφεση/αναίρεση lapsed) | manual diary, holiday/August miscount, no escalation | §2 deterministic engine, dual computation, August/holiday model, escalation ladder, no-silence rule | deadline cannot be "satisfied" without an ack or a filing receipt; earliest-date conservatism |
| F2 | **Conflict scandal** (acting against a client / undisclosed adverse interest) | keyword-only check, missed corporate affiliation, emergent post-M&A conflict | §1 identity-resolved graph, continuous re-scan, never-CLEAR-on-incomplete-data | CLEAR is a positive assertion requiring identity closure; barriers are enforced access-control, not memos |
| F3 | **Privilege waiver accident** (privileged doc disclosed) | misclassification, over-broad disclosure, no gate | §3 classify-at-ingest + quarantine unclassified; fail-closed Disclosure/Publication Gateway (privilege review, DLP, redaction, human approval, immutable receipt) | unclassified defaults to quarantine, not disclosable; disclosure requires an affirmative gate pass |
| F4 | **Inconsistent positions** (argued X and ¬X, exposed before same judges) | no institutional memory of positions | §7 position ledger, contradiction detection, judge-exposure map, BLOCKING-until-decision | contradictions block by default; divergence must be a recorded, authorized act |
| F5 | **Filed the wrong / unsigned / stale version** | partner approved draft A, draft B filed | §4 signature bound to exact version hash; post-signature edit re-opens gate | approval is non-transferable across versions |
| F6 | **E-filing failure treated as success** | assumed submission worked, no receipt captured near platform downtime | §5 receipt-or-it-didn't-happen; outage evidence capture; timestamp reconciliation | no receipt ⇒ deadline stays open and escalating |
| F7 | **Broken chain of custody / authenticity loss** | undocumented transfers, tampered digital copy | §3 cryptographically chained custody ledger, intake hashing | tampering is detectable, not just prohibited; custody gaps are reported, not smoothed |
| F8 | **Confidentiality/secrecy breach (εχεμύθεια)** across matters | screened personnel accessed walled matter | §1 R-CONF-4 technical barriers; default-deny access | barrier is an access-control fact; evaluation errors deny |
| F9 | **Won the motion, lost the client** | tactics optimized without the client's true objective | §8 recorded utility model, alignment check, trade-off frontier | objective is human-recorded; misalignment is surfaced, never hidden |
| F10 | **Impermissible courtroom recording** | party recorded/transmitted without permission | §6 default-deny recording gate | capture disabled unless a recorded court-permission fact exists |
| F11 | **Expert/witness defect** (inadmissible statement, conflicted expert) | missed κλήτευση, unchecked expert independence | §3 witness notice check, expert conflict check, expert deadline control | defects flagged POSSIBLY-INADMISSIBLE, not filed silently |
| F12 | **Deadline computed correctly but on the wrong legal characterization** | right arithmetic, wrong procedure family | §2 AT-DL-8 explicit formalization-gap disclosure + human characterization ownership | the engine states its warranty boundary; proof-checking ≠ correctness |
| F13 | **Confident hallucinated answer on the trusted path** | LLM guessing law/deadlines/conflicts | Global invariant: no LLM on correctness-critical path; τίμια άγνοια as a required output state | decisions are deterministic rules or human escalation; "I don't know" is a first-class result |

---

## 10. Cross-cutting: the Disclosure / Publication Gateway (fail-closed)

Per binding project conditions, only final outputs may become public, and only through a separate fail-closed gateway. This document treats every externalization (a filing, a disclosure to opposing counsel, a publication) as passing the same gate class:

**R-GW-1 (DESIGN-ENTAILED).** Externalization requires, in order: privilege review, confidentiality/DLP scan, redaction of protected content, authority/citation validation, named human approval, and an immutable release receipt. Any step failing blocks the externalization (fail-closed). Internal matters, strategies, reasoning traces, and memories never leave the trust boundary except through this gate.

**AT-GW-1.** GIVEN any attempt to externalize content; WHEN any gate step fails or is skipped; THEN externalization is blocked and the attempt logged. There is no bypass path.

---

## 11. Summary of load-bearing invariants (all DESIGN-ENTAILED, none IMPLEMENTED)

1. No LLM on any correctness-critical decision path; LLMs draft/retrieve/explain only.
2. Conflicts: CLEAR is a positive assertion requiring complete identity closure; incomplete ⇒ AMBIGUOUS, never CLEAR.
3. Deadlines: deterministic, versioned-rule, dual-computed, earliest-date-conservative, satisfied only by an ack or a filing receipt.
4. Evidence: cryptographically chained custody; tamper-evident; unclassified ⇒ quarantine.
5. Drafting: partner signature bound to an exact version hash; any later edit re-opens the gate.
6. Filing: no receipt ⇒ it did not happen; deadline stays open.
7. Recording: default-deny absent recorded court permission.
8. Consistency: contradictions block until a recorded, authorized decision.
9. Client objective: human-recorded utility; trade-offs surfaced, never silently resolved.
10. Externalization: fail-closed gateway, no bypass.
11. Honesty: τίμια άγνοια is a required output state; the formalization gap and recall bounds are stated, never buried.

**Standing residual (UNKNOWN, non-negotiable to disclose):** the formalization gap (reality → typed inputs) and the retrieval-recall gap (corpus presence → idea inclusion) are the two dominant residual risks. Every subsystem mitigates but none closes them; they are owned by named humans and stated in outputs. Claiming otherwise would be the two banned equivocations.

**Superiority claim status:** the operational superiority target (§ project goal) is, at this stage, **HYPOTHESIS** at the system level and **DESIGN-ENTAILED** at the level of each individual control's structural property. No IMPLEMENTED or DEMONSTRATED superiority is asserted in this document; that requires build + proof + owner-docker demonstration per the collaboration protocol.
