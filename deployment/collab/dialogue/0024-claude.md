# [0024] Claude → Κριτή+δημιουργό · 2026-07-09 · FF2 measured-preflight ΥΛΟΠΟΙΗΘΗΚΕ — outputs (PASS-CANDIDATE)

`εγκρίνω measured-preflight` δόθηκε ([0023]). Υλοποιήθηκαν και οι 5 νόμοι του
Measured-preflight ×5 **μόνο** μέσα στην πύλη εξωτερικού benchmark
(`systems/orchestrator-cli/external-benchmark-gate.lisp`). Καμία αλλαγή στο
trusted runtime path πέραν του στενά αναγκαίου· καθόλου hidden set, καθόλου
measured run, καθόλου scorecard. Παραμένει **dry-run/preflight hardening**.

Δεν κρίνω PASS χωρίς output — ορίστε τα μετρημένα, με το ΚΑΘΕ acceptance gate
A–J του [0023] §4 απαντημένο ρητά.

Commit: `468ecacb` — «FF2 measured-preflight: 5 νόμοι στην πύλη εξωτερικού benchmark».

---

## Οι 5 νόμοι — εγγύηση δια κατασκευής, όχι μπάλωμα

### §2.1 Raw-byte fingerprint law → `bytes-v2`
Το παλιό `(sha256-hex (uiop:read-file-string path))` περνούσε τα bytes μέσα από
**string** (UTF-8 decode → re-encode στη `sha256-hex`) — ακριβώς η παγίδα που
απαγορεύει το §2.1. Αντικαταστάθηκε με:

```lisp
(defun %ebg-file-fingerprint (path)
  (format nil "sha256:~A"
          (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))))
```

`ironclad:digest-file` κάνει **streaming πάνω σε `(unsigned-byte 8)`** — καμία
αποκωδικοποίηση, και δεν φορτώνει το αρχείο στη μνήμη (καλύτερο και για το
resource-condition policy). Δηλωμένος νόμος:

```lisp
(defparameter +ebg-fingerprint-law+ "bytes-v2")
```

Η αναφορά γράφει ρητά `fingerprint_law: bytes-v2` (βλ. output κατωτέρω) ώστε
κανένα legacy string-hash να μη συγχέεται με bytes-v2.

**Migration (§2.1):** έψαξα ΟΛΟ το repo — **δεν υπάρχει κανένα persisted EBG
fingerprint ούτε ζωντανό measured bundle**. Τα `*.prov.json` είναι data-source
provenance (χωριστή έδρα, `slw-source-prov/1`)· το `examples/benchmark-results.json`
είναι SPARQL latency benchmark. **Migration = μηδέν**, όπως προέβλεψε το §2.1.

### §2.2 One-form EOF / trailing-data law
Το `%ebg-read-data` επιστρέφει πλέον `(values form status)`:

```lisp
(let ((form (read s nil eof)))
  (if (eq form eof) (values nil :empty)
      (if (eq (read s nil eof) eof) (values form :ok)
          (values form :trailing))))
```

Στο `%ebg-validate`: `:empty → :schema_not_bundle`, `:trailing → :schema_trailing_data`.
Ο reader παραλείπει σχόλια/whitespace, άρα comment-trick που κρύβει δεύτερη
φόρμα **πιάνεται** (το δεύτερο read επιστρέφει τη φόρμα, όχι EOF). Trailing junk
που δεν είναι έγκυρη φόρμα → reader-error → `serious-condition` → `:unreadable`:
πάλι `:invalid`. Ουδεμία σιωπηλή αποδοχή κρυφού payload.

### §2.3 Boolean canonicalization
```lisp
(defun %ebg-canon-bool (v)
  (cond ((member v '(t :t)) (values t t))
        ((member v '(nil :nil)) (values nil t))
        (t (values nil nil))))
```

Κρίσιμο: ανάγνωση στο keyword package κάνει το γυμνό `nil` → `:NIL`, που είναι
**truthy symbol**. Ο κανόνας το χαρτογραφεί σε NIL. Το downstream ελέγχει ΜΟΝΟ
την `valid-p` (`nth-value 1`), ποτέ symbol-truthiness. Αφαιρέθηκε το νεκρό πλέον
`%ebg-booleanish-p`. Επιβεβαιωμένο: το `:stale-law-decoy-p` είναι το ΜΟΝΟ boolean
πεδίο· κάθε άλλο πεδίο συγκρίνεται με `eq` προς συγκεκριμένο keyword.

### §2.4 Exact bad-reason assertions
Ο macro `expect` συγκρίνει το reason με `eq` προς το αναμενόμενο why-code. Κάθε
negative selftest (18 συνολικά) ελέγχει ΑΚΡΙΒΩΣ τον κωδικό — «απέτυχε άρα καλά»
είναι αδύνατο. Αλλαγή reason ⇒ κόκκινο.

### §2.5 Resource-condition policy
```lisp
(defun %ebg-classify-condition (c)
  (if (typep c 'storage-condition) :resource_exhausted :unreadable))
;; handler: (serious-condition (c) (values :invalid (%ebg-classify-condition c) nil))
```

`storage-condition` (μνήμη/στοίβα/χώρος) → `:resource_exhausted`· κάθε άλλη
`serious-condition` → `:unreadable`. Διακριτά, χωρίς crash, χωρίς raw λεπτομέρεια
που ηχεί περιεχόμενο.

---

## Acceptance gates [0023] §4 — ένα προς ένα

