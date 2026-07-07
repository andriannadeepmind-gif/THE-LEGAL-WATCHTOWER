# LAWMAX — MEMORY KERNEL SPECIFICATION
**Specification-only. ZERO runtime behavior change.** Κανένα νέο store, κανένας
Runner, καμία υιοθέτηση, κανένα refactor, κανένα νέο top-level subsystem.
Αυθεντικό ζεύγος: `LAWMAX-MEMORY-KERNEL-SPEC.sexp` (μηχανικά αναγνώσιμο).
Authored-at-commit: **191fd15c** (μετά το Π0 accepted, PASS=30/0 real Docker).

**Ultimate target:** η τελική μηχανική μορφή του Ιδρύματος (LAWMAX Ω — CPEI,
12 στρώματα, InstitutionalAct, Constitutional Compiler, coverage map) έχει ΜΙΑ
έδρα: `LAWMAX-CPEI-TARGET-SPEC.{md,sexp}` — αυτό εδώ παραμένει η έδρα της
απογραφής/πολιτικής μνήμης και ΔΕΝ την επαναλαμβάνει.

Αυτό το κείμενο **χαρτογραφεί ό,τι ήδη υπάρχει** και **ονομάζει ό,τι λείπει** —
δεν προσθέτει τίποτα. Κάθε ισχυρισμός φέρει evidence (αρχείο:γραμμή) από την
πηγή ή τα ζωντανά μητρώα. Πηγή αλήθειας: το `--architecture-constitution-gate`
`:canonical-stores`, ο κώδικας, το git — ΟΧΙ αφήγηση.

---

## 0 · Non-negotiables αυτού του spec

1. **Μία έδρα ανά είδος μνήμης.** Καμία έννοια μνήμης δεν έχει δύο σπίτια.
2. **Ένας writer ανά store.** (Ήδη επιβεβαιωμένο για ledger/lessons: Π0-D.)
3. **Καμία μνήμη-ισχυρισμός χωρίς απόδειξη.** `memory_recorded:true` μόνο μετά
   append+read-back στον ίδιο canonical store (P0 invariant, commit 191fd15c).
4. **Append-only + tamper-evidence** όπου η ιστορία δεν πρέπει να ξαναγραφτεί
   (episodes: SHA-256 chain).
5. **Καμία υλοποίηση εδώ.** Οι φάσεις 1+ απαιτούν ΡΗΤΟ ΟΚ δημιουργού, μία-μία.

---

## 1 · Είδη μνήμης (cognitive taxonomy)

| # | Είδος | Τι κρατά | Store | Persistence | Evidence |
|---|---|---|---|---|---|
| 1 | **Επεισοδιακή** | κάθε αλληλεπίδραση (what happened) | `deployment/self/episodes.sexp` | δίσκος, SHA-256 chain | `source/memory.lisp:45,96` |
| 2 | **Βιογραφική / Genesis** | η αφετηρία & ταυτότητα ζωής | `deployment/self/history.sexp` | δίσκος (bootstrap-tracked) | Σύνταγμα `:canonical-stores` |
| 3 | **Εργαζόμενη (working)** | last-answer / last-question του γύρου | `*ask-memory*` (RAM) | **εφήμερη, ανά process** | `decisions.lisp:1753` |
| 4 | **Μνήμη αποτυχίας (Π0)** | κενά κατανόησης, επιθεωρήσιμα | `deployment/state/failure-ledger.jsonl` | δίσκος, append+read-back | `understanding-learning.lisp:188` |
| 5 | **Αναστοχαστικό aggregate** | μαθήματα (--reflect/--lessons) | `deployment/state/lessons.jsonl` | δίσκος, append | Σύνταγμα `:canonical-stores` |
| 6 | **Προτάσεων / υποψηφίων** | εκκρεμείς προτάσεις + candidate packs | `deployment/self/proposals.sexp`, `deployment/self/candidates/` | δίσκος | Σύνταγμα `:canonical-stores` |
| 7 | **Πολιτικών** | κανόνες αυτο-έγκρισης | `deployment/self/policies.sexp` | δίσκος | `approval-policy.lisp` |
| 8 | **Ταυτότητας συστατικών** | SHA-256 + έδρες, παγωμένα στο build | `deployment/self/component-manifest.sexp` | δίσκος (build artifact) | `build.lisp` freeze |
| 9 | **Γράφου** | snapshot του συλλογιστικού γράφου | `deployment/self/graph-snapshot.sexp` | δίσκος | `graph-import.lisp:186,223` |
| 10 | **Δρομέων (cursors)** | πού έμεινε ο δαίμονας (ΦΕΚ/ΑΠ…) | `deployment/state/<key>-last-seen.txt` | δίσκος, overwrite | `cli-util.lisp:55-70` |
| 11 | **Ουράς επιθεώρησης** | review-queue | `…/review-queue.sexp` | δίσκος | `main.lisp:1269` |
| 12 | **Ίχνους / προέλευσης** | execution trace του γύρου | `*events*` (RAM) | **εφήμερη, ανά process** | `execution-trace.lisp:46` |

