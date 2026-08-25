;;;; rebuild-receipt-A.sexp — CLEAN REBUILD RECEIPT (ΠΑΡΑΓΟΜΕΝΟ)

(:lawmax-rebuild-receipt/1
 :label "rebuild-a"
 :build-root "/var/build-root-A"
 :started-utc "2026-08-24T11:37:14Z" :finished-utc "2026-08-24T11:41:54Z" :seconds 280
 :docker-build-flags "--no-cache --network=none"
 :build-exit-code 0
 :expected-artifact-count 82
 :expected-hash-provenance "experiment/runner/toolchain.manifest.sexp (sha256 f126b5e463cd21820d4373905468f59b112f719879ebf0e8282b2ef8784e038d)"
 :toolchain-closure-sha256 "ea3dc6ad04fbed6238f5fe4d258f82f71ad1a545d39189875d1e4e9538f4d330"
 :base-image "ubuntu@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517"
 :sbcl-source-sha256 "83d8b74f08d2254c59b9790bc1f669e09099457b884720ececbf45f4b46d1776"
 :sbcl-source-provenance "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.0/sbcl-2.4.0-source.tar.bz2 · ΧΩΡΙΣ ανεξάρτητη υπογραφή (δηλωμένο υπόλειμμα)"
 :bootstrap-sbcl "apt ubuntu noble 2:2.2.9-1ubuntu2 — ΕΡΓΑΛΕΙΟ στο στάδιο bootstrap, ΔΕΝ επιβιώνει"
 :dockerfile-sha256 "9543e8679e02dee11b4f39c5fad118ef3207b970cc87757f6d3cc63b6c1158d6"
 :build-context-tree-sha256 "3bef4c0173bb5b139e955a84699662b78d6a4a6fd7a4db9f9426c279dc60e3d3"
 :oci-image-id "sha256:54bd254c336a57661fce71fdfa5d286662f5321ccde0be5f252230b111737fe6"
 :config-digest "sha256:e6d1ddeda48cca03b9ba9f5d38c28eac6ce633730c398f4b906eefac291a6736"
 :rootfs-layers ("sha256:b9a65b3c65ab22d490085bd0bf5490e2409da8748b406870f2463bdc41cd6795" "sha256:612aead3df345228a5221f103bf1719d83b474521393d8ea3b1c7a44e99d5b54" "sha256:152f8ccb4febe2e26c476ad16314225268f1740273663a8552d0001dbddd355a" "sha256:7130711861e0bbf3a8e291a7f4aaa253af4c5e4abfdc4b54b3fbe9d50a1f090b" "sha256:3489d23c4ad49d49460fa5e11005c9b050e62fa56b1a19443dade407d135d409" "sha256:4c2815254bc61f0f92bbefbedd8692fefc45a7e21e911886cbd1baa65226e5c9" )
 :sbcl-version "SBCL 2.4.0"
 :sbcl-core-sha256 "93d2f949cb36210710c6489a674b8f8d89ead07eea4c13253a002aa3ca61c697"
 :sbcl-executable-sha256 "3f628a078d43bf9cc8ec907dfbbd31917866b3c12e3ca7ec071c401b88aa9167"
 :asdf-version "3.3.1"
 :runtime-package-count 1
 :runtime-package-inventory-sha256 "ed6b1ddd66fed264a8bf5fa7c44b37f471e32aad9a8f8f31af40dcd0504f5026"
 :apt-sbcl-in-runtime "ΑΠΩΝ"
 :build-log "rebuild-receipt-A.build.log")
