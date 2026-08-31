--------------------------- MODULE ArgumentEval ---------------------------
(***************************************************************************)
(* Π8-TARGET — TYPED ARGUMENT ΜΕ ΕΚΤΕΛΕΣΙΜΗ ΑΞΙΟΛΟΓΗΣΗ.                    *)
(* Λύνει την αντίφαση «span ή typed argument» υπέρ του typed argument.     *)
(*                                                                         *)
(* Η απόφαση = πλαίσιο επιχειρημάτων Dung (Args, Attacks). Η «αξιολόγηση»  *)
(* είναι ΕΚΤΕΛΕΣΙΜΗ: το grounded extension ως ελάχιστο σταθερό σημείο της  *)
(* χαρακτηριστικής συνάρτησης. Η «βάση» μιας θέσης = τα αποδεκτά           *)
(* επιχειρήματα στο grounded extension — ΟΧΙ όποιο επιχείρημα φέρει token   *)
(* ετυμηγορίας στο κείμενο (span). Ο αρνητικός μάρτυρας = span-εξαγωγή που  *)
(* δέχεται ηττημένο επιχείρημα. Άρα span != αξιολόγηση, δομικά.            *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, TLC

CONSTANT UNSAFE

Args == {"a1", "a2", "a3"}
\* a2 ΕΠΙΤΙΘΕΤΑΙ στο a1 (ένσταση στη θέση a1) και είναι ανεπίθετο ⇒ ισχυρό.
\* a1 φέρει το token ετυμηγορίας (η «πρόταση-ετυμηγορία» στο κείμενο).
Attacks == { <<"a2", "a1">> }
VerdictBearing == {"a1"}   \* η span-ευρετική δέχεται όσα φέρουν token

\* Χαρακτηριστική συνάρτηση Dung: το a είναι acceptable ως προς S αν κάθε
\* επιτιθέμενος b του a αντεπιτίθεται από κάποιο c \in S.
F(S) == { a \in Args :
            \A b \in Args : (<<b, a>> \in Attacks)
                            => (\E c \in S : <<c, b>> \in Attacks) }

\* Grounded extension = ανοδικό σταθερό σημείο από {} (Args πεπερασμένο ⇒ τερματίζει).
RECURSIVE GroundedFrom(_)
GroundedFrom(S) == LET nxt == F(S) IN IF nxt = S THEN S ELSE GroundedFrom(nxt)
Grounded == GroundedFrom({})

VARIABLE accepted
vars == <<accepted>>

\* SAFE: η αποδοχή είναι η ΕΚΤΕΛΕΣΙΜΗ αξιολόγηση (grounded).
\* UNSAFE: η αποδοχή είναι η span-ευρετική (όποιο φέρει token).
Init == accepted = (IF UNSAFE THEN VerdictBearing ELSE Grounded)
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ: η αναφερόμενη αποδοχή ΠΡΕΠΕΙ να ισούται με την εκτελέσιμη
\* αξιολόγηση. Ο αρνητικός μάρτυρας (span) δέχεται το a1 που είναι ηττημένο.
INV_AcceptedEqualsEvaluation == accepted = Grounded
\* Έλεγχος ορθότητας: το επιχείρημα-φορέας ετυμηγορίας a1 ΑΠΟΡΡΙΠΤΕΤΑΙ από
\* την εκτελέσιμη αξιολόγηση (ηττημένο από το ανεπίθετο a2)· το span το δεχόταν.
INV_VerdictBearerRejected == "a1" \notin Grounded
=============================================================================