**Γειτονική, ΟΧΙ μνήμη:** τα `deployment/knowledge/*.sexp` (γλωσσάρι, δεοντικό,
casegrammar) είναι **δηλωτική γνώση/σκαλωσιά (BOOTSTRAP)**, όχι βιωματική μνήμη.
Χαρτογραφούνται ξεχωριστά στο Σύνταγμα (`:bootstrap-artifacts`) και ΔΕΝ ανήκουν
στον memory kernel — η σύγχυση γνώσης/μνήμης είναι ρητά αποτρεπτέα.

---

## 2 · Υπάρχοντα stores (canonical homes) — 8 δηλωμένα + 4 λειτουργικά

**Τα 8 του Συντάγματος** (`:canonical-stores`, επιβάλλεται από `--architecture-
constitution-gate` ⑨ «ένας ρόλος ανά store, κανένα αδήλωτο store»):

| Store | Ρόλος | Writer (μοναδικός) |
|---|---|---|
| `deployment/self/episodes.sexp` | `:experiential-stream` | `orchestrator.memory:record-episode` |
| `deployment/self/history.sexp` | `:biography` (GENESIS) | χειροκίνητο/bootstrap |
| `deployment/self/proposals.sexp` | `:proposal-queue` | adoption surface |
| `deployment/self/graph-snapshot.sexp` | `:graph-snapshot` | `save-graph` |
| `deployment/state/lessons.jsonl` | `:reflection-aggregate` | `%lesson` |
| `deployment/state/failure-ledger.jsonl` | `:dialogue-failure-ledger` | `record-dialogue-failure!` |
| `deployment/self/policies.sexp` | `:approval-policies` | approval surface |
| `deployment/self/candidates/` | `:candidate-pack-staging` | shadow staging |

**4 λειτουργικά stores που ΔΕΝ είναι στο `:canonical-stores`** (χρέος δήλωσης —
βλ. §4 duplicate/gap risks, ΔΕΝ διορθώνεται εδώ):
- `deployment/self/component-manifest.sexp` — build artifact (identity memory).
- `deployment/state/<key>-last-seen.txt` — cursors (progress memory).
- `…/review-queue.sexp` — review queue.
- `*ask-memory*`, `*events*` — in-RAM, εφήμερα (δεν είναι δίσκος, εξ ορισμού
  εκτός `:canonical-stores`, αλλά ΠΡΕΠΕΙ να δηλωθούν ως εφήμερη μνήμη).

---

## 3 · Missing stores (δηλωμένα κενά — ΔΕΝ χτίζονται χωρίς ΟΚ)

