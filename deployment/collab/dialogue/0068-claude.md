# [0068] Αυτο-εντοπισμός regression: η δρομολόγηση FEK-COMPILER ήταν αποσυνδεδεμένη από την ενοποίηση

**Ποιος/πότε:** Claude — 2026-07-12. Αφορμή: εντολή δημιουργού «δεν θέλω να
φαντάζεσαι, θέλω 100% γνώση του κώδικα». Άλλαξα μέθοδο: ανάγνωση ΟΛΗΣ της
αλυσίδας κατανάλωσης πριν από κάθε ισχυρισμό.

## Το εύρημα (διαβασμένο, όχι εικαζόμενο)

Διαβάζοντας την πλήρη διαδρομή που ΕΦΑΡΜΟΖΕΙ τις τροποποιήσεις:
`corpus-spec` (main.lisp:498) → `%auto-amendment-records` (main.lisp:481) →
`laws->records` (bridge:285) → `law->record` (bridge:262) → `%extract-ops`
(bridge:254) → `extract-operations`.

Το `%extract-ops` καλούσε τον extractor **ΧΩΡΙΣ code-resolver/oracle**. Η
αλλαγή μου στο FEK-COMPILER αφαίρεσε το default resolver (`&key (code-resolver
#'%resolve-code)` → `&key code-resolver`), οπότε σε ΑΥΤΗ τη διαδρομή ΚΑΘΕ πράξη
έβγαινε `:code` NIL ⇒ στο `law->record` (bridge:270-276) `codes`=κενό ⇒
`sole`=T ⇒ `here`=ΟΛΕΣ. Δηλαδή **κάθε τροποποίηση θα εφαρμοζόταν σε ΚΑΘΕ έναν
από τους 6 κώδικες** (μόνη ασπίδα το `:if-missing :skip`). Η δρομολόγηση που
έχτισα ήταν αποσυνδεδεμένη από την πραγματική ενοποίηση.

**Χειρότερα**: το gated τεστ `autonomy-consolidation` (Dockerfile:173) έσπαγε
3/10 από την αλλαγή μου — και ΔΕΝ το είχα τρέξει στα προηγούμενα «proof» [0067].
Οι ισχυρισμοί «όλα πράσινα» ήταν ΕΛΛΙΠΕΙΣ. Τα προηγούμενα pushes μου θα έσπαγαν
το owner docker build. Παραδεκτό, διορθωμένο.

## Η διόρθωση (στην έδρα)

- `%extract-ops`, `law->record`, `laws->records` (consolidation-bridge):
  threading `&key code-resolver article-exists-fn` → extractor.
- `%amendment-router` + `%auto-amendment-records` (main.lisp): μνημονευμένο
  (resolver . oracle) από build-legal-id-registry (configs) + census oracle,
  με ΕΠΑΝΑΦΟΡΑ επιλογής corpus (build-legal-id-registry επιλέγει διαδοχικά και
  δεν επαναφέρει — το τεκμηρίωσα και το χειρίστηκα).
- Regression lock (auto-consolidate): με resolver, πράξη poinikos ΔΕΝ διαρρέει
  σε astikos· χωρίς resolver (το παλιό σφάλμα) θα εφαρμοζόταν και στα δύο.
- autonomy-consolidation-test: resolver από registry (καμία hardcoded λίστα).

## Proof (ΟΛΟ το gated cluster, τρέχοντας τη λίστα του Dockerfile)

amendment-extractor 23, amendment-accuracy 8/8, amendment-consolidation-e2e 7,
autonomy-consolidation **10** (ήταν 7/3-fail), consolidation-bridge 18,
consolidation-engine 23, auto-consolidate **22**, government-source 7,
fek-discovery 7, amendment-routing 30, amendment-state 11 (CLI), ingestion-daemon
8, ingestion-e2e 10, legal-id-registry 27 — **0 failed παντού**· CLI φορτώνει.

## Δίδαγμα (μόνιμο)

Πριν κάθε «proof»: τρέξε τη ΛΙΣΤΑ ΤΟΥ DOCKERFILE, όχι τα τεστ που θυμάμαι.
Πριν κάθε ισχυρισμό για τον κώδικα: διάβασέ τον, με αρχείο:γραμμή.
