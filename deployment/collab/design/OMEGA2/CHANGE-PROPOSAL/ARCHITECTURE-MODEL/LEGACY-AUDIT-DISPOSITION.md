# LEGACY-AUDIT-DISPOSITION — v1.4–v1.8 audits are HISTORICAL_EVIDENCE / NON_AUTHORITATIVE_GATE

The legacy v1.8 harness (`V1.8-VERIFY.py`, `V1.8-CONTRADICTION-OMISSION-AUDIT.sh`, `V1.8-VERIFICATION-EVIDENCE.md`,
`V1.8-CANDIDATE-MANIFEST.md`, `V1.8-CLEAN-CLONE-BOOTSTRAP.sh`) and all v1.4–v1.7 audit scripts/outputs are FROZEN at
architecture commit `4787b342282f8d5f2ec4b9e64b11e32b7a64813a` and preserved unchanged as migration input and
historical evidence. They are classified `HISTORICAL_EVIDENCE / NON_AUTHORITATIVE_GATE` in `files-and-roles.sexp`.

Rules honored by this consolidation:
- No guard or literal mutation patch was added to the legacy v1.8 harness.
- A green legacy audit is NEVER a blocking or sufficient acceptance gate here — known legacy versions produced false
  positives (that is precisely why this canonical-model consolidation exists).
- The useful invariant CLASSES and counterexamples from v1.4–v1.8 were migrated into the canonical model as: model
  laws L1–L7 (canonical invariants), golden FAIL fixtures, and generated property families — with the migration
  conflict ledger recording every normalization. Distinct defect classes were preserved; duplicate/invalid checks
  were retired with reason.

The authoritative gate is now `ARCHITECTURE-MODEL-GATE.sh` (SBCL model-law kernel + independent clingo checker +
golden/property fixtures). It is NOT semantic, legal, security, behavioral, operational or qualification proof.
