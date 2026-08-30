------------------------------ MODULE WatchtowerLog ------------------------------
(***************************************************************************)
(* WATCHTOWER VLT — industrial formal model of the ORDERED COMMIT CHAIN.    *)
(*                                                                          *)
(* Closes residual R-s: the executable Python model covered a single        *)
(* decision instance; this model covers a multi-position replicated log and *)
(* the log-consistency properties that the single-decision model could not  *)
(* express: LogMatching, PrefixConsistency, NoCommittedGap,                 *)
(* CommittedPrefixMonotonicity, NoTwoValuesAtSamePosition.                  *)
(*                                                                          *)
(* Abstraction level: an abstract state-machine-replication log with        *)
(* epoch fencing and an election restriction (a new leader adopts the most  *)
(* up-to-date log among a promise quorum). It is NOT a proof of any         *)
(* specific production protocol; it is evidence about the commit-chain      *)
(* semantics the VLT CommitReplicationProfile requires.                     *)
(*                                                                          *)
(* Byzantine replicas may (a) suppress their log at election time and       *)
(* (b) accept replication without the log-matching check.                   *)
(*                                                                          *)
(* Bug constant seeds a defect for the anti-vacuity battery:                *)
(*   "none" | "no_gap_check" | "ignore_adoption" | "truncate_commit"        *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Replicas, Values, Quorum, Byz, MaxEpoch, MaxPos, Bug

ASSUME /\ Byz \subseteq Replicas
       /\ Quorum \in Nat
       /\ MaxEpoch \in Nat /\ MaxPos \in Nat

NoEntry  == [val |-> "none", ep |-> 0]
Entries  == [val: Values, ep: 1..MaxEpoch]
Positions == 1..MaxPos
NoLeader == "none"

VARIABLES epoch, leader, log, committed, promised
vars == <<epoch, leader, log, committed, promised>>

TypeOK ==
  /\ epoch \in 0..MaxEpoch
  /\ leader \in Replicas \cup {NoLeader}
  /\ log \in [Replicas -> [Positions -> Entries \cup {NoEntry}]]
  /\ committed \subseteq [pos: Positions, val: Values]
  /\ promised \in [Replicas -> 0..MaxEpoch]

Init ==
  /\ epoch = 0
  /\ leader = NoLeader
  /\ log = [r \in Replicas |-> [p \in Positions |-> NoEntry]]
  /\ committed = {}
  /\ promised = [r \in Replicas |-> 0]

\* length of a (contiguous by construction) log
LogLen(l) == Cardinality({p \in Positions : l[p] # NoEntry})
LastEp(l) == IF LogLen(l) = 0 THEN 0 ELSE l[LogLen(l)].ep

\* first empty position, 0 if full
FirstEmpty(l) ==
  IF LogLen(l) = MaxPos THEN 0 ELSE LogLen(l) + 1

(***************************************************************************)
(* Election. Q is the promise quorum; Sup are the Byzantine members of Q    *)
(* that suppress their log (present an empty view). The new leader adopts   *)
(* the most up-to-date log among the effective views -- the election        *)
(* restriction that makes the protocol safe under crash faults.             *)
(***************************************************************************)
Empty == [p \in Positions |-> NoEntry]

\* A well-formed log is a contiguous prefix with non-decreasing entry epochs.
\* Discovered by TLC: without this check an electing leader adopts a malformed
\* log presented by a Byzantine replica and log matching collapses.
WellFormed(l) ==
  /\ \A p \in Positions : IF p > 1 THEN ((l[p] # NoEntry) => (l[p-1] # NoEntry)) ELSE TRUE
  /\ \A p \in Positions :
       IF p > 1 THEN ((l[p] # NoEntry /\ l[p-1] # NoEntry) => (l[p-1].ep <= l[p].ep)) ELSE TRUE

View(r, Sup) ==
  IF r \in Sup THEN Empty
  ELSE IF WellFormed(log[r]) THEN log[r] ELSE Empty

MoreUpToDate(a, b) ==
  \/ LastEp(a) > LastEp(b)
  \/ (LastEp(a) = LastEp(b) /\ LogLen(a) >= LogLen(b))

Elect(l, Q, Sup) ==
  /\ epoch < MaxEpoch
  /\ Cardinality(Q) >= Quorum
  /\ l \in Q
  /\ Sup \subseteq (Q \cap Byz)
  /\ LET best == CHOOSE r \in Q : \A s \in Q : MoreUpToDate(View(r, Sup), View(s, Sup))
     IN log' = [log EXCEPT ![l] = IF Bug = "ignore_adoption" THEN Empty ELSE View(best, Sup)]
  /\ epoch' = epoch + 1
  /\ leader' = l
  /\ promised' = [r \in Replicas |-> IF r \in Q THEN epoch + 1 ELSE promised[r]]
  /\ UNCHANGED committed

Append(v) ==
  /\ leader # NoLeader
  /\ FirstEmpty(log[leader]) # 0
  /\ log' = [log EXCEPT ![leader][FirstEmpty(log[leader])] = [val |-> v, ep |-> epoch]]
  /\ UNCHANGED <<epoch, leader, committed, promised>>

\* log-matching precondition, total (no evaluation at position 0)
PrevMatches(r, p) == IF p = 1 THEN TRUE ELSE log[r][p-1] = log[leader][p-1]

Replicate(r, p) ==
  /\ leader # NoLeader
  /\ r # leader
  /\ log[leader][p] # NoEntry
  /\ IF r \in Byz                                  \* Byzantine: no log-matching check
       THEN TRUE
       ELSE promised[r] <= epoch /\ PrevMatches(r, p)   \* fencing + log matching
  \* CONFLICT truncation: accepting an entry at p discards the suffix beyond p ONLY
  \* when the incoming entry conflicts with the stored one. Both halves were found by
  \* TLC: without any truncation a stale suffix survives a prefix overwrite and breaks
  \* log matching; with UNCONDITIONAL truncation a replica discards entries that back an
  \* already committed position and a later leader commits a different value there.
  /\ log' = [log EXCEPT ![r] =
        IF log[r][p] = log[leader][p]
          THEN log[r]                       \* identical entry: idempotent, discards nothing
          ELSE [q \in Positions |-> IF q < p THEN log[r][q]
                                    ELSE IF q = p THEN log[leader][p]
                                    ELSE NoEntry]]
  /\ promised' = [promised EXCEPT ![r] = IF r \in Byz THEN promised[r] ELSE epoch]
  /\ UNCHANGED <<epoch, leader, committed>>

Commit(p) ==
  /\ leader # NoLeader
  /\ log[leader][p] # NoEntry
  /\ log[leader][p].ep = epoch                      \* current-epoch commit rule
  /\ Cardinality({r \in Replicas : log[r][p] = log[leader][p]}) >= Quorum
  /\ IF Bug = "no_gap_check" THEN TRUE
     ELSE IF p = 1 THEN TRUE
     ELSE \E c \in committed : c.pos = p - 1       \* no gap: prefix must be committed
  /\ committed' = committed \cup {[pos |-> p, val |-> log[leader][p].val]}
  /\ UNCHANGED <<epoch, leader, log, promised>>

TruncateCommitted ==
  /\ Bug = "truncate_commit"
  /\ committed # {}
  /\ committed' = committed \ {CHOOSE c \in committed : TRUE}
  /\ UNCHANGED <<epoch, leader, log, promised>>

Next ==
  \/ \E l \in Replicas, Q \in SUBSET Replicas, Sup \in SUBSET Byz : Elect(l, Q, Sup)
  \/ \E v \in Values : Append(v)
  \/ \E r \in Replicas, p \in Positions : Replicate(r, p)
  \/ \E p \in Positions : Commit(p)
  \/ TruncateCommitted

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Safety properties (R-s closure)                                          *)
(***************************************************************************)
Honest == Replicas \ Byz

NoTwoValuesAtSamePosition ==
  \A c1, c2 \in committed : c1.pos = c2.pos => c1.val = c2.val

NoCommittedGap ==
  \A c \in committed : (c.pos = 1) \/ (\E d \in committed : d.pos = c.pos - 1)

LogMatching ==
  \A r1 \in Honest : \A r2 \in Honest : \A p \in Positions :
     (log[r1][p] # NoEntry /\ log[r1][p] = log[r2][p])
       => (\A q \in Positions : (q < p) => (log[r1][q] = log[r2][q]))

PrefixConsistency ==
  \A r1, r2 \in Honest : \A p \in Positions :
     (log[r1][p] # NoEntry /\ log[r2][p] # NoEntry /\ log[r1][p].ep = log[r2][p].ep)
       => log[r1][p].val = log[r2][p].val

CommittedPrefixMonotonicity == [][committed \subseteq committed']_vars

=============================================================================
