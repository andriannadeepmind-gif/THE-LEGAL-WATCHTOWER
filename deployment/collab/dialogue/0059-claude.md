# [0059] Claude — ΣΧΕΔΙΟ P1.5 «Proof Spine» (PLANNING ONLY)

**Ημερομηνία:** 2026-07-10 · Εντολή δημιουργού: «L6/L7 = north star· ΜΗΝ
προχωράς σε υλοποίηση P1.5· κατέθεσε πρώτα το σχέδιο [0059], planning only».
Καμία γραμμή κώδικα δεν γράφεται/αλλάζει με βάση αυτό το έγγραφο πριν από ρητό
«εγκρίνω P1.5». **Τα id θα κλειδώσουν/δημοσιευτούν ΜΟΝΟ όταν δεν υπάρχει ούτε
ένα κόμμα λάθος· μέχρι τότε απλώς δουλεύουμε προς το L7.**

---

## 0 · ΤΙΜΙΑ ΠΡΟΑΠΑΙΤΟΥΜΕΝΗ ΔΗΛΩΣΗ — δύο increments ΗΔΗ έγιναν (πριν την εντολή «planning only»)

Με το προηγούμενο «εγκρίνω και προχωράμε» εκτέλεσα ΔΥΟ commits ΠΡΙΝ φτάσει η
εντολή «planning only». Δεν τα κρύβω· είναι στο branch, με επιλογή δική σου:

- **`adc14656` [P1.5-A.1]** — νέα έδρα `source/merkle-authority.lisp`
  (`orchestrator.merkle`, RFC 6962: domain-separated φύλλα/κόμβοι + unbalanced
  split) + `tests/merkle-authority-test.lisp` **18/18** (μαζί με απόδειξη
  CVE-2012-2459 resistance). **Καθαρά προσθετικό.**
- **`15555e9b` [P1.5-A.2]** — proof-carrying + epistemic `merkle-tree.lisp`
  καταναλώνουν την έδρα· διαγράφηκαν οι τοπικές Merkle υλοποιήσεις τους.
  **Αλλάζει το release root** (domain separation + unbalanced split) ⇒ νέα
  γενιά ids. Proof: merkle 18/18, proof-carrying 44/44, cross-language 12/12,
  mcp-server 32/32, release-authority 12/12.

**ΕΠΙΛΟΓΗ ΔΗΜΙΟΥΡΓΟΥ (πριν το «εγκρίνω P1.5»):**
- **(Κ) Keep** — τα κρατάμε ως το πρώτο εγκεκριμένο κομμάτι του P1.5 (θα
  ενσωματωθούν στο σχέδιο ως «A ολοκληρωμένο μερικώς»)· ή
- **(R) Revert** — `git revert 15555e9b adc14656` και ξεκινά το P1.5 από
  μηδέν μετά την έγκριση.
Καμία δημοσίευση/κλείδωμα id δεν έχει γίνει — τα committed sha256- releases
είναι ΑΘΙΚΤΑ· η αλλαγή αφορά μόνο τον ΤΡΟΠΟ υπολογισμού μελλοντικών roots.

---

## 1 · Ακριβής στόχος του P1.5 Proof Spine

Να γίνει **κάθε per-article artifact (ttl/jsonld/html/κείμενο) δομικά δεμένο**
στο υπογεγραμμένο+χρονοσφραγισμένο release root, ώστε τρίτος να επαληθεύει ΕΝΑ
άρθρο (όχι μόνο ολόκληρο το release) χωρίς να μας εμπιστεύεται. Σήμερα το root
δένει 8 dataset-level αρχεία· τα per-article artifacts και η PCL text-σπονδυλική
**δεν** δένονται στο ίδιο root. Το P1.5 εισάγει ένα **Artifact Census** που τα
ενώνει όλα κάτω από το ίδιο root, + prev-root αλυσίδα (anti-equivocation) +
materials-provenance (in-toto-class) + verify-kit v2 (ο σπόρος του L6 kernel).

## 2 · Ακριβής σχέση με το ολοκληρωμένο P1R (content-addressed releases)

