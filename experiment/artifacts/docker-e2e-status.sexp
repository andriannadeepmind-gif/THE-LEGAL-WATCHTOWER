;;;; experiment/artifacts/docker-e2e-status.sexp
(:lawmax-docker-e2e-status/1
 :verdict "PRODUCTION-EQUIVALENT-DOCKER-E2E: BLOCKED"
 :command "bash authority-v2/proofs/docker-e2e-test.sh"
 :exit-code 1
 :ran-at "2026-08-24T12:0x UTC"
 :daemon-present t :compose-present t
 :pinned-base-image-present-locally t
 :pinned-base-digest "debian@sha256:17122fe3d66916e55c0cbd5bbf54bb3f87b3582f4d86a755a0fd3498d360f91b"
 :failing-stage "Dockerfile RUN apt-get update && apt-get install (stages deps-verify/builder/runtime)"
 :root-cause "ΠΟΛΙΤΙΚΗ ΔΙΚΤΥΟΥ: deb.debian.org 403, security.debian.org 403 (και 6 mirrors: ftp.debian.org, cdn-aws, osuosl, ftp.us, mirrors.kernel.org — όλα 403)"
 :not-attempted
  ("ΔΕΝ αντικαταστάθηκε το base με Ubuntu ή άλλη μη-καρφωμένη Debian"
   "ΔΕΝ τροποποιήθηκε το Dockerfile ούτε το docker-compose.yml"
   "ΔΕΝ δηλώνεται κανένα ισοδύναμο· το Ubuntu image του evaluator είναι AUXILIARY-PROOF-TOOLCHAIN και ΤΙΠΟΤΑ άλλο")
 :unblock-condition "allowlist του deb.debian.org (+security.debian.org) στην πολιτική δικτύου του περιβάλλοντος· καμία αλλαγή κώδικα δεν απαιτείται"
 :independent-gates-continued t)
