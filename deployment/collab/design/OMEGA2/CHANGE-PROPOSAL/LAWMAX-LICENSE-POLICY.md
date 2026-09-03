# LAWMAX-LICENSE-POLICY — Rights & License Architecture (RA-L · v1.7 CANDIDATE · NORMATIVE)

**ΚΑΤΑΣΤΑΣΗ: `SPEC v1.7 CURRENT CANDIDATE — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`.**
Parent `f05f5514`. This is the **single canonical seat** for the rights/license model. It is a specification;
no license is applied to any real artifact here. The machine-readable types live in `V1.7-SCHEMAS.sexp §RA-L`
(`RightsMatrix/1`, `LicensePolicy/1`, `ArtifactRightsClass`, `RightsDisposition`, `LegalReviewState`); this doc
is the human-readable normative statement generated over them. It is bound to the existing citation/dataset
manifest by a versioned `license_policy_id` (RA-K/RA-T), never a second rights store.

## 0. Non-negotiable principles
- **RA-L-1 no unlicensed licensing.** LAWMAX MUST NOT publish a license grant for material for which it holds no
  licensed right. Absent a proven right, `RightsDisposition = :RIGHTS_UNKNOWN` and the artifact is not
  redistributed under any LAWMAX license (it may still be *cited/linked* to the official source).
- **RA-L-2 public-domain requires legal validation.** `:PUBLIC_DOMAIN` is asserted ONLY with
  `LegalReviewState = :LEGALLY_VALIDATED` and an evidence ref. A guess is `:RIGHTS_UNKNOWN`, never public-domain.
- **RA-L-3 official source ≠ LAWMAX work.** The act of enacting a law/decision belongs to its real issuer
  (RA-MIS). LAWMAX licenses ONLY its OWN contribution (consolidation, identity, graph, proofs, datasets,
  software); it never re-licenses the official text as if it authored it.
- **RA-L-4 free verification is never paywalled.** The ability to *verify* a proof/citation offline stays free
  and open (RA-K). The commercial layer sells SLA / warranties / indemnity / volume / support / custom
  attestations — not the truth or its verifiability.
- **RA-L-5 attribution is machine-bound but reasonable.** For LAWMAX-owned material under CC BY 4.0, attribution
  is satisfied in any reasonable manner permitted by CC BY; the *exact mandatory* machine-citation format lives
  in the proof/citation protocol (RA-K) or a separate enterprise/custom contract, and is **not** injected as an
  extra restriction inside the CC BY grant itself (that would be a CC-incompatible added condition).
- **RA-L-6 privacy overrides rights.** Anonymization / DPA restrictions (RA-J `AnonymizationReceipt`) can DENY a
  reproduction/redistribution that the copyright layer would otherwise allow. The stricter of the two governs.

## 1. Artifact rights classes (`ArtifactRightsClass`)
Each artifact class gets its own `RightsMatrix/1`. The classes are disjoint; one artifact carries exactly one
primary class (a derivative names its `derived_from`).

| # | class | who holds the right | default disposition |
|---|---|---|---|
| 1 | `OFFICIAL_SOURCE_TEXT` | the real issuer (State, court, EU, …) | LAWMAX asserts **no** ownership; reproduction governed by the source's own legal status (validated per source type), never a LAWMAX grant |
| 2 | `LAWMAX_CONSOLIDATION_CODIFICATION` | LAWMAX | CC BY 4.0 (owned) — the consolidated/codified expression, clearly marked as LAWMAX consolidation, not the official text |
| 3 | `METADATA_IDENTITY_GRAPH` | LAWMAX (sui generis DB right where applicable) | CC BY 4.0 (owned), subject to DB-right note |
| 4 | `HEADNOTE_SUMMARY_TRANSLATION` | LAWMAX | CC BY 4.0 (owned) + `NON_AUTHORITATIVE` marking (RA-E) |
| 5 | `PROOF_RECEIPT` | LAWMAX | open + free verification (RA-L-4); machine-citation binding via proof protocol |
| 6 | `DATASET_SNAPSHOT` | LAWMAX (compilation) | CC BY 4.0 (owned) + per-item upstream rights preserved; signed manifest (RA-T) |
| 7 | `SPECIFICATION_SCHEMA` | LAWMAX | CC BY 4.0 or approved open spec license |
| 8 | `SOFTWARE` | LAWMAX | separate approved software license (NOT CC BY — CC is not a software license) |

## 2. `RightsMatrix/1` fields (per artifact class)
`rights_basis` · `copyright_status` · `database_right_status` · `public_domain_status` · `reproduction` ·
`transformation` · `redistribution` · `commercial_api_use` · `attribution` · `privacy_anonymization_restriction` ·
`license_version` · `effective_period` · `provenance` · `legal_review_state`.
Each grant field ∈ `RightsDisposition = {:GRANTED, :GRANTED_WITH_CONDITION, :DENIED, :RIGHTS_UNKNOWN}`.
`legal_review_state ∈ LegalReviewState = {:UNREVIEWED, :IN_REVIEW, :LEGALLY_VALIDATED, :DISPUTED, :WITHDRAWN}`.
A field left `:RIGHTS_UNKNOWN` fails closed (no redistribution of that mode).

## 3. Commercial vs. open boundary
- **Open, always free:** verification of proofs/citations; reading the official source via its lawful public
  status; the LAWMAX-owned CC BY layer under CC BY terms.
- **Commercial (separate contract, `license_policy_id` variant):** SLA / uptime, warranties, indemnity, volume /
  rate, priority support, custom machine-citation attestations, private/enterprise integrations. These add
  *service guarantees*, never restrictions on the free-verification path (RA-L-4).

## 4. Binding & versioning
`license_policy_id` is versioned and pinned into the existing citation/dataset manifest (RA-K/RA-T seats), so a
dataset/answer carries the exact rights policy that produced it. A change of terms is a new
`license_policy_id` version with an `effective_period`; historical artifacts keep the policy version under which
they were released (no silent retroactive relicensing).

## 5. What this seat does NOT do (honest scope)
No legal validation is performed here (that is `LegalReviewState` future work, a **finite external gate**:
`RA-L-GATE → owner=creator/legal counsel → required evidence=rights clearance per source type → entry gate before
any public-domain or redistribution grant → failure state=:RIGHTS_UNKNOWN/fail-closed`). No real artifact is
licensed. This is design/spec only.
