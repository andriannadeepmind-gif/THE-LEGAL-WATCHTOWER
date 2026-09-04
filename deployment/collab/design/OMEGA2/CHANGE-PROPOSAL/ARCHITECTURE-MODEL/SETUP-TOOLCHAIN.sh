#!/usr/bin/env bash
# SETUP-TOOLCHAIN — install the two pinned stock tools the architecture-model gate needs (documented step for a
# clean-clone reproduction). No third-party runtime dependency beyond these. Versions pinned in TOOLCHAIN.sexp.
set -e
command -v sbcl >/dev/null 2>&1 || apt-get install -y --no-install-recommends sbcl
python3 -c 'import clingo' 2>/dev/null || pip install clingo==5.8.2
echo "toolchain ready: $(sbcl --version) + clingo $(python3 -c 'import clingo;print(clingo.__version__)')"
