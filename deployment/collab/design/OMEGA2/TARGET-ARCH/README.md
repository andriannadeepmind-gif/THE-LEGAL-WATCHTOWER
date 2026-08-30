# WATCHTOWER VLT — TARGET ARCHITECTURE BUNDLE

Πλήρες σύνολο της αρχιτεκτονικής-στόχου και του εκτελεσμένου formal evidence, όπως προέκυψαν
από τους διαδοχικούς αντιπαλικούς κύκλους Reviewer-A × Reviewer-B.
**Καμία production αλλαγή: το repository THE-LEGAL-WATCHTOWER παραμένει ανέγγιχτο.**

## Σειρά ανάγνωσης
1. `WATCHTOWER-TARGET-ARCHITECTURE-v0.7.md` — self-contained αρχιτεκτονική (I-1…I-40).
2. `WATCHTOWER-v0.7.1-PRE-FREEZE-EVIDENCE-CLOSURE.md` — R-j/R-s/Model-D/R-b/R-f closure,
   οι τρεις απαιτήσεις που ανακάλυψε το TLC, και ο counter-challenge GE-16…GE-19.
3. `WATCHTOWER-v0.7.2-COUNTER-CHALLENGE-CLOSURE.md` — I-41…I-44 όπως εγκρίθηκαν, falsifiers 60–63,
   B-1/B-2/B-3, και το evidence κάθε νέου invariant.
4. `formal/EVIDENCE-PACK.md` + `formal/TLA-RESULTS.md` — τα αποτελέσματα.
5. `formal/REPRODUCIBILITY-LOCK.md` — πώς αναπαράγονται.

## Ιστορικό εκδόσεων (για ιχνηλασιμότητα)
`v0.1` πρώτο καθαρό target · `v0.2` DP#1 · `v0.3` DP#2 · `v0.4` freeze candidate ·
`v0.5` global elite obligations · `v0.6` full closure set · `v0.7` Group-T ·
`v0.7.1` evidence closure · `v0.7.2` counter-challenge closure.
Παλαιότερες εκδόσεις διατηρούνται ως ιστορικό — **δεσμευτικές είναι μόνο οι 0.7 + 0.7.1 + 0.7.2.**

## Formal evidence — τι τρέχει
```
cd formal
python3 run_all.py            # Models A,C,D,D2,E,H (bounded exhaustive) + F,G,I (constructions)
./run_tla.sh                  # TLA+/TLC: WatchtowerLog (R-s) + WatchtowerCore (R-j)
```
Το `tla2tools.jar` ΔΕΝ περιλαμβάνεται· είναι pinned με URI + sha256 στο REPRODUCIBILITY-LOCK.md.

## Πύλη
Τελικό bounded ceiling audit → «GLOBAL ELITE CEILING — PASS» → «v1.0 READY FOR CREATOR FREEZE
DECISION» → **μόνο ο δημιουργός: «εγκρίνω freeze target»** → τότε το MERGED-BLUEPRINT v0.8
ξαναδένεται ως migration plan v0.9.
