;;;; TOOLCHAIN.sexp — pinned identities of the model-law kernel runtime and the independent checker.
;;;; AUTHORITATIVE pin = the ANSI Common Lisp implementation and the stock ASP solver named by (:version ...).
;;;; The (:local-executable-digest ...) values are per-container EVIDENCE only (installed binaries differ by host);
;;;; reproduce the toolchain with (:install ...). No third-party runtime dependency beyond these two stock tools.
(define-toolchain architecture-model-toolchain
  (:kernel-runtime
     (:name "SBCL" :kind ANSI-COMMON-LISP :version "SBCL 2.2.9.debian"
      :install "apt-get install -y sbcl"
      :invocation "sbcl --script ARCHITECTURE-MODEL/KERNEL/model-law-kernel.lisp <ROOT.sexp>"
      :local-executable "/usr/bin/sbcl" :local-executable-digest "2409c8befe0ca3d6309fcce4f820d8257ceff316a437b38115e228d9259f5670"))
  (:independent-checker
     (:name "clingo" :kind ANSWER-SET-PROGRAMMING :version "clingo 5.8.2"
      :rationale "stock declarative logic solver (Datalog/ASP family), no shared parsing or invariant code with the CL kernel"
      :install "pip install clingo==5.8.2"
      :invocation "python3 ARCHITECTURE-MODEL/CHECKER/independent_check.py <ROOT.sexp>"
      :local-module "/usr/local/lib/python3.11/dist-packages/clingo/_clingo.cpython-311-x86_64-linux-gnu.so" :local-module-digest "6ce9dd49177b81bcb5ae15a042de6c8f98368d880510484a68017e5220faec9f")))
