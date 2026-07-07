# LAWMAX Φ1 — UNIVERSAL TURN ID / ROOT SPAN · DESIGN ONLY
**ΣΧΕΔΙΟ, ΟΧΙ ΥΛΟΠΟΙΗΣΗ.** Καμία γραμμή runtime κώδικα δεν αλλάζει από αυτό το
κείμενο. Η υλοποίηση = ξεχωριστό βήμα 3 της κλειδωμένης σειράς, με δικό της
gate και ρητό ΟΚ. Ζεύγος: `LAWMAX-PHASE-1-TURN-ROOT-SPAN-DESIGN.sexp`.
Προέλευση: M1 του Memory Kernel Spec (P1 debt 62570e60) · keystone του
InstitutionalAct (CPEI: act_id/turn_id = τα 2 από τα 3 declared-gaps).

## 1 · Το πρόβλημα που λύνει (από την πηγή, όχι αφήγηση)

Σήμερα ένας γύρος `--ask` γεννά ΤΕΣΣΕΡΑ ασύνδετα ίχνη:

| Τι | Πού | Ταυτότητα σήμερα |
|---|---|---|
| Envelope | stdout | καμία — εφήμερο κείμενο |
| Episode | `episodes.sexp` | eid = sha(kind\|text\|at\|prev) — δικό του |
| Failure record | `failure-ledger.jsonl` | fid = sha(input\|context) — δικό του |
| Trace root-span | `*events*` (RAM) | αύξων ακέραιος id — δικό του |
| Gap | (μέσα στο envelope/ledger) | gid = sha(q) — δικό του |

Κανένα κοινό κλειδί. «Δείξε μου ΟΛΟ τον γύρο Χ» = αδύνατο χωρίς συσχέτιση με
την… ώρα. Ο CPEI στόχος (InstitutionalAct) απαιτεί έναν γονέα.

## 2 · Σχεδιαστική αρχή (κλειδωμένη)

**Το turn_id είναι ΠΕΔΙΟ που διατρέχει τις ΥΠΑΡΧΟΥΣΕΣ έδρες — ΟΧΙ νέο store,
ΟΧΙ νέο αρχείο, ΟΧΙ νέο subsystem.** Κάθε έδρα κρατά το δικό της id όπως
σήμερα (καμία αναδρομική αλλαγή σχημάτων)· απλώς αποκτά ΚΑΙ το κοινό
`turn_id`. Projections rebuild από τα events — το turn_id τα κάνει joinable.

## 3 · Ταυτότητες

- **`turn_id`** = `turn:<sha256-12>` όπου sha256(input ‖ iso-timestamp ‖
  process-nonce ‖ αύξων-μετρητής-γύρου). Μοναδικό ανά γύρο, ντετερμινιστικά
  παραγόμενο ΜΙΑ φορά στην είσοδο του `run-ask`, ΠΡΙΝ από κάθε ταξινόμηση —
  ώστε και το «δεν κατάλαβα» να το φέρει.
- **`root_span_id`** = το ΥΠΑΡΧΟΝ ρίζα-span id του trace (provenance-gate ⑨:
  «εντολή ⇒ ρίζα-span» ήδη ισχύει). ΔΕΝ αντικαθίσταται — το root-span αποκτά
  `:turn-id` στο data plist του. Σχέση: 1 turn_id ↔ 1 root_span_id ανά γύρο.
- Το μελλοντικό `act_id` (CPEI) = παράγωγο του turn_id — ΕΚΤΟΣ αυτής της φάσης.

## 4 · Τα 8 δεσίματα (ένα-ένα, με την έδρα υποδοχής)