| Κενό | Τι λείπει | Γιατί το ξέρουμε | Συνέπεια σήμερα |
|---|---|---|---|
| **M1 · Universal turn id / root span** | ένα σταθερό id ανά --ask γύρο που δένει envelope↔episode↔ledger↔trace | P1 debt (commit 62570e60) | το failure_id, το episode id, το gap_id δεν έχουν ΚΟΙΝΟ γονέα |
| **M2 · Session store** | εργαζόμενη μνήμη που ΕΠΙΒΙΩΝΕΙ process | `*ask-memory*` είναι RAM/ανά process (`decisions.lisp:1753`) | το follow-up «τι εννοείς;» δένει ΜΟΝΟ εντός process — γι' αυτό η πύλη Β το ελέγχει με internal twin |
| **M3 · Recall index** | ευρετήριο ανάκλησης επεισοδίων | `recall` = γραμμική σάρωση λημμάτων | O(n) ανάκληση· δεν κλιμακώνει |
| **M4 · Consolidation** | επεισοδιακή → σημασιολογική (μακρά μνήμη) | καμία διεργασία episodes→concepts | δεν «θυμάται μοτίβα», μόνο συμβάντα |
| **M5 · Cross-session conversation** | συνέχεια διαλόγου μεταξύ συνεδριών | δεν υπάρχει session persistence | κάθε docker run ξεκινά «χωρίς χθες» |

**Καμία από αυτές δεν υλοποιείται τώρα.** Είναι ο χάρτης, όχι εντολή.

---

## 4 · Duplicate risks (τι ΘΑ γινόταν διπλό — και γιατί δεν είναι)

1. **lessons.jsonl vs failure-ledger.jsonl** — και τα δύο «τι δεν κατάλαβα».
   ΔΕΝ είναι διπλό: `lessons` = aggregate αναστοχασμού· `failure-ledger` =
   δομημένη εγγραφή-πρώτη-ύλη. **Ένας writer ο καθένας** (Π0-D, understanding-
   gate ⑬). Ο κανόνας: ΠΟΤΕ κοινός writer, ΠΟΤΕ ο ένας να διαβάζει τον άλλο ως
   πηγή.
2. **episodes.sexp vs failure-ledger.jsonl** — μια μη-κατανοητή ερώτηση μπαίνει
   ΚΑΙ στα episodes (ως `:not-understood`) ΚΑΙ στον ledger. ΔΕΝ είναι διπλό:
   episodes = ρεύμα «τι συνέβη»· ledger = δομημένο «τι κενό». Διαφορετικοί
   ρόλοι, διαφορετικά σχήματα. Κίνδυνος μόνο αν κάποιος τα συγχρονίσει — **δεν
   επιτρέπεται**.
3. **working-memory (last-answer) vs episode props `:answer`** — η ίδια
   περίληψη σε RAM και σε episode. ΔΕΝ είναι διπλό: RAM = εφήμερο working set·
   episode = μόνιμο ρεύμα. Το RAM ΔΕΝ είναι source of truth.
4. **component-manifest.sexp** — δηλωμένο λειτουργικό store εκτός
   `:canonical-stores`. **Δηλωμένο χρέος:** να αποκτήσει ρητή εγγραφή ρόλου
   (`:identity-manifest`) στο Σύνταγμα σε μελλοντική φάση με ΟΚ — όχι εδώ.

---

## 5 · Gates που φυλάνε τη μνήμη (υπάρχοντα, μετρημένα)

| Gate | Τι επαληθεύει για μνήμη | Checks |
|---|---|---|
| `--memory-gate` | επεισόδιο write/read, agenda, recall, SHA-256 chain, ταυτοχρονία 4 νημάτων | 10/10 |
| `--understanding-gate` | Π0-A/B/C/D: ledger append+recall, negative, ξεχωριστός writer | 14/14 |
| `--provenance-gate` | κάθε έμπιστη έξοδος δένεται σε ίχνος· :off ⇒ καταγγελία | 16/16 |
| `--architecture-constitution-gate` ⑨ | ένας ρόλος ανά store, κανένα αδήλωτο store στον δίσκο | (μέρος 12/12) |

**Κανένα νέο gate εδώ.** Οι φάσεις 1+ θα φέρουν νέους ελέγχους ΜΟΝΟ όταν
εγκριθούν, καθένας κλειδώνοντας το πρότυπο αστοχίας που διορθώνει.

---

## 6 · Write / recall policy (υπάρχουσα συμπεριφορά, καταγεγραμμένη)

