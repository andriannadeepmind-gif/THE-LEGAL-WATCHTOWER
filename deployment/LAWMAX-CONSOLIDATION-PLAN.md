# LAWMAX CONSOLIDATION PLAN
**Ontological Closure Audit, μέρος 2/2 — ΟΧΙ νέα features.** Μόνο: τι υπάρχει,
τι είναι διπλό, τι είναι bootstrap, ποια είναι η κανονική έδρα, τι συγχωνεύεται,
τι απαγορεύεται. Κάθε γραμμή με evidence (αρχείο/μητρώο)· επιβολή: το
`--architecture-constitution-gate` κοκκινίζει σε ό,τι αποκλίνει από το Σύνταγμα.

## 1. Τι υπάρχει (επιβεβαιωμένο από ζωντανό dump + πηγή)

150 εντολές · 20 πύλες · 29 ικανότητες · 40 συμβόλαια · 494 συστατικά ·
135 πακέτα · 6 ASDF συστήματα. **26 persistent stores** εντοπισμένα
(απογραφή με writer+role ανά store· τα 8 κανονικά κρίσιμα δηλωμένα στο
Σύνταγμα `:canonical-stores`, τα υπόλοιπα είναι corpus/build artifacts ή
cursors — βλ. §4).

## 2. Δηλωμένη πολλαπλότητα (ΜΕ αιτιολόγηση — Σύνταγμα `:justified-multiplicity`)

| Περιοχή | Υλοποιήσεις | Ετυμηγορία |
|---|---|---|
| Ταξινομητές διαλόγου (9) | learned-understanding → conversation → self → legal → narrative → proof-quest → act-horizon → floor → general-tail | ΔΙΚΑΙΟΛΟΓΗΜΕΝΟ: ένας dispatcher (decompose), διατεταγμένη αλυσίδα· μαθημένοι πρώτοι |
| Κανονικοποίηση κειμένου | `%fold` (1:1 ταύτιση) vs `normalize-greek` (παραπομπές) | ΔΙΚΑΙΟΛΟΓΗΜΕΝΟ με ΧΡΕΟΣ Π3: ενιαία τεκμηρίωση ορίων χρήσης — ήδη 2 bugs από σύγχυση ς/σ |
| Μνήμες αποτυχίας | lessons.jsonl (aggregate) / failure-ledger.jsonl (δομημένο) / episodes.sexp (βίωμα) | ΔΙΚΑΙΟΛΟΓΗΜΕΝΟ: διακριτοί ρόλοι, κοινή εποπτεία (gap-ledger-frame) |
| Μητρώα προτάσεων | Σ11 proposals (γνώση) vs whatif change-proposals | ΔΙΚΑΙΟΛΟΓΗΜΕΝΟ: διαφορετικά αντικείμενα, ΜΙΑ απόφαση (can-adopt) |
| Επιφάνειες διαλόγου | --ask/--ρώτα · /chat+/ask (--serve) · MCP tools | ΔΙΚΑΙΟΛΟΓΗΜΕΝΟ: όλες → run-ask/providers (δεδικασμένο 08a93db6) |
| Ταυτότητα άρθρων | canonical-article-id (τύπος) / legal-id-registry / canonical-uris | **ΧΡΕΟΣ Π2 — υποψήφια συγχώνευση τεκμηρίωσης** (βλ. §5) |


## 2β. Ευρήματα εξαντλητικής σάρωσης (candidates — evidence: ονομασμένες υλοποιήσεις ανά περιοχή· επικύρωση πριν από κάθε πράξη)

| Ρίσκο | Περιοχή | Σύσταση |
|---|---|---|
| HIGH | Accent/κανονικοποίηση: >2 υλοποιήσεις accent-map (%fold, fold-greek, legal-id, content-validation) | ΕΝΑΣ εξαγόμενος accent map — όλα τα fold πάνω του (Π6) |
| HIGH | **Το ζωντανό «δεν κατάλαβα» του run-ask ΔΕΝ τροφοδοτεί ακόμη το failure-ledger** (μόνο %lesson) | Π0: μία γραμμή record-dialogue-failure! — ΛΕΙΤΟΥΡΓΙΚΗ αλλαγή ⇒ εκτός αυτού του pass, ζητά έγκριση |
| HIGH | Τρία άσχετα πράγματα λέγονται «proposal» (Σ11/whatif/review) | Ενιαία ονοματολογία+ids στην τεκμηρίωση — όχι συγχώνευση μηχανών (Π2β) |
| HIGH | Ταυτότητα άρθρων: raw numbers/eIds/graph ids/URIs παράλληλα | Επιβεβαιώνει το Π2 — εκτέλεση ΜΟΝΟ μέσω εγκεκριμένης Φάσης 2 |
| MED | +law-tag-corpus-map+ / +tag-full-names+ χειρόγραφα δίπλα σε configs | Παραγωγή από τα configs (Π7) |
| MED | Αδρανές orchestrator.session store | Απόσυρση ή ένταξη ως Η μία session μνήμη (Π5) |
| MED | Πολλαπλές γραμματικές εξαγωγής παραπομπών | Σύγκλιση γραμματικής αριθμού-άρθρου (Π8) |
| MED | search-corpus prefix-match ≠ διαλογικό lemma-match | Ενιαίο lexical matching (Π9) |
| LOW | Αριθμητική / γράφοι σχέσεων άρθρων | Μόνο τεκμηρίωση στρωμάτωσης — καμία πράξη |

