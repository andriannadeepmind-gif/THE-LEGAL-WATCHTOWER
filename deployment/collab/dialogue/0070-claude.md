# [0070] FEK-COMPILER φάση β': bounded discovery + backtest report ΑΠΟ ΤΗΝ ΕΔΡΑ

**Ποιος/πότε:** Claude — 2026-07-12. Εντολή δημιουργού: «μήπως να το φτιάξεις εσύ
ακόμα καλύτερο;» + «να θυμάσαι 0 διπλά». Το §Superior και των δύο sessions.

## Τι χτίστηκε (χωρίς διπλή έδρα)

Το owner runbook του παράλληλου session ήταν πρόταση (uncommitted, μετρούσε από
log-grep = δεύτερη έδρα μέτρησης). Αντ' αυτού, ΜΙΑ έδρα, ντετερμινιστικό:

1. **`%fek-discover-only`**: FEK_DISCOVER_ONLY=103,105,239 → bounded σύνολο αντί
   για walk. Ντετερμινιστικό, φθηνό, χωρίς δίκτυο-walk. Bounded mode ΔΕΝ προχωρά
   τον cursor (στοχευμένο backtest, όχι forward scan).
2. **Report ΑΠΟ ΤΗΝ ΕΔΡΑ**: FEK_BACKTEST_REPORT=<path> → per-ΦΕΚ structured
   metrics ΑΠΟ το `measure-extraction` (ΟΧΙ log-grep). `%backtest-entry` +
   `%backtest-report->json` (ντετερμινιστικό, ρητοί→double).
3. **«0 διπλά» — ΜΙΑ εξαγωγή ανά ΦΕΚ**: το loop εξάγει τις πράξεις μία φορά·
   log (summarize) ΚΑΙ report (measure-extraction :ops) από τις ΙΔΙΕΣ ops —
   κανένα split-brain, καμία διπλή εξαγωγή. (measure-extraction δέχεται :ops.)

Το bounded discovery ξαναχρησιμοποιεί το υπάρχον ENUMERATE-NEW-FEK/FETCH-FEK-BLOB
(αλλάζει μόνο την πηγή αριθμών). Το fetch μένει owner-edge (δίκτυο).

## Proof

fek-backtest-report **14/14** (καθαρές helpers, χωρίς δίκτυο: parse robustness,
ρητοί→float, ντετερμινιστικό JSON, regression baseline Α'103 routed=1 καταγράφεται)·
amendment-backtest 12, amendment-extractor 23, auto-consolidate 22· CLI φορτώνει.
Gated: fek-backtest-report στο Dockerfile.

## Τίμιο όριο (δηλωμένο, όχι κρυφό)

Το gated τεστ δοκιμάζει τις ΚΑΘΑΡΕΣ helpers ντετερμινιστικά· το ΠΡΑΓΜΑΤΙΚΟ ΦΕΚ
fetch μένει owner-run (δίκτυο — proxy 403 από εδώ). Ο owner run με FEK_DISCOVER_ONLY
+ FEK_BACKTEST_REPORT παράγει backtest-report.json ΑΠΟ την ίδια έδρα. N-version
differential (measure-extraction ≡ 2ος extractor) = δηλωμένη επόμενη φάση.

---

## ΠΡΟΣΘΗΚΗ: κλείσιμο ευρημάτων αντιπαλικού κριτή (φρέσκο πλαίσιο)

Ο κριτής (πάνω στην προ-fix έκδοση) βρήκε — όλα κλειστά:
- **B (HIGH, «0 διπλά» ΨΕΥΔΕΣ):** το `&key ops` του measure-extraction ήταν
  νεκρό (clobber) ΚΑΙ ο caller δεν το περνούσε ⇒ διπλή εξαγωγή ανά ΦΕΚ +
  split-brain (buckets vs routed από 2 εξαγωγές). ΚΛΕΙΣΤΟ: `(or ops …)` +
  ο caller περνά `:ops ops` ⇒ ΜΙΑ εξαγωγή, log+report από τις ΙΔΙΕΣ πράξεις.
- **A (4ος JSON emitter):** ΚΛΕΙΣΤΟ ΔΟΜΙΚΑ — ΜΙΑ cli scalar έδρα
  `%json-scalar` (cli-util) + το `%json-escape` ΜΕΤΑΚΙΝΗΘΗΚΕ εκεί (μία θέση).
  Και τα δύο cli emitters (`%laws->json`, `%backtest-report->json`) την
  καταναλώνουν· `%laws->json` byte-stable (επαληθεύτηκε, ingestion-e2e 10/10).
  Διαπακετικό (epistemic census->json/%tlog + το 2ο %json-escape/%jstr) =
  ΔΗΛΩΜΕΝΗ ξεχωριστή φάση (release-identity-critical bytes — αλλαγή θέλει
  απόδειξη ότι τα release ids ΔΕΝ μετακινούνται· release-vector-conformance).
- **C (silent-accept):** ΚΛΕΙΣΤΟ — whole-token θετικός ακέραιος· «103abc»/«-5»/
  «0» ΑΠΟΡΡΙΠΤΟΝΤΑΙ (test locks: 16/16).
- **D/E/G:** επιβεβαιωμένα ΣΩΣΤΑ από τον κριτή (cursor non-advance, NULL≠0,
  τίμιο framing) — credit.
- **F (integration gap):** το FEK_DISCOVER_ONLY→nums flow είναι network-coupled
  (enum/fetch) ⇒ δηλωμένο ως owner-edge, όχι CI-testable· οι καθαρές helpers gated.

Proof: fek-backtest-report 16/16, amendment-backtest 12, amendment-extractor 23,
auto-consolidate 22, autonomy-consolidation 10, consolidation-bridge 18, ingestion-e2e 10.
