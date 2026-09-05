;;;; TOOLCHAIN.sexp — the pinned identity of every tool on either verification path, AS MODEL FACTS.
;;;;
;;;; REVIEW-2 N-11. Before this pass the toolchain was a bespoke `(define-toolchain ...)` form whose
;;;; `:execution-digest` values were read by NO executable: a shim reporting "SBCL 9.9.9.evil" passed, a clingo
;;;; whose __version__ said "0.0.1-EVIL" passed, and rewriting the declared requirement to 9.9.9 passed while the
;;;; kernel printed the fabricated version back as its own evidence. Pins that nothing reads are documentation.
;;;; They are now ordinary `tool` facts: schema-validated, hash-pinned inside ROOT.sexp, and ENFORCED by
;;;; `gate_checks.py toolchain` before either verifier is allowed to run.
;;;;
;;;; :verified-by is the anti-self-certification rule. No tool proves its own identity: the digest program that
;;;; the Common Lisp path depends on is measured by the Python path's engine, the Python runtime and the ASP
;;;; solver are measured by the digest program, and the SBCL binary is measured by both. A tool whose declared
;;;; verifier is the tool itself would be rejected by the schema's `verifier` enum having no such value.
;;;;
;;;; :sha256 is the exact executable identity on the DECLARED SUPPORTED BASE ENVIRONMENT (see
;;;; SETUP-TOOLCHAIN.sh, Review-2 N-20): Ubuntu 24.04 LTS x86-64, sbcl 2:2.2.9-1ubuntu2 from the Ubuntu
;;;; universe pocket, coreutils 9.4, CPython 3.11 and clingo 5.8.2 from the pinned wheel. On any other host the
;;;; gate stops with a typed TOOLCHAIN-IDENTITY-MISMATCH naming the tool, the observed digest and the pinned
;;;; one; it never silently downgrades to trusting a self-reported version string. Re-pinning for another
;;;; supported environment is an explicit, reviewable edit of these facts — never an automatic accommodation.
;;;;
;;;; There is exactly ONE hashing definition on every path of this model:
;;;;   hash(file)   = SHA-256 over the exact raw bytes;  hash(string) = SHA-256 over the UTF-8 encoding.
;;;; Two independently vetted engines compute it — GNU coreutils sha256sum on the Common Lisp path and
;;;; hashlib/OpenSSL on the Python path — and the gate requires them to agree over identical inputs, including
;;;; CRLF, a lone CR, a UTF-8 BOM and bytes that are not valid UTF-8 at all.

(fact tool SBCL
      :role KERNEL_RUNTIME
      :name "SBCL"
      :semantic-version "2.2.9"
      :variant "SBCL 2.2.9.debian (Ubuntu 24.04 universe, sbcl 2:2.2.9-1ubuntu2)"
      :path "/usr/bin/sbcl"
      :sha256 "2409c8befe0ca3d6309fcce4f820d8257ceff316a437b38115e228d9259f5670"
      :verified-by CHECKER_PATH
      :note "ANSI Common Lisp implementation that runs KERNEL/model-law-kernel.lisp. It is the irreducible bootstrap anchor of the Common Lisp path and is therefore measured by the OTHER path, never by itself.")

(fact tool DIGEST-PROGRAM
      :role DIGEST_PROVIDER
      :name "sha256sum"
      :semantic-version "9.4"
      :variant "sha256sum (GNU coreutils) 9.4"
      :path "/usr/bin/sha256sum"
      :sha256 "e484c36c0613879fbd11058f7a2e194783bced59d4805d64c3d4b0d7f664094d"
      :verified-by CHECKER_PATH
      :note "The ONLY SHA-256 provider of the Common Lisp path (Review-2 N-1). It replaces the former vendored ironclad ASDF closure: 276 tracked files (129 Lisp sources) reached through an ASDF source registry rooted at the whole 3,307-file `third-party/` tree, not one of which was pinned by any executable check. It is a separate implementation lineage from the Python path's OpenSSL engine, so agreement between the two is real cross-engine evidence rather than one engine agreeing with itself.")

(fact tool CPYTHON
      :role CHECKER_RUNTIME
      :name "CPython"
      :semantic-version "3.11.15"
      :variant "CPython 3.11.15 (GCC 13.3.0)"
      :path "/usr/local/bin/python3"
      :sha256 "f56a588548dd013906ae1dcd1b6faa417f4e204da634ff354840d9643e78ff9e"
      :verified-by KERNEL_PATH
      :note "Runtime of the independent checker, the generators and the gate checks. Measured by the Common Lisp path's digest program.")

(fact tool CLINGO
      :role ASP_SOLVER
      :name "clingo"
      :semantic-version "5.8.2"
      :variant "clingo 5.8.2 (pip wheel, cpython-311, manylinux2014 x86-64)"
      :path "/usr/local/lib/python3.11/dist-packages/clingo/_clingo.cpython-311-x86_64-linux-gnu.so"
      :sha256 "6ce9dd49177b81bcb5ae15a042de6c8f98368d880510484a68017e5220faec9f"
      :verified-by KERNEL_PATH
      :note "Stock declarative ASP solver; the compiled extension module is the real executable identity, so that is what is pinned rather than the Python wrapper. Shares no parsing or invariant-evaluation code with the Common Lisp kernel.")

(fact tool OPENSSL-HASH
      :role CHECKER_DIGEST_PROVIDER
      :name "hashlib/OpenSSL"
      :semantic-version "3.0.13"
      :variant "OpenSSL 3.0.13 30 Jan 2024, via CPython hashlib"
      :path "/usr/local/bin/python3"
      :sha256 "f56a588548dd013906ae1dcd1b6faa417f4e204da634ff354840d9643e78ff9e"
      :verified-by KERNEL_PATH
      :note "Second independently vetted SHA-256 engine. It is reached through the CPython binary, so its executable identity is that binary's; the OpenSSL semantic version is checked separately at run time and both engines must agree on every adversarial byte case.")
