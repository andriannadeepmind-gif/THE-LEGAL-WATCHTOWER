;;;; rebuild-receipt-FROZEN-B.sexp — CLEAN REBUILD RECEIPT (ΠΑΡΑΓΟΜΕΝΟ)

(:lawmax-rebuild-receipt/1
 :label "frozen-b"
 :build-root "/var/build-root-B"
 :started-utc "2026-08-24T19:45:16Z" :finished-utc "2026-08-24T19:47:14Z" :seconds 118
 :docker-build-flags "--no-cache --network=none ${EXTRA_BUILD_FLAGS:-}"
 :build-exit-code 0
 :expected-artifact-count 175
 :expected-hash-provenance "experiment/runner/toolchain.manifest.sexp (sha256 3a35624e602c0c32ff17b37a98a62139996d16292f704c48a9c0ce230c38c3e8)"
 :toolchain-closure-sha256 "aa0deefce697721ff6015036b50f0e1e9a3026c91da5ba475d20ae8b74f8ca6b"
 :base-image "ubuntu@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517"
 :sbcl-source-sha256 "83d8b74f08d2254c59b9790bc1f669e09099457b884720ececbf45f4b46d1776"
 :sbcl-source-provenance "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.0/sbcl-2.4.0-source.tar.bz2 · ΧΩΡΙΣ ανεξάρτητη υπογραφή (δηλωμένο υπόλειμμα)"
 :bootstrap-sbcl "apt ubuntu noble 2:2.2.9-1ubuntu2 — ΕΡΓΑΛΕΙΟ στο στάδιο bootstrap, ΔΕΝ επιβιώνει"
 :dockerfile-sha256 "2a790de2e259358635891f9e9b43cfd081067710cf59e69172ae08d9ea01de14"
 :build-context-tree-sha256 "aab32b57195dccaa8d3b323f2bed646247c2d82fe7f5de7cd6d09c078eed4148"
 :oci-image-id "sha256:4b6a9ceb711450618321bbc226f7649beefaab57d900be97133428f6a5bf23bc"
 :config-digest "sha256:66d7b14fcf9cc706e81b86652d83731651cfff70117838b383e3e0d36c8dfe6b"
 :rootfs-layers ("sha256:b9a65b3c65ab22d490085bd0bf5490e2409da8748b406870f2463bdc41cd6795" "sha256:a967c51b8041b7f35f908237303cf642770e89e4d770684831924159b2af0c25" "sha256:8f684339b2ee777cf43f88d042c2dd0118f88deb8dc73e1e74d88fb1fac922e6" "sha256:2b804ff9595750d8111448601144f47d149a2df2ce8f082d3642300a657cc453" "sha256:b5208f2b4197dbf69cce29d6eb5eb4b4d8d2f25b5b098bdde2f942bc9d34e3c9" )
 :sbcl-version "SBCL 2.2.9.debian"
 :sbcl-core-sha256 ""
 :sbcl-executable-sha256 ""
 :asdf-version "3.3.1"
 :runtime-package-count 1
 :runtime-package-inventory-sha256 "d8eec3d40813202da097a4a2b938f1272ab3abcbc791d954121d44227fcb34d2"
 :apt-sbcl-in-runtime "ΑΠΩΝ"
 :build-log "rebuild-receipt-FROZEN-B.build.log")
