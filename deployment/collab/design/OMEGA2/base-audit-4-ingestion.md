# BASE AUDIT — LAYER 4: INGESTION / CORPUS / CITATION (THE OBSERVATORY INTAKE)

**Auditor stance:** adversarial, uncharitable. The prior transformation assumed these foundations sound
and marked them KEEP/light-REFACTOR without a quality audit. This audit falsifies that where false.
**Method:** read the real code (`Read`/`Grep`/`Bash`) — `source/ingestion-daemon.lisp`,
`legislation-ingestion.lisp` (the scheduler core), `government-source.lisp`, `source-profile.lisp`,
`ai-ingest-manifest.lisp`, `ai-corpus-dump.lisp`, `corpus-fingerprint.lisp`, `legal-audit-system.lisp`,
`ai-citation-strategy.lisp`, `citation-authority.lisp`, `legal-extraction-verify.lisp`, plus the
case-law seats `legal-decisions.lisp` / `legal-precedent.lisp` / `eu-interop-layer.lisp` and the CLI
wiring in `systems/orchestrator-cli/{ingestion-commands,decisions,main}.lisp`. `output/`,`output_run1/`
read by path only.
**Claim tags:** THEOREM / DESIGN-ENTAILED / IMPLEMENTED / DEMONSTRATED / EMPIRICAL / HYPOTHESIS / UNKNOWN.
`exists-and-runs` ≠ `correct` ≠ `top-level`. A test that asserts only what the code already does is a
finding, not assurance.

---

## 0. THE BOTTOM LINE UP FRONT (the three attacks the brief asked)

1. **Does the repo ACTUALLY watch/ingest real Greek sources, or is intake a stub/manual?**
   *Partly real, but NOT a watchtower.* `government-source.lisp` really fetches over Drakma (SSRF-guarded),
   really decodes windows-1253, really parses ΦΕΚ search-result HTML and PDF text, really hits Διαύγεια
   opendata. So it is **not a stub** (`IMPLEMENTED`/`DEMONSTRATED` for the fetch path). BUT: (a) the **top
   channels are all UNCONFIGURED** — `source-profile.lisp` itself states the sanctioned ΦΕΚ institutional
   feed, EU-CELLAR and open-data are `UNAVAILABLE` until credentials/URLs are injected, so what actually
   runs is the **fragile web-scraper of `https://search.et.gr`** (the channel the file itself rates
   authority `40`, "fragile and legally grey"); (b) there is **no continuous operation anywhere in the
   deployment** — `grep` over `.github/`, `docker/`, `docker-compose.yml`, `configs/`, `cloudflare/`,
   `scripts/` finds **zero** wiring that runs `run-update-daemon`/`run-ingestion-daemon`. "Continuous, in
   real time" reduces to *a human invoking a CLI command that has a `(sleep interval)` loop*. `EMPIRICAL`:
   the observatory does not observe unless someone launches and babysits it.

2. **Is there any judge-level / case-law ingestion at all, or only statutes?**
   *Case-law and named-judge MODELLING exists; case-law INGESTION does not.* `legal-decisions.lisp` (926 L)
   is a genuine, structured decision parser: identity `(court, number, year)`, **judges WITH ROLES**
   (Πρόεδρος / Εισηγητής / μέλη), applied-provision citations with law tags, tempus-regit-actum anchoring,
   ratio/stance extraction; `legal-precedent.lisp` threads δεδικασμένο into the JTMS with a real defeasible
   defeater. This **falsifies "only statutes."** BUT the decisions arrive as **files a human drops in
   `input/decisions/`** (parsed by `parse-decision-text` from the CLI `decisions.lisp`) — there is **no
   court-registry feed, no Άρειος Πάγος / ΣτΕ / Διαύγεια-decision watcher wired into the scheduler.** The
   only feed sources built are `make-fek-source` (laws) and `make-diavgeia-source` (retained, not primary).
   So: judges/doctrine are *represented*, not *watched*. `IMPLEMENTED` parser; `MISSING` intake.

