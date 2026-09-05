#!/usr/bin/env bash
# SETUP-TOOLCHAIN — bring a clean host to the state ARCHITECTURE-MODEL-GATE.sh requires, with no undocumented
# step, and — separately — say whether a host is already in that state.
#
# REVIEW-2 N-20. The superseded script did three incompatible things at once: it stated no supported base
# environment, it silently required root and network access (`apt-get install`, `pip install`) with no way to
# ask what was missing without attempting to change the machine, and it ended by echoing self-reported version
# strings as if they were evidence. It also pre-compiled a vendored ironclad ASDF closure that the corrected
# Common Lisp path no longer uses at all (Review-2 N-1: the SHA-256 provider is now the pinned external digest
# program declared in TOOLCHAIN.sexp).
#
# SUPPORTED BASE ENVIRONMENT — the one environment for which TOOLCHAIN.sexp carries executable digests:
#     Ubuntu 24.04 LTS, x86-64
#     sbcl        2:2.2.9-1ubuntu2       (universe pocket)
#     coreutils   9.4                    (base image)
#     CPython     3.11.15                at /usr/local/bin/python3
#     clingo      5.8.2                  (pip wheel, cpython-311, manylinux2014 x86-64)
# On any other host the gate stops with a typed TOOLCHAIN-IDENTITY-MISMATCH. That is the intended behaviour:
# re-pinning for a different environment is an explicit, reviewable edit of TOOLCHAIN.sexp, never an automatic
# accommodation, and this script will not perform one.
#
# TWO MODES, NEVER MIXED:
#   --verify     (default)  Reads the machine. Changes NOTHING. Needs no privilege and no network. Prints one
#                           typed line per declared tool and exits 0 only if every prerequisite is present.
#   --provision             Changes the machine. REQUIRES root and network access, and says so before acting.
#                           It installs prerequisites only; it issues no verdict about identity — run --verify
#                           afterwards for that, so that provisioning can never be mistaken for verification.
#
# TYPED OUTCOMES (one per line, machine-readable first token):
#   READY <tool>                     present at its declared path
#   MISSING_PREREQUISITE <tool>      absent; the line names what to install and which mode installs it
#   UNPROVISIONABLE <tool>           absent and this script has no recipe for it — a human decision, not a retry
# Identity is NOT judged here. `gate_checks.py toolchain` is the one seat that compares executable digests, and
# it does so against the model rather than against anything this script prints.
set -uo pipefail
cd "$(dirname "$0")"

MODE="${1:---verify}"
case "$MODE" in
  --verify|--provision) ;;
  *) echo "usage: SETUP-TOOLCHAIN.sh [--verify|--provision]" >&2; exit 2 ;;
esac

# The tools, their roles and their declared paths come from the MODEL, so this script cannot drift from the
# pins. Only the mapping from a declared tool to an OS provisioning recipe lives here, because how a host
# obtains a package is a property of the host, not of the architecture model.
declare_tools() {
  python3 - <<'PY'
import importlib.util, os
spec = importlib.util.spec_from_file_location('sr', 'SEXP-READER.py')
SR = importlib.util.module_from_spec(spec); spec.loader.exec_module(SR)
for f in SR.read_forms_file('TOOLCHAIN.sexp'):
    if SR.head(f) == 'fact' and str(f[1]) == 'tool':
        print('%s\t%s\t%s\t%s' % (SR.canonical_value(f[2], 'TOOLCHAIN.sexp', 'id'),
                                  SR.kv(f, 'role'), SR.kv(f, 'path'), SR.kv(f, 'semantic-version')))
PY
}

recipe_for() {           # tool-id -> the exact command that provisions it, or empty when there is none
  case "$1" in
    SBCL)          echo "apt-get install -y --no-install-recommends sbcl" ;;
    CLINGO)        echo "python3 -m pip install --no-input clingo==$2" ;;
    DIGEST-PROGRAM) echo "apt-get install -y --no-install-recommends coreutils" ;;
    *)             echo "" ;;
  esac
}

TOOLS="$(declare_tools)" || { echo "MISSING_PREREQUISITE TOOLCHAIN.sexp — the model's tool facts are unreadable" >&2; exit 3; }

if [ "$MODE" = "--provision" ]; then
  echo "PROVISIONING — this mode CHANGES THIS MACHINE."
  echo "  privilege assumed: root (package installation)"
  echo "  network assumed:   yes (distribution archive and the Python package index)"
  [ "$(id -u)" = "0" ] || { echo "MISSING_PREREQUISITE root — re-run --provision as root"; exit 4; }
  rc=0
  while IFS=$'\t' read -r id role path version; do
    [ -n "$id" ] || continue
    if [ -e "$path" ]; then echo "READY $id ($path already present)"; continue; fi
    cmd="$(recipe_for "$id" "$version")"
    if [ -z "$cmd" ]; then
      echo "UNPROVISIONABLE $id — no recipe; $path must be provided by the base image ($version)"; rc=5; continue
    fi
    echo "PROVISIONING $id: $cmd"
    if ! sh -c "$cmd"; then echo "MISSING_PREREQUISITE $id — provisioning command failed"; rc=5; fi
  done <<< "$TOOLS"
  echo "PROVISIONING COMPLETE — this mode issues NO verdict. Run './SETUP-TOOLCHAIN.sh --verify' and then"
  echo "'python3 gate_checks.py toolchain', which is the only seat that judges executable identity."
  exit $rc
fi

# --verify: read-only, unprivileged, offline
rc=0
while IFS=$'\t' read -r id role path version; do
  [ -n "$id" ] || continue
  if [ -e "$path" ]; then
    echo "READY $id $role $path (required semantic version $version)"
  else
    cmd="$(recipe_for "$id" "$version")"
    if [ -n "$cmd" ]; then
      echo "MISSING_PREREQUISITE $id $role $path — install with: ./SETUP-TOOLCHAIN.sh --provision ($cmd)"
    else
      echo "UNPROVISIONABLE $id $role $path — must be provided by the supported base image; this script has no recipe"
    fi
    rc=1
  fi
done <<< "$TOOLS"

if [ $rc -eq 0 ]; then
  echo "ALL_PREREQUISITES_PRESENT — every declared tool exists at its declared path. This is a PRESENCE result"
  echo "only: executable identity is judged by 'python3 gate_checks.py toolchain' against TOOLCHAIN.sexp, which"
  echo "compares digests and refuses a self-reported version string as evidence."
else
  echo "PREREQUISITES_INCOMPLETE — the gate will not run. Nothing was changed by this mode."
fi
exit $rc
