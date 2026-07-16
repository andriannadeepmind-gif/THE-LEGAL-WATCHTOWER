# [0091] Π7-U.1 — UNIVERSAL SOURCE CONTRACT (v2, μετά από 2 κριτές)

**Ημερομηνία:** 2026-07-16. **Branch:** `claude/p7u-universal-source-contract`
(νέο, από το εγκεκριμένο `b87f7d8b`). **Εντολή δημιουργού:** «Εγκρίνω την
έναρξη του Π7-U — UNIVERSAL LEGAL SOURCE AND REALITY INGESTION» — καθολική
versioned μηχανή εισαγωγής ΟΛΗΣ της έννομης τάξης, ΟΧΙ ειδικός importer 9 ΦΕΚ.
Πρώτο παραδοτέο: Π7-U.1 contract ΠΡΙΝ από κάθε download. #4A/B/C FROZEN,
GAAF-1 + reasoning layers παγωμένα.

## Παραδοτέο

`deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` (v2) — και τα 9 σημεία της
εντολής:

1. **`legal-source/1`**: FRBR-ισομορφική 4-επίπεδη ταυτότητα
   (work/expression/manifestation/item)· ΟΛΑ τα ids παράγωγα (canonical-hash
   επί κλειστών θεσμικών γεγονότων)· URL/format/χρόνος λήψης/connector ΔΕΝ
   συμμετέχουν ποτέ. Το work_id = ΣΥΝΑΡΤΗΣΗ της υπάρχουσας έδρας
   orchestrator.identity (make-body) όπου αυτή καλύπτει — καμία δεύτερη έδρα.
2. **Τυπολογίες ως versioned data registries** (source-class, authority,
   jurisdiction, relation-kind, formations) κατά το υπάρχον πρότυπο
   body-kind/instrument-kind-registry — με το key-shape ΜΕΣΑ στην εγγραφή:
   η κλάση «enum χωρίς key-shape» πεθαίνει δομικά. Authority registry
   διτεμπορικό (ταυτότητα από ιδρυτικό γεγονός, lineage με
   abolished/re-established/competence-transferred, genesis ακολουθία).
3. **Έξι τύποι κόμβων** (document/act/provision/version/judgment/
   interpretation) με type-guarded σχέσεις (λάθος τύπος άκρου = σφάλμα
   γέννησης record).
4. **Immutable raw artifacts**: content-addressed, append-only, read-back,
   επιζούν και επί αποτυχίας parsing· φορά δεικτών receipt→artifact
   (many-to-one, injective ταυτότητα).
5. **Acquisition receipts** (hash-φέροντα, ΧΩΡΙΣ booleans, anchoring
   TSA/tlog δηλωμένα διαβαθμισμένο) + **official-location** ως journaled
   observations (παράγωγη προβολή, όχι hash-φέρον container) + γέφυρα
   item→manifestation ΣΤΟ extraction-receipt/2.
6. **Σχέσεις σε ΔΥΟ οικογένειες**: text-mutating ⇒ ΜΟΝΟ version-graph events
   (+ instrument/regime events της υπάρχουσας έδρας)· non-mutating ⇒
   `legal-relation/1` ως JOURNAL KIND του ΙΔΙΟΥ journal — ατομικότητα δομική,
   όχι cross-store ευχή. Kinds: interprets, annuls, declares-unconstitutional
   (erga-omnes ΑΕΔ/incidenter), suspends-effect, authorizes-delegation,
   resolves-pilot-question (ν. 3900/2010), precedent-follows/distinguishes,
   codifies (legislative/administrative). Βάση ΜΟΝΟ explicit-citation/
   operative-part — ΠΟΤΕ inferred, κανένα LLM στο trusted path.
7. **Connector = ΔΥΟ συμβόλαια**: `acquirer/1` (impure, μόνο
   artifacts+receipts+observations) / `parser/1` (pure, determinism-gated,
   μόνο canonical objects + uncertainty)· προτάσεις-όχι-εγγραφές μέσω
   admit-edge!· journaled απόρριψη· κοινά conformance vectors gated.
8. **`uncertainty/1`** πρώτης τάξης — 12 kinds (+official-sources-conflict,
   pending-ratification, commencement-unresolved, authenticity-pending)·
   θάνατος μόνο με evidence ή απόφαση δημιουργού, journaled.
