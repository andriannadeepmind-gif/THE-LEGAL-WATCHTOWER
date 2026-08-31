------------------------- MODULE TemporalProjection -------------------------
(***************************************************************************)
(* Π6-TARGET — ΥΠΟΧΡΕΩΤΙΚΟ TEMPORAL PROOF CONTRACT + EVENT-CALCULUS        *)
(* PROJECTION. Κάθε διάταξη = fluent: initiates(Commence)/terminates       *)
(* (Repeal) στον valid-χρόνο, Known στον transaction-χρόνο. Η προβολή «ο   *)
(* νόμος όπως ίσχυε την validD, όπως ήταν γνωστός την knownD» είναι ΚΑΘΑΡΗ  *)
(* ΣΥΝΑΡΤΗΣΗ του (facts, cut). Η απάντηση φέρει TEMPORAL PROOF = η τομή +   *)
(* το σύνολο· το proof ΠΡΕΠΕΙ να αναπαράγει την προβολή (καμία κρυφή        *)
(* κατάσταση). Τα δεδομένα ορίζονται ΕΝΤΟΣ module (bounded, αναπαραγώγιμα). *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT UNSAFE

MaxD == 3
Provisions == {"p1", "p2", "p3"}
\* p2: repeal ΓΝΩΣΤΟΣ αργά (Known=2) — query με knownD<2 ΠΡΕΠΕΙ να τον εξαιρεί.
Commence == [p \in Provisions |-> CASE p = "p1" -> 0 [] p = "p2" -> 1 [] p = "p3" -> 2]
Repeal   == [p \in Provisions |-> 4]
Known    == [p \in Provisions |-> CASE p = "p1" -> 0 [] p = "p2" -> 2 [] p = "p3" -> 0]

VARIABLES validD, knownD, proj, proofCut
vars == <<validD, knownD, proj, proofCut>>

Project(vd, kd) ==
  { p \in Provisions : /\ Commence[p] =< vd
                       /\ vd < Repeal[p]
                       /\ Known[p] =< kd }

\* ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: αγνοεί το knownD (απαντά «όπως ξέρουμε ΤΩΡΑ»).
ProjectUnsafe(vd, kd) ==
  { p \in Provisions : /\ Commence[p] =< vd
                       /\ vd < Repeal[p] }

Compute(vd, kd) == IF UNSAFE THEN ProjectUnsafe(vd, kd) ELSE Project(vd, kd)

TypeOK == /\ validD \in 0..MaxD /\ knownD \in 0..MaxD
          /\ proj \subseteq Provisions
          /\ proofCut \in (0..MaxD) \X (0..MaxD)

Init == /\ validD = 0 /\ knownD = 0
        /\ proj = Compute(0, 0)
        /\ proofCut = <<0, 0>>

Query ==
  \E vd \in 0..MaxD, kd \in 0..MaxD :
    /\ validD' = vd /\ knownD' = kd
    /\ proj' = Compute(vd, kd)
    /\ proofCut' = <<vd, kd>>

Next == Query
Spec == Init /\ [][Next]_vars

\* ① ΟΥΣΙΑΣΤΙΚΗ — καμία μη-γνωστή-τότε διάταξη στην προβολή (bitemporal ορθότητα).
INV_NoUnknownLaw == \A p \in proj : Known[p] =< knownD
\* ② ΤΟ ΣΥΜΒΟΛΑΙΟ ΑΠΟΔΕΙΞΗΣ — η τομή αναπαράγει την προβολή υπό την κανονική συνάρτηση.
INV_ProofReproduces == proj = Project(proofCut[1], proofCut[2])
\* ③ Καμία μελλοντική διάταξη (initiates μετά τη valid στιγμή).
INV_NoFutureLaw == \A p \in proj : Commence[p] =< validD
=============================================================================