3. **The ≤120-char / ≤120 clamp the prior canon flagged — verified, and how crippling?**
   *Verified, and crippling for anything past the Constitution.* Not a char clamp — an **article-number
   clamp**. `citation-authority.lisp:224`:
   ```lisp
   (when (and num (plusp num) (<= num 120))   ; ← hardcoded to the 120-article Constitution
     (pushnew num citations))
   ```
   Every cited article number **> 120 is silently discarded**. The Greek Constitution has 120 articles; the
   Penal Code has 536, the Civil Code ~2035, ΚΠολΔ ~1054. On any real code the citation graph loses the
   majority of its edges **with no error**. Compounding it: `extract-greek-citations` matches **only
   `άρθρο N`** — it ignores law refs (`ν. 4557/2018`), π.δ., υ.α. and paragraphs, **even though
   `*greek-citation-patterns*` defines all of them** — that parameter is *dead* (never consulted by the
   extractor). And `ai-citation-strategy.lisp:908` `(dotimes (i 120) …)` hardwires 120 again. `DEMONSTRATED`.
   Severity: **needs it to be TOP and, for a multi-code observatory, needs it just to WORK.**

4. **Is extraction verified against source, or trusted?**
   *Trusted, not verified against source.* Two "verification" seats exist but neither closes source-fidelity:
   `corpus-fingerprint.lisp` proves the served corpus has not **drifted from a human-committed golden**
   manifest — it never proves the golden matches the ΦΕΚ. `legal-extraction-verify.lisp` proves a proposed
   **deontic structure** is grounded in the provision text — it never proves the provision text matches the
   ΦΕΚ. So the chain "ΦΕΚ → extracted articles" is **trusted at first golden-commit**; everything downstream
   only guards *that trusted snapshot* against later mutation. This is the foundational hole (see §12).

---

## 1. PER-SEAT VERDICTS (summary table)

| Seat | Verdict | Nature of gap |
|---|---|---|
| `legislation-ingestion.lisp` (scheduler core) | **KEEP-AS-IS** | correct incremental/idempotent poller; gap is *orchestration*, not this code |
| `ingestion-daemon.lisp` | **UPGRADE-IN-PLACE** | wires one code at a time; no decision path; propose/auto ok |
| `government-source.lisp` | **UPGRADE-IN-PLACE** | real fetch, but production path = fragile et.gr scrape; extraction = regex |
| `source-profile.lisp` | **KEEP-AS-IS (design) / EMPIRICAL-UNPOPULATED** | elegant ranked consensus, but every high channel unconfigured |
| `ai-ingest-manifest.lisp` | **RESTRUCTURE** | LLM-SEO "digestibility", fabricated DOIs, cc-by license — wrong mission |
| `ai-corpus-dump.lisp` | **KEEP-AS-IS** | clean deterministic JSONL/DCAT emitter |
| `corpus-fingerprint.lisp` | **UPGRADE-IN-PLACE** | strong drift-gate, but proves golden-vs-served, not source-vs-served |
| `legal-audit-system.lisp` | **KEEP-AS-IS (w/ minor UPGRADE)** | fail-closed signing fixed; `(random)` UUIDs, default IP/actor |
| `ai-citation-strategy.lisp` | **REPLACE / DELETE from trusted layer** | public-web citation-farming; violates "internal private" + "All Rights Reserved" |
| `citation-authority.lisp` | **RESTRUCTURE** | ≤120 clamp, άρθρο-only extraction, dead pattern table |
| `legal-extraction-verify.lisp` | **KEEP-AS-IS / UPGRADE** | best-in-layer honest gate; but 81.5% EMPIRICAL classifier, not source-fidelity |
| `legal-decisions.lisp` + `legal-precedent.lisp` | **KEEP model / BUILD intake (NEW)** | real judge/case-law model; no automated feed |
| `eu-interop-layer.lisp` (ΔΕΕ/CELLAR) | **UPGRADE-IN-PLACE** | real CELLAR client exists; not wired as a live ingestion channel |