9. **Μηδέν ΦΕΚ-ειδικά σχήματα**: gate με ρητή λίστα αρχείων· τα προϋπάρχοντα
   `:fek-date`/`:fek-ref` της σπονδυλικής στήλης = ΔΗΛΩΜΕΝΑ υπόλοιπα με
   μελλοντική versioned φάση μετονομασίας. Τα 9 ΦΕΚ = πελάτης του καθολικού.

## ΔΥΟ ΑΝΤΙΠΑΛΙΚΟΙ ΚΡΙΤΕΣ (v1 → v2) — ΟΛΑ τα ευρήματα κλειστά ονομαστικά

**Κριτής νομικής ταυτότητας/πηγών (5 CRIT + 6 SERIOUS + 3 MINOR + 1 NIT):**
- CRIT-1 official_key μόνο για 6/16 κλάσεις (Σύνταγμα/ΠΔ/ΥΑ χωρίς ταυτότητα!)
  ⇒ key-shapes ΜΕΣΑ στο registry, gated load, 1-1 δομικά.
- CRIT-2 ΚΥΑ πολλαπλών εκδοτών vs ενικό authority_id ⇒ authority_ids =
  κανονικά ταξινομημένο σύνολο.
- CRIT-3 ΠΝΠ απούσες (κλάση+κλειδί+κύρωση) ⇒ emergency-legislative-act
  {promulgation_date, gazette_ref} + κύρωση μέσω ΥΠΑΡΧΟΝΤΟΣ :ratification
  instrument event + :expire regime επί μη κύρωσης.
- CRIT-4 ΔΕΥΤΕΡΗ έδρα ταυτότητας δίπλα στο make-body + δεύτερο μητρώο ειδών
  ⇒ work_id ΩΣ ΣΥΝΑΡΤΗΣΗ body_id· source-class registry ΕΠΕΚΤΕΙΝΕΙ την
  υπάρχουσα οικογένεια με δηλωμένη body-kind απεικόνιση· enums → registries.
- CRIT-5 formation ελεύθερο string (3 ids για μία ΣτΕ Ολ) ⇒ registry-backed
  keyword ανά δικαστήριο + numbering unified/per-formation ΣΤΗΝ εγγραφή
  + διάκριση judgment/βουλεύματος/πρακτικού.
- S-6 κώδικες ⇒ μέσω :kodikas + ratifies/codifies (typed νομοθετική/
  διοικητική)· S-7 λείπουσες σχέσεις ⇒ authorizes-delegation,
  declares-unconstitutional{scope}, suspends-effect, resolves-pilot-question·
  S-8 αποδοχή ΝΣΚ ⇒ :acceptance instrument event· S-9 treaty κλειδί χωρίς
  depositary ⇒ {parties, conclusion_date, authentic_title_sha256}· S-10
  authority lineage/kinds/pre-corpus-founding (ΑΠ 1834)· S-11 uncertainty
  kinds ×4· M-12/13/14 jurisdiction registry, protocol registry_series,
  CELEX-για-όλα-τα-eu· NIT-15 grep gate με ρητό πεδίο.

**Κριτής αρχιτεκτονικής/provenance (4 CRIT + 6 SERIOUS + 3 MINOR/NIT):**
- CRIT-1 «pure» connector που κάνει fetch ⇒ ΔΙΑΣΠΑΣΗ acquirer/1 (impure) /
  parser/1 (pure, determinism-gated) με disjoint emits.
- CRIT-2 booleans σε hash-φέρον record (απαγορευμένα από την canonical spec)
  ⇒ integers 0/1 παντού.
- CRIT-3 «ΜΙΑ συναλλαγή» σε δύο stores = ευχή ⇒ legal-relation ως journal
  kind ΤΟΥ ΙΔΙΟΥ journal — atomic append δομικά· relation store = replay
  προβολή· ορφανό μισό = journal-corruption στο replay.
- CRIT-4 αποσιωπημένες 4 μερικές έδρες (source-profile acquired-record +
  ιδιωτικό %canonical, document-fetch ΦΕΚ, government-source, corpus-
  provenance PROV-O) ⇒ ΠΙΝΑΚΑΣ ΜΕΤΑΒΑΣΗΣ §0.2 κατά [0045] (B→Π7-U.2/U.3,
  PROV-O = A/εξαγωγική προβολή).
