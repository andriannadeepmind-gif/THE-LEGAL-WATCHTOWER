#!/usr/bin/env bash
# ============================================================================
# Phase-0 census — trusted/untrusted plane separation ([0094]).
# Deterministic, reproducible enumeration of EVERY code-execution / egress /
# deserialization construct in FIRST-PARTY lisp. The non-LLM enumeration oracle.
# Third-party vendored deps are enumerated separately (count only) — they run in
# the trusted image process but never on the untrusted corpus-data path.
# Usage: bash deployment/verify/census-execution-constructs.sh [repo-root]
# ============================================================================
set -euo pipefail
ROOT="${1:-.}"
cd "$ROOT"

# Whole first-party surface (Κ-6: no systems/source-only seam).
FP=(source systems docker deployment tests scripts determinism build.lisp entrypoint.lisp)
rgfp() { rg --no-heading -n "$@" "${FP[@]}" 2>/dev/null | rg -v '\.md:' || true; }
sec() { printf '\n============================================================\n%s\n============================================================\n' "$1"; }

sec "A. SEXP READERS (interpret s-expressions — eval vector via #.)"
rgfp -e '\(read(-from-string|-preserving-whitespace|-delimited-list)?[[:space:]]'

sec "B. eval"
rgfp -e '\(eval[[:space:]]'

sec "C. load / compile / compile-file (code loading)"
rgfp -e '\((load|compile|compile-file)[[:space:]]'

sec "D. READER-MACRO / READTABLE machinery"
rgfp -e '(set-macro-character|set-dispatch-macro-character|make-dispatch-macro-character|set-syntax-from-char|copy-readtable|named-readtables|in-readtable|\*readtable\*)'

sec "E. with-standard-io-syntax (REBINDS *read-eval* to T — footgun around reads)"
rgfp -e 'with-standard-io-syntax'

sec "F. DYNAMIC SYMBOL RESOLUTION → callable (indirect eval wrappers)"
rgfp -e '(funcall[[:space:]]+\(?(find-symbol|intern)|symbol-function|fdefinition|\(coerce[[:space:]].*(quote function|'"'"'function))'

sec "G. OS PROCESS EXECUTION (shell / external binaries)"
rgfp -e '\((uiop:run-program|uiop:launch-program|sb-ext:run-program|run-fetch-command)\b'

sec "H. NETWORK EGRESS (http client / sockets)"
rgfp -e '(dexador|dex:|drakma|usocket|sb-bsd-sockets|socket-connect|http-get|http-fetch|url-fetch)'

sec "I. *read-eval* bindings present (correlate with A)"
rgfp -e '\*read-eval\*'

sec "J. COUNTS (first-party)"
for label in \
  'sexp-readers:\(read(-from-string|-preserving-whitespace|-delimited-list)?[[:space:]]' \
  'eval:\(eval[[:space:]]' \
  'load/compile:\((load|compile|compile-file)[[:space:]]' \
  'reader-macro:(set-macro-character|set-dispatch-macro-character|make-dispatch-macro-character|set-syntax-from-char)' \
  'with-std-io:with-standard-io-syntax' \
  'os-exec:\((uiop:run-program|uiop:launch-program|sb-ext:run-program)\b' \
  'read-eval-binds:\*read-eval\*' ; do
  name="${label%%:*}"; pat="${label#*:}"
  printf '%-22s %s\n' "$name" "$(rgfp -e "$pat" | wc -l)"
done

sec "K. THIRD-PARTY in-image readers/eval (declared separately, out of migration scope)"
printf 'third-party sexp-reader/eval hits (count only): %s\n' \
  "$(rg --no-heading -n -e '\((read|read-from-string|eval|load)[[:space:]]' third-party 2>/dev/null | wc -l)"
