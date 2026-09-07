<!-- GENERATED — DO NOT EDIT. Regenerate: python3 ARCHITECTURE-MODEL/regenerate.py -->
# Toolchain Identity View — what each verification path is allowed to execute (GENERATED VIEW — DO NOT EDIT)

- generator: `generate_views.py/3`
- canonical-model-root-digest: `5621efcaed1ac6478e7ad3dd2ab9c2986b36bc4812d9a2ef04704d9f94835dd8`
- regeneration command: `python3 ARCHITECTURE-MODEL/regenerate.py`

Review-2 N-11: these are executable policy, not prose. `gate_checks.py toolchain` verifies every row below — path, semantic version and exact executable digest — and refuses to let either verifier run on a mismatch. No tool proves its own identity: `verified by` names the OTHER path.

| tool | role | semantic version | verified by | path |
|---|---|---|---|---|
| CLINGO | ASP_SOLVER | 5.8.2 | KERNEL_PATH | `/usr/local/lib/python3.11/dist-packages/clingo/_clingo.cpython-311-x86_64-linux-gnu.so` |
| CPYTHON | CHECKER_RUNTIME | 3.11.15 | KERNEL_PATH | `/usr/local/bin/python3` |
| DIGEST-PROGRAM | DIGEST_PROVIDER | 9.4 | CHECKER_PATH | `/usr/bin/sha256sum` |
| OPENSSL-HASH | CHECKER_DIGEST_PROVIDER | 3.0.13 | KERNEL_PATH | `/usr/local/bin/python3` |
| SBCL | KERNEL_RUNTIME | 2.2.9 | CHECKER_PATH | `/usr/bin/sbcl` |
