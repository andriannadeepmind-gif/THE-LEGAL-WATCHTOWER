------------------------- MODULE Noninterference -------------------------
(* ΔΙΑΣΤΑΥΡΟΥΜΕΝΗ ΓΝΩΣΗ ΜΕΤΑΞΥ ΥΠΟΘΕΣΕΩΝ. Διόρθωση δημιουργού 11: ΟΧΙ γενική
   «απόδειξη μη-συμπερασιμότητας». Default: η γνώση ΜΕΝΕΙ στην κυψέλη.
   Προαγωγή ΜΟΝΟ με ρητή αποχαρακτηρισμό + πολιτική ροής + έγκριση εταίρου/
   απορρήτου + ΚΑΤΑΓΕΓΡΑΜΜΕΝΟ σκοπό — και τα τέσσερα.                      *)
EXTENDS FiniteSets
CONSTANTS Items, Cells, UNSAFE
Scopes == Cells \cup {"firm"}

VARIABLES home, visible, declassified, policyOK, approved, purposeRecorded
vars == <<home, visible, declassified, policyOK, approved, purposeRecorded>>

TypeOK ==
  /\ home    \in [Items -> Cells]
  /\ visible \in [Items -> SUBSET Scopes]
  /\ declassified \in [Items -> BOOLEAN]
  /\ policyOK  \in [Items -> BOOLEAN]
  /\ approved  \in [Items -> BOOLEAN]
  /\ purposeRecorded \in [Items -> BOOLEAN]

Init ==
  /\ home \in [Items -> Cells]
  /\ visible = [i \in Items |-> {home[i]}]
  /\ declassified = [i \in Items |-> FALSE]
  /\ policyOK = [i \in Items |-> FALSE]
  /\ approved = [i \in Items |-> FALSE]
  /\ purposeRecorded = [i \in Items |-> FALSE]

Gate(i, f) == f' = [f EXCEPT ![i] = TRUE]

DeclassifyStep(i) == /\ Gate(i, declassified)
                     /\ UNCHANGED <<home, visible, policyOK, approved, purposeRecorded>>
PolicyStep(i)     == /\ Gate(i, policyOK)
                     /\ UNCHANGED <<home, visible, declassified, approved, purposeRecorded>>
ApproveStep(i)    == /\ Gate(i, approved)
                     /\ UNCHANGED <<home, visible, declassified, policyOK, purposeRecorded>>
PurposeStep(i)    == /\ Gate(i, purposeRecorded)
                     /\ UNCHANGED <<home, visible, declassified, policyOK, approved>>

PromoteSafe(i, s) ==
  /\ declassified[i] /\ policyOK[i] /\ approved[i] /\ purposeRecorded[i]
  /\ visible' = [visible EXCEPT ![i] = visible[i] \cup {s}]
  /\ UNCHANGED <<home, declassified, policyOK, approved, purposeRecorded>>

\* ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ = Η ΣΗΜΕΡΙΝΗ ΣΥΜΠΕΡΙΦΟΡΑ: «γενικό μάθημα» ανεβαίνει
\* αυτόματα σε καθολική αποθήκη γνώσης (lessons.jsonl, --adopt-knowledge).
PromoteUnsafe(i, s) ==
  /\ visible' = [visible EXCEPT ![i] = visible[i] \cup {s}]
  /\ UNCHANGED <<home, declassified, policyOK, approved, purposeRecorded>>

Promote(i, s) == IF UNSAFE THEN PromoteUnsafe(i, s) ELSE PromoteSafe(i, s)

Next == \E i \in Items :
  \/ DeclassifyStep(i) \/ PolicyStep(i) \/ ApproveStep(i) \/ PurposeStep(i)
  \/ \E s \in Scopes : Promote(i, s)

Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ: καμία ορατότητα εκτός της κυψέλης προέλευσης χωρίς ΚΑΙ ΤΑ ΤΕΣΣΕΡΑ.
INV_NoImplicitFlow ==
  \A i \in Items :
    (visible[i] # {home[i]}) =>
      (declassified[i] /\ policyOK[i] /\ approved[i] /\ purposeRecorded[i])
\* Η προέλευση δεν χάνεται ποτέ.
INV_HomeAlwaysVisible == \A i \in Items : home[i] \in visible[i]
=============================================================================
