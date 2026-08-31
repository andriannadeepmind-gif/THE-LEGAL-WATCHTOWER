---------------------------- MODULE TrustStateSkew ----------------------------
(***************************************************************************)
(* KT1 destruction pass. Same mechanism as TrustState.tla EXCEPT the one   *)
(* thing the original silently assumes: that the verifier's local clock    *)
(* equals real time. §5.5 states v-r =< Delta as an UNCONDITIONAL, real-    *)
(* time guarantee; §5.2 forbids anchoring the cut to wall clock ("epoch,    *)
(* not wall clock"), yet Delta is a wall-clock difference the verifier can  *)
(* only compute against its OWN local clock. Under a partition (KT1) that   *)
(* local clock can LAG real time -- a stopped/slow/rolled-back clock, a     *)
(* dead RTC, a VM-snapshot restore, or (per security-privilege R3, declared *)
(* "below TCB floor") a compromised host. No adversary is required: a clock *)
(* that merely STALLS suffices.                                             *)
(*                                                                          *)
(* now    = REAL time (issuer's honest clock; stamps issued-at = cutAt)     *)
(* vclock = the VERIFIER's local clock; may lag real time (stall).          *)
(* The invariant is measured in REAL time (verdictAt = now, revokedAt = now)*)
(* exactly as §5.5's r and v are real moments.                             *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Keys, MaxTime, Delta

VARIABLES now, vclock, revokedAt, connected, cutRevoked, cutAt, verdict, verdictAt

vars == <<now, vclock, revokedAt, connected, cutRevoked, cutAt, verdict, verdictAt>>

Never == MaxTime + 1

TypeOK ==
  /\ now \in 0..MaxTime
  /\ vclock \in 0..MaxTime
  /\ revokedAt \in [Keys -> 0..Never]
  /\ connected \in BOOLEAN
  /\ cutRevoked \subseteq Keys
  /\ cutAt \in 0..MaxTime
  /\ verdict \in [Keys -> {"none","valid","unknown","revoked"}]
  /\ verdictAt \in [Keys -> 0..MaxTime]

Init ==
  /\ now = 0
  /\ vclock = 0
  /\ revokedAt = [k \in Keys |-> Never]
  /\ connected = TRUE
  /\ cutRevoked = {}
  /\ cutAt = 0
  /\ verdict = [k \in Keys |-> "none"]
  /\ verdictAt = [k \in Keys |-> 0]

\* Real time advances by 1. The verifier's local clock MAY keep pace OR STALL
\* (advance by 0). Stalling models a slow/stopped clock during the partition.
\* No forward jump, no explicit rollback needed -- lag alone is the attack.
Tick ==
  /\ now < MaxTime
  /\ now' = now + 1
  /\ vclock' \in {vclock, vclock + 1}
  /\ vclock' =< now'                    \* verifier clock never ahead of real time
  /\ UNCHANGED <<revokedAt, connected, cutRevoked, cutAt, verdict, verdictAt>>

Revoke(k) ==
  /\ revokedAt[k] = Never
  /\ revokedAt' = [revokedAt EXCEPT ![k] = now]
  /\ UNCHANGED <<now, vclock, connected, cutRevoked, cutAt, verdict, verdictAt>>

Partition ==
  /\ connected' = ~connected
  /\ UNCHANGED <<now, vclock, revokedAt, cutRevoked, cutAt, verdict, verdictAt>>

\* Issuer stamps the cut with REAL time (honest issued-at).
RefreshCut ==
  /\ connected
  /\ cutRevoked' = {k \in Keys : revokedAt[k] =< now}
  /\ cutAt' = now
  /\ UNCHANGED <<now, vclock, revokedAt, connected, verdict, verdictAt>>

\* Freshness is judged against the VERIFIER's local clock, the only clock it
\* has under partition. This is the sole faithful change from TrustState.tla.
Fresh == vclock - cutAt =< Delta

\* The SAFE verify from TrustState.tla -- three outcomes, honest ignorance.
\* verdictAt records REAL now, because §5.5 speaks of the real moment v.
VerifySafe(k) ==
  /\ verdict' = [verdict EXCEPT ![k] =
       IF ~Fresh          THEN "unknown"
       ELSE IF k \in cutRevoked THEN "revoked"
       ELSE "valid"]
  /\ verdictAt' = [verdictAt EXCEPT ![k] = now]
  /\ UNCHANGED <<now, vclock, revokedAt, connected, cutRevoked, cutAt>>

Next ==
  \/ Tick
  \/ Partition
  \/ RefreshCut
  \/ \E k \in Keys : Revoke(k)
  \/ \E k \in Keys : VerifySafe(k)

Spec == Init /\ [][Next]_vars

\* §5.5 verbatim, measured in REAL time. This is the design's "essential
\* guarantee" INV_BoundedExposure, unchanged from TrustState.tla.
INV_BoundedExposure ==
  \A k \in Keys :
    (verdict[k] = "valid" /\ revokedAt[k] =< verdictAt[k])
      => (verdictAt[k] - revokedAt[k] =< Delta)
=============================================================================
