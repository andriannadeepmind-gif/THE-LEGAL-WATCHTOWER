;;;; rebuild-receipt-FROZEN-A.sexp — CLEAN REBUILD RECEIPT (ΠΑΡΑΓΟΜΕΝΟ)

(:lawmax-rebuild-receipt/1
 :label "frozen-a"
 :build-root "/var/build-root-A"
 :started-utc "2026-08-24T19:42:57Z" :finished-utc "2026-08-24T19:45:13Z" :seconds 136
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
 :oci-image-id "sha256:727db0b7a46f346ca09d7bbc189aa1eceabfa195238368f85c60bdcac4161088"
 :config-digest "sha256:66d7b14fcf9cc706e81b86652d83731651cfff70117838b383e3e0d36c8dfe6b"
 :rootfs-layers ("sha256:b9a65b3c65ab22d490085bd0bf5490e2409da8748b406870f2463bdc41cd6795" "sha256:76c0ad2c070980ca7443a3fb88042baecd0cac9eb601a0b36819bcc0f622ddb8" "sha256:9e673183054a3bf56c3a44962198e61ac2a36402bc0d1f60718ba3402bd7ef01" "sha256:27eb8f10e7f17b2054bc2abf23a8d1e3d7b19823926a9344c01e0b536e763c3c" "sha256:e1aba8351d03a349383ba7b682d4bddb2ba86d9e0bc40734166c2770b139a217" )
 :sbcl-version "SBCL 2.2.9.debian"
 :sbcl-core-sha256 ""
 :sbcl-executable-sha256 ""
 :asdf-version "3.3.1"
 :runtime-package-count 1
 :runtime-package-inventory-sha256 "d8eec3d40813202da097a4a2b938f1272ab3abcbc791d954121d44227fcb34d2"
 :apt-sbcl-in-runtime "ΑΠΩΝ"
 :build-log "rebuild-receipt-FROZEN-A.build.log")
