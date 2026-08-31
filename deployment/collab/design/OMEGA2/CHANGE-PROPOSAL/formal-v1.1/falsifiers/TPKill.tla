------------------------------- MODULE TPKill -------------------------------
(***************************************************************************)
(* KT5 DESTRUCTION — bitemporal repeal known-late.                          *)
(* The target's Project() gives a repeal ONLY a valid-time (Repeal[p]) and  *)
(* NO transaction-time. It applies `vd < Repeal[p]` unconditionally on kd.  *)
(* A repeal that BECOMES KNOWN at transaction time KnownRepeal[p] must not   *)
(* remove a provision from a knowledge cut kd < KnownRepeal[p]. We compare   *)
(* the target's DesignProject (copied verbatim from TemporalProjection.tla)  *)
(* against the correct bitemporal CorrectProject, which guards the repeal    *)
(* by its own known-time. Invariant DESIGN=CORRECT is expected to BREAK.     *)
(***************************************************************************)
EXTENDS Naturals

MaxD == 3
Provisions == {"p1"}

Commence    == [p \in Provisions |-> 0]   \* in force from valid-time 0
Known       == [p \in Provisions |-> 0]   \* commencement known from t=0
Repeal      == [p \in Provisions |-> 1]   \* repealed as of valid-time 1
KnownRepeal == [p \in Provisions |-> 2]   \* but the repeal is only KNOWN at t=2

VARIABLES validD, knownD, dproj, cproj
vars == <<validD, knownD, dproj, cproj>>

\* Target's function, verbatim from TemporalProjection.tla (repeal has no kd guard):
DesignProject(vd, kd) ==
  { p \in Provisions : /\ Commence[p] =< vd
                       /\ vd < Repeal[p]
                       /\ Known[p] =< kd }

\* Correct bitemporal projection: the repeal removes p only if it BOTH
\* took effect by valid-time vd AND was known by transaction-time kd.
CorrectProject(vd, kd) ==
  { p \in Provisions : /\ Commence[p] =< vd
                       /\ Known[p] =< kd
                       /\ ~ (Repeal[p] =< vd /\ KnownRepeal[p] =< kd) }

TypeOK == /\ validD \in 0..MaxD /\ knownD \in 0..MaxD
          /\ dproj \subseteq Provisions /\ cproj \subseteq Provisions

Init == /\ validD = 0 /\ knownD = 0
        /\ dproj = DesignProject(0,0) /\ cproj = CorrectProject(0,0)

Query ==
  \E vd \in 0..MaxD, kd \in 0..MaxD :
    /\ validD' = vd /\ knownD' = kd
    /\ dproj' = DesignProject(vd, kd)
    /\ cproj' = CorrectProject(vd, kd)

Next == Query
Spec == Init /\ [][Next]_vars

\* The kill test for KT5: the design's temporal answer must equal the correct
\* bitemporal answer. If it ever differs, a repeal known only later has been
\* applied retroactively (or a known repeal ignored).
INV_DesignEqualsCorrect == dproj = cproj
=============================================================================
