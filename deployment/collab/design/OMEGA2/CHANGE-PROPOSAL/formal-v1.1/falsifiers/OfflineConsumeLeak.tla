-------------------------- MODULE OfflineConsumeLeak --------------------------
(* HONEST EXTENSION of OfflineConsume.tla.
   OfflineConsume.tla teleports a release into a cell: ConsumeOffline(m,r)
   requires r \in certified and updates held[m] with publicObs UNCHANGED.
   That models acquisition as FREE and INVISIBLE. But bytes must move: a cell
   obtains the certified offline copy through SOME distribution channel D, and
   D records the transfer. TrustState.tla independently forces this to be
   PERIODIC: RefreshCut needs `connected`, and Fresh == now-cutAt =< Delta, so
   each live cell must re-contact the cut/release source within every Delta or
   flip to UNKNOWN. This module adds only the one variable the design requires
   and OfflineConsume omitted: distSeen = what the distribution side (A's
   infrastructure) observes about who pulled. *)
EXTENDS FiniteSets
CONSTANTS Matters, Releases
VARIABLES certified, held, publicObs, distSeen
vars == <<certified, held, publicObs, distSeen>>

TypeOK == /\ certified \subseteq Releases
          /\ held \in [Matters -> SUBSET Releases]
          /\ publicObs \subseteq (Matters \cup Releases)
          /\ distSeen \subseteq Matters

Init == /\ certified = {} /\ held = [m \in Matters |-> {}]
        /\ publicObs = {} /\ distSeen = {}

Certify(r) == /\ certified' = certified \cup {r}
              /\ UNCHANGED <<held, publicObs, distSeen>>

\* The ONLY realizable ConsumeOffline: to place a certified copy into cell m,
\* the cell must PULL it from distribution D. D logs the pull as a distinct,
\* long-lived poller (network identity / TLS fingerprint / persistent Delta
\* cadence) => the matter-cell becomes observable to A-side infra.
ConsumeOfflineReal(m, r) ==
  /\ r \in certified
  /\ held' = [held EXCEPT ![m] = held[m] \cup {r}]
  /\ distSeen' = distSeen \cup {m}          \* the transfer leaves a trace
  /\ UNCHANGED <<certified, publicObs>>

Next == \/ \E r \in Releases : Certify(r)
        \/ \E m \in Matters, r \in Releases : ConsumeOfflineReal(m, r)

Spec == Init /\ [][Next]_vars

\* A-side observation now INCLUDES what the distribution channel reveals.
\* The design (§1.6) claims A observes NO matter existence/activity.
INV_PublicBlindToMatters == (publicObs \cup distSeen) \cap Matters = {}
=============================================================================
