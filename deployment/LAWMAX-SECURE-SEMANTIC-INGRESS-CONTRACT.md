# LAWMAX — SECURE-SEMANTIC-INGRESS-CONTRACT (canonical trust boundary)
# EXTERNAL BYTES ≠ LISP FORMS — ΚΑΜΙΑ ΔΙΑΔΡΟΜΗ EXTERNAL INPUT → LISP READER/EVAL

**ΚΑΤΑΣΤΑΣΗ: `DESIGN-ONLY · ACTIVE SHARED TRUST FOUNDATION`.** Καμία γραμμή κώδικα, κανένα
freeze. Η **κανονική έδρα** (μία ανά έννοια) του trust boundary εισόδου, απαιτούμενη από
`CHANGE-PROPOSAL-v1.4.md §4.3/§4.4` και τον νόμο του repo «ΚΑΝΕΝΑ LLM/untrusted input στο
έμπιστο μονοπάτι». Επεκτείνει τη **μοναδική** υπάρχουσα έδρα ασφαλούς αποσειριοποίησης
`source/safe-read.lisp` (REUSE/EXTEND — **όχι** δεύτερη έδρα). POST-C2 closure §3.H/§4.8.

## 0. Ο αμετάκλητος invariant

**External bytes ΔΕΝ γίνονται ποτέ Lisp forms.** Δεν υπάρχει **καμία** διαδρομή
`external input → Lisp reader | reader-macro | macro-expander | compiler | eval`. Το
untrusted υλικό ταξιδεύει **μόνο** ως opaque bytes → constrained parser → **κλειστό typed
AST/Legal IR** (δεδομένα, όχι κώδικας). Παραβίαση ⇒ δομικά αδύνατη, όχι απαγορευμένη.

## 1. Taint states (μονότονη, μη αναστρέψιμη προαγωγή)

```
UNTRUSTED → PARSED → VALIDATED → ADOPTED → CANONICAL
```
- **UNTRUSTED:** opaque bytes (PDF/XML/HTML/OCR/JSON/feed). Καμία ικανότητα.
- **PARSED:** προϊόν sandboxed parser = **κλειστό typed AST** (Legal IR node set), ποτέ
  Lisp form. Μεταπήδηση μόνο μέσω structural validator.
- **VALIDATED:** πέρασε deterministic **symbolic** validator (schema + typing + anchors).
- **ADOPTED:** reviewer/InstitutionalAct adoption όπου θεσμικό (§4.9 τάξη 3).
- **CANONICAL:** μέσα σε υπογεγραμμένο release. **Ποτέ** χωρίς πλήρη αλυσίδα.

Καμία κατάσταση δεν παρακάμπτεται· κάθε μετάβαση journaled (L1). Regressive μετάβαση ⇒
`ingress-nonmonotonic-taint` (fail-closed).

## 2. Sandboxed parsing (out-of-process, capability-less)

PDF/XML/HTML/OCR/archive parsing εκτελείται σε **απομονωμένο process** (§4.4 external
runtime) με **καμία** ικανότητα filesystem / network / subprocess / clock-write. Επικοινωνία
μόνο μέσω του closed `neural-task/1` ↔ `neural-candidate/1` protocol (canonical JSON,
`safe-read.lisp` = **μοναδικό** σημείο εισόδου αποσειριοποίησης). Ο parser επιστρέφει
**typed AST bytes**, ποτέ εκτελέσιμο.

## 3. Απαγορεύσεις στο trusted (Lisp) επίπεδο — πολυεπίπεδη άμυνα

- `*read-eval*` **disabled** — αλλά **ΟΧΙ ως μοναδική άμυνα** (defense in depth).
- **Απαγόρευση `read-from-string` / `read` πάνω σε untrusted input** — καμία κλήση reader
  σε external bytes· ο μόνος parser είναι ο constrained grammar parser (όχι ο Lisp reader).
- **Reader-macro / dispatch-macro escape prevention:** custom readtable **χωρίς** ενεργά
  reader macros για untrusted paths· `#.`, `#,`, `#+/#-`, `#(`, `#*` κ.λπ. αδρανή.
- **Package / symbol escape prevention:** καμία `intern`/`find-symbol` από external bytes·
  κανένα `pkg::sym` δεν προκύπτει από untrusted input· symbols του AST είναι **κλειστό,
  προ-δηλωμένο σύνολο keywords** (node kinds), όχι δυναμικά interned.
