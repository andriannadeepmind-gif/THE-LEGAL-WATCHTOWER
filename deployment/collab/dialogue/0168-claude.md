# 0168 — OPTION-2 CORE · R6-2 ΣΥΣΤΗΜΙΚΟ ΚΛΕΙΣΙΜΟ ΤΗΣ ΚΛΑΣΗΣ ΟΛΙΚΟΤΗΤΑΣ ΣΦΑΛΜΑΤΟΣ

**Ρόλος:** Χειρουργός Πυρήνα. **Parent/base:** `49e0fc2bd8b1f4f25d2750df618914f65d8b7b3d`
(tree `5f171d8c…`, model root `e802249e…`). **Κυβερνών τεκμήριο:** η ανεξάρτητη επιβεβαίωση του `49e0fc2b`, που
**απέρριψε** τη μικροδιόρθωση ως μερική: η ίδια κλάση επιβίωνε στα `--kind fixtures|component|composed` με έδρα
`run_corpus.py:1918` μέσα στο `universe_integrity()` — και η εντολή του δημιουργού
*R6-2 ERROR-TOTALITY SYSTEMIC CLOSURE*.

**Εύρος που ΔΕΝ αγγίχτηκε:** `TOOLCHAIN.sexp`, κύκλος ζωής authorization του R6-1, `SEXP-READER.py`,
`gate_checks.py`, `MODEL-SCHEMA.sexp`, `CLAUDE.md`, DDI‑1…DDI‑4, production/protected/frozen paths. Κανένα
άσχετο refactoring, καμία νέα γενική πολιτική. Schema αμετάβλητη στο `6` — η γραμματική δεν άλλαξε.

---

## 1. Γιατί ο φρουρός δεν αρκούσε
Η προηγούμενη διόρθωση έβαλε `try/except` γύρω από **ένα** σημείο (`--count`). Το `run_corpus.py` όμως καλούσε
`SR.read_model` σε **επτά** σημεία, και η κλήση στο `universe_integrity()` κυριαρχεί και στα τρία `--kind`
entry points. Φρουρός γύρω από λάθος σχήμα δεν εξαλείφει την κλάση.

## 2. Η αναπαραγωγή πριν από κάθε αλλαγή — 4 διαδρομές × 2 σχήματα

| διαδρομή | malformed | missing |
|---|---|---|
| `--count COMPOSED_GATE` | exit 1, traceback 0, typed 1 | exit 1, traceback 0, typed 1 |
| `--kind fixtures` | exit 1, **traceback 9 γρ.**, typed 0 | exit 1, **traceback 7 γρ.**, typed 0 |
| `--kind component` | exit 1, **traceback 9 γρ.**, typed 0 | exit 1, **traceback 7 γρ.**, typed 0 |
| `--kind composed` | exit 1, **traceback 9 γρ.**, typed 0 | exit 1, **traceback 7 γρ.**, typed 0 |

Κανένα false PASS σε καμία περίπτωση: οι μετρούμενοι έλεγχοι απέτυχαν πάντα κλειστά.

## 3. Η συστημική διόρθωση — μία έδρα
Νέα συνάρτηση `read_model(source=HERE, **kw)` στο `run_corpus.py`: **το μοναδικό σημείο του προγράμματος που
καλεί `SR.read_model`**. Μετατρέπει **μόνο** τις δηλωμένες αστοχίες του αναγνώστη — `SR.MissingSourceFile` →
`MISSING-MODEL-FILE`, `SR.SexpError` → `UNREADABLE-MODEL-FILE` — στο υπάρχον typed λεξιλόγιο της έδρας
`gate_checks.model()`. **Καμία** `except Exception` / `except BaseException` / γυμνή `except`: ό,τι είναι έξω
από τη δηλωμένη κλάση παραμένει προγραμματιστικό σφάλμα και κρατά το traceback του.

Και οι **επτά** κλήσεις περνούν πλέον από αυτήν: `root_modules`, `corpus`, `declared_falsifiers`, `_auth`,
`_composed_ids`, `universe_integrity`, `__main__ --count`. Το inline `try/except` της προηγούμενης διόρθωσης
**αποσύρθηκε** — μία έδρα, όχι δύο. Απόδειξη: `grep -c 'SR\.read_model('` = **1**, μέσα στην κοινή έδρα.

Καμία από τις επτά δεν διαβάζει mutated αντίγραφο (όλες διαβάζουν το `HERE`· το `root_modules` καλείται μία
φορά, με `HERE`), οπότε η μετατροπή δεν μπορεί να μετατρέψει καταγεγραμμένη απόρριψη falsifier σε διακοπή.

## 4. Μετά — και οι οκτώ τυποποιημένες

| διαδρομή | malformed | missing |
|---|---|---|
| `--count COMPOSED_GATE` | exit 1, tb 0, `UNREADABLE-MODEL-FILE` | exit 1, tb 0, `MISSING-MODEL-FILE` |
| `--kind fixtures` | exit 1, tb 0, `UNREADABLE-MODEL-FILE` | exit 1, tb 0, `MISSING-MODEL-FILE` |
| `--kind component` | exit 1, tb 0, `UNREADABLE-MODEL-FILE` | exit 1, tb 0, `MISSING-MODEL-FILE` |
| `--kind composed` | exit 1, tb 0, `UNREADABLE-MODEL-FILE` | exit 1, tb 0, `MISSING-MODEL-FILE` |

Καλοσχηματισμένα controls: `--count` 12 / 108 στο exit 0· και τα τρία `--kind` περνούν το όριο ανάγνωσης
μοντέλου κανονικά (`--kind fixtures` → 8 golden + 83 generated, 0 failures).

## 5. Μόνιμη προστασία
`X130` διατηρείται για το `--count`. Νέος **παραμετροποιημένος** `X131-KIND-MODEL-READS-TYPED` (COMPONENT):
τρία `--kind` entry points × {malformed, missing} = **έξι υποπεριπτώσεις**, καθεμία απαιτεί exit ≠ 0, τον σωστό
typed marker, μηδέν `Traceback`, μηδέν false PASS.

**Δεν είναι ταυτολογία.** Στην αδιόρθωτη βάση `49e0fc2b` (κοινή έδρα χωρίς τη μετατροπή, harness αμετάβλητο):
`NOT REJECTED` με **και τις έξι** υποπεριπτώσεις `typed=False traceback=True`. Στη διορθωμένη:
`REJECTED as intended`.

`UF-FALSIFIER` **119 → 120** (αύξηση ορίου, δεν απαιτεί authorization).

## 6. Ετυμηγορία
> `R6-2 ERROR-TOTALITY CLASS SYSTEMICALLY CLOSED — AWAITING FINAL BOUNDED INDEPENDENT CONFIRMATION —
> VERIFIER INFRASTRUCTURE NOT YET LOCKED — DDI-1 BLOCKED — NOT FROZEN — NOT QUALIFIED — IMPLEMENTATION BLOCKED`

Κανένα structural PASS δεν παρουσιάζεται ως semantic, legal, security, behavioural, operational ή qualification
proof. Στάση.
