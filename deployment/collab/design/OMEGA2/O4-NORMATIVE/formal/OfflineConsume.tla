-------------------------- MODULE OfflineConsume --------------------------
(* ΜΟΝΟΔΡΟΜΗ ΚΑΤΑΝΑΛΩΣΗ: το ιδιωτικό καταναλώνει ΠΙΣΤΟΠΟΙΗΜΕΝΕΣ δημόσιες
   εκδόσεις εκτός σύνδεσης· το δημόσιο ΔΕΝ μπορεί να παρατηρήσει ύπαρξη ή
   δραστηριότητα υπόθεσης. Αντιπαράδειγμα Η του Γύρου 2, τυποποιημένο.     *)
EXTENDS FiniteSets
CONSTANTS Matters, Releases, UNSAFE
VARIABLES certified, held, publicObs
vars == <<certified, held, publicObs>>

TypeOK == /\ certified \subseteq Releases
          /\ held \in [Matters -> SUBSET Releases]
          /\ publicObs \subseteq (Matters \cup Releases)

Init == /\ certified = {} /\ held = [m \in Matters |-> {}] /\ publicObs = {}

Certify(r) == /\ certified' = certified \cup {r}
              /\ UNCHANGED <<held, publicObs>>

\* ΑΣΦΑΛΗΣ: αντίγραφο εκτός σύνδεσης. Το δημόσιο δεν μαθαίνει ΤΙΠΟΤΑ.
ConsumeOffline(m, r) ==
  /\ r \in certified
  /\ held' = [held EXCEPT ![m] = held[m] \cup {r}]
  /\ UNCHANGED <<certified, publicObs>>

\* ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ = Η ΣΗΜΕΡΙΝΗ ΤΟΠΟΛΟΓΙΑ: ΕΝΑ δυαδικό σερβίρει και τη
\* δημόσια επιφάνεια και τον δικηγόρο (/ask, /cmd, σελίδες). Το ζωντανό
\* ερώτημα αφήνει ίχνος που ταυτοποιεί την υπόθεση.
QueryLive(m, r) ==
  /\ UNSAFE
  /\ r \in certified
  /\ held' = [held EXCEPT ![m] = held[m] \cup {r}]
  /\ publicObs' = publicObs \cup {m, r}
  /\ UNCHANGED certified

Next == \/ \E r \in Releases : Certify(r)
        \/ \E m \in Matters, r \in Releases : ConsumeOffline(m, r) \/ QueryLive(m, r)

Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ: καμία ταυτότητα υπόθεσης δεν εμφανίζεται ποτέ στο δημόσιο πεδίο.
INV_PublicBlindToMatters == publicObs \cap Matters = {}
\* Καμία κατοχή χωρίς πιστοποίηση — η κατανάλωση είναι μονόδρομη ΚΑΙ ελεγμένη.
INV_OnlyCertifiedHeld == \A m \in Matters : held[m] \subseteq certified
=============================================================================
