---------------------------- MODULE MigrationRepro ----------------------------
(* ADVERSARY EXTENSION of Migration.tla for KT4.
   The original Verifies(p) == p.cv \in retained is a TEST-TAUTOLOGY: it models
   only canonicalizer-ID AVAILABILITY (retention), never the ACTUAL verification
   predicate a proof-carrying verifier must run: re-execute canonicalizer cv on
   the immutable bytes and check the resulting content-id == the hash committed
   in the proof. "text-hash-mismatch" (cited in Migration.tla's own header) and
   threat "#19 Re-canonicalization identity" live in the SECOND conjunct, which
   the model deletes.

   This module keeps §6.1 (tag), §6.2 (retain ID + select from proof), §6.3
   (additive), §6.4 (shadow) FULLY OBEYED, and adds the missing conjunct:
   `reproducible` = the set of canonicalizer versions whose PINNED TOOLCHAIN
   still reproduces its original bytes on the verifier's CURRENT platform.
   O4 §5.2 carries toolchain_manifest as DATA; nothing STRUCTURALLY guarantees
   a 2026 canonicalizer's toolchain (Unicode/ICU/hash-lib build) stays
   byte-reproducible over long horizons. Arch threats #19/#32/#47 concede this.
   PlatformDrift models that design-permitted evolution.                       *)
EXTENDS Naturals, FiniteSets
CONSTANTS MaxV, UNSAFE
VARIABLES schemaV, proofs, retained, reproducible
vars == <<schemaV, proofs, retained, reproducible>>

Proofs == [cv : 1..MaxV, tagged : BOOLEAN]

TypeOK == /\ schemaV \in 1..MaxV
          /\ proofs \subseteq Proofs
          /\ retained \subseteq 1..MaxV
          /\ reproducible \subseteq 1..MaxV

\* Init: v1 canonicalizer retained AND byte-reproducible on today's platform.
Init == /\ schemaV = 1 /\ proofs = {} /\ retained = {1} /\ reproducible = {1}

\* §6.1 obeyed: every issued proof is tagged (UNSAFE=FALSE => compliant world).
IssueProof ==
  /\ proofs' = proofs \cup {[cv |-> schemaV, tagged |-> ~UNSAFE]}
  /\ UNCHANGED <<schemaV, retained, reproducible>>

\* §6.2/§6.3 obeyed: additive; retain ID; new canonicalizer reproducible now.
Migrate ==
  /\ schemaV < MaxV
  /\ schemaV' = schemaV + 1
  /\ retained' = retained \cup {schemaV + 1}
  /\ reproducible' = reproducible \cup {schemaV + 1}
  /\ UNCHANGED proofs

\* DESIGN-PERMITTED (not a rule violation): the pinned toolchain of an OLD
\* canonicalizer version v ceases to be byte-reproducible on the current
\* platform (toolchain/Unicode/crypto evolution — threats #19/#32/#47).
\* §6.2 is STILL obeyed: v stays in `retained` (its ID/spec is retained);
\* only byte-reproducibility of its toolchain is lost. No §6.x rule forbids this.
PlatformDrift ==
  /\ \E v \in reproducible : /\ v < schemaV
                             /\ reproducible' = reproducible \ {v}
  /\ UNCHANGED <<schemaV, proofs, retained>>

\* The REAL verification predicate: select canonicalizer from the proof (retained)
\* AND re-canonicalization must reproduce the committed content-id (reproducible).
Verifies(p) == IF p.tagged
               THEN p.cv \in retained /\ p.cv \in reproducible
               ELSE p.cv = schemaV   /\ p.cv \in reproducible

Next == IssueProof \/ Migrate \/ PlatformDrift
Spec == Init /\ [][Next]_vars

INV_OldProofsStillVerify == \A p \in proofs : Verifies(p)
=============================================================================
