------------------------------ MODULE WatchtowerCore ------------------------------
(***************************************************************************)
(* WATCHTOWER VLT — industrial formal model of the COMMIT/CUT nucleus and   *)
(* the KEY lifecycle. Closes residual R-j for: RootCommit + committed       *)
(* entries, checkpoint cuts, composite (system,matter) evaluation cuts,     *)
(* admission corrections, key destruction/recovery.                         *)
(*                                                                          *)
(* Bug seeds the anti-vacuity battery:                                      *)
(*  "none" | "torn_commit" | "rewrite_history" | "cut_regression"           *)
(*  | "leak_pending" | "basis_future" | "basis_regress" | "resurrect_key"   *)
(*  | "self_recover" | "sign_when_revoked"                                  *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, Sequences, TLC

CONSTANTS Objects, MaxCommits, MaxCuts, MaxSys, MaxMatterCommits, Threshold,
          TotalShares, Bug

ACTIVE == "ACTIVE"   EXPIRED == "EXPIRED"   REVOKED == "REVOKED"
COMPROMISED == "COMPROMISED"                DESTROYED == "DESTROYED"
Statuses == {ACTIVE, EXPIRED, REVOKED, COMPROMISED, DESTROYED}

VARIABLES prepared, intents, commits, corrections, cuts, crashed,
          sysLen, matterChain,
          keyStatus, everDestroyed, signs, recoveries
vars == <<prepared, intents, commits, corrections, cuts, crashed, sysLen, matterChain,
          keyStatus, everDestroyed, signs, recoveries>>

\* view of the ledger at control head h: objects committed before h, minus corrections
View(cm, co, h) ==
  LET added == UNION { cm[i] : i \in 1..h }
      removed == UNION { co[i] : i \in 1..h }
  IN added \ removed

Init ==
  /\ prepared = {} /\ intents = << >> /\ commits = << >> /\ corrections = << >> /\ cuts = << >>
  /\ crashed = FALSE
  /\ sysLen = 0 /\ matterChain = << >>
  /\ keyStatus = ACTIVE /\ everDestroyed = FALSE
  /\ signs = {} /\ recoveries = {}

Committed == IF Len(commits) = 0 THEN {} ELSE UNION { commits[i] : i \in 1..Len(commits) }

(* ---------------- commit / cut nucleus ---------------- *)
Prepare(o) ==
  /\ ~crashed /\ o \notin prepared /\ o \notin Committed
  /\ prepared' = prepared \cup {o}
  /\ UNCHANGED <<intents, commits, corrections, cuts, crashed, sysLen, matterChain,
                 keyStatus, everDestroyed, signs, recoveries>>

CommitTx ==
  /\ ~crashed /\ prepared # {} /\ Len(commits) < MaxCommits
  /\ LET eff == IF Bug = "torn_commit" /\ Cardinality(prepared) > 1
                  THEN {CHOOSE o \in prepared : TRUE} ELSE prepared
         rest == IF Bug = "torn_commit" /\ Cardinality(prepared) > 1
                  THEN prepared \ eff ELSE {}
     IN /\ commits' = Append(commits, eff)
        /\ intents' = Append(intents, prepared)
        /\ prepared' = rest
  /\ corrections' = Append(corrections, {})
  /\ UNCHANGED <<cuts, crashed, sysLen, matterChain, keyStatus, everDestroyed,
                 signs, recoveries>>

Correct(o) ==
  /\ ~crashed /\ o \in Committed /\ Len(commits) < MaxCommits
  /\ commits' = Append(commits, {}) /\ intents' = Append(intents, {})
  /\ corrections' = Append(corrections, {o})
  /\ UNCHANGED <<prepared, cuts, crashed, sysLen, matterChain, keyStatus,
                 everDestroyed, signs, recoveries>>

TakeCut ==
  /\ ~crashed /\ Len(cuts) < MaxCuts
  /\ LET h == Len(commits)
         base == View(commits, corrections, h)
         hh == IF Bug = "cut_regression"
                 THEN (IF Len(cuts) > 0
                         THEN (IF cuts[Len(cuts)].head > 0 THEN cuts[Len(cuts)].head - 1 ELSE h)
                         ELSE h)
                 ELSE h
         stored == IF Bug = "leak_pending" THEN View(commits, corrections, hh) \cup prepared
                                                        ELSE View(commits, corrections, hh)
     IN cuts' = Append(cuts, [head |-> hh, view |-> stored])
  /\ UNCHANGED <<prepared, intents, commits, corrections, crashed, sysLen, matterChain,
                 keyStatus, everDestroyed, signs, recoveries>>

RewriteHistory ==
  /\ Bug = "rewrite_history" /\ Len(commits) > 0 /\ commits[1] # {}
  /\ commits' = [commits EXCEPT ![1] = {}] /\ intents' = [intents EXCEPT ![1] = {}]
  /\ UNCHANGED <<prepared, corrections, cuts, crashed, sysLen, matterChain,
                 keyStatus, everDestroyed, signs, recoveries>>

Crash ==
  /\ ~crashed /\ crashed' = TRUE
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, sysLen, matterChain,
                 keyStatus, everDestroyed, signs, recoveries>>

Recover ==
  /\ crashed /\ crashed' = FALSE /\ prepared' = {}   \* deterministic cleanup
  /\ UNCHANGED <<intents, commits, corrections, cuts, sysLen, matterChain, keyStatus,
                 everDestroyed, signs, recoveries>>

(* ---------------- composite system/matter cuts ---------------- *)
SysCommit ==
  /\ ~crashed /\ sysLen < MaxSys /\ sysLen' = sysLen + 1
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, matterChain,
                 keyStatus, everDestroyed, signs, recoveries>>

MatterCommit(b) ==
  /\ ~crashed /\ Len(matterChain) < MaxMatterCommits
  /\ IF Bug = "basis_future" THEN TRUE ELSE b <= sysLen
  /\ IF Bug = "basis_regress" THEN TRUE
     ELSE IF Len(matterChain) = 0 THEN TRUE
     ELSE b >= matterChain[Len(matterChain)].basis
  /\ matterChain' = Append(matterChain, [basis |-> b, sysAt |-> sysLen])
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, sysLen,
                 keyStatus, everDestroyed, signs, recoveries>>

(* ---------------- key lifecycle ---------------- *)
Sign ==
  /\ IF Bug = "sign_when_revoked" THEN keyStatus \in {ACTIVE, REVOKED, EXPIRED}
     ELSE keyStatus = ACTIVE
  /\ signs' = signs \cup {keyStatus}
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, sysLen,
                 matterChain, keyStatus, everDestroyed, recoveries>>

KeyFault(s) ==
  /\ keyStatus # DESTROYED                       \* DESTROYED is absorbing
  /\ s # keyStatus
  /\ keyStatus' = s /\ everDestroyed' = (everDestroyed \/ s = DESTROYED)
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, sysLen,
                 matterChain, signs, recoveries>>

SelfRecover ==
  /\ Bug = "self_recover" /\ keyStatus = COMPROMISED
  /\ keyStatus' = ACTIVE /\ recoveries' = recoveries \cup {[auth |-> "self", sh |-> 0]}
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, sysLen,
                 matterChain, everDestroyed, signs>>

QuorumRecover(k) ==
  /\ IF Bug = "resurrect_key" THEN TRUE ELSE ~everDestroyed
  /\ IF Bug = "threshold_off" THEN k >= Threshold - 1 ELSE k >= Threshold
  /\ keyStatus' = ACTIVE
  /\ recoveries' = recoveries \cup {[auth |-> "quorum", sh |-> k]}
  /\ UNCHANGED <<prepared, intents, commits, corrections, cuts, crashed, sysLen,
                 matterChain, everDestroyed, signs>>

Next ==
  \/ \E o \in Objects : Prepare(o)
  \/ CommitTx
  \/ \E o \in Objects : Correct(o)
  \/ TakeCut \/ RewriteHistory \/ Crash \/ Recover \/ SysCommit
  \/ \E b \in 0..MaxSys : MatterCommit(b)
  \/ Sign
  \/ \E s \in Statuses : KeyFault(s)
  \/ SelfRecover
  \/ \E k \in 0..TotalShares : QuorumRecover(k)

Spec == Init /\ [][Next]_vars

(* ---------------- properties ---------------- *)
NoHalfCommit ==
  /\ prepared \cap Committed = {}
  /\ \A i \in 1..Len(commits) : commits[i] = intents[i]     \* all-or-nothing
  /\ \A i, j \in 1..Len(commits) : (i # j) => (commits[i] \cap commits[j] = {})

HistoricalImmutability ==
  \A i \in 1..Len(cuts) : cuts[i].view = View(commits, corrections, cuts[i].head)

CutMonotonicity ==
  \A i \in 1..Len(cuts) : (i > 1) => (cuts[i].head >= cuts[i-1].head)

NoBackdating ==
  \A i \in 1..Len(cuts) :
     cuts[i].view \subseteq (IF cuts[i].head = 0 THEN {}
                             ELSE UNION { commits[j] : j \in 1..cuts[i].head })

BasisBackwardOnly ==
  \A i \in 1..Len(matterChain) : matterChain[i].basis <= matterChain[i].sysAt

BasisMonotonic ==
  \A i \in 1..Len(matterChain) :
     (i > 1) => (matterChain[i].basis >= matterChain[i-1].basis)

RevokedKeyCannotAuthorize == signs \subseteq {ACTIVE}

NoSelfRecovery == \A r \in recoveries : r.auth # "self"

RecoveryRequiresThreshold ==
  \A r \in recoveries : (r.auth = "quorum") => (r.sh >= Threshold)

DestroyedKeyCannotReturn == everDestroyed => (keyStatus = DESTROYED)

=============================================================================
