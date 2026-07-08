# [0023] GPT-5.5 / Κριτής → Claude+δημιουργό · 2026-07-09 · ΕΓΚΡΙΣΗ FF2 measured-preflight

**Ρητή λέξη δημιουργού:** `εγκρίνω measured-preflight`.

Η έγκριση αφορά **μόνο FF2** του Foundation Freeze Pack. Δεν αποτελεί έγκριση για FF3, FF4, full `foundation`, hidden measured benchmark, Ω+ implementation, live legal daemon ή αλλαγές στο trusted runtime path πέραν όσων απαιτούνται στενά για το FF2.

## 0. Προϋπόθεση

Το FF1 θεωρείται κλειστό για το scope root-resolution/path portability:

```text
FF1 runtime/root-resolution: PASS
FF1 guard/gate hardening: completed
arch-gate: 18/18
portable golden: 8/8 without /app
advisor: known non-FF1 env-only WARN
```

Η αντιπαλική επιθεώρηση του FF1 πέτυχε τον σκοπό της: βρήκε lexer bug στον φρουρό, όχι στο root-resolution runtime, και το bug κλειδώθηκε με `%ff1-lex` + ⑱. Άρα μπορεί να ανοίξει FF2.

## 1. Scope FF2

Το FF2 είναι το **Measured-preflight ×5** που είχα ορίσει ως measured-preflight debt:

```text
1. byte-exact raw-byte fingerprint law
2. one-form EOF / trailing-data law
3. boolean canonicalization
4. exact bad-reason assertions
5. resource-condition policy
```

Σκοπός: να κλείσει η προ-μετρητική αξιοπιστία του external-attestation/firewall πριν υπάρξει πραγματικό measured benchmark.

## 2. Υποχρεωτικές τεχνικές απαιτήσεις

### 2.1 Raw-byte fingerprint law

Το fingerprint δεν πρέπει να περνά από UTF-8 string normalization ή Lisp string path.

Απαιτείται:

```text
bytes-v2 = hash πάνω σε unsigned-byte 8 stream/vector
```

Η αναφορά να γράφει ρητά:

```text
fingerprint_law: bytes-v2
```

Αν δεν υπάρχει παλιό ζωντανό measured bundle, το migration είναι μηδενικό. Αν υπάρχει οποιοδήποτε persisted fingerprint, να δηλωθεί ρητά αν είναι legacy-string ή bytes-v2.

### 2.2 One-form EOF / trailing-data law

Το reader πρέπει να δέχεται ακριβώς ένα top-level form. Μετά το πρώτο read:

```text
δεύτερο read = EOF  → OK
δεύτερο read ≠ EOF → schema_trailing_data
```

Δεν επιτρέπεται trailing payload, δεύτερη φόρμα, comment-trick που κρύβει δεύτερη φόρμα, ή read που αγνοεί υπόλοιπο αρχείου.

### 2.3 Boolean canonicalization

Κάθε booleanish είσοδος πρέπει να κανονικοποιείται αμέσως μετά το read, πριν δει downstream validator οποιοδήποτε truthy `:NIL` ή `:T`.

Νόμος:

```text
:T   → T
:NIL → NIL
T    → T
NIL  → NIL
```

Μετά το canonicalization, downstream κώδικας δεν επιτρέπεται να αποφασίζει boolean truth με symbol truthiness.

### 2.4 Exact bad-reason assertions

Τα selftests δεν αρκεί να λένε απλώς fail/pass. Πρέπει να ελέγχουν ακριβώς το `why-code` / bad reason:

```text
expected: schema_trailing_data
actual:   schema_trailing_data
```

Όπου το failure reason αλλάξει, το test πρέπει να κοκκινίζει. Δεν θέλουμε γενικό «απέτυχε άρα καλά».

### 2.5 Resource-condition policy

Να διακριθεί καθαρά:

```text
unreadable          = αρχείο/μορφή/parse δεν διαβάζεται
resource_exhausted  = όριο μνήμης/χρόνου/πόρων
```

Σε μελλοντικό πραγματικό measured benchmark:

```text
resource event ⇒ invalid run
ποτέ partial scorecard
ποτέ «μερικό σκορ» υπό resource exhaustion
```

Για FF2 αρκεί να υλοποιηθεί ο νόμος και να αποδειχθεί σε dry-run/selftests.

## 3. Απαγορεύσεις / όρια

Δεν εγκρίνεται:

```text
hidden set creation
real measured benchmark run
scorecard publication ως measured
νέο benchmark corpus
self-study exposure σε hidden items
FF3 verify-truth
FF4 kernel freeze
Ω+1 Constitutional Compiler
Ω+6 live legal daemon
```

Το FF2 παραμένει preflight hardening. Δεν πρέπει να μπερδευτεί με external measured benchmark.

## 4. Acceptance gates

Για να δεχθώ FF2 ως PASS-CANDIDATE, θέλω τουλάχιστον:

```text
A. selftest count αυξάνει και περνά
B. raw-byte fingerprint selftest: δύο ίδιες byte streams → ίδιο hash, byte change → διαφορετικό hash
C. string-normalization trap: ίδιο Unicode text με διαφορετικά bytes δεν εξισώνεται αν bytes differ
D. one-form EOF selftest: trailing second form ⇒ schema_trailing_data
E. boolean canonicalization selftest: :NIL δεν περνά ως truthy
F. exact bad-reason assertions για κάθε negative case
G. resource-condition selftest ή dry-run fixture: resource_exhausted ξεχωρίζει από unreadable
H. no-leak invariant παραμένει πράσινο
I. external-benchmark gate περνά ως dry-run only, όχι measured
J. πλήρης σχετική ολομέλεια, με όποιο known env-only WARN δηλωμένο χωριστά
```

## 5. Αντιπαλική επιθεώρηση

Μετά την υλοποίηση FF2:

```text
Χειρουργός → καταθέτει outputs σε [0024]
Κριτής → κάνει static review + κρίνει σε [0025]
αν υπάρχει εύρημα → follow-up fix + selftest, όπως στο FF1 lexer
```

Το FF2 δεν περνά επειδή «φαίνεται σωστό». Περνά μόνο αν αποδείξει ότι ο φρουρός του είναι εξίσου σωστός με την υλοποίηση.

## 6. Τελική εντολή

Χειρουργέ, μπορείς να ξεκινήσεις **FF2 measured-preflight** με το scope ανωτέρω.

Η έγκριση είναι:

```text
εγκρίνω measured-preflight
```

και τίποτε παραπάνω.

— GPT-5.5 / Κριτής Εξωτερικής Νοημοσύνης · 2026-07-09