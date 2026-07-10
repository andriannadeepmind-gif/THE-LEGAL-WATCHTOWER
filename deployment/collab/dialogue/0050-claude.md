# [0050] Claude (Χειρουργός Πυρήνα) — P1b: πρόοδος, αντιπαλική επιθεώρηση, ανοιχτά

**Ημερομηνία:** 2026-07-10 · Φάση P1b σε εξέλιξη (έγκριση δημιουργού: «ταβάνι εγγυημένα», αποφάσεις i/ii/iii ΝΑΙ).

## Παραδομένα (commits a4a75365 → 77140d1f)
- filename ≡ identity: %article-base στη ΜΙΑ έδρα (pad/uri-id) — βάση από το
  label· E2E: article-005Α.* κανονικά, 0 συνθετικά ονόματα· gated ⑨/⑨β.
- [0047] B4 (μία έδρα provenance-πηγής) + B7 (μία μορφή root, αυστηρή).
- AI ingest manifest: ΕΓΚΥΡΑ JSON objects (:from :plist) + label-aware
  id/article_number/citation ΚΑΙ στους δύο builders (id πλήρως στον plain).
- Αναγέννηση per-article επιφανειών ×6 corpora (9.533 αρχεία): .jsonld
  0 αλλαγές (byte-ίδια = ντετερμινισμός), ttl/hash refresh, 6 manifest.jsonl
  υγιή, +124 proofs Συντάγματος + corpus-proof (πληρότητα iii)· goldens 8/8
  ΧΩΡΙΣ drift (δεν χρειάστηκε GOLDEN_WRITE)· corpus-level P0-κανονικά
  επαναφερμένα.
- Αντίπαλος εύρημα #1 (CRITICAL) ΚΛΕΙΣΜΕΝΟ ωμά: 141 TTL είχαν πάρει
  συνθετικές ταυτότητες από το FRBR μονοπάτι — επαναφορά στις ορθές (77140d1f)·
  τα νόμιμα 4ψήφια lettered (1578Α/1001Α/1011Α) διακρίθηκαν σωστά.

## Αποδείξεις τρέχοντος HEAD
Loop 80/80 · verify-truth 22/22 · ολομέλεια 23/24 (advisor baseline) ·
golden 8/8 · release-gate 49/49 · 0 αληθινά συνθετικά εκτός των αμετάβλητων
ιστορικών/attested release lineage (δηλωμένο).

## ΑΝΟΙΧΤΑ (αντίπαλος #2-#5 — κλείσιμο στην έδρα εντός P1b)
1. **#2 FRBR κλάση**: call sites με (συνθετικός αριθμός + ΓΥΜΝΟ επίθημα) —
   frbr-pipeline-stage:268-288 → unified-frbr-generator:404,
   manifestation-generator-omega:206, format-generator-omega:195,
   greek-law-types:252. Σχέδιο: το LABEL διαπερνά το FRBR (όχι bare suffix) —
   εξάλειψη της κλάσης· μετά ΞΑΝΑ αναγέννηση των TTL από το διορθωμένο
   μονοπάτι (η επαναφορά του 77140d1f είναι ορθή αλλά «παλαιάς εποχής» μορφή).
2. **#3**: -with-config builder — υπόλοιπα synthetic πεδία (article_number,
   citation ~D, provenance_url χωρίς suffix) + συγχώνευση σε ΜΙΑ έδρα με τον
   plain (ζωντανό μονοπάτι: commands.lisp:130,243).
3. **#4**: lettered .html/.proof.json με προϋπάρχουσες synthetic URIs —
   αναγέννηση αφού κλείσει το #2.
4. **#5**: %article-base/% article-suffix συμβόλαιο (αριθμός ως όρισμα) —
   καθάρισμα guard.
5. Εύρημα pipeline-consolidate: ωμά headings στο corpus.jsonl μονοπάτι του
   pipeline (τα P0-κανονικά επαναφέρθηκαν)· κλείσιμο στην έδρα του
   consolidate-stage.

*Η φάση συνεχίζεται — καμία ετυμηγορία δεν ζητείται ακόμη.*
