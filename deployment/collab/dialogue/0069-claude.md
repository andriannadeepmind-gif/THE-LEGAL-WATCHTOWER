# [0069] Backtest harness (self-verify) + κλείσιμο 6 ευρημάτων αντιπαλικού κριτή

**Ποιος/πότε:** Claude — 2026-07-12. Εντολή δημιουργού: «τι θα έκανε η deep mind»
(για το ground-truth χωρίς ετικέτες) + «τέλειο χωρίς απλοποιήσεις/διπλό κώδικα/ράπερ».

## Η DeepMind απάντηση: self-supervision, όχι ετικέτες

`measure-extraction` (source/amendment-extractor.lisp) = ΜΙΑ έδρα μέτρησης που
ΚΑΤΑΝΑΛΩΝΕΙ τα verdicts του extractor (καμία διπλή λογική ταυτότητας). Το σώμα
βαθμολογεί τον εαυτό του σε ήδη-committed αναλλοίωτες: το census βαθμολογεί κάθε
δρομολόγηση, τα νομοτεχνικά ρήματα (ΤΑ ΙΔΙΑ scanners) μετρούν κάλυψη. Fixtures:
ΠΡΑΓΜΑΤΙΚΟ pdftotext a103-2026 + served-census.json (ΑΚΡΙΒΗ article-ids των 6
κωδίκων). Gated: amendment-backtest στο Dockerfile.

## Αντιπαλικός κριτής (φρέσκο πλαίσιο) — 6 ευρήματα, ΟΛΑ κλεισμένα

- **D (HIGH, hand-typed fake oracle):** ΗΔΗ κλειστό πριν τον κριτή — αντικατέστησα
  τα synthetic εύρη (1-462 κ.λπ., λάθος vs census) με membership από το ΠΡΑΓΜΑΤΙΚΟ
  served-census.json (ακριβή ids, με κενά — kdioikitikis έχει 244 όχι 290).
- **A/b (HIGH overclaim):** το «identity-precision … ΑΚΡΙΒΕΣ» ήταν μονόπλευρος
  έλεγχος εύρους. Μετονομασία → `:census-consistency` + ρητό: ΑΝΙΧΝΕΥΤΗΣ out-of-
  range σφάλματος, ΟΧΙ routing-precision (ύπαρξη = αναγκαία, όχι ικανή). Πλήρης
  routing-precision ⇒ labeled oracle (απών, δηλωμένο) ή N-version (επόμενη φάση).
- **C + BONUS (MED-HIGH δομικό):** το «fail-closed» ήταν ατύχημα fixture·
  operation-applicable-p επέστρεφε T για αδρομολόγητη πράξη. ΔΟΜΙΚΗ διόρθωση στο
  law->record: ΜΟΝΟ δρομολογημένες σε ΑΥΤΟΝ τον κώδικα πράξεις αυτο-εφαρμόζονται·
  αδρομολόγητη (ακόμη κι όταν sole) → review, ΠΟΤΕ auto. Το «sole» δεν είναι πια
  άδεια εφαρμογής. Τεστ: 0 records σε ΟΛΟΥΣ τους 6 κώδικες για το a103 (fail-closed
  ΔΟΜΙΚΑ, ελεγμένο μέσω law->record — η πραγματική έδρα εφαρμογής).
- **B (misnomer):** `:structural-recall` → `:ops-per-structural-verb` (λόγος
  κάλυψης με θορυβώδη παρονομαστή, μπορεί >1· ΟΧΙ recall).
- **F (ungated «locked»):** ο ισχυρισμός «precision-locked» ήταν υπερβολή. Τώρα το
  gated τεστ επαληθεύει το ΔΟΜΙΚΟ invariant (μόνο routed auto-applies) σε πραγματικό
  a103 — governs το build. CLI reporting command = δηλωμένο επόμενο (visibility).
- **A/a, seat:** :unknown ήδη τίμιο· measure-extraction one-seat-compliant
  (ξεχωριστό από measured-modality-precision — άλλο domain). Επιβεβαιωμένο από κριτή.

## Proof (ΟΛΟ το cluster, 0 failed)

amendment-backtest 12, auto-consolidate 22, autonomy-consolidation 10,
amendment-consolidation-e2e 7, consolidation-bridge 18, consolidation-engine 23,
amendment-extractor 23, amendment-routing 30, amendment-accuracy 8/8, legal-id 27,
fek-discovery 7, ingestion-e2e 10, ingestion-daemon 8, amendment-state 11 (CLI)· CLI φορτώνει.

## Δηλωμένα επόμενα (τίμια, όχι κρυφά)

1. CLI `--audit-amendments`: measure-extraction πάνω στο AMENDMENT_LAWS_JSON,
   αναγνώσιμος πίνακας (λύνει και το «Select-String ξεχειλίζει»).
2. N-version 2ος extractor (Python) + πύλη συμφωνίας — routing-precision που
   ΔΕΝ στηρίζεται στο census (κλείνει το A/b πλήρως).
3. Round-trip ανακατασκευή (θέλει ιστορικά base texts — πηγή του δημιουργού).
