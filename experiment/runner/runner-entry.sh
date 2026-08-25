#!/bin/bash
# =============================================================================
# ΕΙΣΟΔΟΣ ΤΟΥ RUNNER — το corpus είναι ΦΥΣΙΚΑ ΑΜΕΤΑΒΛΗΤΟ
# =============================================================================
# ΔΟΜΙΚΗ ΛΥΣΗ, ΟΧΙ ΦΡΟΥΡΟΣ: το εξεταζόμενο δέντρο προσαρτάται read-only στο
# /corpus και ΠΑΝΩ του στήνεται overlayfs με merged=/app. Κάθε εγγραφή —
# FASL, __pycache__, lock, ό,τι γράψει οποιαδήποτε σουίτα — προσγειώνεται
# ΑΝΑΓΚΑΣΤΙΚΑ στο /work/upper. Το corpus δεν μπορεί να μεταβληθεί ακόμη κι αν
# μια σουίτα το επιχειρήσει· και το σύνολο των εγγραφών γίνεται ΜΕΤΡΗΣΙΜΟ
# δεδομένο (απογραφή του /work/upper), όχι θόρυβος.
#
# ΤΟ /app ΕΙΝΑΙ ΥΠΟΧΡΕΩΤΙΚΟ: ο runner του corpus (docker/run-standalone-test.lisp)
# έχει καρφωμένα /app/... μονοπάτια. Τα σεβόμαστε αντί να τα αλλάξουμε — το
# corpus είναι τεκμήριο.
set -euo pipefail

[ -d /corpus ] || { echo "::error::ΚΕΝΟ /corpus — δεν προσαρτήθηκε το παγωμένο δέντρο"; exit 2; }

mkdir -p /work/upper /work/ovlwork /work/fasl /work/pycache /work/tmp /app
mount -t overlay overlay -o lowerdir=/corpus,upperdir=/work/upper,workdir=/work/ovlwork /app \
  || { echo "::error::overlayfs ΑΠΕΤΥΧΕ — χωρίς αυτό το corpus ΔΕΝ είναι αμετάβλητο· ΔΕΝ συνεχίζω"; exit 2; }

cd /app
exec "$@"