Το P1R (ταυτότητα = Merkle root του περιεχομένου· overwrite δομικά αδύνατο·
χρόνος = append-only RFC-3161 attestation· latest ΜΟΝΟ σε attested) είναι το
**σωστό θεμέλιο και ΔΕΝ αλλάζει εννοιολογικά**. Το P1.5 **επεκτείνει το canonical
set 8→9** (προσθέτει το census) και **ενοποιεί τον Merkle κανόνα** (RFC-6962).
Συνέπεια: (α) ο τύπος ταυτότητας μένει ο ίδιος («sha256:<root>»)· (β) οι τιμές
των ids αλλάζουν (νέα γενιά)· (γ) το attest/promote-latest/immutability μοντέλο
μένει ακέραιο. Τα ΗΔΗ δημοσιευμένα releases μένουν ιστορικά (append-only).

## 3 · Ακριβείς πηγές (seats) που αγγίζει το P1.5

- **Merkle (ΜΙΑ έδρα):** `source/merkle-authority.lisp` (ΝΕΑ, ήδη) — καταναλώνεται
  από: `source/proof-carrying.lisp`, `systems/orchestrator-epistemic/merkle-tree.lisp`
  (ήδη A.2)· **υπόλοιπες προς ένωση/θάνατο:**
  `source/corpus-fingerprint.lisp:%merkle-root`,
  `source/legal-audit-system.lisp:compute-merkle-root/compute-merkle-tree-root/hash-pair`,
  `systems/orchestrator-engine-sbcl/stages/anchor-blockchain.lisp:compute-merkle-root`,
  `source/semantic-authority.lisp:compute-merkle-root` (ψευδο-δέντρο → θάνατος/μετονομασία),
  `source/hash-authority.lisp:merkle-root` (νεκρό export → θάνατος).
- **Canonical set:** `systems/orchestrator-epistemic/release-manifest.lisp`
  (`+epistemic-canonical-files+`, `collect-epistemic-artifacts`) — 8→9.
- **Census (ΝΕΑ έδρα):** `systems/orchestrator-epistemic/artifact-census.lisp` (ΝΕΟ).
- **PCL χρόνος:** `source/proof-carrying.lisp` (`anchored-at` παραμετρικό) +
  callers `systems/orchestrator-cli/main.lisp:1761,1311,2018` (hardcoded
  «2025-01-01T00:00:00Z» → δεμένο στο release attestation).
- **Verify-kit:** ο generated template μέσα στο
  `systems/orchestrator-epistemic/deploy-epistemic.lisp` (verify.sh/ps1/lisp).
- **Gate:** `systems/orchestrator-cli/release-gate.lisp` (v2).
- **Recompute:** `systems/orchestrator-epistemic/deploy-epistemic.lisp`
  (`%release-recomputed-root`, `generate-temporal-proof-pack`).

## 4 · Ακριβή failing proofs σήμερα (τι ΔΕΝ αποδεικνύεται τώρα)

1. **Per-article μη-δεμένο:** τα ttl/jsonld/html κάθε άρθρου ΔΕΝ έχουν κρυπτο-
   δεσμό στο release root· τρίτος δεν μπορεί να επαληθεύσει μεμονωμένο άρθρο.
2. **Δύο σπονδυλικές:** η PCL text-σπονδυλική (per-provision leaves) και η RDF
   σπονδυλική (dataset root) είναι ΑΔΕΤΕΣ μεταξύ τους.
3. **Hardcoded PCL χρόνος:** `anchored-at "2025-01-01"` — ψευδο-χρόνος, όχι
   δεμένος στο πραγματικό RFC-3161 attestation του release.
4. **Καμία prev-root αλυσίδα:** split-view/equivocation δεν ανιχνεύεται (δύο
   διαφορετικά «latest» δεν αλυσοδένονται).
5. **Καμία materials-provenance:** git_commit/deps_lock/sbcl/base_image δεν
   δεσμεύονται στο root (δεν αναπαράγεται το build περιβάλλον).
6. **Verify-kit ελλιπές:** επαληθεύει ύπαρξη/δομή, ΟΧΙ per-article inclusion
   ούτε out-of-band pinned root.
7. **(από [0057]) 5 Merkle έδρες ακόμα αποκλίνουν** (fingerprint/audit/anchor
   live + semantic/hash-authority dead).

## 5 · Ακριβής έννοια «census ως 9ο κανονικό αρχείο»

