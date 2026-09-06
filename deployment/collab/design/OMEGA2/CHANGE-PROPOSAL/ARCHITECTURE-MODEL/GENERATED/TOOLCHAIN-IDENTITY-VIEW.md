<!-- GENERATED — DO NOT EDIT. Regenerate: python3 ARCHITECTURE-MODEL/regenerate.py -->
# Toolchain Identity View — what each verification path is allowed to execute (GENERATED VIEW — DO NOT EDIT)

- generator: `generate_views.py/3`
- canonical-model-root-digest: `0902776d4672fe77b491e9d6b55fc4865a7362d22efe0382554d132fe847db92`
- regeneration command: `python3 ARCHITECTURE-MODEL/regenerate.py`

Review-2 N-11: these are executable policy, not prose. `gate_checks.py toolchain` verifies every row below — path, semantic version and exact executable digest — and refuses to let either verifier run on a mismatch. No tool proves its own identity: `verified by` names the OTHER path.

| tool | role | semantic version | verified by | path |
|---|---|---|---|---|
| CLINGO | ASP_SOLVER | 5.8.2 | KERNEL_PATH | `/usr/local/lib/python3.11/dist-packages/clingo/_clingo.cpython-311-x86_64-linux-gnu.so` |
| CPYTHON | CHECKER_RUNTIME | 3.11.15 | KERNEL_PATH | `/usr/local/bin/python3` |
| DIGEST-PROGRAM | DIGEST_PROVIDER | 9.4 | CHECKER_PATH | `/usr/bin/sha256sum` |
| OPENSSL-HASH | CHECKER_DIGEST_PROVIDER | 3.0.13 | KERNEL_PATH | `/usr/local/bin/python3` |
| SBCL | KERNEL_RUNTIME | 2.2.9 | CHECKER_PATH | `/usr/bin/sbcl` |