---

## 2. `legislation-ingestion.lisp` — the scheduler core — **KEEP-AS-IS**

- **What it is (`DEMONSTRATED`):** `make-ingestion-source` (name + `(fetcher since)`), `scheduler` with a
  `cursor` (ISO date high-water mark) + `seen` id-set, `poll-once` (fetch>cursor, drop seen, dispatch in a
  deterministic `item<` order, advance cursor, persist injected state), `run-scheduler` (`(sleep interval)`
  loop, `max-polls` for bounded/test runs, `on-cycle` hook). Persistence is **injected** (`save-state-fn`),
  so the core does no file I/O.
- **Correct?** Yes for what it is: incremental, idempotent, deterministic order, replay-safe cursor/seen.
  `IMPLEMENTED` and genuinely clean — no fake fallback, no silent state loss.
- **(a) Defect / limitation:** the "stays up to date **in real time**" banner (lines 6–9) is only true if
  something calls `run-scheduler` forever. Nothing in the repo does (§0.1). Also idempotency is keyed purely
  on `ingest-item-id`; a **re-published/corrected** item that reuses its id (a ΦΕΚ correction — *διόρθωση
  σφάλματος*) is dropped as "seen" — a real correctness hazard for legal text. `DEMONSTRATED` from `poll-once`.
- **(b) WORK vs TOP:** WORK-level is met; the real-time/observatory claim is TOP-level and unmet by *this
  file* — but the fix is not here.
- **(c) Upgrade:** leave the core; add (i) a deployment unit (systemd/compose/CI cron) that actually runs it;
  (ii) a content-hash dimension to `seen` so a corrected re-issue of the same id is *not* silently skipped.

## 3. `ingestion-daemon.lisp` — deployment glue — **UPGRADE-IN-PLACE**

- **What (`DEMONSTRATED`):** wires `source → consolidation-feed → scheduler`; on each amending act re-emits
  `consolidated.{txt,ttl,akn.xml}` + `corpus.jsonl` + `catalog.jsonld` through the GATE-2 write authority
  (`emit-graph`, provenance scope). Two policies: `:auto` (high-confidence ops auto-publish, uncertain →
  review queue) and `:propose` (everything → human YES; the feed is not even called). The `%payload-has-review-p`
  fix (handles both alist and plist record shapes) is a real, honest bug-closure noted in-code.
- **(a) Defect:** it consolidates **one `base-document` at a time** (`run-update-daemon :base-document …`).
  An observatory of "every new law" must maintain **N codes concurrently**, route each amending act to the
  *right* base, and open new corpora when a wholly new law appears. This seat has no multi-corpus dispatch —
  that logic (if any) lives in the CLI `%daemon-cycle`, not here. There is also **no decision/case-law
  branch**: `kind` "decision" items would be handed to a legislation consolidation feed that cannot consume
  them. `DEMONSTRATED`.
- **(b) WORK vs TOP:** WORK for a single tracked code; **needs it to be TOP** for a corpus-wide watchtower.
- **(c) Upgrade:** a corpus router (act → target base-document(s)); a parallel decision-ingestion dispatch
  that feeds `legal-decisions.lisp`, not the consolidation feed.

## 4. `government-source.lisp` — the real fetcher — **UPGRADE-IN-PLACE**

- **Genuinely real (`DEMONSTRATED`, not stub):** exact windows-1253 table (`+cp1253-high+`, the 0x80–0x9F
  smart-quotes ISO-8859-7 lacks — matters for court text); `fetch-url` defensive (never throws, returns a
  status), routed through the **single SSRF guard** `orchestrator.document-fetch:url-fetch-allowed-p` (the
  correct choke point for attacker-controlled ΦΕΚ hrefs) and binary-magic classification so a docx/pdf is
  not force-decoded as text; `parse-fek-listing-html` keys off the `number/year` legislative pattern (robust
  to DOM changes); PDF path via poppler; `make-fek-source`, `make-diavgeia-source`.