- S-5 receipt δείκτης μέσα στο artifact (μη-injective) ⇒ φορά
  receipt→artifact + admission invariant· S-6 «υπάρχοντα gates» ⇒ espec ≡
  proposal schema, authority gate ΔΗΛΩΜΕΝΟ παραδοτέο Π7-U.2· S-7 bootstrap
  κύκλος authority↔work ⇒ journaled genesis ακολουθία· S-8 κενό
  item↔manifestation ⇒ extraction-receipt/2· S-9 typed-partial dates χωρίς
  encoding ⇒ ISO-8601 reduced-precision strings + vectors (Π7-U.2, πριν από
  κάθε hash χρήση)· S-10 «registry_digest στο authority-statement» θα
  παραβίαζε το FROZEN #4 ⇒ δέσμευση ΜΕΣΩ CENSUS, φράση διαγράφηκε· M-11
  grep ψευδο-ακριβές + :fek-date ΗΔΗ στο σχήμα ⇒ ρητή λίστα + δηλωμένο
  υπόλειμμα με φάση μετονομασίας· M-12 tsr path ⇒ digest· M-13
  official-location ⇒ journaled observations, container ΜΗ hash-φέρον.

## Κατάσταση

Commits: `e39e3fea` (v1 draft) → v2 (παρόν commit). **Αναμένεται: ρητό
«εγκρίνω Π7-U.1».** Μόνο μετά: Π7-U.2 (typed-partial canonical vectors,
extraction-receipt/2, authority gate, proposal schemas, conformance vectors,
gr-gazette acquirer+parser) → benchmark 9 ΦΕΚ ως πελάτης του καθολικού.
Κανένα download, κανένας connector μέχρι τότε. #4 + GAAF-1 FROZEN.

---

## [0091+] Π7-U.1A — v3 (9 ευρήματα δημιουργού) → 2 ΝΕΟΙ κριτές → v4

**Εντολή δημιουργού:** v2 = ΙΣΧΥΡΟ DESIGN CANDIDATE, ΟΧΙ έγκριση· 9 ευρήματα
[Δ-1..Δ-9] + απαίτηση 2 νέων κριτών + ονομαστικός negative witness ανά
finding. Ρητά: «Εγκρίνω #4» (κατατέθηκε στο κύριο branch, eb631750)·
Π7-U.2 ΠΑΓΩΜΕΝΟ· GAAF-1 ΠΑΓΩΜΕΝΟ.

**v3 (ad73fc63):** κλείσιμο Δ-1..Δ-9 με W-Δ1..9 — expression/1 sum type
(provision/work-snapshot με cut+RFC-6962 root/single-document)·
manifestation δεσμεύει expression_id· work ≡ body identity (θάνατος 2ου
work_id, issuance facts εκτός ταυτότητας)· registry identity-projectors
(ταξινόμηση ποτέ σε hash)· authority_id από founding_locator+entity_key
χωρίς kind· journal-batch/1 (ένα seq/payload/chain transition)· disjoint
source-work tagged sum· consolidation normative/derived με evidence mode·
raw-artifact μόνο εγγενή + blob↔receipt recovery.

**ΚΡΙΤΗΣ IDENTITY/FRBR/EXPRESSION COLLISION (3 CRIT + 5 SERIOUS + 3 MINOR +
1 NIT — δείκτες [Κ-x], όλα κλειστά στο v4):**
- Κ-C1 ΔΙΠΛΗ οδός ΥΑ/EU (body-kind :ya/:eu-* ΚΑΙ projectors) ⇒ invariant
  ΜΙΑΣ οδού (XOR, gated load) + registry φάση αφαίρεσης §0.2β + W-K1.
- Κ-C2 provision_set_root όχι συνάρτηση του (work,cut): το cut καθηλώνει
  known όχι valid (snapshot-at διτεμπορική)· λείπει leaf encoding ⇒
  valid_at ΣΤΟ schema + σύνολο = ακριβές output snapshot-at + canonical
  JSON leaf + excluded_uncertain + W-K2.
- Κ-C3 άχρονο gr/syntagma ⇒ επανίδρυση οργάνου = ΙΔΙΟ authority_id ⇒
  version_pin στο founding_locator + W-K3.
