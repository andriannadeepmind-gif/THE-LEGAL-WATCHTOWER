--------------------------------- MODULE KernelL1 ---------------------------------
(***************************************************************************)
(* WATCHTOWER v0.7-R — ABSTRACT SEMANTIC KERNEL, LAW L1                    *)
(*                                                                          *)
(* L1.a  operations that can invalidate one another share a LinearizationDomain *)
(* L1.b  one authority-bearing operation per LinearizationPosition          *)
(* L1.c  cross-domain references are causal-backward only                   *)
(* L1.e  no local view produces authority                                   *)
(*                                                                          *)
(* The model does NOT add a guard "reject stale authorisation". It places   *)
(* USE in the same linearization domain as GRANT/REVOKE, which makes a      *)
(* stale-view authorisation INEXPRESSIBLE. Design is a parameter so the     *)
(* claim is falsifiable:                                                     *)
(*   "kernel_L1"      USE is an authority operation in the same domain      *)
(*   "local_view"     the writer authorises from its own lagging view (the  *)
(*                    v0.7.2 + A-2 design that B-1 broke)                    *)
(*   "grant_ref"      separate domain, but the commit references a GRANT    *)
(*                    linearised in the authority domain                     *)
(*   "one_shot"       grant_ref plus a one-position validity window         *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS MaxPos, MaxCommits, Design

Lifecycle == {"GRANT", "REVOKE", "EXPIRE", "COMPROMISE"}
Kinds     == Lifecycle \cup {"USE"}

VARIABLES ops,        \* the single authority linearization domain: one operation per position
          view,       \* how far a separate-domain writer has synchronised (staleness)
          commits     \* set of [use |-> position, auth |-> position used for authorisation,
                      \*          land |-> position at which it landed, truth |-> BOOLEAN]
vars == <<ops, view, commits>>

Init == ops = << >> /\ view = 0 /\ commits = {}

\* last lifecycle decision strictly before position p, restricted to a visible prefix
LastLifecycle(p, limit) ==
  LET hi == IF p - 1 < limit THEN p - 1 ELSE limit
      S  == {i \in 1..hi : ops[i].kind \in Lifecycle}
  IN IF S = {} THEN "NONE" ELSE ops[CHOOSE i \in S : \A j \in S : j <= i].kind

GrantedFull(p)     == LastLifecycle(p, MaxPos) = "GRANT"
GrantedInView(p)   == LastLifecycle(p, view)   = "GRANT"

\* position of the most recent GRANT in the full order, 0 if none
LastGrantPos ==
  LET S == {i \in 1..Len(ops) : ops[i].kind = "GRANT"}
  IN IF S = {} THEN 0 ELSE CHOOSE i \in S : \A j \in S : j <= i

AppendOp(k) ==
  /\ Len(ops) < MaxPos
  /\ ops' = Append(ops, [kind |-> k])
  /\ UNCHANGED <<view, commits>>

Sync ==                                   \* a separate-domain writer catches up, possibly late
  /\ view < Len(ops)
  /\ view' = view + 1
  /\ UNCHANGED <<ops, commits>>

\* A commit records: which USE it rests on, at which position the authorisation was decided,
\* where it landed, and the GROUND TRUTH of whether authority held at the decision point.
Commit(u) ==
  /\ Cardinality(commits) < MaxCommits
  /\ u \in 1..Len(ops)
  /\ ops[u].kind = "USE"
  /\ ~\E c \in commits : c.use = u
  /\ \/ /\ Design = "kernel_L1"
        \* USE is itself an authority operation: authorisation is decided at u, in the one
        \* order that also carries GRANT/REVOKE. No other view exists.
        /\ GrantedFull(u)
        /\ commits' = commits \cup {[use |-> u, auth |-> u, land |-> Len(ops),
                                     truth |-> GrantedFull(u)]}
     \/ /\ Design = "local_view"
        \* the writer decides from its own lagging prefix
        /\ GrantedInView(u)
        /\ commits' = commits \cup {[use |-> u, auth |-> u, land |-> Len(ops),
                                     truth |-> GrantedFull(u)]}
     \/ /\ Design \in {"grant_ref", "one_shot"}
        \* authorisation was decided when the GRANT was linearised in the authority domain
        /\ LastGrantPos > 0
        /\ (IF Design = "one_shot" THEN LastGrantPos = Len(ops) ELSE TRUE)
        /\ commits' = commits \cup {[use |-> u, auth |-> LastGrantPos, land |-> Len(ops),
                                     truth |-> GrantedFull(LastGrantPos + 1)]}
  /\ UNCHANGED <<ops, view>>

Next == \/ \E k \in Kinds : AppendOp(k)
        \/ Sync
        \/ \E u \in 1..MaxPos : Commit(u)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Properties                                                               *)
(***************************************************************************)

\* the authorisation a commit rests on was genuinely valid in the single order
AuthorisationIsGenuine == \A c \in commits : c.truth

\* STRONG semantics: no invalidation may occur between the position at which a commit was
\* authorised and the position at which it landed. (The first formulation of this property
\* was WRONG: it compared against the first revocation ever, which is not a defect once a
\* later re-GRANT is legitimate. Specification corrected, not the design.)
NoInvalidationBetweenAuthAndLanding ==
  \A c \in commits :
     ~\E r \in 1..Len(ops) :
        /\ ops[r].kind \in {"REVOKE", "EXPIRE", "COMPROMISE"}
        /\ r > c.auth
        /\ r <= c.land

\* L1.b — one authority-bearing operation per position (structural: ops is a sequence)
OnePerPosition == \A i \in 1..Len(ops) : ops[i].kind \in Kinds

=============================================================================
