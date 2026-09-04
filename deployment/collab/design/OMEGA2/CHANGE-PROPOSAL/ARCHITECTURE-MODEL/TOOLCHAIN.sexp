;;;; TOOLCHAIN.sexp — pinned identities of every tool on the verification path.
;;;; Each tool is pinned on THREE SEPARATE AXES that are never conflated:
;;;;   (:semantic-requirement ...)  what the architecture actually requires — the conformance level a substitute
;;;;                                build must meet. A source-built conforming binary satisfies this axis.
;;;;   (:distribution-variant ...)  the package/build actually used in this environment. EVIDENCE, not a
;;;;                                requirement: ".debian", a pip wheel or a vendored tree are variants, and a
;;;;                                different variant of the same semantic version is conforming.
;;;;   (:execution-digest ...)      the concrete binary/module digest observed in this container. EVIDENCE only;
;;;;                                it differs per host and can never be a portable requirement.
;;;; Hashing on this model's paths has ONE definition: SHA-256 over exact raw bytes (files) and over the UTF-8
;;;; encoding (strings). Two independently vetted engines compute it — ironclad on the Common Lisp path and
;;;; hashlib/OpenSSL on the Python path — and the gate compares them over identical inputs.
(define-toolchain architecture-model-toolchain
  (:kernel-runtime
     (:name "SBCL" :kind ANSI-COMMON-LISP
      :semantic-requirement (:implementation "SBCL" :version "2.2.9" :conformance ANSI-COMMON-LISP)
      :distribution-variant (:package "sbcl" :build "SBCL 2.2.9.debian" :install "apt-get install -y sbcl")
      :execution-digest (:path "/usr/bin/sbcl"
                         :sha256 "2409c8befe0ca3d6309fcce4f820d8257ceff316a437b38115e228d9259f5670")
      :invocation "sbcl --script ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp <ROOT.sexp>"))
  (:independent-checker
     (:name "clingo" :kind ANSWER-SET-PROGRAMMING
      :semantic-requirement (:implementation "clingo" :version "5.8.2" :conformance ASP-CORE-2)
      :distribution-variant (:package "clingo" :build "clingo 5.8.2 (pip wheel, cpython-311)"
                             :install "pip install clingo==5.8.2")
      :execution-digest (:path "/usr/local/lib/python3.11/dist-packages/clingo/_clingo.cpython-311-x86_64-linux-gnu.so"
                         :sha256 "6ce9dd49177b81bcb5ae15a042de6c8f98368d880510484a68017e5220faec9f")
      :rationale "stock declarative logic solver (Datalog/ASP family); shares no parsing or invariant-evaluation code with the Common Lisp kernel"
      :invocation "python3 ARCHITECTURE-MODEL/CHECKER/independent_check.py <ROOT.sexp>"))
  (:hash-provider
     (:name "ironclad" :kind SHA-256-PROVIDER :path COMMON-LISP
      :semantic-requirement (:implementation "ironclad" :version "0.61" :conformance FIPS-180-4-SHA-256)
      :distribution-variant (:package "ironclad" :build "ironclad v0.61 vendored in-repo"
                             :install "already vendored: third-party/ironclad-v0.61 (ASDF source-registry tree)")
      :execution-digest (:path "third-party/ironclad-v0.61/src/digests/sha256.lisp"
                         :sha256 "94fefad71e8162e6bef4daac85ffca36ae160873e7c7d08628d5fd30268ffc81")
      :source-registry-tree "third-party/"
      :system-name "ironclad"
      :self-test "FIPS 180-4 SHA-256 known-answer vectors (empty, abc, 448-bit, 1e6 x 'a') verified in-process before any model hash is computed; failure aborts with exit code 4"
      :decision "DELIBERATE DEPENDENCY: a vetted maintained provider replaces the former in-repo SHA-256. Kernel smallness does not override cryptographic assurance; there is no fallback implementation."))
  (:checker-hash-provider
     (:name "python-hashlib" :kind SHA-256-PROVIDER :path PYTHON
      :semantic-requirement (:implementation "hashlib" :version "OpenSSL 3.0.13" :conformance FIPS-180-4-SHA-256)
      :distribution-variant (:package "python3" :build "CPython 3.11.15 / OpenSSL 3.0.13 30 Jan 2024"
                             :install "python3 standard library (OpenSSL-backed)")
      :execution-digest (:path "python3 -c \"import ssl; print(ssl.OPENSSL_VERSION)\"" :sha256 NOT-A-FILE)
      :self-test "the same FIPS 180-4 known-answer vectors are verified in-process by the independent checker before any model hash is computed"
      :decision "second independently vetted engine; the gate requires both engines to agree on identical raw-byte inputs")))
