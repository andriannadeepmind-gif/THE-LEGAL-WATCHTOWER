# WATCHTOWER FORMAL ARCHITECTURE EVIDENCE PACK — results

model-set digest (sha256 over all model sources): `c5bb313f13bf3d7fe71535cc3d19fffe64129458331a2604aa3645e0febc2731`

executed: 2026-08-29 · python 3.11.15

Bounded exhaustive state-space exploration. A result is evidence ONLY within its bounds stamp; no result below is a universal theorem.

### MODEL A — Commit/Cut state machine

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'objects': 2, 'certificates': 1, 'max_commits': 3, 'max_cuts': 2, 'max_prepared': 2, 'faults': 'crash+recovery at any point'}
search: EXHAUSTED, states=18122, transitions=30141, max-depth=20

properties:
  - NoHalfCommit: HOLDS (no reachable violation within bounds)
  - NoObjectCommitCycle: HOLDS (no reachable violation within bounds)
  - HistoricalImmutability: HOLDS (no reachable violation within bounds)
  - CutMonotonicity: HOLDS (no reachable violation within bounds)
  - NoBackdating: HOLDS (no reachable violation within bounds)
  - NoSelfCertification: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - torn_commit vs NoHalfCommit: CAUGHT — trace: prepare(o1) -> prepare(o2) -> commit(o1,o2)
  - id_from_commit vs NoObjectCommitCycle: CAUGHT — trace: prepare(o1) -> commit(o1)
  - rewrite_history vs HistoricalImmutability: CAUGHT — trace: prepare(o1) -> commit(o1) -> cut(head=1) -> rewrite_commit0
  - cut_regression vs CutMonotonicity: CAUGHT — trace: prepare(o1) -> commit(o1) -> cut(head=1) -> cut_regress(head=0)
  - leak_pending_into_cut vs NoBackdating: CAUGHT — trace: prepare(o1) -> cut(head=0)
  - pc_future_ref vs NoSelfCertification: CAUGHT — trace: prepare_pc(p1,ref=1) -> commit(p1)

### MODEL C — Authority / capability algebra

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'authorities': ['WRITE_LEGAL', 'WRITE_EPISTEMIC', 'EGRESS'], 'holders': ['h1', 'h2'], 'max_capabilities': 3, 'max_delegation_depth': 1, 'root_classes': ['R_LEGAL', 'R_EPISTEMIC'], 'data_classes': ['PUBLIC', 'PRIVILEGED']}
search: EXHAUSTED, states=15329, transitions=41258, max-depth=9

properties:
  - NoPrivilegeEscalation: HOLDS (no reachable violation within bounds)
  - DelegationNeverIncreasesAuthority: HOLDS (no reachable violation within bounds)
  - NoEgressForRestrictedClasses: HOLDS (no reachable violation within bounds)
  - RootWriteOnlyWithValidEntryProof: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - delegate_superset vs DelegationNeverIncreasesAuthority: CAUGHT — trace: issue(c0,h1,['WRITE_LEGAL']) -> delegate(c0->c0.1,h1,['EGRESS'])
  - write_without_proof vs RootWriteOnlyWithValidEntryProof: CAUGHT — trace: issue(c0,h1,['WRITE_LEGAL']) -> write(c0,R_LEGAL,proof=False)
  - write_without_authority vs NoPrivilegeEscalation: CAUGHT — trace: issue(c0,h1,['WRITE_LEGAL']) -> write(c0,R_EPISTEMIC,proof=True)
  - egress_restricted vs NoEgressForRestrictedClasses: CAUGHT — trace: issue(c0,h1,['EGRESS']) -> egress(c0,PRIVILEGED)

### MODEL D — Matter/system causality and modelled-channel noninterference

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'matters': ['A', 'B'], 'max_system_commits': 2, 'max_commits_per_matter': 2, 'modelled_observation_channel': 'system-visible commit counter + own matter chain', 'outside_model': 'timing, contention, storage latency, traffic (declared residuals)'}
search: EXHAUSTED, states=838, transitions=1179, max-depth=6

