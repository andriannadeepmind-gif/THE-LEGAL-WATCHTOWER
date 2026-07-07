# LAWMAX UNDERSTANDING-LEARNING SUBSTRATE — SCHEMAS v1
**Το υπόστρωμα που κάνει το bot-patching αδύνατο εκ κατασκευής.**
Εντολή δημιουργού 2026-07-07. Πρώτο παραδοτέο: σχήματα + plumbing + φρουροί —
ΟΧΙ «έμαθε νέα ερώτηση».

## Θεμελιώδης διάκριση (όρος #5)

**surface evidence ≠ understanding rule.**
- Οι *feature extractors* (όργανα, bootstrap) ΕΠΙΤΡΕΠΕΤΑΙ να βλέπουν tokens:
  δείκτες, κλίσεις, αντωνυμίες, ερωτηματικές μορφές, παραπομπές — κλειστές
  γραμματικές κλάσεις.
- Οι *adopted understanding rules* ΑΠΑΓΟΡΕΥΕΤΑΙ να περιέχουν exact phrase
  trigger / regex πρόθεσης / keyword shortcut / hardcoded answer. Η γλώσσα
  κανόνων δεν διαθέτει καν τέτοιο χαρακτηριστικό: κανόνας = συζευκτική
  συνθήκη ΜΟΝΟ πάνω σε ονόματα του κλειστού μητρώου χαρακτηριστικών
  (`validate-understanding-rule` απορρίπτει ονομαστικά κάθε άλλο).

Χαρακτηριστικά v1 (αντιστοίχιση στο αφηρημένο λεξιλόγιο του δημιουργού):

| Abstract feature (creator) | Extractor v1 (seat: *understanding-features*) |
|---|---|
| speech_act | `question` (utterance-act, κλειστή γραμματική κλάση) |
| referential_dependency | `reference-marker` (κλειστή κλάση δεικτών διευκρίνισης/δείξης) |
| previous_utterance_available | `has-last-answer` (μνήμη συνεδρίας) |
| explainable_span_available | `quoted-span-in-last-answer`, `last-answer-has-source` |
| legal_corpus_needed | `legal-concept` (γειωμένο λεξικό/ταξινομία) |
| self_model_needed | `second-person` (+ επέκταση v2) |
| computation_needed | `arithmetic-expression` (μορφή, όχι λεξιλόγιο) |
| requested_operation / uncertainty_status / mode-transition | v2 — δηλωμένο χρέος |

## A. FAILURE LEDGER — `deployment/state/failure-ledger.jsonl`
Έδρα: το ΙΔΙΟ state stream με τα lessons (δομημένη επέκταση, append-only)·
επιθεώρηση: `--failures` + gap-ledger-frame στον διάλογο.

```
{ failure_id, input, previous_context, produced_mode,
  expected_mode_if_known, wrong_behavior, trace_id, gap_id, status, ts }
```

## B. UNDERSTANDING PROPOSAL (δομημένο αντικείμενο — ΟΧΙ code patch)

```
(:understanding-proposal
 :proposal-id …            :observed-failure-ids (…)
 :abstract-failure-class … ; π.χ. "self-meta↛conversation-reference"
 :induced-frame …          ; αφηρημένη κατηγορία-στόχος
 :rule (:understanding-rule :id … :when ((feature . bool)…) :frame …)
 :required-features (…)    ; ΜΟΝΟ ονόματα του μητρώου
 :why-not-phrase-specific … ; αποδείξιμο: η γλώσσα δεν εκφράζει φράσεις
 :affected-modes (…) :affected-contracts (…)
 :positive-tests (…) :negative-tests (…) :held-out-tests (…)
 :regression-tests "--dialogue-gate πλήρης"
 :rollback-plan "αφαίρεση pack (hot) — διερμηνέας διάφανος"
 :shadow (…βλ. C…) :decision …)
```

## C. SHADOW EVALUATION (μέσα στην πρόταση — καμία σιωπηλή κρίση)

```
(:shadow :candidate-rule-id …
 :stable-result …          ; πώς ταξινομεί ο ΣΤΑΘΕΡΟΣ εαυτός το original
 :candidate-result …       ; πώς ταξινομεί ΜΕ τον κανόνα (δυναμική σκιά)
 :original-fixed t/nil :positives-failed N :negatives-fired N
 :held-out-passed (k n) :regression-green t/nil)
:decision DENIED | QUARANTINE | REQUIRES-HUMAN   ; ADOPTABLE ⇒ μόνο μετά υπογραφή
```

Φρουροί (acceptance criteria #7 — επιβαλλόμενοι, όχι ευχές):
- χωρίς negative tests ⇒ DENIED · negatives πυροδοτούν ⇒ DENIED (υπεργενίκευση)
- original δεν διορθώνεται ⇒ DENIED · regression (πλήρης σουίτα διαλόγου) κόκκινη ⇒ DENIED
- held-out < 2/3 ⇒ QUARANTINE («έμαθε μόνο τη φράση» = ποτέ pass)
- χωρίς rollback ⇒ δεν συντίθεται καν πρόταση
- phrase literal ⇒ αδιατύπωτο στη γλώσσα (② της πύλης)

## D. HUMAN ADOPTION QUEUE — η ΥΠΑΡΧΟΥΣΑ ουρά Σ11 (`proposals` / `--thoughts` / `--approve`)

```
{ proposal_id, decision, reason, signature_required: ΠΑΝΤΑ t,
  adopted_generation_if_any, rollback_target }
```
Υιοθεσία = εγκατάσταση pack `:understanding-rules` (hot, αναστρέψιμη)·
μέχρι τότε ο κανόνας ΔΕΝ υπάρχει για τον διερμηνέα.

## Ροή (όρος #9 — καμία απευθείας γραφή production classifier)

```
failure → proposal → shadow → evaluation → human approval → adoption(pack)
```
Ο διερμηνέας (`learned-understanding`, εγγεγραμμένος ΠΡΩΤΟΣ) διαβάζει ΜΟΝΟ
υιοθετημένα packs· χωρίς αυτά είναι διάφανος.

## BOOTSTRAP δήλωση (όρος #8)

Όλο το χειροποίητο περιεχόμενο διαλόγου (ταξινομητές cognition-self/legal,
glossary entries, τα regex του «conversation» classifier) είναι **BOOTSTRAP
ΣΚΑΛΩΣΙΑ**: αναγκαία όργανα/αφετηρία — **ΔΕΝ συνιστά μάθηση και δεν
επικαλείται ως απόδειξη νόησης.** Απόδειξη νόησης = ΜΟΝΟ κανόνες που μπήκαν
από τη ροή failure→proposal→shadow→υπογραφή, μετρημένοι σε blind audit.

## Falsifiable test (αποδεκτό από τον δημιουργό)

Νέες αποτυχίες χωρίς εξήγηση → καμία ανθρώπινη επέμβαση σε classifier/regex/
glossary/intent → ledger → γενική πρόταση → held-out → σκιά → υπογραφή →
blind dialogue audit. Αν χρειαστεί ανθρώπινο χέρι στον ταξινομητή: αποτύχαμε.