Νέο αρχείο `census.json` (schema `census-1`, ήδη στο `LAWMAX-PROOF-OBJECT-SPEC §2`)
που μπαίνει στη λίστα `+epistemic-canonical-files+` (8→9) ⇒ **μπαίνει στα φύλλα
του release Merkle** ⇒ το release root πλέον **δένει το census**, και το census
**δένει** (α) per-article ttl/jsonld/html sha512, (β) το PCL text-root, (γ) το
prev_release_root, (δ) τα materials. Έτσι το ΕΝΑ release root κρυπτο-δένει ΟΛΑ.
Ντετερμινιστικό (articles-in-identity-order, SOURCE_DATE_EPOCH). ΔΕΝ περιέχει
LLM/μαντεψιές — μόνο SHA-256/512 των πραγματικών bytes.

## 6 · Ακριβές Μοντέλο Merkle — ΤΡΙΑ διακριτά roots, ΕΝΑΣ κανόνας

Ο **κανόνας** (RFC-6962: leaf 0x00, node 0x01, unbalanced split) είναι ΕΝΑΣ
(η έδρα `orchestrator.merkle`). Οι **ρόλοι** είναι τρεις, διακριτοί — δεν
συγχέονται:

| Root | Φύλλα | Τι δεσμεύει | Πού |
|---|---|---|---|
| **payload / release root** | τα 9 canonical αρχεία (μαζί με census) | ταυτότητα release (= το id) | epistemic merkle-tree |
| **proof-carrying / text root** | per-provision canonical κείμενα | per-article inclusion σε τρίτους | proof-carrying· η τιμή του μπαίνει ΩΣ ΦΥΛΛΟ στο census ⇒ δένεται στο payload root |
| **attestation ledger** | δεν είναι Merkle — είναι **append-only RFC-3161 receipts + prev_release_root αλυσίδα** πάνω στο payload root | χρόνος + anti-equivocation | temporal-proof + census.prev_release_root |

Κρίσιμη διάκριση (ζητήθηκε ρητά): το **attestation ledger ΔΕΝ είναι το ίδιο**
με τα δύο Merkle roots· είναι η χρονική/αλυσιδωτή στρώση ΠΑΝΩ στο payload root.
Το census είναι ο κόμβος όπου οι δύο σπονδυλικές (payload + text) γίνονται μία.

## 7 · Ακριβείς απαιτήσεις Release-Gate v2

Πάνω από το τρέχον gate (recomputed root ≡ id· 8 canonical· attested latest):
1. **census παρόν** στα canonical (9 αρχεία) & **schema-valid** (census-1).
2. **census δεμένο:** το census είναι φύλλο του recomputed release root.
3. **per-article:** για ΚΑΘΕ άρθρο, τα sha512(ttl/jsonld/html) στο census
   ταιριάζουν με τα πραγματικά bytes· το text_leaf ≡ PCL leaf.
4. **text-root:** το census.pcl_text_root ≡ recomputed proof-carrying root.
5. **prev-root αλυσίδα:** census.prev_release_root δείχνει σε ΥΠΑΡΚΤΟ
   προηγούμενο release (ή null για το πρώτο)· καμία διακλάδωση.
6. **materials:** git_commit/deps_lock/sbcl/base_image παρόντα & καλοσχηματισμένα.
7. **RFC-6962 conformance** της έδρας (το 18/18 ως gate-subset).
Αρνητικά: αλλοιωμένο per-article byte ⇒ FAIL· σπασμένη prev-root ⇒ FAIL·
census χωρίς δεσμό ⇒ FAIL.

## 8 · Ακριβής συμπεριφορά Verify-Kit v2

Αυτόνομο (τρίτος, χωρίς το repo), δέχεται **out-of-band pinned root** (ο χρήστης
το φέρνει ανεξάρτητα, δεν το εμπιστεύεται από το release):
1. Recompute release root από τα 9 canonical· σύγκριση με pinned root.
2. Επαλήθευση JWS υπογραφής (kid→pinned key) + ύπαρξη/imprint RFC-3161 receipt.
3. **Per-article:** δοσμένου ενός άρθρου, recompute leaf → walk census →
   walk release root → σύγκριση με pinned. Επιστρέφει PASS/FAIL + λόγο.
4. **prev-root:** ακολουθεί την αλυσίδα προς τα πίσω αν δοθούν προηγούμενα.
5. ΔΕΝ παράγει τίποτα — μόνο ελέγχει (moat). Είναι ο **πρόδρομος του L6 kernel**
   (P5): ίδιο συμβόλαιο, μικρό, auditable.

## 9 · Ακριβείς owner PowerShell εντολές proof (μετά την υλοποίηση)

