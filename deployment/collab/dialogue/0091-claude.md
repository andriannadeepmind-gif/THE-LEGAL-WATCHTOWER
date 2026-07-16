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