| Store | Write | Recall | Tamper-evidence |
|---|---|---|---|
| episodes.sexp | `chained-append` (append-only) | `recall` by lemma (γραμμικό) | **SHA-256 chain** (verify-episode-chain) |
| failure-ledger.jsonl | append **+ read-back επαλήθευση** | `--failures`, gap-ledger-frame | read-back = απόδειξη διάρκειας (P0) |
| lessons.jsonl | append (aggregate) | `--lessons` | — |
| policies.sexp | overwrite εντός surface | policy engine | signed απόφαση αλλαγής |
| cursors *-last-seen.txt | **overwrite** (τελευταία τιμή) | `%read-cursor` | — (idempotent progress) |
| graph-snapshot.sexp | save-graph (snapshot) | load-graph | serialization roundtrip (inference-gate) |
| working-memory (RAM) | `remember` | `recall` | — (εφήμερο εξ ορισμού) |

**Κανόνας διάρκειας (P0 invariant, ενεργός):** κανένα store δεν επιτρέπεται να
δηλώσει «γράφτηκε» χωρίς append **και** read-back από το ΙΔΙΟ path. Οι κωδικοί
αποτυχίας: `ledger_missing / ledger_not_writable / readback_failed /
deployment_mount_missing / canonical_store_unavailable`.

---

## 7 · Trust / provenance policy

- **Κάθε έμπιστη έξοδος** δένεται σε ίχνος εκτέλεσης (provenance-gate ②③④).
- **Κάθε μνήμη-ισχυρισμός** στο trust envelope είναι ΥΠΟΛΟΓΙΣΜΕΝΟΣ, όχι στατικός
  (`memory_recorded` = επαληθευμένο append+read-back).
- **Επεισοδιακή ακεραιότητα:** SHA-256 chain — παραβίαση γίνεται ορατή.
- **Αλλαγές πολιτικής/υιοθέτησης:** υπογεγραμμένες (SHA-256) αποφάσεις με
  what-if + rollback (self-evolution-gate).
- **Καμία μνήμη στο έμπιστο μονοπάτι δεν παράγεται από LLM.** (Σταθερό συμβόλαιο.)

---

## 8 · Implementation phases (ΧΑΡΤΗΣ — καμία εκτέλεση χωρίς ΟΚ ανά φάση)

- **Φ0 — DONE:** απογραφή + αυτό το spec + τίμια μνήμη αποτυχίας (Π0 accepted,
  P0 invariant, PASS=30/0 real Docker).
- **Φ1 — Universal turn id / root span (M1):** ένα id ανά --ask που γίνεται
  γονέας envelope+episode+ledger+trace. *Απαιτεί ΟΚ.* Gate: κάθε γύρος έχει
  ρίζα-span που δένει τα τέσσερα.
- **Φ2 — Session store (M2):** εργαζόμενη μνήμη που επιβιώνει process, ώστε το
  follow-up να δένει μεταξύ κλήσεων. *Απαιτεί ΟΚ.* Ρίσκο: να ΜΗΝ γίνει δεύτερο
  ρεύμα δίπλα στα episodes — πρέπει να είναι προβολή, όχι νέα αλήθεια.
- **Φ3 — Recall index (M3):** ευρετήριο επεισοδίων για ανάκληση O(log n).
  *Απαιτεί ΟΚ.* Ρίσκο: το index είναι ΠΑΡΑΓΩΓΟ των episodes, ποτέ πηγή.
- **Φ4 — Consolidation (M4):** episodes → σημασιολογικά μοτίβα, ως ΠΡΟΤΑΣΕΙΣ
  προς έγκριση (ποτέ auto-adopt). *Απαιτεί ΟΚ.* Περνά από shadow + human.
- **Φ5 — Cross-session (M5):** συνέχεια διαλόγου μεταξύ συνεδριών. *Απαιτεί ΟΚ.*

Κάθε φάση: gated, χωρίς auto-adoption, με human approval, με rollback target.
Καμία δεν ξεκινά πριν την προηγούμενη + ρητό «προχώρα».

---

## 9 · Τι ΔΕΝ κάνει αυτό το spec (ρητά)

Καμία αλλαγή runtime · κανένα νέο store · κανένας νέος writer · κανένα νέο
gate · κανένα Runner · καμία υιοθέτηση · κανένα refactor · κανένα νέο top-level
subsystem · καμία επέκταση νομικής γνώσης. **Μόνο χάρτης + πολιτική + φάσεις.**