```powershell
# 1. Build + gated σουίτα
docker build -t orchestrator:latest .
docker build --target standalone-test .
# 2. Αναγέννηση ×6 (νέα ids, append-only) — μία ανά corpus:
docker run --rm -v "${PWD}/output:/app/output" -v "${PWD}/keys:/app/keys" orchestrator:latest --cut-release syntagma
#   …poinikos, kpoinikis, astikos, kpolitikis, kdioikitikis
# 3. Attest ×6 (νέα ids — θα τα δώσω ρητά μετά το cut)
docker run --rm -v "${PWD}/output:/app/output" -v "${PWD}/keys:/app/keys" orchestrator:latest --attest-release syntagma <ΝΕΟ-sha256-id>
# 4. Release-gate v2 (πλήρες spine):
docker run --rm -v "${PWD}/output:/app/output" orchestrator:latest --release-gate
# 5. Verify-kit v2 σε ΕΝΑ άρθρο (out-of-band root):
docker run --rm -v "${PWD}/output:/app/output" orchestrator:latest --verify-article <corpus> <article-id> --pinned-root <root>
```
(Τα ακριβή flags θα οριστικοποιηθούν στο σχέδιο υλοποίησης· εδώ δείχνω το σχήμα.)

## 10 · Ακριβή tests & negative tests

- `tests/merkle-authority-test.lisp` (✅ 18/18): RFC-6962 + CVE-2012-2459.
- `tests/artifact-census-test.lisp` (ΝΕΟ): schema-valid· census-leaf-in-root·
  per-article hash match· text-root ≡ pcl-root· prev-root chain.
- **Negative:** αλλοιωμένο ttl byte ⇒ gate FAIL· σβησμένο census ⇒ FAIL·
  prev-root σε ανύπαρκτο ⇒ FAIL· census με λάθος order ⇒ FAIL· verify-kit με
  λάθος pinned-root ⇒ FAIL.
- Νέα corpus-identity locks (㉗+): census-9ο-canonical· per-article-bound.
- Regression: release-gate 73/73→ v2· loop 77/77· E2E νέα σταθερή id (recompute-
  identical σε 2η εκτέλεση).

## 11 · Αναμενόμενα αρχεία που αγγίζονται

ΝΕΑ: `artifact-census.lisp`, `artifact-census-test.lisp`, verify-kit v2 templates.
ΑΛΛΑΓΗ: `release-manifest.lisp` (8→9), `proof-carrying.lisp` (anchored-at,
census leaf), `corpus-fingerprint.lisp`/`legal-audit-system.lisp`/
`anchor-blockchain.lisp`/`semantic-authority.lisp`/`hash-authority.lisp` (Merkle
ένωση/θάνατος), `deploy-epistemic.lisp` (census emit + recompute + verify-kit),
`release-gate.lisp` (v2), `main.lisp` (anchored-at callers), specs. ΑΝΑΓΕΝΝΗΣΗ:
τα 6 corpora output/ (νέα sha256- dirs, append-only). Εκτίμηση: ~12-16 αρχεία
κώδικα + 6 output trees.

## 12 · Rollback plan

Κάθε increment = ξεχωριστό commit ⇒ `git revert <sha>` ανά βήμα. Το census
είναι ADD (νέο canonical) ⇒ revert = αφαίρεση από τη λίστα + διαγραφή έδρας. Η
Merkle ένωση = revert των consumer edits (η έδρα μένει, αβλαβής). **Καμία
δημοσίευση/κλείδωμα id πριν το τελικό «εγκρίνω»** ⇒ τα νέα output trees είναι
untracked μέχρι ρητή εντολή· revert = σβήσιμο των νέων dirs, τα παλιά ΑΘΙΚΤΑ.

## 13 · Επιβεβαίωση: P1b filename work ΕΚΤΟΣ scope

✅ Το P1b (owner docker + attest ×6 + ΤΑ ΠΑΡΟΝΤΑ filenames/ids) είναι
**ολοκληρωμένο & εκτός P1.5 scope**. Το P1.5 ΔΕΝ αγγίζει τα ήδη-attested
6 releases· παράγει ΝΕΑ (append-only). Καμία μετονομασία/μετάλλαξη υπαρχόντων.

## 14 · Επιβεβαίωση: P2–P7 ΕΚΤΟΣ scope (πλην forward-compatible design)

