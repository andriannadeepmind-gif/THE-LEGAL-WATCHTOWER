#!/usr/bin/env bash
# SETUP-TOOLCHAIN — prepare the tools the architecture-model gate needs, in a clean clone, with no undocumented
# step. Every identity here is pinned in TOOLCHAIN.sexp on three separate axes (semantic requirement /
# distribution variant / execution digest); this script installs a variant that satisfies the semantic
# requirement. It never installs a hash implementation: the SHA-256 provider is vendored in-repo.
set -e
cd "$(dirname "$0")"
REPO=$(cd ../../../../../.. && pwd)

# 1. the ANSI Common Lisp implementation that runs the model-law kernel
command -v sbcl >/dev/null 2>&1 || apt-get install -y --no-install-recommends sbcl

# 2. the stock ASP solver that is the independent second verification path
python3 -c 'import clingo' 2>/dev/null || pip install clingo==5.8.2

# 3. the vetted SHA-256 provider for the Common Lisp path. It is VENDORED (third-party/ironclad-v0.61) and needs
#    no download; this step only pre-compiles it into the ASDF cache so the first kernel run is not paying a
#    one-off build. Skipping this step changes nothing but the wall-clock of the first run — never the result.
sbcl --script /dev/stdin <<LISP
(require :asdf)
(asdf:initialize-source-registry
  (list :source-registry (list :tree (merge-pathnames "third-party/" #p"$REPO/")) :inherit-configuration))
(handler-bind ((warning #'muffle-warning)) (asdf:load-system "ironclad"))
(format t "ironclad precompiled~%")
LISP

echo "toolchain ready: $(sbcl --version) + clingo $(python3 -c 'import clingo;print(clingo.__version__)') \
+ ironclad v0.61 (vendored) + hashlib/$(python3 -c 'import ssl;print(ssl.OPENSSL_VERSION)')"