properties:
  - CrossNamespaceReferencesAreBackwardOnly: HOLDS (no reachable violation within bounds)
  - MatterBasisCutMonotonic: HOLDS (no reachable violation within bounds)
  - NoModelledCrossMatterObservation: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - allow_future_basis vs CrossNamespaceReferencesAreBackwardOnly: CAUGHT — trace: matter_commit(A,basis=1)
  - allow_basis_regression vs MatterBasisCutMonotonic: CAUGHT — trace: sys_commit(->1) -> matter_commit(A,basis=1) -> matter_commit(A,basis=0)
  - counter_leak vs NoModelledCrossMatterObservation: CAUGHT — trace: matter_commit(A,basis=0)

### MODEL E — Key lifecycle and recovery state machine

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'threshold': 2, 'total_shares': 3, 'statuses': ['ACTIVE', 'EXPIRED', 'REVOKED', 'COMPROMISED', 'DESTROYED'], 'max_transitions': 5, 'faults': 'expiry, revocation, compromise, destruction at any point'}
search: EXHAUSTED, states=1080, transitions=1290, max-depth=5

properties:
  - RevokedKeyCannotAuthorize: HOLDS (no reachable violation within bounds)
  - CompromisedOperationalKeyCannotSelfRecover: HOLDS (no reachable violation within bounds)
  - RecoveryRequiresDeclaredThreshold: HOLDS (no reachable violation within bounds)
  - DestroyedKeyCannotReturnToActive: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - sign_when_revoked vs RevokedKeyCannotAuthorize: CAUGHT — trace: fault(EXPIRED) -> sign(status=EXPIRED)
  - allow_self_recovery vs CompromisedOperationalKeyCannotSelfRecover: CAUGHT — trace: fault(COMPROMISED) -> self_recover
  - threshold_off_by_one vs RecoveryRequiresDeclaredThreshold: CAUGHT — trace: quorum_recover(shares=1)
  - resurrect_destroyed vs DestroyedKeyCannotReturnToActive: CAUGHT — trace: fault(DESTROYED) -> quorum_recover(shares=2)

### MODEL H — matter state continuity / rollback resistance

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'max_head': 3, 'max_epochs': 2, 'adversary': 'may lower the stored chain head arbitrarily (rollback), may restart', 'continuity_mechanism': 'PROFILED: hardware monotonic state | client receipts | privacy-preserving external anchor | rollback-resistant ledger | hybrid', 'outside_model': 'physical extraction of the continuity state itself'}
search: EXHAUSTED, states=30, transitions=86, max-depth=8

properties:
  - NoStaleHighAssuranceServe: HOLDS (no reachable violation within bounds)
  - PublicAnchorRevealsNothing: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - no_continuity_check vs NoStaleHighAssuranceServe: CAUGHT — trace: advance(head=1) -> rollback(head 1->0) -> serve_high_assurance(head=0,anchor=1)
  - publish_on_activity vs PublicAnchorRevealsNothing: CAUGHT — trace: advance(head=1)

## Model B — replication profiles

### MODEL B/CFT_3 — crash-fault profile, no Byzantine replica

verdict: **BOUNDED-EXHAUSTIVE PASS**

bounds stamp: {'replicas': 3, 'quorum': 2, 'byzantine': [], 'values': ['A', 'B'], 'max_epochs': 2, 'log_positions': 1, 'partition_scenarios': [[0, 1, 2], [0, 1], [1, 2], [0]], 'max_partition_changes': 2, 'faults': 'bounded partition/heal; Byzantine replicas may equivocate on acks and suppress their locks at view change'}
search: EXHAUSTED, states=21944, transitions=61408, max-depth=16

properties:
  - NoDualCommittedValue: HOLDS (no reachable violation within bounds)
  - QuorumSafety: HOLDS (no reachable violation within bounds)
  - NoAuthorityWithoutRequiredQuorum: HOLDS (no reachable violation within bounds)