- **(a) Defect / limitation:**
  1. The **production law feed is a scrape of `search.et.gr` HTML** — `source-profile.lisp` itself classes
     this channel authority `40`, "fragile and legally grey." The *authentic* channel (sanctioned ΦΕΚ bulk /
     National Printing House feed) is **not configured** (§5). So intake authenticity is EMPIRICAL-fragile.
  2. Amendment understanding is delegated to `orchestrator.amendment-extractor:extract-amendment-record`
     (regex over stripped text). Whatever that misses becomes a silently-missed amendment; the feed keeps the
     raw item and *ignores* it (line 568 `(if usable record it)`) — honest, but a coverage hole with no alarm.
  3. `%pdf->text` writes to `/tmp/fek-doc-<ut>-<random>.pdf` with `(random 1000000)` — collision-prone and
     non-deterministic; a determinism-first system should use the run-scoped scratch + a content hash.
  4. `materialize-corpus` on a text path does `(map 'string #'code-char content)` when `content` is already
     decoded bytes — a latent mojibake path if a non-UTF-8 body slips through as octets.
- **(b) WORK vs TOP:** fetch mechanics are near-TOP; **source authenticity is not TOP** (scrape, not feed).
- **(c) Upgrade:** configure/obtain the institutional ΦΕΚ feed; make the amendment-extraction miss a
  *first-class review event* (not a silent raw-item pass-through); deterministic temp paths.

## 5. `source-profile.lisp` — ranked multi-source consensus — **KEEP-AS-IS (design) / EMPIRICAL-UNPOPULATED**

- **What (`DEMONSTRATED`):** a MOP metaclass carries per-channel **authority rank** + redistributability;
  `institutional-feed 100 > open-data 80 > eu-cellar 70 > web-scraper 40 > manual 20`. `acquire-with-consensus`
  groups by logical identity, SHA-256-hashes canonical content, and per provision: agreement → TRUSTED
  (`:sole`/`:agreed`); an official source strictly above `*auto-trust-authority*` (80) beats a lower one →
  `:authority-override`; genuine disagreement → `consensus-conflict` → review item (a lawyer confirms). This
  is a real "ανώτερο": automatic where channels agree, human exactly where they diverge. `DESIGN-ENTAILED`
  and well-built — this is the *right shape* for a trusted observatory.
- **(a) Defect:** it is **an empty frame in practice.** `make-institutional-profile` is UNAVAILABLE with no
  `feed-url`/`feed-dir`; `make-eu-cellar-profile` UNAVAILABLE without an `eli`; `make-open-data-profile`
  needs Drakma+endpoint; `default-source-profiles` therefore collapses to **web-scraper + manual-drop** — the
  two lowest channels — so "multi-source consensus" reduces to *one fragile scrape* with nothing to
  corroborate it, and `*auto-trust-authority* 80` means a lone scraper (40) can **never** auto-trust: every
  scraped provision that disagrees with a manual drop goes to conflict. In the common single-source case,
  `%resolve-group` returns `:sole` = TRUSTED **on one unauthenticated scrape**. `EMPIRICAL`.
- **(b) WORK vs TOP:** the design is TOP; the *populated reality* is below WORK for a trusted spine.
- **(c) Upgrade:** provision at least two genuinely-independent authoritative channels (institutional ΦΕΚ +
  EU-CELLAR for EU-origin), so consensus has something to reconcile; otherwise the consensus machinery is
  decorative.

## 6. `ai-ingest-manifest.lisp` — LLM "digestibility" manifest — **RESTRUCTURE**

- **What it actually is:** *not ingestion.* It scores each article's **"saturation"** for LLM-crawler
  attractiveness from factors like `:rdfa :opengraph :schema-org :telemetry :backlinks` (`*saturation-factors*`),
  emits a **HuggingFace** dataset (`stavropoulos/greek-constitution-semantic`), and computes a "quality score"
  that is really a *marketing readiness* score. The banner literally says "maximum AI digestibility",
  "world-class implementation for maximum AI citations".
