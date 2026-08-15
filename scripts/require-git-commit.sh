#!/usr/bin/env bash
# ΜΙΑ έδρα μεταφοράς source identity πριν από Docker/Compose proof builds.
# Εκτυπώνει μόνο το επαληθευμένο 40-hex HEAD. Κενό/default/άλλο commit ⇒ failure.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUPPLIED="${1:-${GIT_COMMIT:-}}"

if [[ ! "$SUPPLIED" =~ ^[0-9a-f]{40}$ ]]; then
  echo "::error::GIT_COMMIT πρέπει να είναι ακριβώς 40 lowercase hex χαρακτήρες (δόθηκε: '${SUPPLIED:-<empty>}')" >&2
  exit 1
fi

ACTUAL="$(git -C "$REPO" rev-parse --verify 'HEAD^{commit}')" || {
  echo "::error::αδυναμία επίλυσης του checkout HEAD σε commit" >&2
  exit 1
}
if [[ ! "$ACTUAL" =~ ^[0-9a-f]{40}$ ]]; then
  echo "::error::το checkout HEAD δεν είναι 40-hex SHA-1: '$ACTUAL'" >&2
  exit 1
fi
if [ "$SUPPLIED" != "$ACTUAL" ]; then
  echo "::error::GIT_COMMIT mismatch: supplied=$SUPPLIED checkout=$ACTUAL" >&2
  exit 1
fi

printf '%s\n' "$ACTUAL"
