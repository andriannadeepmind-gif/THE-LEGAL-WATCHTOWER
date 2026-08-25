#!/usr/bin/env bash
# =============================================================================
# ΑΝΕΞΑΡΤΗΤΟ CLEAN REBUILD + ΑΠΟΔΕΙΞΗ (receipt)
# =============================================================================
# Ένα επιτυχές build ΔΕΝ είναι απόδειξη αναπαραγωγιμότητας. Αυτό το script
# χτίζει από ΚΑΘΑΡΗ ρίζα, ΧΩΡΙΣ cache, ΧΩΡΙΣ δίκτυο, και καταγράφει ΚΑΘΕ πεδίο
# που επιτρέπει σε τρίτον να συγκρίνει δύο εκτελέσεις byte προς byte.
#   rebuild-receipt.sh <build-root> <label> <out.sexp>
set -uo pipefail
ROOT="${1:?build-root}"; LABEL="${2:?label}"; OUT="${3:?out.sexp}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO/experiment/runner/toolchain.manifest.sexp"
DOCKERFILE="$REPO/experiment/runner/Dockerfile.runner"
TAG="lawmax-runner:$LABEL"
t0=$(date -u +%s)

python3 "$REPO/experiment/runner/verify-toolchain.py" "$MANIFEST" "$ROOT" || exit 2

docker build --no-cache --network=none ${EXTRA_BUILD_FLAGS:-} -f "$DOCKERFILE" -t "$TAG" "$ROOT" \
  > "${OUT%.sexp}.build.log" 2>&1
BUILD_RC=$?
t1=$(date -u +%s)

j(){ docker image inspect "$TAG" --format "$1" 2>/dev/null; }
IMAGE_ID="$(j '{{.Id}}')"
CONFIG_D="$(docker image inspect "$TAG" --format '{{json .Config}}' 2>/dev/null | sha256sum | cut -d' ' -f1)"
LAYERS="$(docker image inspect "$TAG" --format '{{range .RootFS.Layers}}{{println .}}{{end}}' 2>/dev/null)"

if [ "$BUILD_RC" -eq 0 ]; then
  IN="docker run --rm --entrypoint /bin/bash $TAG -c"
  SBCL_V="$($IN 'sbcl --version' 2>/dev/null)"
  CORE_H="$($IN 'sha256sum $SBCL_HOME/sbcl.core | cut -d" " -f1' 2>/dev/null)"
  EXE_H="$($IN 'sha256sum /opt/sbcl/bin/sbcl | cut -d" " -f1' 2>/dev/null)"
  ASDF_V="$($IN 'sbcl --noinform --non-interactive --eval "(require :asdf)" --eval "(format t \"~a\" (asdf:asdf-version))" --quit' 2>/dev/null | tail -1)"
  FEATURES="$($IN 'sbcl --noinform --non-interactive --eval "(format t \"~{~a ~}\" (sort (mapcar #\"'"'"'\" (list)) (function string<)))" --quit' 2>/dev/null | tail -1)"
  PKGS="$($IN 'dpkg-query -W -f=\"\${Package}=\${Version}\n\" | sort' 2>/dev/null)"
  PKG_N="$(printf '%s\n' "$PKGS" | grep -c . )"
  PKG_H="$(printf '%s\n' "$PKGS" | sha256sum | cut -d' ' -f1)"
  APT_SBCL="$($IN 'dpkg-query -W -f="${Status}" sbcl 2>/dev/null || echo ΑΠΩΝ' 2>/dev/null)"
else
  SBCL_V=NOT-EXECUTED; CORE_H=NOT-EXECUTED; EXE_H=NOT-EXECUTED
  ASDF_V=NOT-EXECUTED; PKGS=""; PKG_N=0; PKG_H=NOT-EXECUTED; APT_SBCL=NOT-EXECUTED
fi

SRC_SHA="$(grep -A2 ':name "sbcl-2.4.0-source' "$MANIFEST" | grep -o ':sha256 "[0-9a-f]\{64\}"' | cut -d'"' -f2)"
BASE="$(grep -o ':base-image "[^"]*"' "$MANIFEST" | cut -d'"' -f2)"
CLOSURE="$(grep -o ':closure-sha256 "[0-9a-f]\{64\}"' "$MANIFEST" | cut -d'"' -f2)"
N_ART="$(grep -c ':sha256 "[0-9a-f]\{64\}"' "$MANIFEST")"

{
printf ';;;; %s — CLEAN REBUILD RECEIPT (ΠΑΡΑΓΟΜΕΝΟ)\n\n' "$(basename "$OUT")"
printf '(:lawmax-rebuild-receipt/1\n'
printf ' :label "%s"\n :build-root "%s"\n' "$LABEL" "$ROOT"
printf ' :started-utc "%s" :finished-utc "%s" :seconds %s\n' \
       "$(date -u -d @$t0 +%Y-%m-%dT%H:%M:%SZ)" "$(date -u -d @$t1 +%Y-%m-%dT%H:%M:%SZ)" "$((t1-t0))"
printf ' :docker-build-flags "--no-cache --network=none ${EXTRA_BUILD_FLAGS:-}"\n'
printf ' :build-exit-code %s\n' "$BUILD_RC"
printf ' :expected-artifact-count %s\n' "$N_ART"
printf ' :expected-hash-provenance "experiment/runner/toolchain.manifest.sexp (sha256 %s)"\n' \
       "$(sha256sum "$MANIFEST" | cut -d' ' -f1)"
printf ' :toolchain-closure-sha256 "%s"\n' "$CLOSURE"
printf ' :base-image "%s"\n' "$BASE"
printf ' :sbcl-source-sha256 "%s"\n' "$SRC_SHA"
printf ' :sbcl-source-provenance "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.0/sbcl-2.4.0-source.tar.bz2 · ΧΩΡΙΣ ανεξάρτητη υπογραφή (δηλωμένο υπόλειμμα)"\n'
printf ' :bootstrap-sbcl "apt ubuntu noble 2:2.2.9-1ubuntu2 — ΕΡΓΑΛΕΙΟ στο στάδιο bootstrap, ΔΕΝ επιβιώνει"\n'
printf ' :dockerfile-sha256 "%s"\n' "$(sha256sum "$DOCKERFILE" | cut -d' ' -f1)"
printf ' :build-context-tree-sha256 "%s"\n' \
       "$(cd "$ROOT" && find . -type f ! -path './debs-raw/*' ! -path './build-debs-raw/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)"
printf ' :oci-image-id "%s"\n' "$IMAGE_ID"
printf ' :config-digest "sha256:%s"\n' "$CONFIG_D"
printf ' :rootfs-layers ('
printf '%s' "$LAYERS" | while read -r l; do [ -n "$l" ] && printf '"%s" ' "$l"; done
printf ')\n'
printf ' :sbcl-version "%s"\n' "$SBCL_V"
printf ' :sbcl-core-sha256 "%s"\n' "$CORE_H"
printf ' :sbcl-executable-sha256 "%s"\n' "$EXE_H"
printf ' :asdf-version "%s"\n' "$ASDF_V"
printf ' :runtime-package-count %s\n :runtime-package-inventory-sha256 "%s"\n' "$PKG_N" "$PKG_H"
printf ' :apt-sbcl-in-runtime "%s"\n' "$APT_SBCL"
printf ' :build-log "%s")\n' "$(basename "${OUT%.sexp}.build.log")"
} > "$OUT"

echo "receipt: $OUT (build exit=$BUILD_RC)"
exit $BUILD_RC
