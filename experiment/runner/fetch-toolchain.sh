#!/usr/bin/env bash
# =============================================================================
# ΣΤΑΔΙΟ BOOTSTRAP — Η ΜΟΝΗ ΘΕΣΗ ΟΠΟΥ ΕΠΙΤΡΕΠΕΤΑΙ ΔΙΚΤΥΟ
# =============================================================================
# Αποκτά ΜΙΑ ΦΟΡΑ τα bytes που δηλώνει το toolchain manifest και τα βάζει
# content-addressed στο store. Κάθε byte επαληθεύεται με το sha256 του
# manifest ΠΡΙΝ γίνει δεκτό. Αναντιστοιχία ⇒ ΑΠΟΡΡΙΨΗ, όχι προειδοποίηση.
#
# Μετά από αυτό, το `build-runner.sh` τρέχει με --network=none. Το δίκτυο ΔΕΝ
# είναι μόνιμη εξάρτηση της κατασκευής· είναι εφάπαξ προμήθεια.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${LAWMAX_RUNNER_CACHE:-/var/cache/lawmax-runner}"
MANIFEST="$REPO/experiment/runner/toolchain.manifest.sexp"
[ -f "$MANIFEST" ] || { echo "::error::λείπει το manifest"; exit 2; }

mkdir -p "$CACHE/debs" "$CACHE/build-debs" "$CACHE/src"

# ── ① base image ΜΕ DIGEST (content-addressed· ο mirror δεν μπορεί να νοθεύσει) ──
BASE="$(grep -o ':base-image "[^"]*"' "$MANIFEST" | cut -d'"' -f2)"
echo "▶ base image: $BASE"
docker pull "$BASE" >/dev/null

# ── ② κάθε artifact: κατέβασμα ΜΟΝΟ αν λείπει, αποδοχή ΜΟΝΟ αν το sha256 δένει ──
ok=0; failed=0
while IFS=$'\t' read -r store sha url; do
  dest="$CACHE/$store/$sha.deb"; [ "$store" = "src" ] && dest="$CACHE/src/$(basename "${url%%\?*}")"
  if [ -f "$dest" ] && [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$sha" ]; then
    ok=$((ok+1)); continue
  fi
  tmp="$(mktemp)"
  if ! curl -sSL --max-time 900 -o "$tmp" "$url"; then
    echo "  ΑΠΕΤΥΧΕ ΛΗΨΗ  $url"; rm -f "$tmp"; failed=$((failed+1)); continue
  fi
  got="$(sha256sum "$tmp" | cut -d' ' -f1)"
  if [ "$got" != "$sha" ]; then
    echo "  ΑΝΑΝΤΙΣΤΟΙΧΙΑ $url"; echo "    αναμ. $sha"; echo "    ελήφθη $got"
    rm -f "$tmp"; failed=$((failed+1)); continue
  fi
  mv "$tmp" "$dest"; ok=$((ok+1))
done < <(python3 - "$MANIFEST" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
def section(name):
    i = text.find(f":{name}\n")
    if i < 0: return ""
    j = text.find("\n :", i + 1)
    return text[i:j if j > 0 else len(text)]
for sec, store in (("runtime-packages","debs"), ("build-packages","build-debs"),
                   ("source-artifacts","src")):
    body = section(sec)
    for sha, url in zip(re.findall(r':sha256 "([0-9a-f]{64})"', body),
                        re.findall(r':url "([^"]+)"', body)):
        print(f"{store}\t{sha}\t{url}")
PY
)

echo "bootstrap: $ok επαληθευμένα · $failed απέτυχαν"
[ "$failed" -eq 0 ] || { echo "::error::η προμήθεια ΔΕΝ ολοκληρώθηκε — καμία μερική toolchain"; exit 1; }
python3 "$REPO/experiment/runner/verify-toolchain.py" "$MANIFEST" "$CACHE"