- **No package qualifier, no `|escaped|`, no `\` escapes** που να αλλάζει symbol resolution.

## 4. Constrained grammar + structural + symbolic validators

- **Constrained grammar:** το untrusted parsing δέχεται **μόνο** τη γλώσσα του τύπου
  (ST-nn profile, source-registry)· ό,τι δεν ανήκει ⇒ `ingress-grammar-violation`.
- **Structural validator:** επιβάλλει το closed AST schema (βάθος, arity, κλειστά kinds).
- **Deterministic symbolic validator:** typing + anchors + no-boolean-in-hash-record.
- **Neural semantic detector:** **μη εξουσιοδοτική ένδειξη** μόνο (`neural-candidate/1`,
  PLANE-3)· ποτέ δεν προάγει μόνο του UNTRUSTED→VALIDATED (I-4.3a). «Semantically
  valid-looking malicious» υλικό απορρίπτεται από τον **symbolic** validator, όχι από το neural.

## 5. Τρεις ΞΕΧΩΡΙΣΤΕΣ είσοδοι (καμία σύγχυση)

| είσοδος | τι δέχεται | trust path | ποτέ |
|---|---|---|---|
| **Legal ingestion** | opaque legal bytes (ST-nn) | §2 sandbox → AST → validators | ποτέ Lisp form· ποτέ code |
| **Cockpit intent** | typed `cockpit_intent` (§4.12, κλειστό σχήμα, RBAC/MFA) | signed intent → M5 queue | ποτέ direct-publish· ποτέ eval |
| **Code changes** | source diffs | ανθρώπινη έγκριση + gates (L12) | ποτέ από legal/cockpit input |

Η σύγχυση των τριών (π.χ. legal bytes ως code, ή cockpit intent ως legal object) ⇒
`ingress-channel-confusion` (fail-closed).

## 6. Extension error taxonomy (διακριτή από MLTP §4.3)
```
ingress-nonmonotonic-taint · ingress-grammar-violation · ingress-channel-confusion ·
read-time-execution-attempt · reader-macro-escape · package-symbol-escape ·
excessive-nesting · decompression-bomb · xml-entity-expansion · injected-directive ·
ontology-poisoning-candidate · unvalidated-neural-promotion
```
Κάθε όνομα έχει βήμα εκπομπής (§4/§5). Καμία boolean σε hash-record.

## 7. Predeclared kill tests (design-only, ΜΗ εκτελεσμένα) — κάθε ένα αποδεικνύει ΜΗΔΕΝΙΚΗ παρενέργεια

| SIK | επίθεση | αναμενόμενο |
|---|---|---|
| **SIK-1** | read-time execution (`#.(delete-file ...)` σε untrusted) | `read-time-execution-attempt`· 0 side effect (no file/proc/net) |
| **SIK-2** | reader macro / dispatch escape | `reader-macro-escape`· inert readtable |
| **SIK-3** | package/symbol escape (`cl-user::*x*`) | `package-symbol-escape`· καμία intern |
| **SIK-4** | excessive nesting (10^6 βάθος) | `excessive-nesting`· bounded, no stack blow |
| **SIK-5** | archive/PDF decompression bomb | `decompression-bomb`· bounded output, sandbox killed |
| **SIK-6** | XML entity expansion (billion laughs) | `xml-entity-expansion`· entities disabled |
| **SIK-7** | prompt injection στο κείμενο εγγράφου | `injected-directive`· neural = μη εξουσιοδοτικό· καμία εντολή εκτελείται |
| **SIK-8** | ontology poisoning (κακόβουλο mapping candidate) | `ontology-poisoning-candidate`· symbolic validator απορρίπτει· καμία CANONICAL προαγωγή |
| **SIK-9** | semantically valid-looking malicious legal candidate | απορρίπτεται από deterministic symbolic validator (όχι neural)· μένει PLANE-3 |

**Απόδειξη μηδενικής παρενέργειας:** κάθε SIK τρέχει σε sandbox με 0 capabilities· το
harness επιβεβαιώνει καμία εγγραφή fs/net/proc, καμία μεταβολή taint state πέρα από
`UNTRUSTED`. (Implementation Book work package· ΜΗ εκτελεσμένο.)

## 8. Έδρες & τι ΔΕΝ κάνει

**Έδρες:** `safe-read.lisp` (μοναδικό deserialization entry: EXTEND)· `document-fetch.lisp`
(external fetcher orchestration πρότυπο: REUSE)· §4.3/§4.4 neural runtime (sandbox host).
**MISSING (Implementation Book):** capability-less sandbox host, constrained-grammar
parsers ανά ST, taint-state enforcer, SIK harness. **Δεν** υλοποιεί τίποτα· δεν είναι
γενική παράγραφος ασφαλείας — είναι **δομικό trust boundary** με invariant, taint states,
κλειστή error taxonomy και predeclared kill tests.