- Κ-S4 entity_key ελεύθερη επιλογή / locator tri-type χωρίς tag ⇒ κανόνας
  προτεραιότητας + tagged union + W-K4· Κ-S5 μονο-διατακτικό work διπλή
  expression ⇒ δηλωμένη μέρος/όλον διάκριση + παραγώγιμη ισοδυναμία + W-K5·
  Κ-S6 content_sha256 χωρίς normalization ⇒ §2 canonical spec ρητά + W-K6·
  Κ-S7 Rule-B χωρίς namespace/register ⇒ lsw1: + register-id ταυτοτικό +
  tagged work refs + W-K7· Κ-S8 ΠΝΠ ΦΕΚ Α΄68 ≥2 τριάδες ΑΠΟΔΕΔΕΙΓΜΕΝΑ ⇒
  typed gazette_ref + Rule-B works μόνο single-document + W-K8·
  Κ-M9 language ISO 639-1 κλειστός πίνακας + W-K9· Κ-M10 edition_facts
  απαριθμημένα + publisher tagged + W-K10· Κ-M11 make-body number guard
  ΣΤΗΝ έδρα + W-K11· Κ-NIT12 Συντακτικές Πράξεις = δηλωμένο όριο v1.

**ΚΡΙΤΗΣ JOURNAL ATOMICITY/LEGAL-EFFECT (4 CRIT + 4 SERIOUS + 2 MINOR +
1 NIT — δείκτες [Τ-x], όλα κλειστά στο v4):**
- Τ-C1 torn-tail ΣΥΓΚΟΛΛΗΣΗ στο υπάρχον append-line (crash μισογραμμένη
  γραμμή + επόμενο append = μόνιμο corruption) ⇒ §0.5.1 torn-heal/framing
  ΣΤΗΝ έδρα journal.lisp — BLOCKING προ-παραδοτέο Π7-U.2 + W-JB-TORN.
- Τ-C2 precondition εκτός lock = race→μόνιμο corruption (ζωντανός πρόγονος:
  %journal! υπολογίζει chain προ-lock, αγνοεί το last του chained-append)
  ⇒ compare-and-append ΥΠΟ το lock, typed stale-precondition + W-JB-RACE.
- Τ-C3 «journaled record» χωρίς δηλωμένο journal — το version-graph journal
  είναι per-body, ΔΟΜΙΚΑ ακατάλληλο για receipts ⇒ ΡΗΤΗ topology §0.3:
  version-graph journal (per-body) + corpus journal (ΕΝΑ)· cross-journal
  batch ΑΠΑΓΟΡΕΥΕΤΑΙ + W-J-TOPOLOGY.
- Τ-C4 4 συν-γεννήσεις εκτός batch (uncertainty+καραντίνα, work+issuance,
  expression+manifestation, reject+uncertainty) ⇒ ΕΞΑΝΤΛΗΤΙΚΟΣ πίνακας
  §0.4 (καραντίνα ≡ ανοιχτή uncertainty — η 2η σημαία δεν υπάρχει·
  expression/manifestation = παράγωγες ταυτότητες όχι γεγονότα) +
  W-COBIRTH-SWEEP.
- Τ-S5 fsync με ignore-errors = ψευδο-durable ⇒ §0.5.3 fsync honesty +
  W-FSYNC-LIE· Τ-S6 consolidation mode χωρίς κριτή/έδρα + ο κίνδυνος του
  δημιουργού (normative-ως-derived) χωρίς witness ⇒ mode-decision journaled
  record (decider: creator) + αντίστροφος δομικός φρουρός + W-Δ8β·
  Τ-S7 replay-υποχρέωση από ΜΕΤΑΒΛΗΤΟ registry + κανένα relation-retract ⇒
  registry digest pinned ΣΤΟ record + retract-σε-batch συμμετρικό +
  W-REG-PIN/W-REL-RETRACT· Τ-S8 κανένα write authority/rate ⇒ single-writer
  ανά journal + rejects δεσμεύουν digest + W-FLOOD· Τ-M9 subevent
  ids/σειρά/TILING κατανάλωση δηλωμένα + W-JB-SUB-ID· Τ-M10 κενό/nested
  batch reject + W-JB-NEST· Τ-NIT typed torn verdict.

**v4 = παρόν commit.** Συνολικό ιστορικό κριτών Π7-U.1: 2 (v1) + δημιουργός
(v2) + 2 (v3) = 5 αντιπαλικές επιθεωρήσεις, 44 ευρήματα, ΟΛΑ κλειστά
ονομαστικά με 31 named negative witnesses (§12). **ΑΝΑΜΕΝΕΤΑΙ: τελικό
«εγκρίνω Π7-U.1».** Π7-U.2 ΠΑΓΩΜΕΝΟ (με §0.5 journal fixes ως BLOCKING
πρώτα παραδοτέα). #4 CLOSED. GAAF-1 ΠΑΓΩΜΕΝΟ.
