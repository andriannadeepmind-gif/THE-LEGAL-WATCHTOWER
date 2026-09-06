# CANONICAL-ENCODING — AMC2, the normative fact/commitment encoding

**Version `AMC2`.** Declared in `MODEL-SCHEMA.sexp` as `:canonical-encoding`, so the encoding version is inside
the hash-pinned schema and every implementation refuses to proceed against a version it does not implement.

## 1. Why this exists

`AMC1` — the superseded encoding — rendered a fact as `TYPE|ID|KEY=VALUE|…`. That is a **delimiter** encoding,
and delimiters are only unambiguous while no value can contain them. Nothing forbade `|` or `=` inside a string
value, so two structurally different, individually legal models rendered to identical bytes:

    A:  (fact source-class COLLIDE-PROBE … :maps-to "m|REASON=r")
    B:  (fact source-class COLLIDE-PROBE … :maps-to "m"  :reason "r")

Both passed every law on both verification paths, and both produced the commitment `ae7ac96196584e1c…`. The
commitment claims to be *the identity of the fact universe*; an encoding in which two different universes share
an identity cannot support that claim. Escaping `|` alone would not settle it either — it moves the ambiguity to
the escape character. `AMC2` removes the class: **nothing is ever searched for, because every component carries
its own length.**

## 2. The encoding

Let `utf8(s)` be the UTF-8 encoding of `s`, and `|utf8(s)|` its length in bytes.

    enc(s)  :=  decimal(|utf8(s)|)  ":"  utf8(s)

`enc` is injective: the decimal length is terminated by the single `:` that cannot occur in a decimal numeral, and
the following byte count is exact, so a reader recovers `s` without inspecting its content. Concatenations of
`enc` values are therefore uniquely parseable, and no value can impersonate a boundary.

### 2.1 Fact rendering

Given a fact of type `T`, id `I` and pairs `(k, v)`:

* `T` and every key are upper-cased; `I` and every value are the canonical value rendering
  (string → content, integer → decimal, plain symbol → upper-case name; control characters are not legal values);
* each pair is encoded as `enc(KEY) ‖ enc(VALUE)` and the encoded pair **strings** are sorted in code-point order;
* the render is

      enc("AMC2") ‖ enc(schema-version) ‖ enc(TYPE) ‖ enc(ID) ‖ enc(decimal(n)) ‖ pair₁ ‖ … ‖ pairₙ

  where `n` is the number of pairs.

The `enc("AMC2")` prefix is **domain separation**; `enc(schema-version)` **binds the render to the schema** that
declared the fact types, so the same bytes under a different schema are a different render by construction.

### 2.2 Commitment digest

For a scope label `S` and a set of renders `L` (sorted in code-point order):

    digest(S, L)  :=  SHA-256( enc("AMC2-COMMITMENT") ‖ enc(schema-version) ‖ enc(S)
                               ‖ enc(decimal(|L|)) ‖ enc(l₁) ‖ … ‖ enc(l_|L|) )

Scope labels are `TOTAL`, `MODULE:<module>` and `FAMILY:<fact-type>`. Domain separation between scopes means a
per-module digest can never be mistaken for, or replayed as, a total digest.

There is no separator anywhere in this construction. The count is carried explicitly, so a set of `k` renders and
any other set cannot coincide, and the empty set has a well-defined digest of its own.

## 3. Where it is implemented

Three independent implementations, no shared code, one specification:

| path | file | reached by |
|---|---|---|
| Common Lisp kernel | `KERNEL/model-law-kernel.lisp` (`enc`, `commitment-lines`) | `KERNEL-COMMITMENT.txt` |
| independent checker | `CHECKER/independent_check.py` (`enc`, `canonical_fact_render`, `commitment_lines`) | `CHECKER-COMMITMENT.txt` |
| reference | `SEXP-READER.py` (`enc`, `canonical_fact_render`, `canonical_digest`) | `gate_checks.py encoding` |

`gate_checks.py encoding` recomputes the whole commitment through the reference implementation and requires it to
equal the other two **byte for byte**. Agreement of three separately written implementations on one written
specification is what the commitment rests on.

## 4. What is falsified

* `X46-COMMITMENT-DELIMITER-COLLISION` — for adjacent-in-sort-order fields `k1 < k2` with `k1` a string, the model
  `{k1: "x|K2=y"}` must produce a different commitment from `{k1: "x", k2: "y"}` on all three implementations.
* `X47-ENCODING-VERSION-BINDING` — a schema declaring an encoding version no implementation implements must be a
  typed refusal, never a verdict.
* The property family `PF-ENC-INJECTIVITY` enumerates delimiters, backslashes, equals signs, Unicode, empty
  values and adjacent fields from the model itself.

## 5. What this does not establish

That two models with different meaning always differ here — only that two models with different **facts** always
differ here. Semantic equivalence is not addressed, and no cryptographic property beyond SHA-256's is claimed.
