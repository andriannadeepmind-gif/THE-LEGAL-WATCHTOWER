# OPTION-A-ORIGINAL-20-GATE-SURVIVAL-MATRIX

**Read-only reconnaissance artifact — NOT a repository file.** Target: commit `4ee2b58a8df0941845ab786bd0ff859844b94dde`, tree `ad71185a26b3beb39da6d50c09f567cff0475def`, branch `claude/lawmax-omega-arch-review-vgi9zl`. Produced by three fresh-context agents (git archaeology, artifact semantics, adversarial skeptic) plus the orchestrator's own `git show`-derived lineage and mapping; every claim carries a commit/file/line citation; nothing was executed (`sbcl`/`clingo` absent in the session container).

## 0. Governing statement — what was found, what was not, and how the 20 are identified

1. **The phrase "Full build, all 20 gates" exists nowhere in the repository**: zero hits in every tracked file of all 7 refs and in all 517 commit messages (English and Greek phrasings; `git grep` over all refs; `git log --all -S`). The option pair exists in the repository only as LABELS: "option-1 / full-build closure" first at `f04bf7e6` ([0161] §1 scope exclusion), "Option-2 core" first in the TITLE of the external Review #1 report (`dialogue/0161-claude.md:5`), "Επιλογή Α / OPTION-A / the original 20 Full-Build gates" only at `4ee2b58a` ([0164]:10,51,100; STATE-OF-PLAY:999,1019; GATE.sh:230-231; packet:157). **No document in the repository defines either option or lists the 20 gates.** Verdict of the archaeology: **PARTIALLY-EVIDENCED** (name in repo, list NOT-IN-REPO).
2. **The only 20-gate artifact in repository history** is `ARCHITECTURE-MODEL-GATE.sh` at `a2f45f6d` (byte-identical at `818b7dd9`, the tree Review #1 judged): exactly 20 counted `ck` calls, whose comment headers number the CONCEPTS `G1…G21` (G3 unheadered, G10–G12 merged into one check, G9 split into 09a/09b). The `a2f45f6d` commit message itself says "20/20 gates PASS (incl. anti-omission G19-G21)" (verified, message line 24). The numbering therefore pre-dates the script and came from the [0160] order, which is not in the repository.
3. **Identification adopted here (after the skeptic, finding S-1): a CONCEPT identity with a different SCOPE, not a set identity.** The candidate "original 20 Option-A Full-Build gates" = the gate concepts G1…G21 as realised by the 20 `ck` checks of `818b7dd9`, DEMANDED OVER THE FULL 66-CLASS MODEL AFTER DDI-1…DDI-4. Evidence that the scope differs: the 20 checks byte-for-byte cannot be full-build gates — G20 requires a `:status DEFERRED_DATA_IMPORT` row to be present (`a2f45f6d` GATE:94), which is absent by design after DDI-4; G21 drops the row `V1.8-SCHEMAS__define-record` (GATE:96), which is IMPORTED after DDI-2; `build_deferred.py` hard-codes the IMPORTED set of 4 (`4ee2b58a` build_deferred.py:75-80, `OVER-CLAIMED-IMPORT` L236-239). Under this reading the [0164] sentence "those original gates remain a mandatory future stage after DDI-1…DDI-4" is a reconciliation, not a contradiction. **Every status in §4 is therefore the status of the concept over the CORE model (4 imported classes); the DDI column is primary.**
4. **The identification stays a CANDIDATE.** Whether Option A's "20" counts the 20 `ck` calls, the 21 G-numbered concepts, or a list in the external review, is not decidable from the clone (adjudication A-1 below). This document does not reconstruct the list from imagination; it reconstructs what the repository proves and names the external artifact that settles the rest (§9).

## 1. Search universe and lexical evidence (archaeology, verified by the orchestrator)

### 1.1 Search universe (what was actually searched)

| axis | value | evidence |
|---|---|---|
| refs | 9 refs = 7 distinct tips (`refs/heads/claude/lawmax-omega-arch-review-vgi9zl`=4ee2b58a, `origin/main`=e621dbe1, `origin/agent/verification-integrity-repair-20260815`=20084e46, `origin/claude/blind-input-capsule-phase-2-efiajz`=78277cc0, `origin/claude/deep-seek-project-handoff-7q4j6o`=eeda9834, `origin/claude/fable5-recovery-audit-xbucre`=af0eb3c9, `origin/claude/rev3-2-verification-qny3ie`=2b910271); 0 tags | `git for-each-ref`; `git rev-parse --branches --remotes \| sort -u` = 7 |
| commits | 517 reachable from all refs; clone not shallow; reflog 1 entry, stash 0, `git fsck --unreachable --no-reflogs` printed nothing | `git rev-list --all \| wc -l` |
| pickaxe (`git log --all -S`) | "20 gates", "all 20", "Full build", "full-build", "full build", "20 πύλες", "Επιλογή Α", "Option A", "option-1", "option 1", "20/20", "Option-A", "Option-2", "option-2", "Επιλογή 2", "Επιλογή Β", "20 πυλών" | §1.1 |
| message grep (`git log --all -i --grep`) | same phrases + "twenty", "Option 2", "option" | §1.1 |
| content grep over all 7 tips (`git grep -F`) | "Option A", "Option-A", "Επιλογή Α", "option-1", "full-build", "Full build", "20 gates", "20 OPTION-A", "twenty gates", "20 πύλες", "Option-2", "OPTION-2", "option-2", "Full-Build", "FULL-BUILD", "20 Full", `\bG(19\|20\|21)\b`, "K01…K25" | `gitgrep-allrefs.txt` |
| gate file history | `git log --all --follow -- GATE` = exactly 5 commits: a2f45f6d, f04bf7e6, af0eb3c9, a87bb6b7, 4ee2b58a (818b7dd9 and cc52a27d do not touch it) | §2 |
| dialogue records | `deployment/collab/dialogue/0160..0164-claude.md` read in full; `AI-DIALOGUE.md` rows 150–154 (L259–263); `STATE-OF-PLAY.md` L7, L107, L858–1025 | §3 |
| CHANGE-PROPOSAL tree | V1.3–V1.8 audit scripts, `V1.8-VERIFY.py`, manifests, `IMPLEMENTATION-SEQUENCE.md`, `PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md`, `V1.7-ROOT-AUTHORITY-ACCEPTANCE-MATRIX.md`, `V1.8-VERIFICATION-EVIDENCE.md`; AM adjudication/packet/template/TCB documents | §4 |
| non-AM gate universes | `deployment/LAWMAX-REPO-ONTOLOGY-MAP.{md,sexp}`, `deployment/LAWMAX-CONSOLIDATION-PLAN.md`, `deployment/verify/gate-registry.sexp`, `deployment/verify/assess-gate-plenary.sh`, `systems/orchestrator-cli/*.lisp` `--*-gate` strings, `deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | §4.3 |


### 1.2 Where the words come from (attempted refutation of the BRIEF)

#### 1.1 The exact phrase and its components

* "Full build, all 20 gates" (and "all 20 gates", "Option-A", "Επιλογή 2/Β", "option 1", "twenty gates", "20 πυλών"): **zero hits** in any tracked file of any ref and in any commit message. The BRIEF's claim is confirmed, not refuted.
* "all 20" pickaxe hit c7c10502 is a false positive ("treat all 2026 agentic capability claims as UNKNOWN", `deployment/collab/design/OMEGA2/TARGET-ARCH/WATCHTOWER-v0.7.1-PRE-FREEZE-EVIDENCE-CLOSURE.md` neighbourhood).
* "20 gates" occurs in the repo **only** as the count of the a2f45f6d gate script: commit message a2f45f6d ("ARCHITECTURE-MODEL-GATE.sh: 20/20 gates PASS (incl. anti-omission G19-G21)"), `deployment/collab/dialogue/0160-claude.md:48` ("PASS (20/20 gates)"), `deployment/collab/AI-DIALOGUE.md:259`, and — negated — `deployment/collab/dialogue/0164-claude.md:100` ("τα αρχικά 20 gates της Επιλογής Α"). `git log --all -S"20 gates"` returns exactly a2f45f6d and 4ee2b58a.
* "Option-2 / OPTION-2": first appears at f04bf7e6 (2026-09-04 19:52:45 UTC) as part of the *title of the external Review #1 report*: `deployment/collab/dialogue/0161-claude.md:5` "INDEPENDENT CANONICAL-MODEL CORE REVIEW — OPTION-2 CORE @ 818b7dd9". It does not appear in 0160 or in a2f45f6d/818b7dd9. `git log --all -S"Option-2"` → 4ee2b58a only (hyphenated spelling in `AM/TCB-BASELINE-RECONCILIATION.md:280`); `--grep=Option-2` → f04bf7e6, af0eb3c9, a87bb6b7, 4ee2b58a.
* "option-1 / full-build closure" first appears at f04bf7e6: `0161-claude.md:13` (§1 "Τι δεν έγινε … option-1/full-build closure"), repeated `0162-claude.md:12`, `AM/REVIEW-2-CORRECTION-ADJUDICATION.md:13-14` ("Option-1 / full-build closure … remain blocked and untouched"), `STATE-OF-PLAY.md:908,959`.
* "Επιλογή Α" (Greek) and "OPTION-A" appear **only at 4ee2b58a** ([0164]): `0164-claude.md:10` ("Επιλογή Α και τα αρχικά 20 Full-Build gates"), `:51` ("21 OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES"), `:100`; `STATE-OF-PLAY.md:999,1019`; `AI-DIALOGUE.md:263`; `GATE:230-231`; `AM/ROOT-OPERATOR-DECISION-PACKET.md:157`; `AM/PACKET-TEMPLATE.md:66`; `AM/REVIEW-4-CORRECTION-ADJUDICATION.md:30`. `git log --all -S"Επιλογή Α"` → 4ee2b58a only.
* Therefore the naming pair is: **Option-1 = Option A = Επιλογή Α = "full-build closure" / "the original 20 Full-Build gates"** and **Option-2 = "core"** (the canonical-model core with 4 IMPORTED classes and DDI-1…4 deferred, per `0160-claude.md:8-12` "core-complete" scope). No document in the repo *defines* either option; both exist only as labels in scope-exclusion lists and verdict strings.

#### 1.2 Who authored the option list — UNKNOWN in-repo

The BRIEF states "the option list itself came from an EXTERNAL independent review report". The repo does **not** say this. What it says: the Review #1 report is an external read-only attachment, "ΟΧΙ artifact του repo: δεν αντιγράφηκε, δεν τροποποιήθηκε, δεν αναδημιουργήθηκε εδώ" (`0161-claude.md:7-9`), and its *title* already contains "OPTION-2 CORE" (`0161-claude.md:5`). Whether the reviewer or the creator enumerated Option 1/Option 2 is not recorded. Two hints point to the creator: (a) the Greek form "Επιλογή Α" occurs only in the creator-facing records [0164]/STATE-OF-PLAY; (b) `0164-claude.md:51-54` and `AM/REVIEW-4-CORRECTION-ADJUDICATION.md:30` say "the order anticipated 20" (creator's order), and the disambiguating sentence "NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES" was produced under that order. This is an ADJUDICATION ITEM (§6, A-5), not a finding.

#### 1.3 "Option A" namespace collisions (NOT the full-build option)

Three unrelated binary choices in the repo also use the label "Option A"; none is the full-build option:
1. `AM/TCB-DECISION.md:12,32,37,49,65,86` (added at af0eb3c9): "Option A — an external digest program, pinned as a model fact" vs Option B vendored SHA-256 (Review #2 N-1).
2. `deployment/collab/design/OMEGA2/TARGET-ARCH/WATCHTOWER-v0.7.1-PRE-FREEZE-EVIDENCE-CLOSURE.md:13,58` (c7c10502, 2026-08-30): "Model D proof-scope mismatch — CLOSED κατά Option A".
3. Commit message ffbcbe21 (2026-07-20, "[0094/Phase1] Η ΜΙΑ safe-read έδρα"), body line 15: "η μετανάστευση των 20 σημείων + η ασφαλής ανακατασκευή ικανοτήτων (BPE/trace = Option A)" — 20 read/eval/load call sites of Phase 1, "Option A" = a BPE/trace reconstruction choice. The coincidence of "20" + "Option A" here is lexical only (July, Lisp Phase 1, before the CHANGE-PROPOSAL track existed).


## 2. Gate-check lineage of `ARCHITECTURE-MODEL-GATE.sh` across the seven ARCHITECTURE-MODEL commits (computed from `git show`)


| commit | counted checks | informational | acceptance subsets | names (in script order) |
|---|---|---|---|---|
| `a2f45f6d` | 20 | 0 | 0 | `01-inventory-zero-unclassified`, `04-kernel-parses-and-passes`, `05-exact-hash-universe`, `02-no-duplicate-facts`, `03-conflicts-recorded`, `13-independent-agree`, `06-two-generations-identical`, `07-regen-empty-diff`, `08-manual-view-edit-detected`, `09a-kernel-sloc-budget`, `09b-kernel-no-regex`, `10-12-fixtures-and-properties`, `14-omission-detected`, `15-disagreement-blocks`, `16-decision-packet`, `17-no-exhaustive-human-review`, `18-legacy-nonauthoritative`, `19-deferred-ledger-exact-universe`, `20-deferred-in-model-universe`, `21-omission-gate-bites` |
| `818b7dd9` | 20 | 0 | 0 | `01-inventory-zero-unclassified`, `04-kernel-parses-and-passes`, `05-exact-hash-universe`, `02-no-duplicate-facts`, `03-conflicts-recorded`, `13-independent-agree`, `06-two-generations-identical`, `07-regen-empty-diff`, `08-manual-view-edit-detected`, `09a-kernel-sloc-budget`, `09b-kernel-no-regex`, `10-12-fixtures-and-properties`, `14-omission-detected`, `15-disagreement-blocks`, `16-decision-packet`, `17-no-exhaustive-human-review`, `18-legacy-nonauthoritative`, `19-deferred-ledger-exact-universe`, `20-deferred-in-model-universe`, `21-omission-gate-bites` |
| `f04bf7e6` | 20 | 2 | 0 | `gen-01-declared-order-runs`, `inv-01-inventory-equals-tracked-universe`, `inv-02-regeneration-leaves-no-drift`, `inv-03-two-generations-identical`, `inv-04-manual-view-edit-detected`, `krn-01-kernel-passes`, `krn-02-no-hash-universe-violation`, `krn-03-no-duplicate-seat-violation`, `krn-04-kernel-source-budget`, `chk-01-independent-path-passes`, `chk-02-fact-set-commitments-identical`, `chk-03-both-paths-consume-root-universe`, `hsh-01-two-vetted-engines-agree`, `fix-01-golden-and-property-fixtures`, `fls-01-held-out-falsifiers-rejected`, `led-01-deferred-ledger-exact-universe`, `led-02-ledger-inside-model-universe`, `doc-01-conflict-ledger-reconciled`, `doc-02-decision-packet-reconciled`, `doc-03-no-historical-code-on-live-path` |
| `af0eb3c9` | 19 | 5 | 0 | `tch-01-pinned-tools-are-the-tools-executed`, `gen-01-declared-order-is-total-and-acyclic`, `gen-02-artifacts-regenerate-byte-identical`, `inv-01-inventory-equals-candidate-universe`, `art-01-generated-artifact-universe-is-exact`, `sea-01-every-seat-resolves-or-declares-why`, `ver-01-both-paths-agree-on-one-fact-universe`, `ver-02-kernel-source-budget-400-lines`, `hsh-01-two-vetted-engines-agree-on-raw-bytes`, `cor-01-corpus-universe-is-exact`, `fix-01-golden-and-generated-fixtures`, `fls-00-battery-executed-is-the-candidates-battery`, `fls-01-component-falsifiers-all-rejected`, `led-01-deferred-ledger-exact-source-universe`, `doc-01-conflict-ledger-reconciled-both-ways`, `doc-02-decision-packet-reconciled-to-the-model`, `doc-03-governance-closure-declared-and-historic-free`, `ro-01-working-tree-byte-identical-after-the-run`, `ro-02-candidate-tree-unchanged-by-the-run` |
| `a87bb6b7` | 22 | 4 | 4 | `tch-01-pinned-tools-are-the-tools-executed`, `gen-01-declared-order-is-total-and-acyclic`, `gen-02-artifacts-regenerate-byte-identical`, `inv-01-inventory-equals-candidate-universe`, `art-01-generated-artifact-universe-is-exact`, `sea-01-every-seat-resolves-or-declares-why`, `ver-01-both-paths-agree-on-one-fact-universe`, `ver-02-kernel-source-budget-400-lines`, `tcb-01-acceptance-base-within-the-authored-cap`, `hsh-01-two-vetted-engines-agree-on-raw-bytes`, `prv-01-verifier-is-the-candidates-machinery`, `uni-01-no-declared-family-below-its-floor`, `enc-01-three-implementations-one-encoding`, `cor-01-corpus-universe-is-exact`, `fix-01-golden-and-generated-fixtures`, `fls-01-component-falsifiers-all-rejected`, `led-01-deferred-ledger-exact-source-universe`, `doc-01-conflict-ledger-reconciled-both-ways`, `doc-02-decision-packet-reconciled-to-the-model`, `doc-03-governance-closure-declared-and-historic-free`, `ro-01-repository-content-identical-after-the-run`, `ro-02-candidate-tree-unchanged-by-the-run` |
| `cc52a27d` | 22 | 4 | 4 | `tch-01-pinned-tools-are-the-tools-executed`, `gen-01-declared-order-is-total-and-acyclic`, `gen-02-artifacts-regenerate-byte-identical`, `inv-01-inventory-equals-candidate-universe`, `art-01-generated-artifact-universe-is-exact`, `sea-01-every-seat-resolves-or-declares-why`, `ver-01-both-paths-agree-on-one-fact-universe`, `ver-02-kernel-source-budget-400-lines`, `tcb-01-acceptance-base-within-the-authored-cap`, `hsh-01-two-vetted-engines-agree-on-raw-bytes`, `prv-01-verifier-is-the-candidates-machinery`, `uni-01-no-declared-family-below-its-floor`, `enc-01-three-implementations-one-encoding`, `cor-01-corpus-universe-is-exact`, `fix-01-golden-and-generated-fixtures`, `fls-01-component-falsifiers-all-rejected`, `led-01-deferred-ledger-exact-source-universe`, `doc-01-conflict-ledger-reconciled-both-ways`, `doc-02-decision-packet-reconciled-to-the-model`, `doc-03-governance-closure-declared-and-historic-free`, `ro-01-repository-content-identical-after-the-run`, `ro-02-candidate-tree-unchanged-by-the-run` |
| `4ee2b58a` | 21 | 3 | 4 | `tch-01-pinned-tools-are-the-tools-executed`, `gen-01-declared-order-is-total-and-acyclic`, `gen-02-artifacts-regenerate-byte-identical`, `inv-01-inventory-equals-candidate-universe`, `art-01-generated-artifact-universe-is-exact`, `sea-01-every-seat-resolves-or-declares-why`, `ver-01-both-paths-agree-on-one-fact-universe`, `ver-02-kernel-source-budget-400-lines`, `tcb-01-acceptance-base-measured-and-every-growth-attributed`, `hsh-01-two-vetted-engines-agree-on-raw-bytes`, `prv-01-verifier-is-the-candidates-machinery`, `uni-01-no-declared-family-below-its-floor`, `enc-01-three-implementations-one-encoding`, `cor-01-corpus-universe-is-exact`, `fix-01-golden-and-generated-fixtures`, `fls-01-component-falsifiers-all-rejected`, `led-01-deferred-ledger-exact-source-universe`, `doc-01-conflict-ledger-reconciled-both-ways`, `doc-02-decision-packet-reconciled-to-the-model`, `doc-03-governance-closure-declared-and-historic-free`, `ro-01-repository-content-identical-after-the-run` |

Canonical-path counts (what the command counts when judging a committed tree, i.e. the mode every review used): `a2f45f6d` 20 · `818b7dd9` 20 · `f04bf7e6` 20 (+2 informational) · `af0eb3c9` **18** (+4 informational; `fls-00` counts only for a tree-ish candidate and `ro-02` only for WORKTREE, so exactly one of them counts in any mode — [0162] line 40 records "18 μετρούμενοι έλεγχοι, 4 INFORMATIONAL") · `a87bb6b7` **21** (+4; `ro-02` is a `ck` only in WORKTREE mode, a `note` otherwise — [0163] line 104 "21 έλεγχοι") · `cc52a27d` 21 (+4) · `4ee2b58a` 21 (+3; `ro-02` removed by R4-7). Acceptance subsets are FOUR from `a87bb6b7` on (`provenance`, `model-checks`, `composed-gate-falsifiers` via `sub`, plus the inline `ACCEPT evidence` subset that the `sub` regex does not see). The raw regex extraction above over-counts the conditional checks by one at `af0eb3c9`, `a87bb6b7` and `cc52a27d`.


## 3. What the dialogue records and packets say about Option A and the 20 (archaeology §3)


| record | line(s) | statement |
|---|---|---|
| `0160-claude.md` | 4 | order title only: «FINAL VERIFIER-REGRESS EXIT PASS — CANONICAL ARCHITECTURE MODEL + SINGLE-OPERATOR ASSURANCE» (order body not in repo) |
| `0160-claude.md` | 8-12 | scope "core-complete"; every other fact class DEFERRED_DATA_IMPORT (DDI-1..4) — the "full build" complement is thereby the deferred data |
| `0160-claude.md` | 48-51 | "PASS (20/20 gates) … G19-G21 anti-omission" — the only positive statement of "20 gates" |
| `0161-claude.md` | 4-9 | order «OPTION-2 CORE INDEPENDENT-REVIEW REMEDIATION — F-1…F-13»; governing document = external report "INDEPENDENT CANONICAL-MODEL CORE REVIEW — OPTION-2 CORE @ 818b7dd9", verdict FAILED/CORRECTION REQUIRED (0 P0, 5 P1, 4 P2, 4 P3); "εξωτερικό read-only συνημμένο, ΟΧΙ artifact του repo" |
| `0161-claude.md` | 13 | out of scope: "DDI-1…DDI-4 · option-1/full-build closure · …" — first occurrence of option-1 |
| `0161-claude.md` | 31 | F-10 row: "ck01 δομικά ανίκανο να αποτύχει· ck03/16/17/18 grep-παρουσίας· ck09b στενή blacklist· ck07 scope hole" — Review #1 examined the a2f45f6d ck set by its 01..21 labels |
| `0161-claude.md` | 41-43 | "20 μετρούμενοι έλεγχοι … ότι το πλήθος έτυχε να είναι πάλι 20 είναι σύμπτωση, όχι διατηρημένος στόχος" |
| `0161-claude.md` | 45 | "32 held-out falsifiers (K01–K25 της εντολής + X26–X32)" — the creator's order contained a numbered K01–K25 list not in the repo (the K-ids survive only as falsifier names in `run_falsifiers.py`/`run_corpus.py`) |
| `0161-claude.md` | 72 | verdict "… DDI-1 BLOCKED — NOT FULL-BUILD COMPLETE — …" |
| `0162-claude.md` | 12 | "option-1 / full-build closure" out of scope; 40: "18 μετρούμενοι έλεγχοι, 4 INFORMATIONAL" |
| `AM/REVIEW-2-CORRECTION-ADJUDICATION.md` | 13-14 | "DDI-1…DDI-4, Option-1 / full-build closure, SPEC freeze, qualification, MISSION, WP-00, Implementation-Book regeneration and production implementation all remain blocked" |
| `0163-claude.md` | 104 | full ACCEPT "4/4 subsets, 21 έλεγχοι / 0 FAIL" |
| `0164-claude.md` | 10 | untouched: "DDI-1…DDI-4, Επιλογή Α και τα αρχικά 20 Full-Build gates, …" |
| `0164-claude.md` | 50-54 | R4-7: "21 OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES. Η εντολή του δημιουργού προέβλεπε «20» υποθέτοντας ότι το ro-02 μετριόταν στην canonical διαδρομή· δεν μετριόταν … οπότε η αφαίρεσή του αφήνει τους 21 που μέτρησε ο κριτής." — NB: the "20" the R4 order anticipated is the *Option-2 check count* (a wrong expectation), a different 20 from the Option-A gates |
| `0164-claude.md` | 100 | "Τα 21 counted checks ΔΕΝ είναι, δεν υποκαθιστούν και δεν εκτελούν τα αρχικά 20 gates της Επιλογής Α" |
| `AM/REVIEW-4-CORRECTION-ADJUDICATION.md` | 30 | R4-7 row: "… **21 OPTION-2 ACCEPTANCE CHECKS — NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES**, which remain a mandatory future stage after DDI-1…DDI-4. (The order anticipated 20 …)" |
| `AM/ROOT-OPERATOR-DECISION-PACKET.md` / `AM/PACKET-TEMPLATE.md` | 155-158 / 64-67 | same sentence; "Those original gates remain a mandatory future stage after DDI-1…DDI-4; nothing below completes, replaces or executes them" |
| `STATE-OF-PLAY.md` | 884, 911 | "NOT FULL-BUILD COMPLETE"; 999, 1019: "Επιλογή Α / αρχικά 20 Full-Build gates" |

Nowhere in these records is a single Option-A gate named. The label enters the repo already formed (f04bf7e6) and is only ever negated or excluded.


## 4. Candidate identifications, ranked (archaeology §4) and the twenty gate cards (matrix §2)


#### C1 (most probable referent of the NUMBER; contradicted as the referent of the FUTURE STAGE) — the 20 `ck` calls of `GATE` at 818b7dd9/a2f45f6d
*For:* (i) exactly 20, and the only "20 gates" the repository ever asserted (§1.1); (ii) 818b7dd9 is the exact tree that Review #1 judged under the title "OPTION-2 CORE @ 818b7dd9" (`0161-claude.md:5`), so the option vocabulary and this 20-gate script are contemporaneous; (iii) Review #1's F-10 attacked "the number 20" itself — commit f04bf7e6 message "The number 20 is not preserved as a target", `0161-claude.md:41-43`; (iv) the a2f45f6d scope is explicitly "core-complete" with everything else DDI (`0160-claude.md:8-12`), so "full build" naturally means "this core + DDI-1…4", and "all 20 gates" would then mean "the same 20 gates, passed over the full model".
*Against:* (i) `0164-claude.md:51`, `GATE:230-231`, `AM/ROOT-OPERATOR-DECISION-PACKET.md:157-158` describe the original 20 as "a mandatory future stage after DDI-1…DDI-4 … nothing here completes, replaces or executes them" — but the a2f45f6d 20 were executed and PASSed at a2f45f6d (`0160-claude.md:48`) and then dismantled by f04bf7e6 as unsound (ck01 "structurally unable to fail", ck03/16/17/18 "grep-presence", `0161-claude.md:31`), which is hard to reconcile with "future stage" unless the sentence means "re-executed over the full model"; (ii) the script's own numbering is G1…G21 (21 concepts, §2.1), so "20" is an implementation count, not a specification count; (iii) the label "Option-A" first appears only at 4ee2b58a, three commits after the a2f45f6d script was retired, with no back-reference to labels 01…21.

#### C2 — an external 21-item gate specification G1…G21 behind the [0160] order
*For:* the comment headers G1…G21 in the a2f45f6d blob (§2.1) and "G19-G21 anti-omission" (`0160-claude.md:50`; a2f45f6d message) prove a numbered gate list existed *before* the script (the merge of G10–G12 and split of G9 are implementation decisions against a prior numbering). If the creator's [0160] order enumerated "20 gates" and the implementer appended G21 (or the order listed G1…G21 and the option text rounded to the 20 `ck` calls), C1 and C2 are the same list under two counts.
*Against:* 21 ≠ 20; the order body is not in the repo (`0160-claude.md:4` records the title only); no other file lists G-names.

#### C3 — the 20 orchestrator plenary gates (`--*-gate` CLI commands) of 2026-07-07
*For:* an exact in-repo list of 20 gates exists: `999af09f:deployment/LAWMAX-REPO-ONTOLOGY-MAP.sexp:14` (`:gates 20`) with the 20 commands `--advisor-gate --architecture-constitution-gate --component-gate --contract-gate --deontic-gate --dialogue-gate --draft-gate --event-gate --extension-gate --fluid-gate --generation-gate --inference-gate --iq-gate --memory-gate --mirror-gate --policy-gate --provenance-gate --self-evolution-gate --subsumption-gate --understanding-gate` (`(:command "--…-gate" …)` lines 20-142 of that blob); `deployment/LAWMAX-REPO-ONTOLOGY-MAP.md:14` "| Πύλες | **20** |" and `deployment/LAWMAX-CONSOLIDATION-PLAN.md:9` "20 πύλες" still say 20 at HEAD; and "full build" in the older repo vocabulary is the owner's full Docker build (`STATE-OF-PLAY.md:107` "Owner-side full build = τελικό gate Phase 1"; commit b71b835c "full build closure").
*Against:* the plenary grew to 24 (49bc72bb, `deployment/verify/gate-registry.sexp` first version, 2026-07-21) and 25 (fd505275 "--capability-gate (25η πύλη)"; HEAD `gate-registry.sexp:20-44` lists 25; `systems/orchestrator-cli/*.lisp` register 25 distinct `--*-gate` strings), and [0115] already reports "ολομέλεια 25/25" (05eae8d6, 2026-07-22) — so by September the plenary had not been "20" for six weeks; the Option-A/Option-2 vocabulary lives exclusively in the ARCHITECTURE-MODEL track, where every exclusion list pairs "Επιλογή Α / 20 Full-Build gates" with DDI-1…4, Implementation Book, WP-00 (`0164-claude.md:10`, `STATE-OF-PLAY.md:1019`), never with the Lisp plenary; the ontology-map "20" is a stale July census (last commit touching it: 999af09f). Numeric coincidence.

#### C4 — other exactly-20 lists in the repo (screened; all rejected as gate lists)
* 20 BUILT seats: `AM/seats.sexp` `:status BUILT` ×20 (of 33); `0162-claude.md:45`. Seats, not gates.
* V1.8 candidate manifest: "20 rows, one (self) + 19 pinned artifacts" (`…/CHANGE-PROPOSAL/V1.8-CANDIDATE-MANIFEST.md:59`). Files, not gates.
* 20 Merkle mutation witnesses: commit 1e01eb41 [0118] "mutation witnesses 20/20 killed", `scripts/merkle-mutation-witness.sh`. July, Merkle track.
* "20 σημείων" of ffbcbe21 (Phase-1 read/eval/load sites) — §1.3.
* Screened and ≠ 20: composed-gate falsifiers G01…G11 (11; `AM/verification-corpus.sexp`), V1.8 guards (11; `V1.8-VERIFY.py`), T8 tests (18), DFT+RA8 requirements (18), RA-GATE-* (13; `V1.7-ROOT-AUTHORITY-ACCEPTANCE-MATRIX.md:14-26`), WPs (15), subsystems (26), Θ threats (21), KW ids (109), Q ids (47), SIK (9), ST (28), universe-floors (6), property families (5), golden fixtures (8), audit checks v1.4/1.5/1.6/1.7/1.8 = 158/75/56/49/47 (commit 4787b342 message), model `test` facts (21), `requirement` facts (24). None is a 20-gate list.

#### C5 — "Option A" collisions (§1.3): not candidates.


### 4.6 Classification rules used for the survival equation (matrix §1)


- **PRESERVED**: a counted check at 4ee2b58a computes the same thing from the same input class with the same
  threshold/needle, standing alone (not folded into another check).
- **LEGITIMATELY GENERALIZED (= SUPERSEDED_WITH_PROOF)**: the property is protected at 4ee2b58a by a counted check
  (or a kernel law + fixture/property-family + held-out falsifier under a counted check) that is STRICTLY stronger
  or broader, AND a named review finding (F-n / N-n / R3-n / R4-n) retired the old form. Both citations are given.
- **MISSING**: no counted check at 4ee2b58a protects the property; an `INFORMATIONAL_PRESENCE_CHECK` note is NOT a
  check by the repository's own rule (`4ee2b58a:GATE:26-28`: "A check that cannot fail is not a check … EXCLUDED
  from the count"). So a gate DEMOTED to informational is placed in MISSING **as a counted gate**, with its note
  named; the alternative reading is stated in §3.
- Each of the 20 is in exactly one set. Sub-labels (e.g. "PRESERVED (strengthened)") do not create new sets.

---


### 4.7 The twenty gates, one card each (matrix §2). **Scope note (S-1): every `ST` below is the status of the concept over the CORE model at `4ee2b58a`; `DDI` names the batches after which the concept must be re-demanded over the full model.**


Field legend: **W** original wording (quoted) · **S** source · **P** property · **I** required inputs ·
**O** required outputs/evidence · **DDI** which batches must be complete for the gate to be meaningful over the
FULL model (batch definitions: `4ee2b58a:AM/build_deferred.py:86-104`) · **NOW** artifact at 4ee2b58a ·
**ST** status · **AC** executable acceptance criterion · **F** falsifier · **L** lineage (name at each commit; the
extracted names are in `WORK/gate-lineage.md`) · **SET** equation set.

#### G01 — `01-inventory-zero-unclassified`
- **W** `a2f45f6d:GATE:11-13`:
  `# G1 file-role inventory zero unclassified` /
  `u=$(python3 build_inventory.py | grep -oE 'unclassified=[0-9]+' | cut -d= -f2); python3 build_inventory.py >/dev/null; git checkout -- files-and-roles.sexp 2>/dev/null || true` /
  `ck 01-inventory-zero-unclassified "$u" 0`
- **S** `a2f45f6d:GATE:13`
- **P** every tracked path is classified exactly once; none unclassified.
- **I** `git ls-files` universe; `build_inventory.py` classifier; committed `files-and-roles.sexp`.
- **O** `unclassified=0`; (implicitly) inventory == committed module.
- **DDI** none for meaning (inventory is over paths, not facts). Note: the ledger's source universe is now DERIVED
  from this inventory (`4ee2b58a:AM/build_deferred.py:38-70`), so G19/G21 inherit G01's correctness.
- **NOW** `inv-01-inventory-equals-candidate-universe` (`4ee2b58a:GATE:172` → `GC:1377-1460`): key set both ways
  (`GC:1399-1400`), quarantine roles named and fatal (`GC:1407-1409`; `4ee2b58a:AM/classification-rules.sexp:7`
  "There is no catch-all", `:45` R-009Q REVIEW_REQUIRED), every named row re-derived (`GC:1416-1425`), DEAD RULE
  (`GC:1431-1434`), multiset total (`GC:1450-1452`), C-quoted key (`GC:1453-1454`). Judged over an immutable
  candidate tree, never restored (`GC:9-17`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding check: `inv-01` (`GC:1377`). Retiring findings: F-1/F-2/F-3 and F-10
  ("ck01 δομικά ανίκανο να αποτύχει", `D0161:22-24,31`; commit f04bf7e6 "G1 regenerates into a temporary file,
  byte-compares … `git checkout` no longer appears in the gate"); N-15 (`R2:94`); N-18 (`R2:102-105`); the old
  `role()` catch-all is at `a2f45f6d:AM/build_inventory.py:56` ("unmatched tracked file … OUT_OF_SCOPE_WITH_REASON"),
  which is why `unclassified` (`:62-68`) could never be non-empty.
- **AC** `gate_checks.py inventory --tree <T> --base <B>` exits 0 and prints `GATECHECK inventory: PASS`; any of
  `EXTRA-INVENTORY-PATH | UNCLASSIFIED | REVIEW_REQUIRED | INVENTORY-CLASSIFICATION-DRIFT | DEAD RULE |
  DIRECTORY-RULE-MISCOUNT | MULTISET-MISMATCH | C-QUOTED-INVENTORY-KEY` ⇒ exit 1.
- **F** K01/K02/K03/K04/K05/K06/K07 (`VC:132-142`), X26/X58 dead rule (`VC:171,254-258`); coded at `RC:654-698,899`.
- **L** a2f45f6d/818b7dd9 `01-inventory-zero-unclassified` → f04bf7e6 `inv-01-inventory-equals-tracked-universe`
  (`f04bf7e6:GATE:31`) → af0eb3c9 `inv-01-inventory-equals-candidate-universe` (`af0eb3c9:GATE:70`) → a87bb6b7 `:152`
  → cc52a27d (identical script) → 4ee2b58a `:172`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G02 — `02-no-duplicate-facts`
- **W** `a2f45f6d:GATE:20-21`: `# G2 no duplicate facts (L2) + ledger present` / `ck 02-no-duplicate-facts "$(grep -c 'VIOLATION L2' /tmp/k.out)" 0`
- **S** `a2f45f6d:GATE:21`
- **P** L2 one seat: no duplicate (type,id), no id under two types (`a2f45f6d:K:51,54,60`).
- **I** kernel output over `ROOT.sexp`.
- **O** zero `VIOLATION L2` lines.
- **DDI** all four: every imported class adds ids to the uniqueness universe; DDI-1 seats (`define-capability-seat`,
  `define-canonical-identity`) collide by construction with `seats.sexp` ids unless one seat is chosen
  (33 seats, `4ee2b58a:AM/seats.sexp`); DDI-4 `define-wp-purpose` would give `wp` a second origin
  (`WORK/orchestrator-notes.md` N2).
- **NOW** kernel L2 (`K:124,126,133`, `law2-unique` `K:190-197`) + checker L2 (`IC:24,174`) under
  `ver-01-both-paths-agree-on-one-fact-universe` (`4ee2b58a:GATE:177` → `GC:975-999`: KERNEL-VERDICT `979-981`);
  schema uniqueness laws `4ee2b58a:AM/MODEL-SCHEMA.sexp:308,319-322`; fixture `FX-L2-DUPLICATE-STORE` (`VC:28-29`);
  property family `PF-L2-DUPLICATE-STORE` cardinality 10 (`VC:48-50`) run through BOTH paths (`RC:602-622`).
- **ST** SUPERSEDED_WITH_PROOF (folded). Superseding: `ver-01` + L2 + `fix-01`. Retiring: F-4 (`D0161:25`: checker
  refuses a verdict unless commitments are byte-identical) and F-8 (duplicate rows, `D0161:29`); N-5 (`R2:57-62`);
  R3-12 seat-path uniqueness (`R3:33`); the grep-count form disappeared at af0eb3c9 (was `krn-03` at `f04bf7e6:GATE:52`).
- **AC** `gate_checks.py commitments` exits 0 with kernel `ARCHITECTURE MODEL LAWS: PASS` AND checker
  `INDEPENDENT ARCHITECTURE INVARIANTS: PASS` AND byte-identical commitments; `fix-01` exit 0 with the L2 family at
  exactly 10 cases.
- **F** `FX-L2-DUPLICATE-STORE`, `PF-L2-DUPLICATE-STORE`, X43 rival store writer (`VC:214-216`), X57 duplicate rule
  (`VC:249-253`), K05 duplicate inventory key.
- **L** a2f45f6d `02-no-duplicate-facts` → f04bf7e6 `krn-03-no-duplicate-seat-violation` (`f04bf7e6:GATE:52`) →
  af0eb3c9 folded into `ver-01` (`af0eb3c9:GATE:75`) → a87bb6b7 `:157` → cc52a27d → 4ee2b58a `:177`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G03 — `03-conflicts-recorded`
- **W** `a2f45f6d:GATE:22`: `ck 03-conflicts-recorded "$([ -f MODEL-MIGRATION-CONFLICT-LEDGER.md ] && grep -cq '| 1 |' MODEL-MIGRATION-CONFLICT-LEDGER.md && echo 1 || echo 0)" 1` (header comment shared with G2 at `:20`, "+ ledger present")
- **S** `a2f45f6d:GATE:22`
- **P** every migration normalization is recorded (no silent normalization).
- **I** `MODEL-MIGRATION-CONFLICT-LEDGER.md`.
- **O** file exists and contains a row numbered 1 (presence only).
- **DDI** every batch: the ledger's kinds are CLOSED (`GC:874-902`: DATAFLOW-CYCLE, COMPOSITE-WP,
  NON-SUBSYSTEM-CONSUMER; anything else is `LEDGER-ROW-UNKNOWN-KIND`). DDI-2/DDI-3 nested-list flattening
  (`4ee2b58a:AM/MODEL-SCHEMA.sexp:5-6`; `WORK/orchestrator-notes.md` N4) is a new normalization class that
  `doc-01` cannot yet reconcile — the check must be extended per batch or it will reject the ledger.
- **NOW** `doc-01-conflict-ledger-reconciled-both-ways` (`4ee2b58a:GATE:211` → `GC:856-918`): every row checked
  against the model (`LEDGER-ROW-NOT-IN-MODEL`) and every model normalization required to have a row
  (`UNRECORDED-NORMALIZATION`, `GC:903-913`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `doc-01`. Retiring: F-10 ("ck03/16/17/18 grep-παρουσίας",
  `D0161:31`; commit f04bf7e6 "Gate honesty (F-10)"); strengthened "both ways" at af0eb3c9 (N-14, `R2:93`).
  Note: the literal old check would still pass at HEAD (`4ee2b58a:AM/MODEL-MIGRATION-CONFLICT-LEDGER.md` has one
  `| 1 |` row) — it was retired for being unfalsifiable, not for failing.
- **AC** `gate_checks.py conflict-ledger` exit 0 / `GATECHECK conflict-ledger: PASS`.
- **F** X30-UNRECORDED-NORMALIZATION (`VC:182`; `RC:924`).
- **L** a2f45f6d `03-conflicts-recorded` → f04bf7e6 `doc-01-conflict-ledger-reconciled` (`f04bf7e6:GATE:80`) →
  af0eb3c9 `doc-01-conflict-ledger-reconciled-both-ways` (`af0eb3c9:GATE:114`) → a87bb6b7 `:191` → cc52a27d →
  4ee2b58a `:211`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G04 — `04-kernel-parses-and-passes`
- **W** `a2f45f6d:GATE:15-17`: `# G4 model parses/composes + kernel PASS` / `sbcl --script KERNEL/model-law-kernel.lisp ROOT.sexp >/tmp/k.out 2>&1; kec=$?` / `ck 04-kernel-parses-and-passes "$([ $kec -eq 0 ] && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:17`
- **P** the whole model parses, composes from ROOT, and satisfies L1–L7 on the SBCL path.
- **I** `ROOT.sexp` + pinned modules; SBCL.
- **O** exit 0 and `ARCHITECTURE MODEL LAWS: PASS`.
- **DDI** all four (it is the verdict over whatever facts exist). Before DDI-2/DDI-3 can import, L1's value grammar
  (`4ee2b58a:AM/MODEL-SCHEMA.sexp:5-6`: string | integer | plain symbol; no nested lists) must be extended or the
  forms flattened — otherwise the kernel cannot even read the imported classes (`K:39-48,141`).
- **NOW** `ver-01` (`GC:975-999`, KERNEL-VERDICT `979-981`) executed over the exported candidate with the PINNED
  interpreter (`GC:961-963`, `tool_path('KERNEL_RUNTIME')`), plus `tch-01` before any verdict (`4ee2b58a:GATE:164-165`).
- **ST** SUPERSEDED_WITH_PROOF (folded). Superseding: `ver-01`. Retiring: F-4 (`D0161:25`), N-9 ROOT discipline
  (`R2:88`), N-17 typed missing-module results (`R2:96`), R3-3 pinned interpreter (`R3:24`), R3-13 readtable
  closure (`R3:34`; `K:56-60`). Was `krn-01-kernel-passes` at `f04bf7e6:GATE:50`.
- **AC** `gate_checks.py commitments`: kernel exit 0 AND needle `ARCHITECTURE MODEL LAWS: PASS` (`GC:979`).
- **F** `FX-L1-UNDECLARED-TYPE` (`VC:26-27`), K22/K23/X27/X33-X39/X45 (`VC:163-202,218-220`), K25 provider
  unavailable (`VC:170`; `RC:882`).
- **L** a2f45f6d `04-kernel-parses-and-passes` → f04bf7e6 `krn-01-kernel-passes` → af0eb3c9 `ver-01` → a87bb6b7 →
  cc52a27d → 4ee2b58a `:177`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G05 — `05-exact-hash-universe`
- **W** `a2f45f6d:GATE:18-19`: `# G5 exact module/hash universe = kernel L7 (no L7 violation in a passing run)` / `ck 05-exact-hash-universe "$(grep -c 'VIOLATION L7' /tmp/k.out)" 0`
- **S** `a2f45f6d:GATE:19`
- **P** L7: exactly the pinned modules exist, each with its pinned SHA-256; no extra module.
- **I** kernel output.
- **O** zero `VIOLATION L7`.
- **DDI** any batch that adds a module (UNKNOWN which will; `ROOT.sexp` currently pins 14, `4ee2b58a:AM/ROOT.sexp:12`).
  Meaning is stable; universe grows.
- **NOW** kernel L7 now also recomputes the root digest (`K:269-313`, digest `:313`), requires exactly one
  `define-model-root` (`:276`), duplicate keys (`:283`), schema-version binding (`:287`), module-count (`:311`);
  checker L7 independently (`IC:18-21`); both under `ver-01`. Fixture `FX-L7-MODULE-HASH-DRIFT` (`VC:38-39`).
- **ST** SUPERSEDED_WITH_PROOF (folded). Superseding: `ver-01` + L7 on both paths. Retiring: F-6 ("root digest
  διαβαζόταν, δεν επανυπολογιζόταν", `D0161:27`), N-9 (`R2:88`), N-16 (`R2:95`). Was `krn-02-no-hash-universe-violation`
  at `f04bf7e6:GATE:51`.
- **AC** kernel PASS and checker PASS with identical commitments (`GC:979-992`); `hsh-01` exit 0 for the raw-bytes
  engines (`GC:1324-1373`).
- **F** K10 new pinned module, K16 root digest alone, X32 module count, X37/X38/X39 ROOT discipline (`VC:145,158,184,192-202`);
  coded `RC:736,776,963`.
- **L** a2f45f6d `05-exact-hash-universe` → f04bf7e6 `krn-02-no-hash-universe-violation` → af0eb3c9 `ver-01` →
  a87bb6b7 → cc52a27d → 4ee2b58a `:177`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G06 — `06-two-generations-identical`
- **W** `a2f45f6d:GATE:30-35`: `# G6 two clean generations byte-identical (generator + ROOT)` / (two runs of `generate_views.py` + `build_root.py`, `diff -rq /tmp/g1 GENERATED && diff -q /tmp/r1 ROOT.sexp`) / `ck 06-two-generations-identical "$g6" 1`
- **S** `a2f45f6d:GATE:35`
- **P** generation is deterministic.
- **I** generator + root builder run twice in the working tree.
- **O** byte-identical `GENERATED/` and `ROOT.sexp`.
- **DDI** none for meaning; every batch adds artifacts only if `generation-order.sexp` declares them
  (`4ee2b58a:AM/generation-order.sexp:38-61`).
- **NOW** `gen-02-artifacts-regenerate-byte-identical` (`4ee2b58a:GATE:169` → `GC:425-456`): the declared order is
  run in a PRIVATE copy and every declared artifact byte-compared to the candidate's blob (`ARTIFACT-DRIFT`,
  `GC:450-452`). Determinism is implied: candidate blob == fresh generation, for every check run.
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `gen-02`. Retiring: N-2 (`R2:31-41`; `4ee2b58a:GATE:18-24`), N-3
  (`R2:43-48`), N-12 fixed `/tmp` (`R2:91`). Was `inv-03-two-generations-identical` at `f04bf7e6:GATE:41`.
- **AC** `gate_checks.py generation --work <W>` exit 0; `ARTIFACT-NOT-PRODUCED | ARTIFACT-ABSENT-FROM-CANDIDATE |
  ARTIFACT-DRIFT` ⇒ exit 1.
- **F** G02-PRE-EXISTING-DRIFT-ERASED (composed, `VC:223`; `RC:1123-1132` targets `gen-02`), G03/G04 (`VC:224-225`).
- **L** a2f45f6d `06-two-generations-identical` → f04bf7e6 `inv-03-two-generations-identical` → af0eb3c9 `gen-02-artifacts-regenerate-byte-identical` (`af0eb3c9:GATE:67`) → a87bb6b7 `:149` → cc52a27d → 4ee2b58a `:169`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G07 — `07-regen-empty-diff`
- **W** `a2f45f6d:GATE:36-41`: `# G7 clean regeneration leaves the working tree byte-identical to the canonical index/HEAD content.` … `ck 07-regen-empty-diff "$(git status --porcelain GENERATED ROOT.sexp 2>/dev/null | grep -E '^.[^ ?]' | wc -l | tr -d ' ')" 0`
- **S** `a2f45f6d:GATE:41`
- **P** committed derived artifacts equal a clean regeneration (no drift).
- **I** working tree after regeneration; `git status --porcelain` over `GENERATED ROOT.sexp` only.
- **O** zero worktree-dirty lines.
- **DDI** none.
- **NOW** `gen-02` (same seat as G06, but compared against the immutable candidate blob instead of a porcelain
  column; `GC:9-17`), plus the `candidate` step reporting working-tree difference without altering it
  (`GC:258-296`), plus `ro-01-repository-content-identical-after-the-run` (`4ee2b58a:GATE:219-221`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `gen-02` (+ `ro-01`). Retiring: F-10 "ck07 scope hole" (`D0161:31`)
  and N-2/N-14 "porcelain-column regex could not see the index" (`4ee2b58a:GATE:21`; `R2:93`). Was
  `inv-02-regeneration-leaves-no-drift` (still porcelain) at `f04bf7e6:GATE:34-35`.
- **AC** as G06; additionally `ro-01` exit 0 (`WT_BEFORE == WT_AFTER`, content-sensitive: `AM/acceptance_runtime.py:191`).
- **F** G02 (drift must be NAMED, not erased), G01 (gate writes to tree → `ro-01`, `RC:1108-1120`).
- **L** a2f45f6d `07-regen-empty-diff` → f04bf7e6 `inv-02-regeneration-leaves-no-drift` → af0eb3c9 `gen-02` (+`ro-01`) → a87bb6b7 → cc52a27d → 4ee2b58a. **Survived (generalized).**
- **SET** GENERALIZED.

#### G08 — `08-manual-view-edit-detected`
- **W** `a2f45f6d:GATE:42-46`: `# G8 manual generated-view edit detected` / `cp GENERATED/OWNERSHIP-MATRIX.md /tmp/ov.bak; echo "MANUAL TAMPER" >> GENERATED/OWNERSHIP-MATRIX.md` / `python3 generate_views.py >/dev/null` / `if diff -q /tmp/ov.bak GENERATED/OWNERSHIP-MATRIX.md …; then g8=1 …  # regen restores canonical -> tamper gone -> detected` / `ck 08-manual-view-edit-detected "$g8" 1; rm -f /tmp/ov.bak`
- **S** `a2f45f6d:GATE:46`
- **P** a hand edit of a generated view cannot survive/hide.
- **I** tamper in place in the working tree + regeneration.
- **O** regeneration restores the canonical bytes.
- **DDI** none.
- **NOW** the property is inverted into a judgement over the candidate: `gen-02` NAMES a tampered artifact as
  `ARTIFACT-DRIFT` (`GC:450-452`); the exact original mutation ("MANUAL TAMPER" appended to `OWNERSHIP-MATRIX.md`) is
  the held-out composed falsifier G02 (`VC:223`; `RC:1123-1132`) and, unregistered, `RC:811-834` (see §5 A-4).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `gen-02` + G02 under the composed battery (acceptance subset
  `composed-gate-falsifiers`, `4ee2b58a:GATE:139-142`). Retiring: N-2 ("the judge rewrote the evidence", `R2:31-41`),
  N-12 (`R2:91`), N-14 residual row "`led-02`, `inv-04` … both are gone" (`R2:129`), `4ee2b58a:GATE:22-23`
  ("deliberately tampered with a tracked view in the working tree … an interrupted run left the repository damaged").
  Was `inv-04-manual-view-edit-detected` at `f04bf7e6:GATE:42-46` (still tamper-in-place), retired at af0eb3c9.
- **AC** composed battery: `run_corpus.py --kind composed --base <B>` exits 0 with `not-rejected=0` and `CONTROL HOLDS`
  (`4ee2b58a:GATE:142,147`); G02 must make the inner gate fail through `gen-02` with reason `ARTIFACT-DRIFT`
  (`RC:1067-1075`).
- **F** G02 itself; if `gen-02` were neutered, G02 reports NOT REJECTED ⇒ subset FAIL.
- **L** a2f45f6d `08-manual-view-edit-detected` → f04bf7e6 `inv-04-manual-view-edit-detected` → af0eb3c9 retired from
  the counted set; property carried by `gen-02` + composed G02 (`af0eb3c9:AM/run_gate_falsifiers.py:295`) → a87bb6b7
  (`run_corpus.py` COMPOSED) → cc52a27d → 4ee2b58a `RC:1372`. **Survived (generalized into a held-out falsifier).**
- **SET** GENERALIZED.

#### G09a — `09a-kernel-sloc-budget`
- **W** `a2f45f6d:GATE:48-50`: `# G9 kernel budget + no regex/grep-as-proof` / `sloc=$(grep -vE '^[[:space:]]*;|^[[:space:]]*$' KERNEL/model-law-kernel.lisp KERNEL/sha256.lisp | wc -l | tr -d ' ')` / `ck 09a-kernel-sloc-budget "$([ "$sloc" -le 400 ] && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:50`
- **P** the Lisp verification path stays small (≤ 400 non-blank non-comment lines).
- **I** kernel sources.
- **O** count ≤ 400.
- **DDI** none for meaning; DDI-2/DDI-3 may force schema growth (nested values) and thus kernel growth — at 4ee2b58a
  the path is at 400/400 (`4ee2b58a:AM/files-and-roles.sexp:1090-1091`: 67 + 333; `D0162:51`), so ANY kernel growth for
  DDI trips this gate. That is a real DDI entry criterion.
- **NOW** `ver-02-kernel-source-budget-400-lines` (`4ee2b58a:GATE:178-179`): identical grep formula and threshold;
  second file is `hash-provider.lisp` (sha256.lisp deleted by F-11, `D0161:32`).
- **ST** EXISTS (PRESERVED).
- **AC** `grep -vE '^[[:space:]]*;|^[[:space:]]*$' KERNEL/model-law-kernel.lisp KERNEL/hash-provider.lisp | wc -l` ≤ 400.
- **F** add one non-comment line to either file ⇒ 401 ⇒ FAIL (no held-out corpus row exercises it; `tcb-01` measures the
  same files and would name the growth, `GC:1501-1508`).
- **L** a2f45f6d `09a-kernel-sloc-budget` → f04bf7e6 `krn-04-kernel-source-budget` (`f04bf7e6:GATE:53-54`) → af0eb3c9
  `ver-02-kernel-source-budget-400-lines` (`af0eb3c9:GATE:76-77`) → a87bb6b7 `:158-159` → cc52a27d → 4ee2b58a `:178-179`. **Survived (preserved).**
- **SET** PRESERVED.

#### G09b — `09b-kernel-no-regex`
- **W** `a2f45f6d:GATE:51`: `ck 09b-kernel-no-regex "$(grep -vE '^[[:space:]]*;' KERNEL/model-law-kernel.lisp KERNEL/sha256.lisp | grep -ciE 'ppcre|run-program|sb-ext:run|\(search |cl-ppcre|shell-out')" 0`
- **S** `a2f45f6d:GATE:51`
- **P** the kernel uses no regex / substring search / shell-out as structural proof.
- **I** kernel sources.
- **O** zero blacklist hits.
- **DDI** none.
- **NOW** NOT COUNTED. `note krn-lexical-scan` (`4ee2b58a:GATE:224-225`) with a NARROWED blacklist `ppcre|shell-out`.
  The original blacklist would now report 1 hit: `sb-ext:run-program` at `4ee2b58a:AM/KERNEL/hash-provider.lisp:54`,
  which is the DELIBERATE design of TCB-DECISION Option A (`4ee2b58a:AM/TCB-DECISION.md:12-16,86`; N-1 `R2:21-29`).
  Structural substitutes for PART of the property: reader-macro closure `K:56-60` (R3-13), value grammar
  `K:30-37,102`, budget `ver-02`; but nothing counted forbids substring search or a second shell-out.
- **ST** MISSING as a counted gate (DEMOTED to `INFORMATIONAL_PRESENCE_CHECK`). Demoting findings: F-10 "ck09b
  στενή blacklist" (`D0161:31`), N-14 (`R2:93`), `R2:181` ("The lexical scan of the kernel sources cannot prove absence
  and is reported as informational, not counted"); the property itself was narrowed by N-1/TCB-DECISION.
- **AC** (would be) an executable rule that names the ONE permitted external call (the pinned `DIGEST_PROVIDER`) and
  rejects every other `run-program`/`search`/regex form in the kernel by AST, not by grep. NONE at 4ee2b58a.
- **F** none held out. A held-out kernel edit adding `(search …)` as a law implementation would be reported as
  `found 0` by the note (blacklist no longer contains `(search`) and counted nowhere.
- **L** a2f45f6d `09b-kernel-no-regex` → f04bf7e6 `note krn-lexical-scan` (`f04bf7e6:GATE:85-86`, blacklist
  `ppcre|run-program|sb-ext:run|shell-out`) → af0eb3c9 note (`af0eb3c9:GATE:131-132`, blacklist `ppcre|shell-out`) →
  a87bb6b7 `:208-209` → cc52a27d → 4ee2b58a `:224-225`. **Lost as a gate at f04bf7e6; note survives.**
- **SET** MISSING (demoted). Alternative reading in §3.

#### G10-12 — `10-12-fixtures-and-properties`
- **W** `a2f45f6d:GATE:53-55`: `# G10-G12 golden PASS/FAIL fixtures + property families` / `python3 run_fixtures.py >/tmp/fx.out 2>&1; fxc=$?` / `ck 10-12-fixtures-and-properties "$([ $fxc -eq 0 ] && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:55`
- **P** golden PASS/FAIL fixtures (one per law) pass/fail for their exact reason; generated property families are
  rejected; kernel/clingo agree on shared laws (`a2f45f6d:AM/run_fixtures.py:2-5`).
- **I** `FIXTURES/PASS|FAIL/*.sexp` (8), generated families (22: L6 `subs[:6]`, L5 privates, L3 ghosts ×3, L2
  `stores[:4]`, L4 ×3 — `a2f45f6d:AM/run_fixtures.py:69-87`).
- **O** `golden fixtures=8 generated properties=22 failures=0`, exit 0.
- **DDI** every batch: property families are declared with EXACT cardinality (`VC:42-56`: 26 subsystems, 6 private
  types, 10 stores, 33 seats, 8 stage-edges) — a batch that adds a subsystem/type/store/seat changes the exact number
  and `cor-01`/`fix-01` must be re-authored (the floors in `VC:60-71` are minimums and do not block growth, but the
  cardinalities are equalities, `RC:625-651`).
- **NOW** `fix-01-golden-and-generated-fixtures` (`4ee2b58a:GATE:194-196` → `RC --kind fixtures`): every fixture and
  every generated case through BOTH paths with law AND reason (`RC:602-622`); universe declared as facts
  (`VC:24-56`) and checked exactly by `cor-01` (`4ee2b58a:GATE:193` → `GC:554-614`), floored by `uni-01`
  (`GC:697-782`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `fix-01` + `cor-01` + `uni-01`. Retiring: N-4 ("το corpus πιστοποιούσε
  τον εαυτό του", `R2:50-55`), N-5 (`R2:57-62`), N-19 (`R2:106-108`; undeclared `[:6]`/`[:4]` caps gone), R3-7
  (`R3:28`), R4-1 (`R4:23`). The original ran only L3/L4/L5 through clingo (`a2f45f6d:AM/run_fixtures.py:65`).
- **AC** `run_corpus.py --kind fixtures --base <B>` exit 0 AND `gate_checks.py corpus` exit 0 AND
  `gate_checks.py universe` exit 0.
- **F** G05-CORPUS-SHRUNK (`VC:226`), K08/K09 multi-line (`VC:143-144`), X61–X70 (`VC:275-337`), G09/G10 (`VC:385-395`).
- **L** a2f45f6d `10-12-fixtures-and-properties` → f04bf7e6 `fix-01-golden-and-property-fixtures` (`f04bf7e6:GATE:68`) →
  af0eb3c9 `fix-01-golden-and-generated-fixtures` + `cor-01` (`af0eb3c9:GATE:84-87`) → a87bb6b7 `:173-176` (+`uni-01` `:169`) →
  cc52a27d → 4ee2b58a `:193-196`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G13 — `13-independent-agree`
- **W** `a2f45f6d:GATE:24-28`: `# G13 independent checker PASS + agreement` / `python3 CHECKER/independent_check.py ROOT.sexp >/tmp/c.out …` / `kv=$(grep -q 'ARCHITECTURE MODEL LAWS: PASS' /tmp/k.out && echo PASS || echo FAIL)` / `cv=$(grep -q 'INDEPENDENT ARCHITECTURE INVARIANTS: PASS' /tmp/c.out && echo PASS || echo FAIL)` / `ck 13-independent-agree "$([ "$kv" = "$cv" ] && [ "$kv" = PASS ] && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:28`
- **P** an independent second path (clingo, own parser) reaches PASS and agrees with the kernel.
- **I** kernel and checker outputs.
- **O** both PASS strings.
- **DDI** all four (the checker must read every imported class; at a2f45f6d it read a hard-coded 6-module list,
  `a2f45f6d:AM/CHECKER/independent_check.py:15-16`, and only L3/L4/L5, `:2-7`).
- **NOW** `ver-01-both-paths-agree-on-one-fact-universe` (`4ee2b58a:GATE:177` → `GC:975-999`): both verdicts AND
  byte-identical fact-set commitments (`COMMITMENT-MISMATCH`, `GC:991-992`); the checker REFUSES a verdict without the
  kernel's commitment (`IC:25-26`; K21 `RC:849-858`); checker now derives L1–L7 (`IC:503-535,617-623`); `enc-01`
  adds a third implementation (`GC:1002-1049`); `prv-01` binds the executing machinery (`GC:641-694`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `ver-01` (+`enc-01`, `prv-01`). Retiring: F-4 (`D0161:25`: "ο checker
  ΑΡΝΕΙΤΑΙ ετυμηγορία αν δεν ταυτίζεται byte-προς-byte"), R3-1 (`R3:22`), R3-2 (`R3:23`). Was three checks at
  f04bf7e6 (`chk-01/02/03`, `f04bf7e6:GATE:58-60`).
- **AC** `gate_checks.py commitments` exit 0 (`GATECHECK commitments: PASS`).
- **F** K11 fact-count mismatch, K12 family-digest mismatch, K21 self-certified pass (`VC:146-147,162`; `RC:761,766,849`).
- **L** a2f45f6d `13-independent-agree` → f04bf7e6 `chk-01-independent-path-passes` + `chk-02-fact-set-commitments-identical` + `chk-03-both-paths-consume-root-universe` → af0eb3c9 `ver-01` (`af0eb3c9:GATE:75`) → a87bb6b7 `:157` → cc52a27d → 4ee2b58a `:177`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G14 — `14-omission-detected`
- **W** `a2f45f6d:GATE:57-72`: `# G14 corrupt neutral export / omit fact detected: (a) omit a fact -> kernel FAILs; (b) export regen restores` / (temp copy; drop every line starting `(fact req-map S03__`; rehash ROOT; run kernel) / `ck 14-omission-detected "$([ $omitec -ne 0 ] && echo 1 || echo 0)" 1; rm -rf "$d"`
- **S** `a2f45f6d:GATE:72`
- **P** an omitted fact (L6 mapping of S03) is detected by the kernel even after a consistent rehash.
- **I** temp copy of all modules; python rehash; kernel.
- **O** kernel non-zero exit.
- **DDI** DDI-1 at minimum: L6's requirement/test universe is DERIVED from `define-subsystem`
  (`4ee2b58a:AM/build_model.py:37,160-165`); the V1.8 DDI-1 seat classes reference RA-*/RA8-*/T8-* ids that are not
  model facts (`WORK/orchestrator-notes.md` N1) — over the full model L6 must include them or the gate is meaningful
  only over the core.
- **NOW** property family `PF-L6-UNMAPPED-SUBSYSTEM`, cardinality 26 (every subsystem, ALL its req-maps removed —
  `VC:42-44`; `RC:630-634`), exact law + reason on both paths (`RC:602-620`), under `fix-01`; fixture
  `FX-L6-SUBSYSTEM-NO-MAP` (`VC:36-37`); kernel L6 also checks seat agreement (`K:255-266`); checker L6 (`IC:532-535`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `fix-01` (PF-L6 ×26). Retiring: N-4/N-5 (`R2:50-62`; the (b) half
  "export regen restores" is the N-2 class, `R2:31-41`). Note part (b) of the original comment was never
  implemented as a check even at a2f45f6d (only (a) is coded, `a2f45f6d:GATE:58-72`).
- **AC** `run_corpus.py --kind fixtures` exit 0 with the L6 family at exactly 26 cases each rejected for
  `has no requirement->seat->test->WP mapping` on both paths.
- **F** neutering `law6-reqmap` makes 26 cases NOT rejected ⇒ `fix-01` FAIL; G05 corpus shrunk.
- **L** a2f45f6d `14-omission-detected` → f04bf7e6 inside `fix-01-golden-and-property-fixtures` (both paths, commit msg
  "30 fixtures, each now run through BOTH paths") → af0eb3c9 `fix-01` (PF-L6 26) → a87bb6b7 → cc52a27d → 4ee2b58a. **Survived (generalized).**
- **SET** GENERALIZED.

#### G15 — `15-disagreement-blocks`
- **W** `a2f45f6d:GATE:74-79`: `# G15 deliberate kernel/clingo disagreement BLOCKS: run clingo on an L4-cycle temp while kernel sees baseline` / (append `(fact stage-edge PUBLISH__ACQUIRE …)` to a temp copy; run clingo) / `# kernel(baseline)=PASS, clingo(mutated)=FAIL -> disagreement -> agreement check must be FALSE` / `ck 15-disagreement-blocks "$([ "$kv" = PASS ] && [ $disc -ne 0 ] && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:79`
- **P** when the two paths disagree, no PASS is issued.
- **I** two different inputs (baseline vs mutated) to two paths.
- **O** clingo non-zero on the mutated copy while kernel PASS on baseline.
- **DDI** all four (same as G13).
- **NOW** the disagreement is made STRUCTURAL: the checker refuses any verdict unless its commitment equals the
  kernel's (`IC:25-26`; `COMMITMENT-UNAVAILABLE` needle in K21 `RC:856`), and `ver-01` fails on `COMMITMENT-MISMATCH`
  (`GC:991-992`); every fixture and property case must be rejected by BOTH paths for the SAME law (`RC:616-620`,
  "path disagreement"); L4 fixture `FX-L4-PIPELINE-CYCLE` and family `PF-L4-STAGE-CYCLE` ×8 (`VC:32-33,54-56`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `ver-01` + `fix-01` both-path rule + K21 under `fls-01`. Retiring:
  F-4 (`D0161:25`). The original test compared two DIFFERENT models (baseline vs mutated) — a construction that
  proves clingo can fail, not that disagreement blocks; the commitment binding removes the class.
- **AC** `gate_checks.py commitments` exit 1 whenever the two commitments differ or either verdict is not PASS.
- **F** K11, K12, K21 (`RC:761-775,849-858`).
- **L** a2f45f6d `15-disagreement-blocks` → f04bf7e6 `chk-02-fact-set-commitments-identical` (`f04bf7e6:GATE:59`) →
  af0eb3c9 `ver-01` + K21 under `fls-01` → a87bb6b7 → cc52a27d → 4ee2b58a. **Survived (generalized).**
- **SET** GENERALIZED.

#### G16 — `16-decision-packet`
- **W** `a2f45f6d:GATE:81-83`: `# G16 decision packet from evidence` / `python3 build_decision_packet.py >/dev/null 2>&1` / `ck 16-decision-packet "$([ -f ROOT-OPERATOR-DECISION-PACKET.md ] && grep -cq 'APPROVE / REJECT / DEFER\|APPROVE\b' ROOT-OPERATOR-DECISION-PACKET.md && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:83`
- **P** a single-operator decision packet exists, built from evidence.
- **I** packet builder; packet file.
- **O** file present containing `APPROVE`.
- **DDI** DDI-4 completion flips the meaning: `GLOBAL` promotion is `FORBIDDEN_UNTIL_DDI_COMPLETE` while any class is
  `AUTHORITATIVE_AT_SOURCE` (`GC:1098-1104`; `4ee2b58a:AM/ROOT-OPERATOR-DECISION-PACKET.md:46,139,195`); the packet's
  deferred volume (`GC:1089-1093`) changes at every batch.
- **NOW** `doc-02-decision-packet-reconciled-to-the-model` (`4ee2b58a:GATE:212` → `GC:1075-1125`): every total
  recomputed from the model, both commitments matched (`GC:1111-1121`), authority split and GLOBAL promotion
  enforced (`GC:1094-1104`); packet offers APPROVE (bounded) only (`…PACKET.md:198`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `doc-02`. Retiring: F-10 (`D0161:31`), N-7 (`R2:70-79`).
- **AC** `gate_checks.py packet --work <W>` exit 0; `PACKET-MISMATCH | PACKET-EXTRA | GLOBAL-PROMOTION-OVERCLAIM |
  PROMOTION-UNDECLARED | PACKET-UNRECONCILED` ⇒ exit 1.
- **F** K20-PACKET-UNDERCOUNT, X44-GLOBAL-PROMOTION-OVERCLAIM (`VC:161,217`; `RC:837,989`), X59/X60 (`VC:259-268`).
- **L** a2f45f6d `16-decision-packet` → f04bf7e6 `doc-02-decision-packet-reconciled` (`f04bf7e6:GATE:81`) → af0eb3c9
  `doc-02-decision-packet-reconciled-to-the-model` (`af0eb3c9:GATE:115`) → a87bb6b7 `:192` → cc52a27d → 4ee2b58a `:212`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G17 — `17-no-exhaustive-human-review`
- **W** `a2f45f6d:GATE:84-85`: `# G17 no gate requires exhaustive human review (asserted in packet)` / `ck 17-no-exhaustive-human-review "$(grep -cq 'No gate requires exhaustive human repository review' ROOT-OPERATOR-DECISION-PACKET.md && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:85`
- **P** single-operator assurance: no gate demands exhaustive human reading of the repository.
- **I** the packet's prose.
- **O** the sentence is present (`a2f45f6d:AM/ROOT-OPERATOR-DECISION-PACKET.md:3-4`; still present at
  `4ee2b58a:AM/ROOT-OPERATOR-DECISION-PACKET.md:4`).
- **DDI** none.
- **NOW** NOT COUNTED. `note packet-single-operator-assurance` (`4ee2b58a:GATE:226`): "the statement is prose, its
  totals are what the counted checks reconcile". No counted check measures the property (e.g. that every counted
  check is machine-decidable over the candidate without a human reading step).
- **ST** MISSING as a counted gate (DEMOTED). Demoting findings: F-10 (`D0161:31`), N-14 (`R2:93`); commit f04bf7e6
  "Only two lexical checks survive; both are reported as INFORMATIONAL_PRESENCE_CHECK and excluded from the count".
- **AC** (would be) a mechanical statement, e.g. every counted check's inputs are the candidate tree + pinned tools
  only (`GC:22-51` documents this per check but nothing asserts it). NONE at 4ee2b58a.
- **F** none; deleting the sentence changes the note's text, no verdict.
- **L** a2f45f6d `17-no-exhaustive-human-review` → f04bf7e6 `note packet-single-operator-assurance` (`f04bf7e6:GATE:87`)
  → af0eb3c9 `:133` → a87bb6b7 `:210` → cc52a27d → 4ee2b58a `:226`. **Lost as a gate at f04bf7e6; note survives.**
- **SET** MISSING (demoted). Alternative reading in §3.

#### G18 — `18-legacy-nonauthoritative`
- **W** `a2f45f6d:GATE:86-87`: `# G18 legacy audits classified non-authoritative (not used as proof here)` / `ck 18-legacy-nonauthoritative "$(grep -cq 'NON_AUTHORITATIVE_GATE' files-and-roles.sexp && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:87`
- **P** the frozen v1.x harness is classified non-authoritative and is not used as proof (`a2f45f6d:AM/LEGACY-AUDIT-DISPOSITION.md:1-18`).
- **I** `files-and-roles.sexp` (21 occurrences of the token at a2f45f6d).
- **O** token present.
- **DDI** none.
- **NOW** `doc-03-governance-closure-declared-and-historic-free` (`4ee2b58a:GATE:213` → `GC:1283-1311`): the REAL
  transitive execution closure of every `GOVERNANCE_MACHINERY` entrypoint must contain no `HISTORICAL_EVIDENCE`
  file (`HISTORICAL-CODE-IN-CLOSURE`, `GC:1297-1299`) and nothing undeclared (`CLOSURE-UNDECLARED`), with
  unresolvable call sites as findings (R3-5). Classification: R-000/R-012 `HISTORICAL_EVIDENCE`
  (`4ee2b58a:AM/classification-rules.sexp:15,54-56`), 580 rows at HEAD. The literal token `NON_AUTHORITATIVE_GATE`
  no longer exists in `4ee2b58a:AM/files-and-roles.sexp` (0 hits) — the original check as written would FAIL at HEAD.
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `doc-03`. Retiring: F-7 ("`V1.8-VERIFY.py` … ζωντανή εξάρτηση",
  `D0161:28`), F-10 (`D0161:31`), N-13 (`R2:92`), R3-5 (`R3:26`).
- **AC** `gate_checks.py dependency-closure` exit 0.
- **F** X31-HISTORICAL-ON-LIVE-PATH (`VC:183`; `RC:936-960`, performs an actual reintroduction).
- **L** a2f45f6d `18-legacy-nonauthoritative` → f04bf7e6 `doc-03-no-historical-code-on-live-path` (`f04bf7e6:GATE:82`) →
  af0eb3c9 `doc-03-governance-closure-declared-and-historic-free` (`af0eb3c9:GATE:116`) → a87bb6b7 `:193` → cc52a27d →
  4ee2b58a `:213`. **Survived (generalized).**
- **SET** GENERALIZED.

#### G19 — `19-deferred-ledger-exact-universe`
- **W** `a2f45f6d:GATE:89-92`: `# G19 no source fact class silently omitted: every v1.6-v1.8 (file,class) is IMPORTED|DEFERRED_DATA_IMPORT|` / `#     OUT_OF_MIGRATION_SCOPE, exact-universe against an independent re-scan, every deferred class finite-batched.` / `python3 build_deferred.py >/dev/null 2>&1; python3 build_deferred.py --verify >/tmp/ddi.out 2>&1; ddic=$?` / `ck 19-deferred-ledger-exact-universe "$([ $ddic -eq 0 ] && grep -q 'DEFERRED-IMPORT LEDGER: PASS' /tmp/ddi.out && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:92`
- **P** every source (file, class) is in the ledger exactly once with a status; every deferred class has a finite batch.
- **I** the six source registries (literal list at `a2f45f6d:AM/build_deferred.py:18`), the ledger.
- **O** `DEFERRED-IMPORT LEDGER: PASS`, exit 0.
- **DDI** EVERY batch changes its meaning: `IMPORTED` is a hard-coded dict of what THIS pass imported
  (`4ee2b58a:AM/build_deferred.py:75-80`) and verify (d) fails any other IMPORTED row as `OVER-CLAIMED-IMPORT`
  (`:236-239`); `:authority` must be `CANONICAL_IN_MODEL` iff IMPORTED (`:231-234`). So DDI-n cannot flip a class to
  IMPORTED without editing the builder — the gate is an entry criterion for each batch, and at DDI-4 completion the
  meaning becomes "deferred=0". Also the ledger is itself a hash-pinned module (`4ee2b58a:AM/ROOT.sexp:17`).
- **NOW** `led-01-deferred-ledger-exact-source-universe` (`4ee2b58a:GATE:204-208`): same command, same needle, run
  inside the exported candidate seat; verify strengthened: multiset first (`build_deferred.py:210-213`), missing /
  phantom (`:218-219`), count (`:222`), batch (`:228`), authority (`:231-234`), over-claim (`:237-239`), typed
  `MISSING-SOURCE-FILE` exit 5 (`:25-36`), source universe DERIVED from the inventory (`:38-70`).
- **ST** EXISTS (PRESERVED, strengthened). Note: the original ran `build_deferred.py` (regenerate) BEFORE `--verify`
  in the working tree (`a2f45f6d:GATE:91`) — the N-2 class; at 4ee2b58a only `--verify` runs, over the candidate.
- **AC** `cd <seat> && build_deferred.py --verify` exit 0 AND output contains `DEFERRED-IMPORT LEDGER: PASS`.
- **F** K17-DUPLICATE-LEDGER-ROW (`RC:788-798`), K18-MISSING-SOURCE-FILE (`RC:801-808`), G07-UNADJUDICATED-SOURCE
  (`RC:1188-1209`, must fail through `led-01`).
- **L** a2f45f6d `19-deferred-ledger-exact-universe` → f04bf7e6 `led-01-deferred-ledger-exact-universe` (`f04bf7e6:GATE:76`)
  → af0eb3c9 `led-01-deferred-ledger-exact-source-universe` (`af0eb3c9:GATE:108-111`) → a87bb6b7 `:185-188` → cc52a27d →
  4ee2b58a `:205-208`. **Survived (preserved).**
- **SET** PRESERVED.

#### G20 — `20-deferred-in-model-universe`
- **W** `a2f45f6d:GATE:93-94`: `# G20 the deferred ledger is inside the hash-rooted model universe (pinned in ROOT + carries DEFERRED_DATA_IMPORT rows)` / `ck 20-deferred-in-model-universe "$(grep -q 'deferred-imports.sexp' ROOT.sexp && grep -q ':status DEFERRED_DATA_IMPORT' deferred-imports.sexp && echo 1 || echo 0)" 1`
- **S** `a2f45f6d:GATE:94`
- **P** the ledger is a hash-pinned model module and carries deferred rows.
- **I** `ROOT.sexp`, `deferred-imports.sexp`.
- **O** both substrings present.
- **DDI** the second conjunct (`:status DEFERRED_DATA_IMPORT` present) becomes FALSE by design when DDI-4 completes —
  the gate's meaning inverts at full build (the correct full-build statement is "deferred = 0").
- **NOW** the first conjunct is kernel L7 on both paths (`K:269-313`; `IC:18-21`) over `4ee2b58a:AM/ROOT.sexp:17`
  (`deferred-imports.sexp` pinned) under `ver-01`, plus the ledger declared as generated artifact
  `ART-DEFERRED-LEDGER` (`4ee2b58a:AM/generation-order.sexp:38-39`) under `art-01` (`GC:520-550`) and `gen-02`; the
  second conjunct is L1 closed enum `migration-status` (`4ee2b58a:AM/MODEL-SCHEMA.sexp:56`) + verify authority/batch
  rules (`build_deferred.py:227-234`) under `led-01`, and the packet's deferred volume under `doc-02` (`GC:1089-1093`).
  Both substrings still literally exist at HEAD (`ROOT.sexp:17`; `deferred-imports.sexp:7`).
- **ST** SUPERSEDED_WITH_PROOF. Superseding: `ver-01`(L7) + `art-01` + `led-01` + `doc-02`. Retiring: F-10 residual
  row "`led-02` … gone; what remains counted can fail on a defect it names" (`R2:129`), N-14 (`R2:93`), N-3 (`R2:43-48`).
- **AC** kernel/checker L7 PASS with `deferred-imports.sexp` among the pins; `gate_checks.py artifacts` exit 0.
- **F** K10 (a pinned module ignored by one path), X32, G03-ARTIFACT-DELETED (`VC:145,184,224`).
- **L** a2f45f6d `20-deferred-in-model-universe` → f04bf7e6 `led-02-ledger-inside-model-universe` (`f04bf7e6:GATE:77`,
  same grep) → af0eb3c9 retired (F-10 residual, `R2:129`); property in L7 + `art-01` → a87bb6b7 → cc52a27d → 4ee2b58a.
  **Survived (generalized into laws/facts).**
- **SET** GENERALIZED.

#### G21 — `21-omission-gate-bites`
- **W** `a2f45f6d:GATE:95-99`: `# G21 anti-omission gate actually bites: drop one ledger row -> --verify FAILs with MISSING-FROM-LEDGER; regen restores` / `grep -v 'source-class V1.8-SCHEMAS__define-record ' deferred-imports.sexp > /tmp/ddi.mut && cp /tmp/ddi.mut deferred-imports.sexp` / `python3 build_deferred.py --verify >/tmp/ddi2.out 2>&1; bitec=$?` / `python3 build_deferred.py >/dev/null 2>&1   # regenerate -> canonical ledger restored` / `ck 21-omission-gate-bites "$([ $bitec -ne 0 ] && grep -q 'MISSING-FROM-LEDGER' /tmp/ddi2.out && echo 1 || echo 0)" 1; rm -f /tmp/ddi.mut`
- **S** `a2f45f6d:GATE:99`
- **P** the ledger verifier is not vacuous: removing one row is detected as `MISSING-FROM-LEDGER`.
- **I** in-place mutation of the tracked ledger, `--verify`, regeneration.
- **O** non-zero exit + `MISSING-FROM-LEDGER`.
- **DDI** same as G19 (every batch).
- **NOW** the gate no longer mutates anything (N-2); the "bites" property lives in held-out falsifiers under
  `fls-01-component-falsifiers-all-rejected` (`4ee2b58a:GATE:199-202`) and the composed battery: K17 (DUPLICATE-LEDGER-ROW,
  `RC:788-798`), K18 (MISSING-SOURCE-FILE, `RC:801-808`), G07 (a qualifying source with no ledger rows ⇒ `led-01` must
  fail with `DEFERRED-IMPORT LEDGER: FAIL`, `RC:1188-1209`). The verify branch that the original exercised
  (`MISSING-FROM-LEDGER`, `4ee2b58a:AM/build_deferred.py:218`) is reached by G07 (every (file,class) of the new file is
  missing) but NO held-out case names `MISSING-FROM-LEDGER` or drops a SINGLE existing row: `grep MISSING-FROM-LEDGER`
  over every runner at f04bf7e6, af0eb3c9, a87bb6b7, 4ee2b58a = 0 hits.
- **ST** SUPERSEDED_WITH_PROOF, with a named residual (§5 A-3). Superseding: `fls-01` (K17/K18) + composed G07.
  Retiring: N-2 (in-gate mutation of the tracked tree, `R2:31-41`), N-6 (hand-written source list, `R2:64-68`), F-8/F-9
  (`D0161:29-30`).
- **AC** `run_corpus.py --kind component --base <B>` exit 0 with `not-rejected=0`; composed `G07` REJECTED as intended.
- **F** K17, K18, G07. Residual: the single-row drop (`V1.8-SCHEMAS__define-record`) is not held out by name.
- **L** a2f45f6d `21-omission-gate-bites` → f04bf7e6 K17/K18 under `fls-01-held-out-falsifiers-rejected`
  (`f04bf7e6:GATE:69-72`; `f04bf7e6:AM/run_falsifiers.py:634-635`) → af0eb3c9 `fls-01-component-falsifiers-all-rejected` +
  G07 (`af0eb3c9:AM/run_gate_falsifiers.py:301`) → a87bb6b7 → cc52a27d → 4ee2b58a `RC:1355-1356,1378`. **Survived
  (generalized), single-row mutation not carried by name.**
- **SET** GENERALIZED.

---


## 5. The survival equation (matrix §3) with the skeptic's alternative readings


    original 20  =  PRESERVED (2)  +  LEGITIMATELY GENERALIZED / SUPERSEDED_WITH_PROOF (16)  +  MISSING (2)

| set | members (each of the 20 appears exactly once) |
|---|---|
| PRESERVED (2) | `09a-kernel-sloc-budget` → `ver-02`; `19-deferred-ledger-exact-universe` → `led-01` |
| LEGITIMATELY GENERALIZED (16) | `01`→`inv-01`; `02`→`ver-01`+L2+`fix-01`; `03`→`doc-01`; `04`→`ver-01`; `05`→`ver-01`(L7)+`hsh-01`; `06`→`gen-02`; `07`→`gen-02`+`ro-01`; `08`→`gen-02`+G02; `10-12`→`fix-01`+`cor-01`+`uni-01`; `13`→`ver-01`+`enc-01`+`prv-01`; `14`→`fix-01`(PF-L6); `15`→`ver-01`+K21; `16`→`doc-02`; `18`→`doc-03`; `20`→`ver-01`(L7)+`art-01`+`led-01`; `21`→`fls-01`(K17/K18)+G07 |
| MISSING as counted gates (2) | `09b-kernel-no-regex` (demoted to `note krn-lexical-scan`); `17-no-exhaustive-human-review` (demoted to `note packet-single-operator-assurance`) |

Where the demoted pair goes, and why: they sit in MISSING because the repository's own counting rule says a
presence-only check is not a check (`4ee2b58a:GATE:26-28`; N-14 `R2:93`), the notes cannot fail
(`4ee2b58a:GATE:89`: `note` only increments `info`), and no counted check protects either property. This is NOT a
claim that anything was silently lost: both demotions are recorded with a finding (F-10 `D0161:31`; N-14 `R2:93`;
commit f04bf7e6 "Only two lexical checks survive … excluded from the count"), and 09b's original property was
additionally NARROWED on purpose (TCB-DECISION Option A introduced the one permitted `run-program`,
`hash-provider.lisp:54`).

Alternative reading (for the creator to fix, §5 A-2): if "demoted with a named finding" counts as "legitimately
generalized", the equation reads 2 + 18 + 0. Under NO reading is any member unaccounted for or counted twice.

Consistency check against the orchestrator's draft (`WORK/my-gate-mapping.md`): identical membership; the draft
left the demoted pair's set open; this matrix fixes it to MISSING with the rule above.

---


**Alternative readings recorded by the skeptic (S-4), none of which changes membership or total:** if "PRESERVED" is read strictly (same input class AND same second measured file), G19 becomes GENERALIZED (its source universe is now derived from the inventory rather than a literal list, and it verifies over an export instead of after regeneration) and G09a becomes GENERALIZED (the second measured file changed from `sha256.lisp` to `hash-provider.lisp`), giving **1 + 17 + 2** or **0 + 18 + 2**. Together with A-2 (demoted pair as GENERALIZED: **2 + 18 + 0**) the creator has four consistent readings; under every one of them each of the 20 appears exactly once and none is unaccounted for.

## 6. Checks at `4ee2b58a` with no ancestor among the 20 (matrix §4), with the ancestry relation unified (S-3)


Source for names: `4ee2b58a:GATE` lines cited; counted set = 21 (`4ee2b58a:GATE:229-230`; `D0164:50-54`).

| kind | name | line | introduced | finding | ancestor among the 20? |
|---|---|---|---|---|---|
| counted | `tch-01-pinned-tools-are-the-tools-executed` | 165 | af0eb3c9 | N-11/N-1 (`R2:90,21-29`), R3-3 (`R3:24`), R4-2 (`R4:25`) | NONE — new |
| counted | `gen-01-declared-order-is-total-and-acyclic` | 168 | f04bf7e6 (`gen-01-declared-order-runs`), renamed af0eb3c9 | F-13/N-3 (`R2:43-48`) | NONE — new (the old gate ran producers in a private script order) |
| counted | `gen-02-artifacts-regenerate-byte-identical` | 169 | af0eb3c9 | N-2 | ancestor 06/07/08 |
| counted | `inv-01-inventory-equals-candidate-universe` | 172 | f04bf7e6 | F-1/F-2/F-3/F-10 | ancestor 01 |
| counted | `art-01-generated-artifact-universe-is-exact` | 173 | af0eb3c9 | N-3, R3-11 | NONE — new (also carries half of 20) |
| counted | `sea-01-every-seat-resolves-or-declares-why` | 174 | af0eb3c9 | N-10 (`R2:89`) | NONE — new |
| counted | `ver-01-both-paths-agree-on-one-fact-universe` | 177 | af0eb3c9 | F-4 | ancestor 04/13/15 (+02/05 via kernel) |
| counted | `ver-02-kernel-source-budget-400-lines` | 178-179 | af0eb3c9 (rename) | — | ancestor 09a |
| counted | `tcb-01-acceptance-base-measured-and-every-growth-attributed` | 182 | a87bb6b7 (`…within-the-authored-cap`), renamed 4ee2b58a | R3 §15 (`R3:38-47`), R4 §TCB (`R4:32-38`) | NONE — new |
| counted | `hsh-01-two-vetted-engines-agree-on-raw-bytes` | 185 | f04bf7e6 (`hsh-01-two-vetted-engines-agree`) | F-11 | NONE — new |
| counted | `prv-01-verifier-is-the-candidates-machinery` | 188 | a87bb6b7 | R3-2 (`R3:23`) | NONE — new |
| counted | `uni-01-no-declared-family-below-its-floor` | 189 | a87bb6b7 | R3-7, R4-1 | NONE — new |
| counted | `enc-01-three-implementations-one-encoding` | 190 | a87bb6b7 | R3-1 | NONE — new |
| counted | `cor-01-corpus-universe-is-exact` | 193 | af0eb3c9 | N-4 | NONE — new (kinship with 10-12: it guards the universe 10-12 ran, but 10-12 never checked a universe) |
| counted | `fix-01-golden-and-generated-fixtures` | 194-196 | f04bf7e6 | N-4/N-5/N-19 | ancestor 10-12 / 14 |
| counted | `fls-01-component-falsifiers-all-rejected` | 199-202 | f04bf7e6 (`fls-01-held-out-falsifiers-rejected`) | review #1 order (`D0161:45-46`) | ancestor 21 (and the in-gate mutation tests 08/14/15 as a class) |
| counted | `led-01-deferred-ledger-exact-source-universe` | 205-208 | f04bf7e6 | F-8/F-9/N-6 | ancestor 19 |
| counted | `doc-01-conflict-ledger-reconciled-both-ways` | 211 | f04bf7e6 | F-10 | ancestor 03 |
| counted | `doc-02-decision-packet-reconciled-to-the-model` | 212 | f04bf7e6 | F-10/N-7 | ancestor 16 |
| counted | `doc-03-governance-closure-declared-and-historic-free` | 213 | f04bf7e6 (`doc-03-no-historical-code-on-live-path`) | F-7/N-13/R3-5 | ancestor 18 |
| counted | `ro-01-repository-content-identical-after-the-run` | 219-221 | af0eb3c9 (`ro-01-working-tree-byte-identical-after-the-run`) | N-2, R3-9, R4-7 | NONE — new (weak kinship with 07: 07 measured regeneration drift, ro-01 measures the GATE's own writes) |
| informational | `krn-lexical-scan` | 224-225 | f04bf7e6 | F-10/N-14 | ancestor 09b (demoted) |
| informational | `packet-single-operator-assurance` | 226 | f04bf7e6 | F-10/N-14 | ancestor 17 (demoted) |
| informational | `composed-gate-battery` | 227 | af0eb3c9 | N-2 | NONE — new |
| subset | `provenance` | 132 | a87bb6b7 | R3-2/R3-15 | NONE — new |
| subset | `model-checks` | 137 | a87bb6b7 | R3-15 | NONE as a subset (it wraps the `--checks` phase, i.e. all 21) |
| subset | `composed-gate-falsifiers` | 142 | a87bb6b7 | N-2/R3-15 | NONE — new |
| subset | `evidence` | 143-149 | a87bb6b7 | R3 own-found (`R3:51-53`) | NONE — new |

Totals: counted 21 = 10 with an ancestor + **11 new**; informational 3 = 2 demoted ancestors + **1 new**;
acceptance subsets 4 = **4 new**. **new_checks = 16.**

Lineage counts (canonical path, from `WORK/gate-lineage.md`): 20 → 20 → 20(+2) → 18(+4) → 21(+4) → 21(+4) → 21(+3).
Retired counted checks that were NOT among the 20 and are not at HEAD: `fls-00-battery-executed-is-the-candidates-battery`
(af0eb3c9 only, `af0eb3c9:GATE:96-101`; superseded by `prv-01`, R3-2), `ro-02-candidate-tree-unchanged-by-the-run`
(af0eb3c9–cc52a27d; removed R4-7 `R4:30`), `chk-03-both-paths-consume-root-universe`/`module-universe` (f04bf7e6 only;
folded into `ver-01`/L7).

---


**Unified ancestry (S-3).** The table above uses the PRIMARY-seat relation (a current check descends from an original gate only if it is the main seat of that gate's property): 10 counted checks with an ancestor + 11 new; 3 informational = 2 demoted + 1 new; 4 subsets new → **new_checks = 16**. Under the AUXILIARY relation used in the equation of §5 (a current check counts as descendant if it carries any part of the property), `hsh-01`, `art-01`, `ro-01`, `enc-01`, `prv-01`, `cor-01`, `uni-01` also inherit, leaving **4 genuinely new counted checks: `tch-01`, `gen-01`, `sea-01`, `tcb-01`**. Both numbers are reported; neither is a target.

## 7. Adjudication items (matrix §5 and archaeology §6, merged; A-6 of the archaeology withdrawn per S-5)

### 7.1 From the matrix

- **A-1 — What "the original 20" denotes.** 20 `ck` calls (`a2f45f6d:GATE`) vs 21 order items G1…G21 (G10-G12 merged,
  G3 unheadered, G9 split). The repository never lists the 20 by name; the order that numbered them is not a repo
  artifact (`D0161:7-8` for the review; the order is only quoted by title `D0160:4`). Both sides cited in §0.
- **A-2 — Set of the demoted pair (09b, 17).** MISSING-as-gate (this matrix, rule §1) vs GENERALIZED-with-proof
  (F-10/N-14 named the demotion). Decides whether the equation is 2+16+2 or 2+18+0.
- **A-3 — G21's exact mutation has no held-out successor.** `MISSING-FROM-LEDGER` (`4ee2b58a:AM/build_deferred.py:218`)
  is exercised only indirectly by G07 (`RC:1188-1209`, needle `DEFERRED-IMPORT LEDGER: FAIL`); no corpus row drops a
  single existing ledger row (0 hits for `MISSING-FROM-LEDGER` in any runner at f04bf7e6/af0eb3c9/a87bb6b7/4ee2b58a).
  A data-only row cannot express it (mutation kinds `APPEND REPLACE CHECK GATE` target facts/checks/gate, not
  `build_deferred.py --verify`; `4ee2b58a:AM/MODEL-SCHEMA.sexp:66`), so closing it costs code in the TCB.
- **A-4 — Dead code in the measured TCB: `f19_restore_instead_of_compare`.** Defined at `RC:811-834` (it is the direct
  descendant of gate 08's "MANUAL TAMPER" mutation), NOT registered in `CODED_COMPONENT` (`RC:1343-1369`) nor
  `COMPOSED` (`RC:1370-1380`), and `K19` is absent from `VC` (0 hits at 4ee2b58a; last present at
  `f04bf7e6:AM/run_falsifiers.py:636` as `K19-restore-not-compare`). `cor-01` reads only the two tables by AST
  (`GC:617-631`) so an unregistered function is invisible to it. Retirement is implied by N-2 (`R2:39-41`: "the previous
  falsifier for this class could not detect its own defect because it never ran the gate") but never named. Lines are
  counted by `tcb-01` (`run_corpus.py` is TCB-0006-class machinery, `VC:117-119`). Mediocrity-hunt finding: dead seat.
- **A-5 — Gate 09b's property was narrowed by design, then demoted.** TCB-DECISION (`AM/TCB-DECISION.md:12-16,86`)
  admits exactly one `sb-ext:run-program` (`hash-provider.lisp:54`), so the original blacklist can no longer be the
  check; the residual "no regex/substring as proof" is unprotected (note only). Whether an AST-level kernel-purity
  check is wanted for Option A is a creator decision.
- **A-6 — Documentation drift on gate 18's token.** `4ee2b58a:AM/LEGACY-AUDIT-DISPOSITION.md:6` still says the legacy
  harness is "classified `HISTORICAL_EVIDENCE / NON_AUTHORITATIVE_GATE` in `files-and-roles.sexp`", but the token
  `NON_AUTHORITATIVE_GATE` occurs 0 times in `4ee2b58a:AM/files-and-roles.sexp` and is not in the `file-role` enum
  (`MODEL-SCHEMA.sexp:52-55`); only R-012's reason says "NON_AUTHORITATIVE (frozen …)" (`classification-rules.sexp:56`).
- **A-7 — DDI entry criteria implied by the gates (from §2 DDI fields), to be adopted or refused:** (i) `IMPORTED` dict
  and authority rule in `build_deferred.py:75-80,231-239` must change per batch or `led-01` rejects the batch; (ii) L1
  value grammar (`MODEL-SCHEMA.sexp:5-6`) blocks DDI-2/DDI-3 nested forms (N4 in `WORK/orchestrator-notes.md`);
  (iii) property-family EXACT cardinalities (`VC:42-56`) and `cor-01` must be re-authored whenever a batch adds
  subsystems/types/stores/seats; (iv) `doc-01`'s closed row kinds (`GC:874-902`) cannot record flattening
  normalizations; (v) the Lisp path is at 400/400 (`files-and-roles.sexp:1090-1091`) so any kernel change for DDI trips
  `ver-02`; (vi) L6's requirement/test universe is derived from `define-subsystem` while DDI-1 seats cite RA-*/T8-* ids
  (N1 in `WORK/orchestrator-notes.md`); (vii) G20's second conjunct inverts at DDI-4 completion.
- **A-8 — Reviews retired checks by CLASS, never by original gate id.** No review document maps F/N/R findings back to
  `01…21`; the mapping in §2 is this agent's reconstruction from the finding texts. If the creator wants the mapping to
  be authoritative it needs a seat (e.g. a `gate-lineage` fact family), which does not exist.


### 7.2 From the archaeology (A-6 withdrawn: the lineage table now lists four acceptance subsets)

* **A-1 Identity of "the original 20 Option-A Full-Build gates".** Side 1: C1 — the 20 `ck` calls at 818b7dd9 (§4 C1 evidence for). Side 2: an external, never-committed list, distinct from C1 (§4 C1 evidence against; "mandatory future stage" at `GATE:230-231`, `0164-claude.md:51`). Only the creator's orders / Review #1 can settle it.
* **A-2 Meaning of "Full build".** Side 1: the canonical-model track — core + DDI-1…4 + Implementation-Book/WP-00 closure (`0160-claude.md:8-12`; exclusion lists `0161:13`, `0162:12`, `0164:10`). Side 2: the older repo vocabulary — the owner's full Docker build / plenary of `--*-gate` commands (`STATE-OF-PLAY.md:107`; b71b835c; C3). The [0161]-[0164] context favours side 1; the words alone do not.
* **A-3 Gate count in the specification vs the script.** The a2f45f6d blob numbers G1…G21 (§2.1) while every record says "20/20 gates". Whether the [0160] order specified 20 or 21 gates is UNKNOWN; if 21, "all 20 gates" is itself a miscount inherited by Option A.
* **A-4 Second seat for the plenary gate set.** `deployment/LAWMAX-REPO-ONTOLOGY-MAP.{md:14,sexp:14}` and `deployment/LAWMAX-CONSOLIDATION-PLAN.md:9` state 20 gates; `deployment/verify/gate-registry.sexp:20-44` (declared "η ΜΙΑ πηγή αλήθειας του συνόλου πυλών", L3) states 25. Stale duplicate figure outside the AM scope; relevant only because it is the one in-repo "20 gates" list a reader could mistake for Option A.
* **A-5 Origin of the option list.** Side 1 (BRIEF): the external review report. Side 2: the creator's order (Greek "Επιλογή Α" appears only in creator-facing records; "the order anticipated 20", `AM/REVIEW-4-CORRECTION-ADJUDICATION.md:30`). The repo records neither.


## 8. Unknowns (honest ignorance; matrix §6 + archaeology §7)


- **U-1** The text of the order that defined Option A / the Full-Build gate set — NOT IN REPO (only its consequences
  and disclaimers are; §0).
- **U-2** Whether Option A's "20 gates" are exactly these 20 `ck` calls, the 21 G-numbers, or a list in the external
  review attachment (`D0161:5-8`) — UNKNOWN.
- **U-3** Whether "Full Build" additionally required the 20 to pass over the FULL (66-class) model — UNKNOWN; if yes,
  every status in §2 is a status over the CORE only (the 20 passed over 4 imported classes,
  `a2f45f6d:AM/ROOT-OPERATOR-DECISION-PACKET.md:37-39`).
- **U-4** Which DDI batches will add hash-pinned modules (affects G05/G20 scope) — UNKNOWN until the batch plans exist.
- **U-5** Nothing here was executed: `sbcl`/`clingo` are absent in this container (`WORK/orchestrator-notes.md` N6), so
  "the literal old check would pass/fail at HEAD" statements are derived from grep counts over `git show`, not runs.


* The full text of the Review #1–#4 reports and of the creator's orders for [0160], [0161], [0162], [0163], [0164] — all external ("read-only συνημμένο, ΟΧΙ artifact του repo", `0161:7-9`, `0163:6`, `0164:6`).
* Whether "20" in Option A counts the 20 `ck` calls, the G1…G21 concepts, or an unrelated list.
* Whether the option enumeration was authored by the reviewer or the creator (A-5).
* Which invocation mode Review #3 used when it "counted 21" (`0164-claude.md:53-54`) — consistent with the tree-ish `--checks "$TREE"` path (§2.4) but not stated.
* `ACCEPT.sh` (mentioned in [0163]) was never tracked (`git log --all -- '*ACCEPT.sh'` = 0; `0164-claude.md:57-58`); its content is unrecoverable from the clone, which also has no unreachable objects.


## 9. Verdict and the exact external artifact required from the creator


**PARTIALLY-EVIDENCED.** The *name* (Option-1 = Option A = Επιλογή Α = full-build closure with "the original 20 Full-Build gates"; Option-2 = core) is in the repo from f04bf7e6 onward, only as a scope-exclusion label and a negation. The *list* of those 20 gates is **NOT-IN-REPO**: no tracked file, commit message, dialogue record, packet, adjudication document or audit script of any of the 7 refs / 517 commits names even one Option-A gate, and the phrase "Full build, all 20 gates" occurs nowhere. The only 20-gate set the repository ever asserted is C1 (the 20 `ck` calls of `GATE` at a2f45f6d/818b7dd9, numbered G1…G21 in its comments), whose identification with "the original 20 Option-A gates" is supported by contemporaneity and by Review #1's F-10 but contradicted by the "mandatory future stage" wording of [0164]. The BRIEF's specific claim that the option list "came from the external review report" is not evidenced in-repo (§1.2).

**Exact external artifacts the creator must supply** (in priority order):
1. The **Review #1 report** — *"INDEPENDENT CANONICAL-MODEL CORE REVIEW — OPTION-2 CORE @ 818b7dd9"*, verdict *"OPTION-2 CANONICAL CORE INDEPENDENT REVIEW FAILED — CORRECTION REQUIRED"* (5×P1 F-1…F-5, 4×P2 F-6…F-9, 4×P3 F-10…F-13) — the attachment governing commit **f04bf7e6** (`0161-claude.md:4-9`), delivered between 818b7dd9 (2026-09-04 04:47:43Z) and f04bf7e6 (2026-09-04 19:52:45Z). If it contains an option section ("Option 1: Full build, all 20 gates / Option 2: core"), that is the source.
2. The **creator's order that selected Option 2**, whose title is recorded as «OPTION-2 CORE INDEPENDENT-REVIEW REMEDIATION — F-1…F-13 SYSTEMIC CLOSURE» (`0161-claude.md:4`), together with its K01–K25 falsifier list (`0161-claude.md:45`) — same commit f04bf7e6. If the reviewer did not enumerate options, this message did.
3. The **[0160] order** «FINAL VERIFIER-REGRESS EXIT PASS — CANONICAL ARCHITECTURE MODEL + SINGLE-OPERATOR ASSURANCE» (`0160-claude.md:4`) governing **a2f45f6d**, the only plausible source of the G1…G21 gate numbering (§2.1, C2).
4. The **Review #4 order** (R4-1…R4-7, TCB ceiling withdrawal) governing **4ee2b58a**, which "anticipated 20" and dictated the sentence "NOT THE ORIGINAL 20 OPTION-A FULL-BUILD GATES" (`0164-claude.md:51-54`, `AM/REVIEW-4-CORRECTION-ADJUDICATION.md:30`) — the latest place where the creator restated what "the original 20" are.


**The one question the artifact must answer (skeptic S-8):** *In the first document that enumerated "Option 1 — Full build, all 20 gates / Option 2 — core", which 20 items are the gates: the 20 counted `ck` checks of `ARCHITECTURE-MODEL-GATE.sh` at `818b7dd9`, the 21 numbered concepts G1…G21 of the [0160] order, or another list — and does "Full build" mean that those gates are to be passed over the complete 66-class model after DDI-1…DDI-4?* Until it is answered, this matrix is a CANDIDATE mapping over the core model and DDI-1 remains blocked by the creator's own standing verdict.

## 10. Adversarial verification record (skeptic findings, verbatim) and the corrections applied

Corrections applied in this document: S-1 (identification restated as concept + scope; §0 ¶3; scope note on §4.7); S-2 (the orchestrator draft's row 20 attributed `X30` to the ledger — corrected to K17/K18/G07 in `my-gate-mapping.md`; the matrix cards were already correct); S-3 (both ancestry relations reported, §6); S-4 (alternative readings, §5); S-5 (A-6 withdrawn, §7.2). S-6, S-7, S-9 were attacks that failed (statuses evidenced, equation sums, nothing invented). S-8 is carried as the governing unknown (§9).

**gates-skeptic** — adversarial review of gates-archaeology/report.md, gates-matrix/survival-matrix.md and WORK/my-gate-mapping.md

Read-only. RO clone HEAD `4ee2b58a` (tree `ad71185a`). Every claim below was re-derived with `git show`/`git log`/`git grep`
on the RO clone; nothing was executed. `AM` = `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/ARCHITECTURE-MODEL`,
`GATE` = `AM/ARCHITECTURE-MODEL-GATE.sh`, `D016x` = `deployment/collab/dialogue/016x-claude.md`.

### 10.1 What the skeptic re-verified

| item | result |
|---|---|
| `git log --all --follow -- GATE` | exactly a2f45f6d, f04bf7e6, af0eb3c9, a87bb6b7, 4ee2b58a; `git diff` of GATE a2f45f6d↔818b7dd9 and a87bb6b7↔cc52a27d is empty |
| `git log --all -S"20 gates"` | a2f45f6d, 4ee2b58a only |
| a2f45f6d GATE | 20 `ck` at L13,17,19,21,22,28,35,41,46,50,51,55,72,79,83,85,87,92,94,99; headers G1…G21 at L11,15,18,20,24,30,36,42,48,53,57,74,81,84,86,89,93,95; `ck 03` (L22) has no own header |
| f04bf7e6 GATE | 20 `ck` (L28,31,35,41,46,50,51,52,54,58,59,60,63,68,72,76,77,80,81,82) + 2 `note` (L86,87); header L8-14 |
| af0eb3c9 GATE | 19 distinct `ck` names (L63…L125); `fls-00` counted only when CAND≠WORKTREE (L96-101), `ro-02` only when CAND=WORKTREE (L123-128); notes L132-134 → 18 counted in any mode; commit message L105 "18 counted gate checks pass, 0 fail, 4 declared informational" |
| a87bb6b7 GATE | `sub` L112,117,122 + inline `ACCEPT evidence: PASS` L129 (4 subsets); `tcb-01-…-within-the-authored-cap` L162; `ro-02` ck L202 / note L204; notes L209-211; commit message L40 "21 checks"; cc52a27d message L25 "4 of 4 subsets, 21 checks" |
| 4ee2b58a GATE | 21 `ck` (L165,168,169,172,173,174,177,179,182,185,188,189,190,193,196,202,208,211,212,213,221), 3 `note` (L225-227), `sub` L132,137,142 + inline L149; `note()` only increments `info` (L89); L26-28 counting rule; L229-231 OPTION-2 / OPTION-A sentence |
| a2f45f6d neighbours | `run_fixtures.py:5` "(gate 15)"; `CHECKER/independent_check.py:2` "(gate 13-15)", `:15-16` hard-coded 6-module list; `ROOT-OPERATOR-DECISION-PACKET.md:57` "(gate 15)", `:37-39` DDI 56 / IMPORTED 4 / OOS 6, `:3-4` human-review sentence; `build_inventory.py:56` catch-all, `:62-68` `unclassified`; `run_fixtures.py:65` shared=L3/L4/L5, `:71` `subs[:6]`, `:83` `stores[:4]`; `build_deferred.py:18-19` literal 6-file SOURCES; commit message L24 "20/20 gates PASS (incl. anti-omission G19-G21)" |
| 4ee2b58a neighbours | `KERNEL/hash-provider.lisp:54` `sb-ext:run-program`; `files-and-roles.sexp` 0× `NON_AUTHORITATIVE_GATE` (a2f45f6d: 21×), `:1090-1091` 67+333=400; `LEGACY-AUDIT-DISPOSITION.md:6`; conflict ledger 1× `| 1 |`; `ROOT.sexp:12,17`; `deferred-imports.sexp:7`; `build_deferred.py:38-44,75-80,210-239` (`MISSING-FROM-LEDGER` L218, `OVER-CLAIMED-IMPORT` L237); `MODEL-SCHEMA.sexp:5-6,56,66`; `TCB-DECISION.md:12-16`; `gate_checks.py` L9-17,425-452,617-619,856-905,975-992,1075-1104,1283-1299,1377-1434,1501-1503; kernel L56-60,190,269-313; checker L18-26; `verification-corpus.sexp` L28-29,42-50,132-133,182-184,223-226, 0× `K19`; `run_corpus.py` L811 (only occurrence of `f19_restore_instead_of_compare` → unregistered), L924-933 (`f30` targets `conflict-ledger`), L1123-1125, L1188-1190, L1343-1380; `classification-rules.sexp` L7,15,45,54-56; `generation-order.sexp:38-39`; R2 L13-14,93,129,181; R4 L23,25,30; packet L4,155-158; `PACKET-TEMPLATE.md:64-67` |
| runners | `MISSING-FROM-LEDGER` 0 hits in f04bf7e6 `run_falsifiers.py`, af0eb3c9 `run_falsifiers.py`+`run_gate_falsifiers.py`, a87bb6b7 and 4ee2b58a `run_corpus.py`; f04bf7e6 `run_falsifiers.py:636` `K19-restore-not-compare`; 25 distinct `K01…K25` names at f04bf7e6 |
| dialogue / SOP | D0160:4,8-12,48-51; D0161:4-9,13,31,41-43,45,72; D0162:12,40,45,51; D0163:6,49,104; D0164:6,10,50-54,57-58,100; STATE-OF-PLAY L7,107,858-861,883-884,908-911,959,999,1019; AI-DIALOGUE L259-263; 4ee2b58a message L35-37,51 |
| C3 | `999af09f:deployment/LAWMAX-REPO-ONTOLOGY-MAP.sexp:14` `:gates 20`; `…MAP.md:14`; `LAWMAX-CONSOLIDATION-PLAN.md:9`; `deployment/verify/gate-registry.sexp:3` (the "25" I did not recount) |

No per-gate status claim in the matrix lacks commit-level evidence. The "would pass/fail at HEAD" statements are grep-derived and declared so (matrix U-5).

### 10.2 Findings

#### S-1 — P1 — WEAKENED — "a2f45f6d's 20 ck = the original 20 Option-A Full-Build gates" is stated as a SET identity; the evidence supports a CONCEPT identity with a different SCOPE
Claim attacked: archaeology §4 C1 / §5; matrix §0 title; my-gate-mapping.md title.
"Full build" = DDI-1…DDI-4 closure (all 66 classes in the model): D0160:8-12 (scope "core-complete", rest DDI); D0161:72 + STATE-OF-PLAY:883-884 ("DDI-1 BLOCKED — NOT FULL-BUILD COMPLETE"); D0161:13, D0162:12, STATE-OF-PLAY:908,959 ("option-1 / full-build closure" listed with DDI-1…4); D0164:10, STATE-OF-PLAY:1019 ("DDI-1…DDI-4, Επιλογή Α και τα αρχικά 20 Full-Build gates" as one scope); 4ee2b58a GATE:230-231, packet:157-158 ("mandatory future stage after DDI-1…DDI-4").
The 20 ck commands byte-for-byte CANNOT be full-build gates: a2f45f6d GATE:94 (G20 requires `:status DEFERRED_DATA_IMPORT` present — absent by design after DDI-4, enum `MODEL-SCHEMA.sexp:56`); GATE:96 (G21 drops `V1.8-SCHEMAS__define-record`, an IMPORTED row after DDI-2); 4ee2b58a `build_deferred.py:75-80,236-239` (IMPORTED dict of 4 → `OVER-CLAIMED-IMPORT` for any full-build ledger). The numbering is external to the script: a2f45f6d `run_fixtures.py:5` "(gate 15)", `independent_check.py:2` "(gate 13-15)", packet:57 "(gate 15)", commit L24 "G19-G21"; D0160:4 quotes the order by title only; Review #1 attacked by `ck` label (D0161:31); [0161] calls the count 20 a coincidence (D0161:41-43; f04bf7e6 message L67-68,83).
Best-fitting reading: Option A = full build (DDI-1…4 closure) AND the SAME gate concepts G1…G21 (realised as 20 `ck` at 818b7dd9) demanded over the COMPLETE model — which is what the matrix `DDI` fields, U-3 and the orchestrator's "Caveat (decisive)" already describe but file as UNKNOWN. Archaeology C1 "Against (i)" calls the "future stage" wording a contradiction; under this reading it is the reconciliation.
Required correction: (i) restate the identification in all three documents as "SET = gate concepts G1…G21 realised as the 20 `ck` of GATE @ 818b7dd9; SCOPE = the full 66-class model after DDI-4"; (ii) label every matrix `ST` as "status over the CORE model" and promote `DDI` to the primary column; (iii) reword archaeology C1 "Against (i)" and drop "contradicted" from the §5 verdict sentence.

#### S-2 — P2 — CONFIRMED_DEFECT — orchestrator draft row 20 attributes X30 to the deferred ledger
`WORK/my-gate-mapping.md` row 20 names "K18, X30, G07". X30 = `X30-UNRECORDED-NORMALIZATION` (`4ee2b58a:AM/verification-corpus.sexp:182`), implemented by `f30_unrecorded_normalization` (`run_corpus.py:924-933`), which tampers `MODEL-MIGRATION-CONFLICT-LEDGER.md` and targets `conflict-ledger` (= `doc-01`, successor of G03). Correction: row 20 → K17 (`RC:788-798`), K18 (`RC:801-808`), G07 (`RC:1188-1209`); X30 belongs to row 3.

#### S-3 — P2 — CONFIRMED_DEFECT — matrix §3 and §4 use two different ancestry relations
§3 lists `hsh-01` under G05, `art-01` under G20, `ro-01` under G07, `enc-01`+`prv-01` under G13, `cor-01`+`uni-01` under G10-12; §4 marks all of them "NONE — new". Under §3's relation: 17 with ancestor + 4 new (`tch-01`, `gen-01`, `sea-01`, `tcb-01`); under §4's: 10 + 11 ("new_checks = 16"). Correction: define "primary seat" vs "auxiliary seat" once and compute both columns from it.

#### S-4 — P3 — WEAKENED — "PRESERVED" for G19 and G09a is looser than the matrix's own §1 rule
G19: a2f45f6d read a literal six-file `SOURCES` list (`build_deferred.py:18-19`) and regenerated before verifying (`GATE:91`); 4ee2b58a derives the universe from the inventory (`build_deferred.py:38-44`) and only verifies over an export (`GATE:205-208`) — input class changed → GENERALIZED by §1, giving 1+17+2. G09a: second measured file changed (`sha256.lisp` → `hash-provider.lisp`, F-11) and digesting left the counted path for an external program (`hash-provider.lisp:54`, `TCB-DECISION.md:12-16`; `GATE:180-181` "the LISP PATH's budget, NOT the total trusted computing base"). Correction: keep PRESERVED with both caveats on the cards, or move G19 to GENERALIZED (1+17+2); add to A-2 for the creator.

#### S-5 — P3 — CONFIRMED_DEFECT (stale) — archaeology A-6 / §2.6 already resolved
`WORK/gate-lineage.md` (mtime 20:23:04, after report.md 20:22:37) lists 4 subsets and says "Acceptance subsets are FOUR". Correction: delete A-6 and the §2.6 sentence.

#### S-6 — P2 — REFUTED (attack failed) — per-gate statuses without commit-level evidence
All 20 cards' `W`, `NOW`, `L` and every "would pass/fail at HEAD" statement checked against `git show` at the named commits (see §0). None lacks evidence. The orchestrator draft cites finding IDs without lines (weaker, not invented).

#### S-7 — P2 — REFUTED (attack failed) — equation double-counts / ≠ 20
PRESERVED {09a,19}; GENERALIZED {01,02,03,04,05,06,07,08,10-12,13,14,15,16,18,20,21}; MISSING {09b,17}: 2+16+2 = 20, each of the 20 `ck` names of `a2f45f6d:GATE` exactly once; orchestrator membership identical. Caveat (A-1): the equation is over `ck` calls; if Option A's "20" are order items (21 G-numbers), the universe differs.

#### S-8 — P1 — UNRESOLVED — who enumerated the options; the one external artefact required
The Review #1 report's TITLE already reads "OPTION-2 CORE @ 818b7dd9" (D0161:5), so the vocabulary was fixed no later than that report; "Επιλογή Α" occurs only in creator-facing records (D0164:10; STATE-OF-PLAY:1019); D0164:51-54 shows the creator's Review-4 order "anticipated «20»" (for the Option-2 count). Authorship is not provable from the clone; the BRIEF's "came from the external review report" is not evidenced in-repo.
Required artefact: the FIRST document that enumerated "Option 1 — Full build, all 20 gates / Option 2 — core": the Review #1 report "INDEPENDENT CANONICAL-MODEL CORE REVIEW — OPTION-2 CORE @ 818b7dd9" (delivered between 818b7dd9 2026-09-04 04:47:43Z and f04bf7e6 19:52:45Z) and, if not there, the creator's order «OPTION-2 CORE INDEPENDENT-REVIEW REMEDIATION — F-1…F-13 SYSTEMIC CLOSURE» (D0161:4). Question, verbatim: "In 'Option 1 — Full build, all 20 gates': (a) does 'Full build' mean DDI-1…DDI-4 closure — all 66 source classes imported into the canonical model? (b) does 'all 20 gates' denote the 20 `ck` checks of ARCHITECTURE-MODEL-GATE.sh at 818b7dd9 (numbered G1–G21 in its comments), to be passed over that full model — or a different list? (c) if different, its members; (d) was this enumeration written by the independent reviewer or by you?" Secondary (settles A-3 only): the [0160] order «FINAL VERIFIER-REGRESS EXIT PASS — …» (D0160:4), source of the G1…G21 numbering.

#### S-9 — P3 — REFUTED (attack failed) — reconstruction from imagination
Non-repo inputs are limited to: matrix `AC` for 09b/17 ("(would be) … NONE at 4ee2b58a"); the finding→gate mapping (declared A-8); archaeology C2 (declared hypothesis); `WORK/orchestrator-notes.md` N1/N2/N4/N6 (exist at L3,12,18,22). No list, gate name, order or review text was invented; the Option-A list is consistently reported NOT-IN-REPO.

### 10.3 Net effect
Keep the lineage table and the 20 cards; relabel the identification and the ST scope (S-1); fix X30 (S-2); unify ancestry (S-3); decide PRESERVED for G19/G09a (S-4); drop A-6 (S-5); put S-8's verbatim question at the top of the creator packet.

