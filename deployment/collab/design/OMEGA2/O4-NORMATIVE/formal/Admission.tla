---------------------------- MODULE Admission ----------------------------
(* ΠΡΟΤΑΣΗ AI → ΑΠΟΔΟΧΗ. Διορθωμένο μοντέλο (διόρθωση δημιουργού 3).
   Το ΠΡΑΓΜΑΤΙΚΟ repo ΕΧΕΙ: (α) λευκό κατάλογο 3 frame types με συμβολικό
   επαληθευτή ΠΡΙΝ την κατασκευή (advisor.lisp:64-70, λευκός κατάλογος),
   (β) ΔΥΟ εξειδικευμένες execute-step (cognition-legal.lisp:277, 323).
   Το ΠΡΑΓΜΑΤΙΚΟ εύρημα: η execute-step ΔΕΝ ΕΙΝΑΙ ΟΛΙΚΗ, και το generic
   default είναι ALLOW για τα μη καλυπτόμενα (frame, step) ζεύγη.          *)
EXTENDS FiniteSets
CONSTANTS Frames, Steps, Whitelisted, FullCoverage, UNSAFE
\* Whitelisted : SUBSET Frames  — όσα ο σύμβουλος επιτρέπεται να προτείνει
\* FullCoverage: TRUE ⇒ ΟΛΙΚΗ execute-step· FALSE ⇒ η ΣΗΜΕΡΙΝΗ μερική κάλυψη

VARIABLES proposed, built, admitted, evidence
vars == <<proposed, built, admitted, evidence>>

Pairs == [f : Frames, s : Steps]
SomeStep == CHOOSE s \in Steps : TRUE
\* Τα (frame, step) ζεύγη που ΕΧΟΥΝ εξειδικευμένη execute-step.
Covered == IF FullCoverage THEN Pairs ELSE {p \in Pairs : p.s = SomeStep}

TypeOK == /\ proposed \subseteq Frames
          /\ built    \subseteq Frames
          /\ admitted \subseteq Pairs
          /\ evidence \in [Pairs -> BOOLEAN]

Init == /\ proposed = {} /\ built = {} /\ admitted = {}
        /\ evidence = [p \in Pairs |-> FALSE]

\* Ο σύμβουλος προτείνει οτιδήποτε — αναξιόπιστος προτείνων.
Propose(f) == /\ proposed' = proposed \cup {f}
              /\ UNCHANGED <<built, admitted, evidence>>

\* Ο ΛΕΥΚΟΣ ΚΑΤΑΛΟΓΟΣ + συμβολική επαλήθευση: υπάρχει ΚΑΙ στο σημερινό repo.
Build(f) == /\ f \in proposed /\ f \in Whitelisted
            /\ built' = built \cup {f}
            /\ UNCHANGED <<proposed, admitted, evidence>>

\* ΣΤΑΔΙΟ 3. Καλυμμένο ζεύγος ⇒ πραγματική επαλήθευση που παράγει τεκμήριο.
ExecCovered(f, s) ==
  /\ f \in built /\ [f |-> f, s |-> s] \in Covered
  /\ evidence' = [evidence EXCEPT ![[f |-> f, s |-> s]] = TRUE]
  /\ admitted' = admitted \cup {[f |-> f, s |-> s]}
  /\ UNCHANGED <<proposed, built>>

\* ΜΗ καλυμμένο ζεύγος. SAFE = fail-closed (ΔΕΝ γίνεται δεκτό).
\* UNSAFE = η σημερινή generic default (values t nil): δεκτό ΧΩΡΙΣ τεκμήριο.
ExecUncovered(f, s) ==
  /\ f \in built /\ [f |-> f, s |-> s] \notin Covered
  /\ UNSAFE
  /\ admitted' = admitted \cup {[f |-> f, s |-> s]}
  /\ UNCHANGED <<proposed, built, evidence>>

Next == \/ \E f \in Frames : Propose(f) \/ Build(f)
        \/ \E f \in Frames, s \in Steps : ExecCovered(f, s) \/ ExecUncovered(f, s)

Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ: τίποτα δεν γίνεται δεκτό χωρίς ΠΑΡΑΧΘΕΝ τεκμήριο.
INV_NoAdmissionWithoutEvidence == \A p \in admitted : evidence[p]
\* Ο λευκός κατάλογος κρατά: μη εγκεκριμένο frame δεν κατασκευάζεται ποτέ.
INV_WhitelistHolds == built \subseteq Whitelisted
=============================================================================