| Gate | Απαίτηση | Απόδειξη |
|---|---|---|
| **A** | selftest count ↑ και περνά | 18 → **25/25** (⑲–㉕ νέοι) |
| **B** | ίδια bytes → ίδιο hash· 1 byte → διαφορετικό | ⑲ ✓ |
| **C** | string-norm trap: ίδιο render, διαφ. bytes → διαφ. hash | ⑳ (NFC U+00E9 vs NFD e+U+0301) ✓ |
| **D** | trailing second form → `schema_trailing_data` | ㉑ ✓· ㉒ (comment-trick) ✓ |
| **E** | `:NIL` δεν περνά ως truthy | ㉓ ✓· ㉔ (item :maybe → invalid) ✓ |
| **F** | exact bad-reason για κάθε negative | `expect` με `eq` σε ΟΛΑ ✓ |
| **G** | `resource_exhausted` ξεχωρίζει από `unreadable` | ㉕ ✓ |
| **H** | no-leak invariant πράσινο | ⑤ ✓ (αναφορά χωρίς hidden/visible/scoring/citation) |
| **I** | gate = dry-run only, όχι measured | verdict `:not-run`· `note: κανένα hidden item δεν εκτελέστηκε` |
| **J** | πλήρης σχετική ολομέλεια, known WARN χωριστά | **21/22**· advisor δηλωμένο κατωτέρω |

## Output — πύλη (25/25)
```
✓ ⑲ (B) bytes-v2: ίδια byte streams ⇒ ίδιο hash· αλλαγή 1 byte ⇒ διαφορετικό
✓ ⑳ (C) string-norm trap: ίδιο render (é), διαφορετικά bytes ⇒ ΔΙΑΦΟΡΕΤΙΚΟ hash
✓ ㉑ (D) trailing δεύτερη top-level φόρμα ⇒ :invalid / schema_trailing_data
✓ ㉒ (D′) block comment ΠΡΙΝ από κρυφή δεύτερη φόρμα ⇒ schema_trailing_data
✓ ㉓ (E) boolean canon: :NIL→NIL (όχι truthy)· :T→T· :maybe→invalid
✓ ㉔ (E′) item :stale-law-decoy-p :maybe (μη-boolean) ⇒ :invalid / schema_item_invalid
✓ ㉕ (G) resource policy: storage-condition→:resource_exhausted, error→:unreadable (διακριτά)

── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK: 25/25 αυτο-έλεγχοι πέρασαν · verdict: :not-run
   (κανένα bundle δεν προσκομίστηκε) · fingerprint_law: bytes-v2 ──
GATE --external-benchmark-gate EXIT=0
```

## Output — ολομέλεια (21/22)
```
════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (22) ════
  --advisor-gate: ΑΠΕΤΥΧΕ        ← env-only baseline (κάτω)
  --architecture-constitution-gate: ΠΕΡΑΣΕ
  --external-benchmark-gate: ΠΕΡΑΣΕ
  … (τα υπόλοιπα 20) ΠΕΡΑΣΕ
```

**advisor 10/15 = προϋπάρχον env-only κενό, ΟΧΙ FF2/path παλινδρόμηση.** Οι 5
αστοχίες είναι όλες dream/consultant materialized-decisions (γράψιμο πακέτων,
ανάγνωση ρήματος, ροή έγκρισης πολιτικής) — **μηδενικές αναφορές σε path, /app,
ή fingerprint**. Ίδια βασική γραμμή με το FF1 [0020]/[0021].

---

## §5 — «ο φρουρός εξίσου σωστός με την υλοποίηση»
Έκανα εστιασμένη **αυτο-αντιπαλική** ανάγνωση του φρουρού πριν την κατάθεση:
- Το `:empty` διατηρεί την προ-FF2 σημασιολογία (`:schema_not_bundle`).
- Trailing **junk** (όχι έγκυρη φόρμα) → `:unreadable`, όχι σιωπηλή αποδοχή.
- Σχόλιο **χωρίς** επόμενη φόρμα → `:ok` (τα σχόλια δεν είναι data· το
  fingerprint δεσμεύει τα ακριβή bytes· η αναφορά δεν τυπώνει τίποτα από το αρχείο).
- Κανένα άλλο πεδίο δεν διαβάζεται με symbol-truthiness (μόνο `:stale-law-decoy-p`).

**Απόφαση αρχιτεκτονικής (δηλώνω ρητά για κρίση):** το `%ebg-file-fingerprint`
καλεί `ironclad:digest-file` **απευθείας**, όχι μέσω `orchestrator.journal`. Λόγος:
η μόνη hashing έδρα του journal (`sha256-hex`) δέχεται **string** — είναι η ίδια η
παγίδα του §2.1. Το ironclad χρησιμοποιείται ήδη απευθείας σε 8 σημεία του repo
(merkle-tree, temporal-proof, anchor-blockchain, config-accessor…), άρα η απευθείας
χρήση είναι η καθιερωμένη πρακτική του κώδικα, όχι παράβαση επιπέδου. Το «bytes-v2»
είναι τοπικός νόμος της πύλης εξ ορισμού (η αναφορά δηλώνει `fingerprint_law`).

Η **τυπική** στατική/αντιπαλική επιθεώρηση ανήκει σε σένα, Κριτή, για το [0025]
([0023] §5). Αν βρεις εύρημα στον φρουρό → follow-up fix + selftest, όπως στο
lexer του FF1.

## Όρια που τηρήθηκαν ([0023] §3)
Κανένα: hidden set, real measured run, scorecard ως measured, νέο corpus,
self-study exposure, FF3, FF4, Ω+1, Ω+6. Μόνο FF2 preflight.

---
**Παραδοτέο:** FF2 = **PASS-CANDIDATE**. Αναμένω στατική επιθεώρηση + κρίση [0025].

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
