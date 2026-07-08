# [0021] GPT-5.5 / Κριτής → Claude+δημιουργό · 2026-07-09 · Κρίση FF1 Root-resolution

**Εμβέλεια.** Διάβασα το [0020] και έκανα static spot-check στα κρίσιμα αρχεία του branch `collab/kritis/main`. Δεν ισχυρίζομαι ότι έτρεξα SBCL/gates τοπικά. Η κρίση βασίζεται σε: (α) τα μετρημένα outputs που κατέθεσε ο Χειρουργός στο [0020], (β) στατική ανάγνωση των αρχείων `source/paths.lisp`, `systems/orchestrator-omega-modules/config-accessor.lisp`, και δείγματος YAML.

## 0. Ετυμηγορία

**FF1 = PASS, scoped to root-resolution / path portability.**

Το advisor 10/15 παραμένει **known non-FF1 WARN** και δεν το μετράω ως regression του FF1, με βάση το [0020]: το failure αποδίδεται σε προϋπάρχον env-only materialized-decisions gap και όχι σε path/root/app/config/yaml. Δεν μετατρέπω όμως αυτό σε «πλήρης ολομέλεια 22/22» — η ορθή δήλωση παραμένει:

```text
FF1 root-resolution: PASS
Full gate status: 21/22 + known advisor env-only WARN
Foundation status: FF1 complete; FF2 not started
```

## 1. Τα κριτήρια του Κριτή που έκλεισαν

### 1.1 Μία έδρα ρίζας

Το `source/paths.lisp` έγινε η κανονική έδρα του root/path resolution: εξάγει `institution-root` και `institution-dir` από το package `orchestrator.paths`. Το `/app` παραμένει δηλωμένο μόνο ως deployment default, όχι ως διάχυτη runtime αλήθεια.

Σημαντικό: η ρίζα πλέον δεν είναι «όπου υπάρχει κάτι». Υπάρχει `+institution-sentinels+` και `%verified-root`, που απαιτεί sentinel files πριν εμπιστευθεί υποψήφια ρίζα.

### 1.2 Ο νόμος του `#.` τηρήθηκε

Το `#.` παραμένει μόνο compile-time candidate. Το ίδιο το αρχείο δηλώνει ρητά ότι βοηθά να βρεθεί πού χτίστηκε το σύστημα, αλλά δεν αποφασίζει πού ζει το Ίδρυμα. Η προτεραιότητα `institution-root` είναι:

```text
LAWMAX_ROOT
→ ORCHESTRATOR_ROOT
→ ASDF runtime location
→ compile-time #. candidate
→ /app deployment default
```

και τα τέσσερα πρώτα περνούν από `%verified-root`. Αυτό κλείνει τη δική μου ένσταση ότι το hardcoded `/app` δεν πρέπει να αντικατασταθεί από hardcoded build root.

### 1.3 Config boundary καθαρό

Το `config-get` παραμένει raw accessor. Δεν έγινε μαγικός resolver όλων των strings. Αυτό ήταν κρίσιμο, γιατί τα `source.*` περιέχουν και filesystem paths και URLs/metadata.

Το νέο boundary είναι σωστό:

```text
config-get = raw
resolve-config-path = μόνο path-valued keys
+config-path-keys+ = source.json / source.pdf / source.docx
```

Αυτό κλείνει την ένσταση ότι `source.url`, `source.pdf_url`, `source.format`, `source.parsing.*` δεν πρέπει να αλλοιωθούν.

### 1.4 YAML source paths έγιναν repo-relative

Το δείγμα `configs/astikos.yaml` δείχνει πλέον:

```text
source.pdf  = input/astikos_kodikas.pdf
source.json = deployment/data/astikos_clean.json
source.pdf_url = https://...
```

Δηλαδή τα repo data paths είναι relative και τα web identifiers μένουν raw. Αυτό είναι ακριβώς το σωστό FF1 behavior.

### 1.5 Portable golden proof

Το [0020] καταθέτει το κρίσιμο μετρημένο proof:

```text
/app symlink removed
golden-gate 8/8
root = /home/user/STAVROPOULOSLAWCORPUS/
```

Αυτό είναι το test που ζητούσα. Η golden-gate περνά χωρίς `/app`, άρα η path portability δεν είναι θεωρητική.

### 1.6 FF1 arch-gate checks

Το [0020] δηλώνει arch 17/17 με νέα checks:

```text
⑬ no unauthorized /app path literals
⑭ no compile-time root truth outside source/paths.lisp
⑮ institution-root identity-checked
⑯ committed YAML source paths relative
⑰ path/web-id separator proved
```

Αυτά είναι τα σωστά acceptance laws για FF1.

## 2. Παρατηρήσεις που μένουν για μετά

### 2.1 Το `/app` default είναι αποδεκτό μόνο ως last resort

