--------------------------- MODULE ArgKill ---------------------------
(* KT6 destruction pass. Same characteristic function F and Grounded as   *)
(* ArgumentEval.tla. Two AFs selected by MUTUAL:                          *)
(*   MUTUAL=FALSE : base AF  Attacks={<<a2,a1>>}          (a1 defeated)   *)
(*   MUTUAL=TRUE  : conflict Attacks={<<a2,a1>>,<<a1,a2>>}(a1 undecided)  *)
(* We compute the STANDARD 3-valued grounded labelling IN/OUT/UNDEC and   *)
(* show the design's two-valued `accepted`(=IN) gives the SAME output for *)
(* a1 in both AFs, while the legal status (defeated vs unresolved) flips. *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANT MUTUAL
Args == {"a1","a2","a3"}
Attacks == IF MUTUAL THEN { <<"a2","a1">>, <<"a1","a2">> } ELSE { <<"a2","a1">> }
F(S) == { a \in Args : \A b \in Args : (<<b,a>> \in Attacks)
                                       => (\E c \in S : <<c,b>> \in Attacks) }
RECURSIVE GroundedFrom(_)
GroundedFrom(S) == LET nxt == F(S) IN IF nxt = S THEN S ELSE GroundedFrom(nxt)
Grounded == GroundedFrom({})
\* Standard grounded labelling:
InSet   == Grounded
OutSet  == { a \in Args : \E c \in Grounded : <<c,a>> \in Attacks }
UndecSet== Args \ (InSet \cup OutSet)

VARIABLE accepted
vars == <<accepted>>
Init == accepted = Grounded         \* the design's representation: exactly IN
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars

\* What the case-law query returns for a1 under the design: membership in
\* `accepted`. This is IDENTICAL (a1 absent) in BOTH modes:
INV_DesignOutputForA1 == "a1" \notin accepted
\* The legal truth under the standard labelling: a1 is DEFEATED only in base.
\* Holds MUTUAL=FALSE, FAILS MUTUAL=TRUE  =>  the two situations are distinct
\* legal facts that the design's `accepted`-only output cannot carry.
INV_A1IsActuallyDefeated == "a1" \in OutSet
=============================================================================