- **(a) Defects (multiple, `DEMONSTRATED`):**
  1. **Mission-wrong.** Binding condition = *internal private single-firm*. This seat is about being *found &
     cited by public AI systems* — the opposite of a private trusted spine. It belongs (if anywhere) to a
     separate public-publication surface, never the intake layer.
  2. **License contradiction.** Dataset card hardcodes `license: cc-by-4.0` (lines 512, 609). CLAUDE.md:
     "Άδεια: All Rights Reserved παντού." A CC-BY stamp on the firm's corpus is a governance violation.
  3. **Fabricated identifiers.** `generate-semantic-beacon` (sibling seat) mints `DOI: 10.5281/stavropoulos.N`
     — a DOI namespace the firm does not own; presenting an unregistered DOI is fabrication ("no fabrication").
  4. `structured_citations` = count of the `+citation-scanner+` regex hits; `saturation` mixes real signals
     with `:telemetry`/`:opengraph` that are constant (`check-factor-present` returns fixed booleans) — so the
     "readiness percentage" is partly a tautology over hardcoded constants.
- **(b) WORK vs TOP:** it runs and is deterministic — but it is solving the *wrong problem* for this system.
- **(c) Restructure:** strip the SEO/HuggingFace/DOI/telemetry apparatus; if a machine-readable export is
  wanted, keep only the neutral, license-correct `dataset-jsonl-string`/`manifest->json-string` (the live
  `/dataset` endpoint) under All-Rights-Reserved, and move even that behind the fail-closed Publication
  Gateway, not the intake layer.

## 7. `ai-corpus-dump.lisp` — JSONL/DCAT emitter — **KEEP-AS-IS**

- Clean, deterministic, hand-escaped JSON; one article per JSONL line with eId/number/heading/in-force/status/
  amended-by/date/text/paragraphs; DCAT catalog advertising distributions. In-force logic honest
  (repealed → excluded). No fabrication, no wall-clock. `IMPLEMENTED`, correct, appropriately scoped. The one
  nit: `base-uri` defaults to the public `stavropouloslaw.com/eli` — fine for the served surface, but this is
  a *consumption/output* seat, not intake; its presence in the "ingestion" set is a taxonomy artifact.

## 8. `corpus-fingerprint.lisp` — the "correctness guarantee" — **UPGRADE-IN-PLACE**

- **Strong (`DEMONSTRATED`):** per-provision SHA-256 over the whole subtree with **length-prefixed** canonical
  encoding (no delimiter ambiguity), folded into an **RFC-6962 Merkle root** (single `orchestrator.merkle`
  seat, domain-separated leaves/nodes — the CVE-2012-2459 duplicate-last footgun explicitly removed);
  `fingerprint-diff` locates drift as exact ADDED/REMOVED/CHANGED eId sets; structural invariants
  (`%eid-invariants`): unique eIds, no empty article, **no sequence gap** (with `known-absent` for
  source-omitted articles — a genuinely thoughtful touch), canonical ascending order, count match. Safe-read
  manifest load (`*read-eval* nil`). This is the **best-engineered seat in the layer.**
