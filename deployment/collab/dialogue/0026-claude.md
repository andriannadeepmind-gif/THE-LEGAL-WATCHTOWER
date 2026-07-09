# [0026] Claude → Κριτή+δημιουργό · 2026-07-09 · FF2 follow-up — εύρημα [0025] κλεισμένο + 2 non-blocking notes

Δεκτή η κρίση [0025]. Το εύρημα ήταν σωστό: το exact bad-reason law (§2.4) ήταν
**μερικό** — τα item-level negatives επιβεβαίωναν μόνο το top-level
`:schema_item_invalid`, αφήνοντας το εσωτερικό item `:why` ανέλεγκτο. Ένα
regression που άλλαζε π.χ. `:item_scoring_missing → :item_layer_invalid` θα
περνούσε απαρατήρητο. Κλείστηκε. Έκλεισα ΚΑΙ τα δύο non-blocking notes —
ανώτατη πρακτική, όχι μπάλωμα.

Commit: `b4ace527`.

## 1. Blocking — `expect-item-why` (exact item-why law ΠΛΗΡΕΣ)

Νέος macro μέσα στον selftest· κάθε item-level negative απαιτεί **ταυτόχρονα**:

```lisp
(expect-item-why label file-text want-item-why)
;; ⇒ verdict = :invalid
;;   reason  = :schema_item_invalid
;;   (getf (first (getf info :bad-items)) :why) = want-item-why   ; eq
```

Το `:why` εκτίθεται ήδη από το `%ebg-validate` στο `info` ως
`(:bad-items ((:item-index i :why <code>) …))` — ο macro απλώς το **επιβάλλει**.
Μετατράπηκαν επί τόπου τα 5 item negatives (ίδιο count, αυστηρότερα):

| test | εσωτερικό `:why` που πλέον επιβάλλεται |
|---|---|
| ⑭ διπλότυπο id | `:schema_duplicate_id` (0008) |
| ⑮ χωρίς :scoring | `:item_scoring_missing` |
| ⑯ κενές citations χωρίς τίμια-άγνοια | `:item_required_citations_invalid` |
| ⑰ marker μόνο σε distractors | `:item_required_citations_invalid` |
| ㉔ :stale-law-decoy-p :maybe | `:item_stale_law_decoy_p_invalid` |

Αλλαγή οποιουδήποτε εσωτερικού why-code ⇒ **κόκκινο**. Το «απέτυχε άρα καλά»
είναι πλέον αδύνατο σε **κάθε** επίπεδο (bundle μέσω `expect` + item μέσω
`expect-item-why`).

Output:
```
✓ ⑭ διπλότυπο item :id ⇒ :schema_item_invalid · item :why=:schema_duplicate_id (0008)
✓ ⑮ item χωρίς :scoring ⇒ :schema_item_invalid · item :why=:item_scoring_missing
✓ ⑯ κενές :required-citations … ⇒ item :why=:item_required_citations_invalid (0009 §2.2)
✓ ⑰ κενές citations με marker ΜΟΝΟ σε distractors ⇒ item :why=:item_required_citations_invalid
✓ ㉔ item :stale-law-decoy-p :maybe ⇒ item :why=:item_stale_law_decoy_p_invalid
```

## 2. Note #1 — bounded/handled sidecar read

Το παλιό `(first (uiop:read-file-lines side))` έκανε **unbounded slurp** ΠΡΙΝ
από κάθε validation — αντίθετο με την ίδια την προϋπόθεση της πύλης («size caps
πριν από κάθε ανάγνωση»). Νέα έδρα:

```lisp
(defun %ebg-read-sidecar-fingerprint (bundle-path)
  … read-sequence σε buffer +ebg-sidecar-max-chars+ (512) …
     (serious-condition () nil))   ; χειρισμένο, ποτέ crash/leak
```

Κακόβουλο πολυ-GB `.sha256` **δεν φορτώνεται ποτέ**. Επιπλέον **latent bug**
που βρήκα διορθώνοντας: το παλιό `(string-trim " \t\r\n" …)` — στο CL string ο
backslash είναι single-escape, άρα `" \t\r\n"` = `" trn"` (τα **γράμματα** space/t/r/n,
ΟΧΙ tab/CR/LF). Δηλαδή δεν αφαιρούσε ποτέ πραγματικό CRLF. Τώρα:
`'(#\Space #\Tab #\Return #\Newline)` — σωστό.

Απόδειξη (ζωντανά):
```
VALID-SIDECAR    => "sha256:aa…aa"   (πρώτη γραμμή, CRLF stripped, 2η γραμμή αγνοήθηκε)
OVERSIZED-SIDECAR (5 MB, χωρίς newline) => length 512  (bounded· κατάντη fingerprint_format)
```

## 3. Note #2 — invalid-UTF-8 fixture (㉖)

Νέος helper `wrb` γράφει **ΩΜΑ bytes** (παρακάμπτει external-format). Το ㉖
γράφει ακολουθία μη-έγκυρου UTF-8 (`#xFF #xFE #x00 #x80 #xC3 #x28 …`) και δείχνει
ότι το `bytes-v2` fingerprint **λειτουργεί** εκεί που ένα `read-file-string`
(UTF-8) θα έριχνε decoding error — ίδια bytes ⇒ ίδιο hash, 1 byte ⇒ διαφορετικό.
Ενισχύει άμεσα την απόδειξη bytes-v2.

## Outputs

```
── ΠΥΛΗ ΕΞΩΤΕΡΙΚΟΥ BENCHMARK: 26/26 αυτο-έλεγχοι πέρασαν · verdict: :not-run · fingerprint_law: bytes-v2 ──
GATE --external-benchmark-gate EXIT=0

════ ΟΛΟΜΕΛΕΙΑ ΠΥΛΩΝ (22) ════   → 21/22 ΠΕΡΑΣΕ
  --advisor-gate: ΑΠΕΤΥΧΕ   ← προϋπάρχον env-only baseline (materialized-decisions), αμετάβλητο
  --external-benchmark-gate: ΠΕΡΑΣΕ
  … (υπόλοιπα 20) ΠΕΡΑΣΕ
```

## Όρια που τηρήθηκαν
Καμία αλλαγή στο trusted runtime path· κανένα hidden set/measured run/scorecard·
όχι FF3/FF4/Ω+. Μόνο FF2 preflight hardening.

---
**Παραδοτέο:** το blocking εύρημα [0025] κλεισμένο, τα 2 non-blocking notes κι
αυτά. Αναμένω σύντομη κρίση **[0027]**. FF3 verify-truth ΔΕΝ ανοίγει — περιμένει
ρητό `εγκρίνω` του δημιουργού.

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
