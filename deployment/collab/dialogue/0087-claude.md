# [0087] Claude — Διάγνωση owner docker corpus-identity (120≠124) + O-3 στην είσοδο του hub

**Ημερομηνία:** 2026-07-13 · **Ρόλος:** Χειρουργός Πυρήνα ΚΑΙ Κριτής · **HEAD:** 3f5d693a → αυτό το commit
**Αφορμή:** owner docker build (φρέσκο pull, Windows) — ΟΛΕΣ οι σουίτες πράσινες ΕΚΤΟΣ
corpus-identity: 47 passed / 6 FAILED («① syntagma: 120 άρθρα», απόντα art_5Α/9Α/100Α/101Α σε ②×4/④/⑤).

## 1. Διάγνωση — αλυσίδα αποδείξεων (όχι εικασία)

| # | Γεγονός | Απόδειξη |
|---|---------|----------|
| 1 | Το repo στο 3f5d693a έχει **124** άρθρα με ΚΑΙ τα 4 lettered | `git show HEAD:deployment/data/syntagma_clean.json` → 124, τίτλοι 5Α/9Α/100Α/101Α παρόντες |
| 2 | Ίδιο commit, ίδιο test, τοπικά: **53/53 PASS** | τρέξιμο tests/corpus-identity-test.lisp σε αυτό το περιβάλλον, πριν από κάθε αλλαγή |
| 3 | Κανένα gated test δεν γράφει το source.json μέσα στην εικόνα | στατική σάρωση tests/: `write-source-json` μόνο σε /tmp (source-materialize), `materialize-pdf-sources` 0 κλήσεις από tests |
| 4 | Το .dockerignore ΔΕΝ αποκλείει deployment/data/*.json | ανάγνωση όλων των patterns (root-anchored) — το S6-003 ΔΕΝ είναι η αιτία εδώ |
| 5 | Το docker διαβάζει ό,τι βρίσκεται στο build context | Dockerfile:89 `COPY deployment/ /app/deployment/` |
| 6 | Το σφραγισμένο prov stamp του repo δένει το 124-περιεχόμενο | `syntagma_clean.json.prov.json` content_sha256=`sha256:d729b9c6…` ≡ sha256 του committed αρχείου |

**Συμπέρασμα (μοναδική συνεπής εξήγηση):** το build context στο μηχάνημα του δημιουργού
περιέχει το ΠΑΛΙΟ 120-άρθρων `deployment/data/syntagma_clean.json` (η προ-2019-αναθεώρησης
έκδοση χωρίς lettered). Το «φρέσκο pull» ΔΕΝ το διαψεύδει: το αρχείο άλλαξε στο repo στις
2026-07-05 (a644c1d0)· ένα `git pull` ξαναγράφει ΜΟΝΟ αρχεία που άλλαξαν στο pulled range.
Αν το τοπικό αντίγραφο έχει από τότε παλιό/τροποποιημένο περιεχόμενο, ΚΑΘΕ επόμενο pull το
αφήνει άθικτο — και το `git status` θα το δείχνει `modified`. Η προηγούμενη απόδοση
«stale working copy» ήταν σωστή ως προς τον μηχανισμό αλλά ΑΝΑΠΟΔΕΙΚΤΗ ως τότε — τώρα είναι
αποδεδειγμένη δι' αποκλεισμού με τα 1-6.

## 2. Το θεσμικό εύρημα — παράκαμψη έδρας (η δική μας ευθύνη)

Η έδρα O-3 υπήρχε ήδη: `provenance-checked-json-source` αρνείται unstamped/tampered
source.json. **Αλλά το `corpus-spec` — ο κόμβος που τρέφει consolidation / serve /
intelligence / κάθε identity test — διάβαζε το source.json ΑΠΕΥΘΕΙΑΣ** με
`resolve-config-path`, χωρίς το gate. Έτσι στο docker του δημιουργού:

- stale JSON (120) + φρέσκο stamp (του 124) = **hash mismatch που το σύστημα ΕΙΧΕ στα χέρια του**
- και όμως προήγαγε σιωπηλά τα ανεπαλήθευτα bytes σε «authoritative corpus»,
- κοκκίνισε 6 checks πιο κάτω, χωρίς καμία απόδοση αιτίας.

Ίδια κλάση με [0086]: σιωπηλή κατανάλωση εκτός έδρας. Κλείνεται ΣΤΗΝ ΕΔΡΑ, όχι με φρουρό.

## 3. Υλοποίηση (η ανώτατη μορφή, μία έδρα ανά έννοια)

1. **ΜΙΑ ετυμηγορία provenance:** `%source-provenance-status` → `(values status want have)`
   με status ∈ {`:valid`, `:unstamped`, `:tampered`, `:missing`}. Το boolean-μόνο
   `%source-provenance-valid-p` ΠΕΘΑΝΕ (αντικαταστάθηκε, δεν τυλίχθηκε)· οι 2 εσωτερικοί
   καταναλωτές του materialize κρίνουν μέσω της ετυμηγορίας.
2. **Αποδιδόμενη άρνηση:** το O-3 gate τυπώνει πλέον ΠΟΙΟ αρχείο, ΠΟΙΑ ετυμηγορία,
   want/have hashes ΚΑΙ τη διόρθωση (git restore / --materialize-pdf). Ένα κόκκινο docker
   log ονομάζει μόνο του την αιτία. Η παράκαμψη `ORCHESTRATOR_ALLOW_UNVERIFIED_JSON=1`
   παραμένει ρητή/καταγεγραμμένη — και πλέον ΔΕΝ «προάγει» ανύπαρκτο αρχείο.
3. **corpus-spec gated:** η είσοδος του hub περνά ΜΟΝΟ από `provenance-checked-json-source`·
   άρνηση ⇒ ERROR (τίμια άγνοια — δεν χτίζεται authoritative corpus από μη επαληθευμένη πηγή).
4. **Μόνιμα locks (corpus-identity-test):** ㉗ συμπεριφορικό — unstamped→valid→tampered→missing
   σε temp αρχείο με τον ΠΡΑΓΜΑΤΙΚΟ writer/verdict· ㉗β source-scan — το σώμα του
   `corpus-spec` περιέχει το gate και ΚΑΝΕΝΑ ωμό resolve-config-path (αναίρεση της
   καλωδίωσης κοκκινίζει).

Με αυτό, το ακριβές failure mode του δημιουργού γίνεται δομικά αδύνατο ως ΣΙΩΠΗΛΟ:
stale bytes πλέον σταματούν στο κατώφλι, ονομαστικά, πριν χτιστεί οτιδήποτε.

## 4. Proof (τοπικά, σε αυτό το commit)

| Σουίτα | Αποτέλεσμα |
|---|---|
| corpus-identity (με ㉗/㉗β) | **55/55** |
| seat-integrity | 18/18 |
| corpus-service | 44/44 |
| multi-corpus-service | 12/12 |
| ai-corpus-dump | 14/14 |
| consolidation-feed | 12/12 |
| corpus-provenance | 12/12 |
| ingestion-e2e | 10/10 |
| autonomy-consolidation | 10/10 |
| amendment-consolidation-e2e | 7/7 |
| mcp-live-resolver | 16/16 (με SOURCE_DATE_EPOCH όπως στο docker· χωρίς αυτό κοκκινίζει ΑΝΕΞΑΡΤΗΤΑ της αλλαγής — runner-env, το Dockerfile το θέτει ARG στο :17) |

Σύνολο: **11 σουίτες, 210 checks, 0 αποτυχίες.** Και τα 6 σώματα έχουν έγκυρα stamps
στο repo (έλεγχος sha256 ×6 = OK), άρα το αυστηροποιημένο corpus-spec δεν αλλάζει
τίποτα σε συνεπές δέντρο — αλλάζει ΜΟΝΟ το αποτέλεσμα σε αλλοιωμένο.

## 5. Οδηγίες δημιουργού (το τοπικό working copy)

Στο `C:\STAVROPOULOSLAWCORPUS` (PowerShell):

```powershell
git status -- deployment/data/syntagma_clean.json     # περιμένω: modified (ο ένοχος)
git restore deployment/data/syntagma_clean.json       # επαναφορά στο committed 124
(Get-Content -Raw deployment/data/syntagma_clean.json | ConvertFrom-Json).Count   # πρέπει: 124
```

Αν το status βγει ΚΑΘΑΡΟ και το Count 124, τότε το docker build τρέχει από ΑΛΛΟΝ φάκελο —
έλεγξε από πού εκτελείται. Μετά το pull των αλλαγών [0087], ξανά:

```powershell
docker build --progress=plain --no-cache-filter=standalone-test --target standalone-test -t lawmax-test .
```

Αναμενόμενο: corpus-identity **55 passed, 0 failed**. (Αν το αρχείο ΔΕΝ έχει αποκατασταθεί,
το νέο αναμενόμενο είναι ΡΗΤΟ κόκκινο στο ①: «⛔ syntagma: source.json με HASH MISMATCH …
want sha256:d729b9c6… have sha256:…» — η άρνηση πλέον αυτο-ονομάζεται.)

## 6. Υπόλοιπα (τίμια)

- Το docker-context ↔ commit binding (απόδειξη ότι ΟΛΟ το context ≡ δηλωμένο commit) μένει
  ανοιχτό ως S6-003/S6-010 (reproducible build) — δική τους φάση· το παρόν κλείνει το
  data-integrity σκέλος για ΚΑΘΕ κατανάλωση source.json.
- Owner docker proof του παρόντος = το πράσινο 55/55 στο μηχάνημα του δημιουργού.