- **(a) The defect that matters:** the banner claims it "takes the source text and codifies it PERFECTLY, with
  zero error, and PROVES it." It proves **no such thing about the source.** `fingerprint-matches-golden`
  compares the served document to a **golden manifest a human committed once**. It is a *determinism / no-drift*
  proof relative to that human snapshot — **not** a *fidelity-to-ΦΕΚ* proof. If the very first extraction
  mis-read the ΦΕΚ (a dropped clause, an OCR'd digit), the golden enshrines the error and the fingerprint
  gate will forever certify the wrong text as "correct." `DEMONSTRATED` (this is what the code does);
  `THEOREM`-not-reached for "matches the law." This is proof-checking mislabelled as formalization/extraction
  correctness — the exact conflation the canon forbids.
- **(b) WORK vs TOP:** great as a drift gate; the *headline correctness claim* is unearned.
- **(c) Upgrade:** rename/rescope the claim to "no-drift-from-ratified-golden"; add a **source-fidelity
  admission step** (see §12): the golden may only be *ratified* after an independent re-derivation from the
  authenticated source agrees byte-for-byte (or a human diff sign-off is recorded), so the golden is *earned*,
  not asserted.

## 9. `legal-audit-system.lisp` — PROV-O audit trail — **KEEP-AS-IS (minor UPGRADE)**

- **Solid (`DEMONSTRATED`):** hash-chained entries (SHA-512, prev-hash linked), PROV-O turtle/json-ld/xml,
  Merkle seal via the single merkle seat, and the **fail-closed signing fix (Blocker#1)** is real and
  correctly reasoned: with a key configured, `sign-entry` **signals** rather than downgrading to the forgeable
  `SIGNED:` legacy string, and `verify-signature` **rejects** legacy signatures once a public key is present
  (closing the recompute-and-forge hole). Constant-time legacy compare.
- **(a) Minor defects:** `generate-uuid`/`generate-activity-id` use `(random …)` — non-deterministic ids in a
  determinism-first system (audit ids will differ run-to-run, defeating replay equality on those fields);
  `get-client-ip`→`"127.0.0.1"` and `get-user-agent`→`"ORCHESTRATOR/1.1"` default to fabricated-looking
  provenance when unset (honest-ignorance would prefer `nil`/UNKNOWN). `verify-gdpr-compliance` only `warn`s
  on a missing justification rather than failing.
- **(b/c):** WORK-and-mostly-TOP; swap `random` ids for a deterministic content-derived id; make unset
  IP/agent explicit UNKNOWN, not a plausible default.

## 10. `ai-citation-strategy.lisp` — citation FARMING — **REPLACE / DELETE from the trusted layer**

- **What it is:** an SEO/observability apparatus to **maximize and track citations of the firm's corpus by
  public AI systems** — `citation-beacon`s inviting GPT-4/Claude/Bard/… to cite (with ORCID, fabricated DOIs,
  "reward: Acknowledgment in future versions"), Prometheus **POSTs to a public endpoint**, MongoDB storage,
  per-AI-system "velocity" metrics.
- **(a) Defects (`DEMONSTRATED`):** (i) diametrically opposed to the *internal private single-firm* binding —
  it exists to broadcast and be cited externally; (ii) `dotimes (i 120)` hardwires the 120-article
  Constitution again; (iii) emits `schema:license <…/by/4.0/>` — CC-BY again vs All-Rights-Reserved; (iv)
  `send-prometheus-metric` does an outbound `drakma:http-request` from what is nominally corpus code — an
  egress path with no gateway; (v) whole thing is speculative telemetry (`setup-webhook-listener` etc. are
  `t`-returning stubs).
- **(b/c):** This is not intake and not trusted-spine material. **Delete it from the observatory core**; if
  the firm ever wants public-citation analytics, it lives outside the trust boundary, behind the Publication
  Gateway, under the correct licence, with no unreviewed egress.

## 11. `citation-authority.lisp` — citation graph / TF-IDF / PageRank — **RESTRUCTURE**

- **What (`DEMONSTRATED`):** pure-Lisp citation graph, TF-IDF embeddings, PageRank (power iteration, dangling
  handled), Brandes betweenness, semantic-hub scoring, pure-Lisp JSON. Competent graph code.
- **(a) The crippling defects:**
  1. **The ≤120 clamp** (`line 224`, quoted in §0.3): any cited article number > 120 is dropped silently.
     Hardwires the corpus to the Constitution. For the Penal/Civil/Procedure codes this **erases most
     citation edges** with no error. `DEMONSTRATED`.
  2. **άρθρο-only extraction.** `extract-greek-citations` scans only `"άρθρο/άρθρον"` literals; it **never
     reads `*greek-citation-patterns*`** (which defines law/π.δ./υ.α./Σύνταγμα/παράγραφος patterns). That
     rich pattern table is **dead code**. So cross-law references — the backbone of a real legal citation
     graph — are invisible. `DEMONSTRATED`.
  3. Consequence: the graph is *intra-single-document, article→article, numbers ≤120*. PageRank/betweenness
     over that is a toy metric, not "maps every reference."
- **(b) WORK vs TOP:** for a multi-code observatory it fails **just to WORK**; the graph algorithms are TOP-
  quality but fed a crippled edge set.
- **(c) Restructure:** delete the `≤120` guard (bound by the *actual* corpus article set, not a constant);
  make `extract-greek-citations` consume `*greek-citation-patterns*` and emit **typed, cross-corpus**
  references (`(:law 4557 2018 :article 42 :paragraph 5)`), resolving law-tag→corpus so edges cross documents;
  only then are centrality metrics meaningful.

## 12. `legal-extraction-verify.lisp` — the "neural proposes / symbolic judges" gate — **KEEP-AS-IS / UPGRADE**

- **The strongest idea in the layer (`DEMONSTRATED`):** a proposal→proof-obligation verifier. An LLM proposes
  a deontic structure for a provision; the symbolic core accepts **only if proven** by four deterministic
  checks: **V1** provenance (valid `corpus:article`, node exists if a graph is given), **V2** *grounding* —
  the cited evidence passage must appear **verbatim** in the provision text **and** carry a deontic operator
  compatible with the claimed modality, **V3** structural type validity, **V4** self-consistency (no
  `O(a)∧F(a)` from one source) in the JTMS. One failure ⇒ rejection with an explicit reason ("honest
  ignorance, never a silent guess"). The deontic classifier (`classify-deontic-sentence`) is priority- and
  scope-aware (subordinate/relative/conditional spans, negation-as-inversion, exclusive «μόνο»), and was hardened
  by **measured adversarial rounds (163 samples, 5 critics, 56% → 81.5%)**. This is the right anti-hallucination
  posture and it is real, not a tautology.
- **(a) Honest limits (the audit's job):**
  1. It verifies **deontic-structure grounding against the provision text** — it does **not** verify the
     provision text against the ΦΕΚ. So it is the *inner* gate; the *outer* source-fidelity gate (§8) is the
     one still missing. Together they leave the "ΦΕΚ → text" edge **trusted**.
  2. The classifier is a **hand-rolled Greek NLP heuristic at 81.5% EMPIRICAL accuracy** — i.e. ~1 in 5
     deontic classifications is wrong on the measured set. V2 requires the *marker to be present*, which
     catches fabricated modality, but a **mis-classified-yet-present** marker (the ~18%) can still pass V2 and
     mint a wrong norm. Presented as part of the "trusted path," an 81.5% classifier is `EMPIRICAL`, not the
     "0 λάθος" the creator law demands — it *narrows* error, it does not eliminate the class.
  3. Coverage is **deontic norms only.** "Maps every new law + decision + doctrine" needs far more extracted
     structure (definitions, cross-references, temporal scope, sanctions, procedure) — each of which would
     need its own proof-obligation, none of which exist here yet.
- **(b) WORK vs TOP:** best-in-layer and near-TOP *for deontic extraction*; the surrounding fidelity gate and
  the non-deontic structure are missing for TOP.
- **(c) Upgrade:** keep verbatim; add the source-fidelity V0 (evidence text ⊂ *authenticated source bytes*,
  not just the served provision); treat the 81.5% classifier as a *proposer confidence*, not a trusted
  oracle — its output should still route through human review below a threshold, and its accuracy should be a
  standing measured gate, not a one-off number.

## 13. Case-law / judges / EU — model present, INTAKE is NEW work

- `legal-decisions.lisp` (**KEEP model**): genuine structured decisions — **named judges with roles**,
  applied-provision citations bound to the served codes' graph, tempus-regit-actum ("court applied the very
  text served today, PROVABLY" vs "τροποποιήθηκε μετά την απόφαση"), ratio/stance. Identity from filename
  `(court,number,year)` so identity never depends on parsing — sound.
- `legal-precedent.lisp` (**KEEP**): δεδικασμένο in the JTMS with a real defeasible defeater (a stale-judgment
  conclusion retracts itself when a later decision reaffirms on the current text) — and it *fixed* a dead
  existential defeater (unbound `?d2`) — honest, correct non-monotonic modelling.
- `eu-interop-layer.lisp` (**UPGRADE**): real `search-cellar-by-eli` / `fetch-cellar-document` /
  `search-eurlex` clients against the EU's official SPARQL/EUR-Lex endpoints exist — but are wired only as an
  optional `make-eu-cellar-profile` that is UNAVAILABLE unless an `eli` is supplied; **no ΔΕΕ (CJEU) / ΕΔΔΑ
  (ECtHR) decision watcher** feeds the scheduler.
- **NEW work required (clearly NEW, not a broken existing seat):**
  - a **decision-ingestion source** (Άρειος Πάγος / ΣτΕ / Εφετεία registries, Διαύγεια-decision feed, ΔΕΕ &
    ΕΔΔΑ) that yields `kind "decision"` ingest-items and routes them to `parse-decision-text`, not the
    legislation consolidation feed;
  - a **judge registry** as a first-class corpus (the per-judge analytics the header promises are only as
    live as the decisions fed in — today: manual files);
  - **doctrine ingestion** (νομική θεωρία) has *no seat at all* — the mission's "doctrine" axis is unbuilt.

---

## 14. THE SINGLE MOST SERIOUS FOUNDATIONAL DEFECT

**Extraction is TRUSTED, never verified against the authoritative source — and the seat that advertises
"codifies PERFECTLY, zero error, PROVES it" only proves the served corpus has not drifted from a
human-committed golden, not that the golden matches the ΦΕΚ.**

For a system whose whole reason to exist is to be *the trusted spine* ("no fabrication; the trusted spine a
legal super-system is built on"), the ΦΕΚ→text edge is the root of trust — and it is exactly the edge with
**no verifier**. `corpus-fingerprint.lisp` guards *golden→served* (drift), `legal-extraction-verify.lisp`
guards *proposal→provision-text* (deontic grounding), the audit trail guards *record integrity* — a beautiful
chain of guarantees **all anchored to a first extraction that no machine ever checked against the official
source.** A single mis-read at golden-commit is enshrined and then *certified correct forever* by the very
"correctness guarantee." This is proof-checking presented as formalization/extraction correctness — the
prohibited conflation — sitting under the layer's headline claim. `DESIGN-ENTAILED` hole; `DEMONSTRATED` in
the code paths.

**Second-order, but nearly as damaging and far more concrete:** the citation/reference layer is hardwired to
the 120-article Constitution (`≤120` clamp + άρθρο-only extraction + dead pattern table + `dotimes 120`), so
the instant the corpus is any real Greek code, the reference graph silently loses most of its edges. Combined
with (a) top acquisition channels unconfigured (only a fragile et.gr scrape runs), (b) no deployment wiring
that keeps the daemon alive, and (c) case-law/judges/doctrine present as *parsers* but with *no automated
feed*, the current intake is **an on-demand, single-code, Constitution-shaped scraper with an unverified
root of trust — not the continuous, corpus-wide, source-faithful observatory the mission requires.**

**Restructure/build priority:** (1) a source-fidelity admission gate that *earns* the golden (independent
re-derivation from authenticated source must agree before ratification); (2) de-hardcode citation extraction
(remove `≤120`, drive the real pattern table, typed cross-corpus edges); (3) populate ≥2 authoritative
acquisition channels so consensus is real; (4) deploy the daemon as an always-on unit; (5) BUILD decision +
judge + doctrine ingestion feeds (NEW); (6) delete the public-web SEO/citation-farming seats from the trusted
core; (7) demote the 81.5% deontic classifier from "trusted" to "measured proposer + human review."
