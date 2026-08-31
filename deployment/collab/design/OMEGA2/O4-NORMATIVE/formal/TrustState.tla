---------------------------- MODULE TrustState ----------------------------
(***************************************************************************)
(* Η6 — ΑΝΑΚΛΗΣΗ ΥΠΟ ΠΑΛΑΙΟ / ΔΙΑΜΕΡΙΣΜΕΝΟ ΕΠΑΛΗΘΕΥΤΗ.                     *)
(*                                                                         *)
(* Η προηγούμενη διατύπωση («ανακληθέν κλειδί δεν επικυρώνει τίποτα μετά,  *)
(* ακόμη και υπό διαμερισμό») είναι ΑΔΥΝΑΤΗ: επαληθευτής χωρίς επικοινωνία *)
(* δεν μπορεί να γνωρίζει γεγονός που δεν παρατήρησε.                      *)
(*                                                                         *)
(* Η ΣΩΣΤΗ ΣΗΜΑΣΙΟΛΟΓΙΑ που μοντελοποιείται εδώ:                           *)
(*   - signed trust-state cut  : (revoked, issuedAt) υπογεγραμμένο         *)
(*   - maximum staleness Delta : ρητό όριο παλαιότητας                     *)
(*   - valid-at-known-cut      : η ετυμηγορία αφορά ΤΗ ΓΝΩΣΤΗ ΤΟΜΗ         *)
(*   - UNKNOWN/UNAVAILABLE     : όταν η τομή δεν ανανεώνεται               *)
(*   - καμία δήλωση "valid now" πέρα από το freshness bound                *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Keys, MaxTime, Delta, UNSAFE

VARIABLES now,            \* πραγματικός χρόνος
          revokedAt,      \* Keys -> Nat \cup {MaxTime+1}: πότε ανακλήθηκε (MaxTime+1 = ποτέ)
          connected,      \* TRUE όταν ο επαληθευτής μπορεί να ανανεώσει την τομή
          cutRevoked,     \* το σύνολο ανακλήσεων ΣΤΗ ΓΝΩΣΤΗ ΤΟΜΗ
          cutAt,          \* ο χρόνος έκδοσης της γνωστής τομής
          verdict,        \* [k \in Keys -> {"none","valid","unknown","revoked"}]
          verdictAt       \* ΤΟ ΠΑΡΑΘΥΡΟ ΤΗΣ ΕΤΥΜΗΓΟΡΙΑΣ: κάθε απάντηση φέρει τη στιγμή της

vars == <<now, revokedAt, connected, cutRevoked, cutAt, verdict, verdictAt>>

Never == MaxTime + 1

TypeOK ==
  /\ now \in 0..MaxTime
  /\ revokedAt \in [Keys -> 0..Never]
  /\ connected \in BOOLEAN
  /\ cutRevoked \subseteq Keys
  /\ cutAt \in 0..MaxTime
  /\ verdict \in [Keys -> {"none","valid","unknown","revoked"}]
  /\ verdictAt \in [Keys -> 0..MaxTime]

Init ==
  /\ now = 0
  /\ revokedAt = [k \in Keys |-> Never]
  /\ connected = TRUE
  /\ cutRevoked = {}
  /\ cutAt = 0
  /\ verdict = [k \in Keys |-> "none"]
  /\ verdictAt = [k \in Keys |-> 0]

Tick ==
  /\ now < MaxTime
  /\ now' = now + 1
  /\ UNCHANGED <<revokedAt, connected, cutRevoked, cutAt, verdict, verdictAt>>

Revoke(k) ==
  /\ revokedAt[k] = Never
  /\ revokedAt' = [revokedAt EXCEPT ![k] = now]
  /\ UNCHANGED <<now, connected, cutRevoked, cutAt, verdict, verdictAt>>

Partition ==
  /\ connected' = ~connected
  /\ UNCHANGED <<now, revokedAt, cutRevoked, cutAt, verdict, verdictAt>>

\* Ο επαληθευτής ανανεώνει την υπογεγραμμένη τομή ΜΟΝΟ όταν επικοινωνεί.
RefreshCut ==
  /\ connected
  /\ cutRevoked' = {k \in Keys : revokedAt[k] =< now}
  /\ cutAt' = now
  /\ UNCHANGED <<now, revokedAt, connected, verdict, verdictAt>>

Fresh == now - cutAt =< Delta

\* Η ΑΣΦΑΛΗΣ ΚΡΙΣΗ: τρεις εκβάσεις, ποτέ δύο.
VerifySafe(k) ==
  /\ verdict' = [verdict EXCEPT ![k] =
       IF ~Fresh          THEN "unknown"
       ELSE IF k \in cutRevoked THEN "revoked"
       ELSE "valid"]
  /\ verdictAt' = [verdictAt EXCEPT ![k] = now]
  /\ UNCHANGED <<now, revokedAt, connected, cutRevoked, cutAt>>

\* ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: αγνόησε το freshness bound (η σημερινή πρακτική:
\* το κλειδί ταξιδεύει μέσα στο artifact, καμία τομή, κανένα όριο).
VerifyUnsafe(k) ==
  /\ verdict' = [verdict EXCEPT ![k] =
       IF k \in cutRevoked THEN "revoked" ELSE "valid"]
  /\ verdictAt' = [verdictAt EXCEPT ![k] = now]
  /\ UNCHANGED <<now, revokedAt, connected, cutRevoked, cutAt>>

Verify(k) == IF UNSAFE THEN VerifyUnsafe(k) ELSE VerifySafe(k)

Next ==
  \/ Tick
  \/ Partition
  \/ RefreshCut
  \/ \E k \in Keys : Revoke(k)
  \/ \E k \in Keys : Verify(k)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* ΟΙ ΑΝΑΛΛΟΙΩΤΕΣ.                                                         *)
(*                                                                         *)
(* ΠΕΙΘΑΡΧΙΑ ΜΗ-ΚΕΝΟΤΗΤΑΣ (το μάθημα του KernelL1.tla, όπου ο φύλακας      *)
(* GrantedFull(u) ΗΤΑΝ η ίδια έκφραση με την τιμή truth): η ΟΥΣΙΑΣΤΙΚΗ     *)
(* αναλλοίωτη διατυπώνεται ΑΠΟΚΛΕΙΣΤΙΚΑ πάνω στην ΠΡΑΓΜΑΤΙΚΗ κατάσταση    *)
(* (revokedAt, now) — ΠΟΤΕ πάνω στην κατάσταση του ίδιου του επαληθευτή    *)
(* (cutRevoked, cutAt), γιατί τότε θα ήταν αληθής εκ κατασκευής.           *)
(***************************************************************************)

\* ① Η ΟΥΣΙΑΣΤΙΚΗ. Μόνο ground truth. Ο επαληθευτής ΕΠΙΤΡΕΠΕΤΑΙ να πει
\* "valid" για ανακληθέν κλειδί — αυτό είναι αναπόφευκτο υπό διαμερισμό —
\* αλλά ΠΟΤΕ για περισσότερο από Delta μετά την ανάκληση. Φραγμένη άγνοια.
INV_BoundedExposure ==
  \A k \in Keys :
    (verdict[k] = "valid" /\ revokedAt[k] =< verdictAt[k])
      => (verdictAt[k] - revokedAt[k] =< Delta)

\* ② ΣΥΜΜΟΡΦΩΣΗ (δηλώνεται ΡΗΤΑ ως μη-ουσιαστική μόνη της): καμία ετυμηγορία
\* "valid" πέρα από το freshness bound. Ο αρνητικός μάρτυρας τη σκοτώνει.
INV_ConformanceFreshness ==
  \A k \in Keys : (verdict[k] = "valid") => (verdictAt[k] - cutAt =< Delta)

\* ③ Καμία σιωπηλή τρίτη έκβαση: όταν η τομή είναι παλαιά, η απάντηση είναι
\* ΡΗΤΑ "unknown" — τίμια άγνοια, ποτέ εικασία.
INV_StaleYieldsUnknown ==
  \A k \in Keys : (verdictAt[k] - cutAt > Delta) => (verdict[k] # "valid")
=============================================================================