Όλα τα παραπάνω = ΧΡΕΗ προς πρόταση (change-proposal), κανένα δεν εκτελείται
σε αυτό το pass. Το Π0 είναι το μόνο επείγον: χωρίς αυτό ο Runner θα διαβάζει
μισό ledger.

## 3. Bootstrap (σκαλωσιά — ΔΕΝ είναι μάθηση, σημασμένο & ελεγχόμενο από πύλη ⑩)

`cognition-self.lisp` (ταξινομητές/frames/συνθέσεις) · `self-glossary.sexp` ·
`dialogue-gate.lisp` (σουίτα) · `casegrammar-core.sexp` (σπόροι) ·
feature extractors (`understanding-learning.lisp`). Αντικαθίστανται σταδιακά
ΜΟΝΟ από υιοθετημένους understanding-rules (failure→proposal→shadow→υπογραφή).

## 4. Stores — κανονικές έδρες

**Κανονικά (Σύνταγμα):** episodes / history / proposals / graph-snapshot /
candidates/ (self) · lessons / failure-ledger (state) · policies.sexp (self).
**Εκτός συντάγματος αλλά νόμιμα (artifacts, όχι «μνήμες»):** output/<corpus>/*
(ντετερμινιστικά build artifacts), deployment/data/decisions/* (corpus
νομολογίας + prov), verify/golden (fingerprints), input/decisions (intake),
state/*-last-seen.txt + fek-*.json (cursors δικτύου), output/review-queue.sexp,
output/proposals/*.sexp (external ingest door), daemon-status.json (heartbeat).
**ΧΡΕΟΣ Π1:** τα cursors/heartbeat/review-queue να δηλωθούν σε δεύτερο πίνακα
`:artifact-stores` του Συντάγματος ώστε ο έλεγχος ⑨ να επεκταθεί από
self/state σε ΟΛΟ το δέντρο. (Σημερινό ⑨: self/*.sexp + state/*.jsonl.)

## 5. Τι συγχωνεύεται (σειρά προτεραιότητας — ΚΑΝΕΝΑ τώρα, όλα μέσω πρότασης)

- **Π1** Επέκταση `:canonical-stores` → πλήρης κάλυψη δίσκου (μόνο δήλωση+πύλη).
- **Π2** Ταυτότητα άρθρων: ένα κείμενο-συμβόλαιο που ορίζει canonical-article-id
  ως ΤΟΝ τύπο και registry/uris ως καταναλωτές· ό,τι δεν συμμορφώνεται,
  προσαρμόζεται (μέσω change-proposal, ποτέ silent refactor).
- **Π3** Κανονικοποίηση: τεκμηρίωση «πότε %fold / πότε normalize-greek» +
  έλεγχος πύλης που πιάνει χρήση της λάθος συνάρτησης σε νέο κώδικα.
- **Π4** In-memory ledgers χωρίς δίσκο (*adoption-records*, *study-cache*,
  trace events): ήδη δηλωμένα χρέη διάρκειας — παραμένουν, δεμένα στο
  MEMORY primitive, μέχρι το substrate (generations) να δώσει φυσική λύση.

## 6. Τι απαγορεύεται (επιβάλλεται από την πύλη — όχι από καλή θέληση)

1. Νέα εντολή χωρίς εγγραφή στο Σύνταγμα (⑥/②: **η ίδια η πύλη το απέδειξε** —
   κοκκίνισε στον εαυτό της μέχρι να χαρτογραφηθεί).
2. Νέα κορυφαία έννοια εκτός των 13 primitives.
3. Δεύτερο μονοπάτι υιοθεσίας εκτός can-adopt/Σ11 (⑧).
4. Νέο store σε self/state χωρίς δήλωση (⑨).
5. Bootstrap χωρίς σήμανση / επίκληση bootstrap ως απόδειξη μάθησης (⑩).
6. LLM έξοδος σε trusted path (κανόνας :no-llm-trusted-path· μονή πόρτα:
   data-only ingest → can-adopt).
7. Adopted understanding-rule με phrase/token literal (αδιατύπωτο στη γλώσσα —
   --understanding-gate ②).