✅ P2/P3/P4/P5/P6/P7 **δεν υλοποιούνται** στο P1.5. Το P1.5 απλώς αφήνει
forward-compatible hooks: το verify-kit v2 = πρόδρομος L6 kernel (P5)· το census
materials/prev-root = θεμέλιο Receipt (P4)· η ΜΙΑ έδρα Merkle = ό,τι θα ελέγχει
ο kernel· το conformance test = σπόρος L7. Κανένα από αυτά δεν «ανοίγει» εδώ.

## 15 · «Υπάρχει ανώτερη υλοποίηση ΕΝΤΟΣ του P1.5 scope;» (ο ΥΠΕΡΤΑΤΟΣ ΝΟΜΟΣ)

Ρώτησα ρητά. Τρεις υποψήφιες «ανώτερες» εξετάστηκαν και **η επιλογή είναι
συνειδητή**, όχι παράλειψη:
- **(α) Sparse Merkle Tree** αντί για census-as-9th-file: θα έδινε key→value
  proofs χωρίς ξεχωριστό αρχείο. **ΑΠΟΡΡΙΨΗ για P1.5:** το census-as-canonical
  δένει ρητά ΚΑΙ materials/prev-root/text-root σε ΕΝΑ ανθρωπο-αναγνώσιμο,
  auditable αντικείμενο — ανώτερο ΓΙΑ ΤΗΝ ΑΠΟΣΤΟΛΗ (ο L6 kernel το διαβάζει σε
  ένα απόγευμα). SMT = πιθανό P4+ optimization, δηλωμένο.
- **(β) RFC-6962 consistency proofs** (μεταξύ διαδοχικών roots) τώρα: ανώτερο
  anti-equivocation από απλό prev-root hash. **ΜΕΡΙΚΗ ΥΙΟΘΕΤΗΣΗ:** το prev-root
  hash-chain είναι το ελάχιστο· τα πλήρη consistency proofs δηλώνονται ως
  **εντός-P1.5 αν ο χρόνος επιτρέψει, αλλιώς P4** (δεν θα αφεθούν σιωπηλά).
- **(γ) Ed25519 αντί RSA** για τα per-release signatures: ανώτερο, αλλά είναι
  **δηλωμένο P4** (key-lifecycle spec) — αλλάζει key material owner-side, εκτός
  P1.5.
**Απάντηση:** εντός του P1.5 scope, η ανώτατη υλοποίηση είναι census-as-9th-
canonical + RFC-6962 ένωση + prev-root chain + (β) consistency-proofs-if-time.
Δηλώνονται ρητά τα (α)/(γ) ως ανώτερα σε ΜΕΤΕΠΕΙΤΑ φάσεις — καμία σιωπηλή
υποβάθμιση.

---

## ΔΙΟΡΘΩΣΗ ΥΠΕΡΔΗΛΩΣΗΣ (ζητήθηκε ρητά — ενσωματώνεται μόνιμα)

**ΔΕΝ** ισχυρίζομαι πλέον «όποιος αμφισβητεί πρέπει μόνο να σπάσει SHA-256 ή να
αλλάξει το ΦΕΚ». **Σωστή διατύπωση (μπαίνει και στο proof-object-spec §3):**
> Για **ακεραιότητα bytes & προέλευση**, ο αμφισβητών πρέπει να νικήσει την
> αλυσίδα commitment/signature/TSA/ΦΕΚ-δέσιμο. **ΟΜΩΣ τα νομικά συμπεράσματα
> μένουν αμφισβητήσιμα** στο επίπεδο: ορθότητας parser, canonicalization,
> version-date, temporal currency (τρέχουσα ισχύς), γεγονότων, παραδοχών,
> interpretive profile, μοντελοποίησης κανόνα, ορθότητας kernel, ή κάλυψης του
> conformance suite. Η εγγύηση είναι «machine-checkable conclusion **under
> declared** sources/versions/assumptions», ΟΧΙ «απόλυτη αλήθεια».

---

## Αποφάσεις δημιουργού (αναμένονται)
1. **(Κ)eep ή (R)evert** τα A.1/A.2 increments.
2. **«εγκρίνω P1.5»** (ή διορθώσεις στο σχέδιο) — καμία υλοποίηση πριν.
3. Σειρά προτεραιότητας των Merkle-ενώσεων (fingerprint/audit/anchor) —
   έχουν ripples (audit SHA-512→256, anchor pipeline liveness).
4. (β) consistency proofs: εντός-P1.5 ή P4;