| # | Δέσιμο | Έδρα | Πώς (στην υλοποίηση) |
|---|---|---|---|
| 1 | **turn_id** | `run-ask` (decisions.lisp) | γεννιέται στην είσοδο, δεσμεύεται dynamic var `*current-turn-id*` για τη διάρκεια του γύρου |
| 2 | **root_span_id** | execution-trace | το root-span του γύρου παίρνει `:turn-id` στο data· `turn_id ↔ tevent-id` αμφίδρομα |
| 3 | **envelope link** | `%ask-envelope` | νέες γραμμές `turn_id:` + `root_span_id:` σε ΚΑΘΕ έξοδο (πάντα, όχι μόνο σε αποτυχία) |
| 4 | **episode link** | `record-episode` (:props) | `:turn-id <id>` στα props του :interaction episode — το σχήμα ΔΕΝ αλλάζει, props είναι ήδη ανοιχτό plist |
| 5 | **failure-ledger link** | `record-dialogue-failure!` | νέο JSON πεδίο `"turn_id"` δίπλα στα υπάρχοντα — append-only, παλιές γραμμές ΧΩΡΙΣ turn_id μένουν έγκυρες (πεδίο optional στο read) |
| 6 | **trace link** | όλα τα child spans | κληρονομούν το turn_id μέσω του root-span γονέα — ΚΑΜΙΑ αλλαγή στα child events |
| 7 | **gap_id link** | gap δημιουργία στο run-ask | το gap record/envelope φέρει και turn_id· gid μένει ως έχει (σταθερό ανά ερώτηση, ΣΚΟΠΙΜΑ — ίδια ερώτηση = ίδιο gap, άλλος γύρος) |
| 8 | **recall link** | gap-ledger-frame («δείξε μου τι κατέγραψες») + νέο ερώτημα «δείξε μου τον γύρο <turn_id>» | η ανάκληση δείχνει ΟΛΟ τον γύρο: input, mode, episode eid, fid, gid, root_span — joined πάνω στο turn_id |

## 5 · Αναλλοίωτα (τα gates της υλοποίησης — βήμα 3)

1. Κάθε `--ask` γύρος εκπέμπει turn_id στο envelope — ΠΑΝΤΑ (και answered και
   not-understood και refused).
2. Το ΙΔΙΟ turn_id εμφανίζεται σε: envelope ∧ episode props ∧ (αν γράφτηκε
   failure) ledger line ∧ root-span data. Τεστ: ένας γύρος → grep το id και
   στα τέσσερα.
3. Δύο διαδοχικοί γύροι ⇒ ΔΙΑΦΟΡΕΤΙΚΑ turn_ids (μοναδικότητα), ακόμη και με
   ίδια ερώτηση.
4. Παλιές εγγραφές χωρίς turn_id διαβάζονται κανονικά (backward-compat — το
   πεδίο είναι προσθετικό, ποτέ απαιτούμενο στο read).
5. P0 invariant ΑΘΙΚΤΟ: το memory_recorded παραμένει append+read-back — το
   turn_id απλώς συμμετέχει στο γραφόμενο record.
6. Κανένα νέο αρχείο στον δίσκο (architecture-gate ⑨ πράσινο αμετάβλητο).
7. Recall γύρου: «δείξε μου τον γύρο turn:…» επιστρέφει τα joined στοιχεία ή
   τίμιο «δεν βρέθηκε».

## 6 · Τι ΔΕΝ κάνει η Φ1

Κανένα νέο store/ledger/αρχείο · καμία αλλαγή στα υπάρχοντα ids (eid/fid/gid/
span-id μένουν) · καμία μετανάστευση παλιών δεδομένων · όχι session-persistence
(αυτό = Φ2/M2) · όχι act_id/jurisdiction (CPEI αργότερα) · όχι Runner/learning.

## 7 · Σχέδιο υλοποίησης (βήμα 3, μετά από ΟΚ)

Αγγίζονται ΜΟΝΟ: `decisions.lisp` (γέννηση + envelope + gap δέσιμο),
`memory.lisp` ή ο καλών του record-episode (1 prop), `understanding-learning.lisp`
(1 JSON πεδίο), `execution-trace.lisp`/exec-provenance (root-span data +
κληρονομιά), `cognition-self.lisp` (recall γύρου στο gap-ledger-frame).
+ Νέοι έλεγχοι στα ΥΠΑΡΧΟΝΤΑ gates (understanding/provenance/dialogue) —
όχι νέα πύλη εκτός αν κριθεί στο βήμα 3. + Εγγραφή στο Σύνταγμα ό,τι
χαρτογραφείται. Rollback: revert του ενός commit· τα optional πεδία δεν
σπάνε κανέναν αναγνώστη.