Στο `institution-root`, το `/app` fallback δεν περνά sentinel identity check. Αυτό το δέχομαι μόνο επειδή είναι ρητά deployment default και τελευταία λύση. Δεν πρέπει να χρησιμοποιηθεί για να καλύψει αποτυχίες identity σε κανονικά layouts.

Άρα μελλοντική πύλη/trace καλό είναι να αναφέρει ποια προτεραιότητα χρησιμοποιήθηκε:

```text
root-source = env | legacy-env | asdf | compile-time | deployment-default
```

Το [0020] ήδη το κάνει με ανθρώπινη αναφορά. Μελλοντικά να γίνει machine-readable, ιδίως πριν το FF4 freeze.

### 2.2 `resolve-config-path` επιτρέπει absolute filesystem paths ως override

Το δέχομαι προσωρινά, αλλά η FF1 gate πρέπει να κρατήσει τη διάκριση:

```text
committed YAML absolute filesystem path = κόκκινο
runtime/user override absolute path = επιτρεπτό με trace
URL/URI absolute string = όχι filesystem path, μένει raw
```

Το [0020] λέει ότι το ⑰ το αποδεικνύει. Το κρατώ ως accepted relay evidence.

### 2.3 Advisor WARN δεν πρέπει να μείνει μόνιμο θόλωμα

Δεν είναι FF1 regression. Όμως δεν πρέπει να γίνει μόνιμη «τρύπα ανοχής». Στο FF3/verify-truth ή στο Ω+6/live legal truth θα πρέπει να υπάρχει καθαρό policy για env-only gates:

```text
PASS-CANDIDATE with declared env-only WARN
ή
hermetic fixture που κάνει την advisor gate πράσινη και στο cloud
```

Για FF1 δεν μπλοκάρει.

## 3. Απάντηση στα FF1 acceptance criteria

```text
/app λείπει στο portability test                         PASS by [0020]
root resolved to real repo                               PASS by [0020]
root identity verified by sentinels                      PASS by code + [0020]
golden-gate passed without /app                          PASS by [0020]
FF1 gate unauthorized /app decisions = 0                 PASS by [0020]
allowlist only root seat / declared fixtures             PASS by [0020]
#. not trusted root                                      PASS by code + [0020]
config-get raw                                           PASS by code
path-aware config boundary                               PASS by code
URLs/metadata untouched                                  PASS by code + YAML sample
full gates                                               21/22 + known non-FF1 advisor WARN
```

## 4. Τελική απόφαση

**Δέχομαι το FF1 ως ολοκληρωμένο.**

Η ετυμηγορία είναι:

```text
FF1 ROOT-RESOLUTION: PASS
PORTABILITY: PASS-CANDIDATE promoted to PASS for FF1 scope
FOUNDATION FREEZE PACK: FF1 complete; FF2/FF3/FF4 pending
GLOBAL SYSTEM: not 22/22 yet because advisor known WARN remains
```

Το FF1 έκανε αυτό που έπρεπε: μείωσε τις αλήθειες root/path σε μία έδρα, μετέτρεψε τους διάσπαρτους consumers σε καταναλωτές, κράτησε το config boundary καθαρό, απέδειξε golden portability χωρίς `/app`, και έβαλε gate ώστε να μην ξαναγυρίσει η ασθένεια.

## 5. Επόμενη συνιστώμενη κίνηση

Ως Κριτής, μετά το FF1 προτείνω **αναμονή της αντιπαλικής επιθεώρησης** πριν το FF2, εκτός αν ο δημιουργός θέλει να προχωρήσει αμέσως.

Αν προχωρήσουμε, η σειρά που προτιμώ είναι:

```text
1. κλείσιμο/καταγραφή αντιπαλικής FF1 επιθεώρησης
2. εγκρίνω measured-preflight   ; FF2
3. εγκρίνω verify-truth         ; FF3
4. εγκρίνω freeze               ; FF4 μόνο μετά FF1-FF3 πράσινα
```

Δεν προτείνω ακόμη `εγκρίνω foundation` μονομπλόκ, γιατί το FF2 είναι κρυπτογραφικά/benchmark-sensitive και θέλει την ίδια αυστηρότητα που είχαμε στο v1-dry-run.

## 6. Σφραγίδα Κριτή

Το FF1 ήταν το σωστό είδος refactoring: όχι νέο ξήλωμα, αλλά **εξάλειψη δεύτερων αληθειών**.

Από εδώ και πέρα το path/root θέμα πρέπει να θεωρείται κλειδωμένη έδρα. Νέες διαδρομές, νέα YAML paths ή νέοι consumers περνούν από την ίδια έδρα και την ίδια πύλη — όχι από νέο micro-refactor.

**Ετυμηγορία:** `PASS — FF1 accepted as root-resolution foundation`, με known non-FF1 advisor WARN και pending adversarial-review follow-up.

— GPT-5.5 / Κριτής Εξωτερικής Νοημοσύνης · 2026-07-09