mutation battery (teeth — a seeded defect MUST be caught):
  - quorum_off_by_one vs QuorumSafety: CAUGHT — trace: elect(l=0,e=1,promise=[0, 1],lie=0) -> propose(A@1) -> ack(r0,A@1,reachable=True) -> commit(A@1,acks=1)
  - ignore_lock vs NoDualCommittedValue: CAUGHT — trace: elect(l=0,e=1,promise=[0, 1],lie=0) -> propose(A@1) -> ack(r0,A@1,reachable=True) -> ack(r1,A@1,reachable=True) -> commit(A@1,acks=2) -> elect(l=0,e=2,promise=[0, 1],lie=0) -> propose(B@2) -> ack(r0,B@2,reachable=True) -> ack(r1,B@2,reachable=True) -> commit(B@2,acks=2)
  - ack_from_unreachable vs NoAuthorityWithoutRequiredQuorum: CAUGHT — trace: elect(l=0,e=1,promise=[0, 1],lie=0) -> propose(A@1) -> ack(r0,A@1,reachable=True) -> partition([0, 1]) -> ack(r2,A@1,reachable=False) -> commit(A@1,acks=2)

### MODEL B/CFT_3_BYZ — crash-fault profile under a Byzantine replica

EXPECTED OUTCOME: a safety violation. This run is the executable evidence for invariant I-24 — a crash-fault-tolerant profile may not be claimed under a Byzantine threat model. A violation here is the intended demonstration.

bounds stamp: {'replicas': 3, 'quorum': 2, 'byzantine': [2], 'values': ['A', 'B'], 'max_epochs': 2, 'log_positions': 1, 'partition_scenarios': [[0, 1, 2], [0, 1], [1, 2], [0]], 'max_partition_changes': 2, 'faults': 'bounded partition/heal; Byzantine replicas may equivocate on acks and suppress their locks at view change'}
search: EXHAUSTED, states=33944, transitions=93988

  - NoDualCommittedValue: VIOLATED — trace: elect(l=0,e=1,promise=[0, 1],lie=0) -> propose(A@1) -> ack(r0,A@1,reachable=True) -> ack(r2,A@1,reachable=True) -> commit(A@1,acks=2) -> elect(l=1,e=2,promise=[1, 2],lie=0) -> propose(B@2) -> ack(r0,B@2,reachable=True) -> ack(r1,B@2,reachable=True) -> commit(B@2,acks=2)
  - QuorumSafety: holds
  - NoAuthorityWithoutRequiredQuorum: holds

### MODEL B/BFT_4 — Byzantine profile, n=4, quorum=3, f=1

EXPECTED OUTCOME: safe. Quorum intersection 2q-n = 2 exceeds f = 1, so every committed value retains an honest witness across a view change.

bounds stamp: {'replicas': 4, 'quorum': 3, 'byzantine': [3], 'values': ['A', 'B'], 'max_epochs': 2, 'log_positions': 1, 'partition_scenarios': [[0, 1, 2, 3], [0, 1, 2], [1, 2, 3], [0, 1]], 'max_partition_changes': 2, 'faults': 'bounded partition/heal; Byzantine replicas may equivocate on acks and suppress their locks at view change'}
search: EXHAUSTED, states=146888, transitions=471880

  - NoDualCommittedValue: HOLDS (no reachable violation within bounds)
  - QuorumSafety: HOLDS (no reachable violation within bounds)
  - NoAuthorityWithoutRequiredQuorum: HOLDS (no reachable violation within bounds)

## Model D2 — noninterference per declared channel

  - identifiers: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - handles: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - counters: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - sequence_numbers: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - namespace_presence: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - storage_keys: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - cache_keys: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - control_messages: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - error_results: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - authorization_outcomes: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT
  - explicit_metadata: baseline EXHAUSTED (9 states) HOLDS=True · seeded leak CAUGHT

## Counter-challenge evidence (I-41, I-42, I-44)

  - MODEL F (I-41 verifiable answers): PASS — honest answer verifies; rejected attacks: omit_middle, omit_last, omit_first, forge_value, drop_boundary, wrong_root
  - MODEL G (I-42 typed accountability): PASS — true_equivocation=ok; independent_disagreement=ok; protocol_violation=ok; unverifiable_statement=ok; identical_restatement=ok
  - MODEL I (I-44 canonical encoding): PASS — round-trip, canonical acceptance, injectivity, domain separation, differential; 5/5 malleability mutants caught

## OVERALL

**ALL MODELS: BOUNDED-EXHAUSTIVE PASS**

Scope not covered by these models (declared, not silently generalized): runtime/hardware integrity, physical and timing side channels, cryptographic primitive strength, supply-chain and update mechanics, long-term validation, human identity assurance, and every property whose enforcement lives outside the modelled state machines. Those remain contract + assumption-ledger items and empirical falsifiers.
