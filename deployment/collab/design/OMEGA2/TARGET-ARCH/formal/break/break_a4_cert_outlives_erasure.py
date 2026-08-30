"""BREAK A-4 — an AnswerCertificate (I-41) survives a governed erasure (I-26/I-31) and keeps
proving the erased content. Executable demonstration against our own reference construction.

The two invariants were designed independently and compose into a contradiction:
  I-41 binds an answer to a certified view root with inclusion proofs over (index, key, VALUE).
  I-26/I-31 promise that after a governed erasure the plaintext is unrecoverable.
A certificate issued before the erasure is a self-contained, third-party-verifiable artifact
that still proves the erased value. It is not a copy that leaked -- it is proof.
"""
import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
from model_f_answers import AuthView, client_verify

MATTER = {"m-note01": "client admitted the debt on 12/3",   # PRIVILEGED, later erased
          "m-note02": "meeting minutes",
          "m-note03": "expert opinion"}

def main():
    view = AuthView(MATTER)
    cert = view.answer("m-note01", "m-note02")          # served to a recipient, day 1
    ok, why = client_verify(cert, view.root)
    print(f"day 1 — certificate issued and verified: {ok} ({why})")
    print(f"        it proves verbatim: {[(e['k'], e['v']) for e in cert['elements']]}")

    # day 2: governed erasure of m-note01 (DEK destroyed, ciphertext sanitized, certificate
    # of erasure appended). The live store no longer holds the plaintext.
    remaining = {k: v for k, v in MATTER.items() if k != "m-note01"}
    view_after = AuthView(remaining)
    print("\nday 2 — governed erasure executed; live store no longer holds the plaintext")

    still_ok, why2 = client_verify(cert, view.root)
    print(f"        old certificate still verifies against the OLD root: {still_ok} ({why2})")
    print(f"        and still proves: {[(e['k'], e['v']) for e in cert['elements']]}")
    leak = any(e["k"] == "m-note01" for e in cert["elements"])
    print(f"        ERASED CONTENT STILL PROVEN BY A VALID CERTIFICATE: {leak}")

    broken, why3 = client_verify(cert, view_after.root)
    print(f"\n        against the NEW root the same certificate fails: {not broken} ({why3})")
    print("        -> either old certificates break (advice already given becomes unverifiable)")
    print("           or old roots are retained (and the erasure is incomplete at the proof layer)")
    print(f"\nBREAK A-4 CONFIRMED: {leak}")
    return 0 if leak else 1

if __name__ == "__main__":
    raise SystemExit(main())
