;;;; experiment/artifacts/suite-census.sexp — ΠΑΡΑΓΟΜΕΝΟ από census.py
;;;; ΣΟΥΙΤΕΣ ≠ CHECKS. Τα δύο μεγέθη δηλώνονται ΧΩΡΙΣΤΑ και δεν αθροίζονται.

(:lawmax-suite-census/1
 :ran-at "2026-08-24T12:15:52Z"
 :runner-image "lawmax-runner:frozen"
 :inventory-rule "glob tests/*-test.lisp ΜΕΙΟΝ docker/standalone-suite-exclusions.txt (Η ΜΙΑ έδρα του corpus)"
 :suite-files 136
 :declared-suite-exclusions 1
 :declared-nonsuite-files 8
 :executed 136
 :exit-zero 132
 :exit-nonzero 4
 :unparsed-result 5
 :checks-passed-total 2839
 :checks-failed-total 3
 :wallclock-seconds 612
 :suites
  ((:suite "ai-corpus-dump" :file "tests/ai-corpus-dump-test.lisp" :sha256 "6ebb7e80c93eb9486b1441bb60df9befcdc6b9eb560e498a3e9ef36392aa0367"
    :gated t :exit 0 :checks-passed 14 :checks-failed 0 :seconds 101.0
    :corpus-write-attempts ("deployment/self/proposals.sexp.lock"))
   (:suite "ai-ingest-manifest" :file "tests/ai-ingest-manifest-test.lisp" :sha256 "2bafb1dbc01118174d8e551f95e21caabe31cf80498e3f7f760186fe0da93143"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 30.1
    :corpus-write-attempts ())
   (:suite "akoma-ntoso-emitter" :file "tests/akoma-ntoso-emitter-test.lisp" :sha256 "37e1c7b6e1a821e83d23ca37df03f835bd15fc4ff4d792f2073cd3ad8161952c"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "amended-split" :file "tests/amended-split-test.lisp" :sha256 "c980550935c837aaa9e321563036233939409e38269dc58bd19ebed5834eae24"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "amendment-accuracy" :file "tests/amendment-accuracy-test.lisp" :sha256 "cc90506556cf921b3c5004b09d2eba38ec85305d407f9bb5967901b6fa67fd94"
    :gated t :exit 0 :checks-passed 8 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "amendment-backtest" :file "tests/amendment-backtest-test.lisp" :sha256 "ce2ebfbcd64c8ffcd9ca50249f88e4a617a26db6adca9de380391c2efdbf0bf0"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "amendment-consolidation-e2e" :file "tests/amendment-consolidation-e2e-test.lisp" :sha256 "57814230890f4cb27683faec443d79549f9f8150e687e7b635287ff64932b886"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "amendment-extractor" :file "tests/amendment-extractor-test.lisp" :sha256 "775228f1dc5fcabcb24636d5fc20fad850c867d08c85dabb544e05650e1a091b"
    :gated t :exit 0 :checks-passed 23 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "amendment-routing" :file "tests/amendment-routing-test.lisp" :sha256 "6cf1729ad0a34db871da1de18db542b0bf74bb576329e6fc2d86226dfc3edbce"
    :gated t :exit 0 :checks-passed 30 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "amendment-state" :file "tests/amendment-state-test.lisp" :sha256 "9507d72103face512dec36ce68b50cff2734e35f6e7d4aed2665e9da1348ea11"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "anomaly-detection" :file "tests/anomaly-detection-test.lisp" :sha256 "a4940472e56184fc7a94c2e6527ec6e54813f7e7bb0b2777cff7c29b2d41daa3"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "architecture-multiplicity" :file "tests/architecture-multiplicity-test.lisp" :sha256 "ca01fc897a501b5c46092d0b38537b11b57bd8e8ca0835c7781f552585a3cc9a"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "article-identity" :file "tests/article-identity-test.lisp" :sha256 "3245afccab81033218860a33bedcbdaa1fd23191928bac1b0b7c7c75ad469469"
    :gated t :exit 0 :checks-passed 59 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "article-number-fidelity" :file "tests/article-number-fidelity-test.lisp" :sha256 "5dd8e392fa8730bfa1cd7943f8c7e2bca146811115e219b88b45eba32e63c02a"
    :gated t :exit 0 :checks-passed 10 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "artifact-census" :file "tests/artifact-census-test.lisp" :sha256 "815b40f55dc76dae3ae97ba377d88ed36cfeaa36dabfdd3924328cd154c4699e"
    :gated t :exit 0 :checks-passed 21 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "as-known-e2e" :file "tests/as-known-e2e-test.lisp" :sha256 "3ab36e543f6354e94418f93678e6ae394283ac25f4f7ea4ef51e6ce53d98ec4e"
    :gated t :exit 0 :checks-passed 27 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ("deployment/data/version-graph/gr-nomos-2020-9998.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9998.vgraph.sexp.lock" "deployment/data/version-graph/gr-nomos-2020-9999.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9999.vgraph.sexp.lock" "deployment/data/version-graph/gr-syntagma.vgraph.sexp" "deployment/data/version-graph/gr-syntagma.vgraph.sexp.lock"))
   (:suite "ast-gate" :file "tests/ast-gate-test.lisp" :sha256 "f62fb2acbbf82fba5c003815c4879439cab8627dd0f44b45fac2a9f43b654d38"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "ast-persistence" :file "tests/ast-persistence-test.lisp" :sha256 "ef16361a8ae691d6ceb97c2924cd88147ecefd4f6b8c66b91f2ed30da3107d74"
    :gated t :exit 0 :checks-passed 30 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "audit-signature-failclosed" :file "tests/audit-signature-failclosed-test.lisp" :sha256 "414f0694af019172b42627e7272fa5b35e418b05275664d6161d51903496050e"
    :gated t :exit 0 :checks-passed 5 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "authority-cross-language" :file "tests/authority-cross-language-test.lisp" :sha256 "38268f32103ce02cf923b8102c9466ce59fd18a6f08b819d6ca68da682c70500"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "authority-evidence-replay" :file "tests/authority-evidence-replay-test.lisp" :sha256 "9fcbad90f566d6b37c45ddd492ac80abc54ce32b3dcb2be530acb4021bd5b11b"
    :gated t :exit 0 :checks-passed 33 :checks-failed 0 :seconds 6.5
    :corpus-write-attempts ("deployment/data/version-graph/apbc-source-graph.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-1-53642622610385-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-10-180159283101072-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-11-237000228647112-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-12-230408993280759-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-13-97313854846961-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-14-98847432426997-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-15-139300325204172-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-16-221513432183285-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-17-242885828163382-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-18-83676051892502-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-19-100098711707904-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-2-263100937968462-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-20-90456986376402-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-21-274471005992364-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-22-268239368764149-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-23-164382050071376-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-24-149699825591508-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-25-199572810964262-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-26-125136755738912-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-27-124584272837120-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-3-172978737592756-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-4-221302190856013-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-5-197636405883640-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-6-35741853280398-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-7-183417684415052-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-8-112977989285919-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock" "deployment/data/version-graph/apbreplay-9-97286742920214-3a23299448f40e81e8f27877d26b152706ef59ee82cd62ff09a8d60436439b6e.vgraph.sexp.lock"))
   (:suite "authority-proof-bundle" :file "tests/authority-proof-bundle-test.lisp" :sha256 "e17dd7c6b0cd0d8bb969fa09fc7ebd1e91599ab08ac06be0092740812c24790f"
    :gated t :exit 0 :checks-passed 66 :checks-failed 0 :seconds 6.6
    :corpus-write-attempts ())
   (:suite "auto-consolidate" :file "tests/auto-consolidate-test.lisp" :sha256 "0416917609eaa799056d8131d2b2da7ce98f82b2274be4853a3295a4cff22f99"
    :gated t :exit 0 :checks-passed 22 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "auto-update-verdict" :file "tests/auto-update-verdict-test.lisp" :sha256 "62a3b7f03b9b937ed6144067e9523ce1dd550761e01e4c46ea8f796f5ec28e5e"
    :gated t :exit 0 :checks-passed 5 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "autonomy-consolidation" :file "tests/autonomy-consolidation-test.lisp" :sha256 "54a92e88e65bd9dbfa94e20c6a99d4bad38cd0afac8dc2ce3f4c1b912bd4e1e5"
    :gated t :exit 0 :checks-passed 10 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "blockchain-authority" :file "tests/blockchain-authority-test.lisp" :sha256 "93a4bc11af2815a5510e3debd414c541f250edcbf6cfe27e5da2fbe3de506659"
    :gated t :exit 0 :checks-passed 32 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "bpe-persistence" :file "tests/bpe-persistence-test.lisp" :sha256 "7d79fab75aab3bd190e4ea3d27d7dd52edb6750d691eeb14574680d2c5a9a499"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "canonical-serialization" :file "tests/canonical-serialization-test.lisp" :sha256 "e82a122c1086d06592c9ea1fb201db3879ec051fdb759be7545a11a289ce7ae5"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "capability-api" :file "tests/capability-api-test.lisp" :sha256 "c1597b75455bf18a5f414d2ebefe8f888a53b60d96b229f0da6374218513af1e"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 2.7
    :corpus-write-attempts ())
   (:suite "capability-gate" :file "tests/capability-gate-test.lisp" :sha256 "cc2b8a93df1043ff84a3c37bc5dc9657295c79cf817c4a733cdef787cc2f9645"
    :gated t :exit 0 :checks-passed 14 :checks-failed 0 :seconds 20.0
    :corpus-write-attempts ("deployment/self/episodes.sexp.lock" "deployment/self/graph-snapshot.sexp" "deployment/self/history.sexp.lock"))
   (:suite "capability-registry" :file "tests/capability-registry-test.lisp" :sha256 "75a2d202d05da7b743b93d4bef289e6aad699edec1afddc36b2c91630ff1f074"
    :gated t :exit 0 :checks-passed 33 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "casegrammar" :file "tests/casegrammar-test.lisp" :sha256 "32cd3d0b030caeefd4f83cf54be716501b99df307b97721f756ab4fbd82fdb6e"
    :gated t :exit 0 :checks-passed 30 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "citation-authority" :file "tests/citation-authority-test.lisp" :sha256 "ba486239c233642d4e0aebe1eda4915bbc8190da45a2b06a1f9af471894270d4"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "clean-json-format" :file "tests/clean-json-format-test.lisp" :sha256 "3f1b133f4c708030306192ff191b5b6e2e56a442653d224d8809445b66c4b0fa"
    :gated t :exit 0 :checks-passed 13 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "clean-output" :file "tests/clean-output-test.lisp" :sha256 "f10bde0bdf9d1cb61a42cbda78473cd50f7808f02da96ad99542e6145b688f36"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "cockpit" :file "tests/cockpit-test.lisp" :sha256 "50cbe90db768052977820f3699b16db7361c5448d15a83e4bfcacab5cd1170ca"
    :gated t :exit 0 :checks-passed 37 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "codification-validation" :file "tests/codification-validation-test.lisp" :sha256 "85be91123fd381df5afffa7ed23d5f9270a7237126ac31df22083f5601c5046a"
    :gated t :exit 0 :checks-passed 17 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "comparison" :file "tests/comparison-test.lisp" :sha256 "7dee4ebc07d561ec27c7e08a9a36934898a001b350b3b563738c0f282b9e47ea"
    :gated nil :exit 0 :checks-passed :unknown :checks-failed :unknown :seconds 3.4
    :corpus-write-attempts ())
   (:suite "consolidation-bridge" :file "tests/consolidation-bridge-test.lisp" :sha256 "732e2ab8cd81dab557ea3f538150fb564f704ad4f658215f22af7029fb9569de"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "consolidation-engine" :file "tests/consolidation-engine-test.lisp" :sha256 "160d7a7079901a5fe4cd32e1278d507cb66cc592a7cbb86ec1be935e2eea5727"
    :gated t :exit 0 :checks-passed 23 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "consolidation-feed" :file "tests/consolidation-feed-test.lisp" :sha256 "891f0469be516292599d0c25bf94f42710d934c147feb80d7957b31311140df4"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "constitution-crawler" :file "tests/constitution-crawler-test.lisp" :sha256 "5c714ee186bb171528aafbce85f4325f5b7890a4a91833a2a675ee94ed0c848b"
    :gated t :exit 0 :checks-passed 14 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "corpus-diff" :file "tests/corpus-diff-test.lisp" :sha256 "890d6ca471519b609b0bdd5e695b5843f9ea6be4e43fe2f0fbe52e925ded8f5f"
    :gated t :exit 0 :checks-passed 13 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "corpus-eu-links" :file "tests/corpus-eu-links-test.lisp" :sha256 "a190080ceaeb1309774f7fb0706e5c0aa40e876db3768b7491ddf1b1e0db30cb"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "corpus-fingerprint" :file "tests/corpus-fingerprint-test.lisp" :sha256 "5c71d22474dc0ef31299a4c1fe70bd08389a753bb0222584f6536086b1b0daf4"
    :gated t :exit 0 :checks-passed 30 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "corpus-identity" :file "tests/corpus-identity-test.lisp" :sha256 "e8a1d799352dbc23c21bafc22f9d5d34408b1ce0f22512a5b4d1d4cfb3da9930"
    :gated t :exit 0 :checks-passed 55 :checks-failed 0 :seconds 5.7
    :corpus-write-attempts ())
   (:suite "corpus-intelligence" :file "tests/corpus-intelligence-test.lisp" :sha256 "f577add79b66920d53b89de4bb55e43e34ba350cc37fd4a95282e0dea6b29537"
    :gated t :exit 0 :checks-passed 24 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "corpus-provenance" :file "tests/corpus-provenance-test.lisp" :sha256 "7699f4d453f1164e212019e4a7cae2f485ccf1d67c1491fef5f2b1af86f006d5"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "corpus-search" :file "tests/corpus-search-test.lisp" :sha256 "944b92652dd77b7ca82d9b365cfcae9d46fe98965a03215fd93caba532abbe09"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "corpus-service" :file "tests/corpus-service-test.lisp" :sha256 "922d602419c408d4b69a849acf8ec990cd6e54643a91f0ef0fd3f5ce912593ab"
    :gated t :exit 0 :checks-passed 53 :checks-failed 0 :seconds 3.9
    :corpus-write-attempts ())
   (:suite "corpus-sparql" :file "tests/corpus-sparql-test.lisp" :sha256 "2bdbdd06384122cf260d2c04d85ff73af0ef67a0c22e30ea7909f18e926517e9"
    :gated t :exit 0 :checks-passed 9 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "cross-language-verifier" :file "tests/cross-language-verifier-test.lisp" :sha256 "4b84551ebc9ea95e9f6940da33d7e168b58ae0a9549cf8d39b2fae1833c6ef9c"
    :gated t :exit 0 :checks-passed :unknown :checks-failed :unknown :seconds 3.4
    :corpus-write-attempts ())
   (:suite "currentness-34" :file "tests/currentness-34-test.lisp" :sha256 "2862d52c007bde43e6a7e6d7e3f2cbbb0c5c1524598b963fafcd0fa23b688d78"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 5.2
    :corpus-write-attempts ())
   (:suite "dependency-contract-consistency" :file "tests/dependency-contract-consistency-test.lisp" :sha256 "eb203786e14182a5ba594f5c128e392d1c9ecc340a0f4ff07dddc2346dd4dc4a"
    :gated t :exit 0 :checks-passed 5 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "deps-hash" :file "tests/deps-hash-test.lisp" :sha256 "2cb3d092b8b555b8f94bf7983f9eda872f1279394b4fc45bc572451b709957e5"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "document-fetch" :file "tests/document-fetch-test.lisp" :sha256 "0ef1b9c43f9ea1741a70fdf2f4c2fe5038c291f58e314351bc5694b010b9a061"
    :gated t :exit 0 :checks-passed 29 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "dsanet-chrome" :file "tests/dsanet-chrome-test.lisp" :sha256 "5afa5ef41f77a1680b36330347c6c53bccc17b2e82f7122201d5b4fd1c0bfbed"
    :gated t :exit 0 :checks-passed 65 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "errata-boundary" :file "tests/errata-boundary-test.lisp" :sha256 "6c011c3603b09bf08c393eb8269e96a070e346cf607009713152432bf9aee201"
    :gated t :exit 0 :checks-passed 6 :checks-failed 0 :seconds 7.6
    :corpus-write-attempts ())
   (:suite "escape-sequences" :file "tests/escape-sequences-test.lisp" :sha256 "7a2e0e359d5f9a0323bc27daf3b77f9508c2edf72c00aba93527126d2765d933"
    :gated t :exit 0 :checks-passed 38 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "fek-article-header" :file "tests/fek-article-header-test.lisp" :sha256 "76db912e168dc522b4b9ddd3f1067b42c12516d8fd18356f6c4cb4598fe3dd3e"
    :gated t :exit 0 :checks-passed 9 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "fek-backtest-report" :file "tests/fek-backtest-report-test.lisp" :sha256 "a0d7b78251d68aebb375c53bb482cb8b00d3bed271562c760fd5504b0b946f06"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "fek-discovery" :file "tests/fek-discovery-test.lisp" :sha256 "ec8e951ace4dac7b8dbc8374ae7cbbc67d4d12bfcc1a9f473a996bb1fa8c8755"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "fek-html-parser" :file "tests/fek-html-parser-test.lisp" :sha256 "6e244ad2b3c156a5391b42fc670e037d51a00fe69438026c3df8e1d7b8562ea8"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "fek-ingestion" :file "tests/fek-ingestion-test.lisp" :sha256 "5a8c2f4e65a5bf3a0c074cac17182363e1f86b399c0dc73434764b85d861d24e"
    :gated t :exit 0 :checks-passed 10 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "fek-noise" :file "tests/fek-noise-test.lisp" :sha256 "bfb367751507bbe4fd0183d339283ed4c276ee30ad54caa8090bae69d7c97298"
    :gated t :exit 0 :checks-passed 21 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "fek-rubric" :file "tests/fek-rubric-test.lisp" :sha256 "60d10b39930bf57df13ea4955576e6c7702b260cc568953dc10a2a6e9c73c199"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "government-source" :file "tests/government-source-test.lisp" :sha256 "88816a4816d4375c6c5ef00036cab61f560960e2b58de2d14f1ae84ebce2ebb7"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 5.7
    :corpus-write-attempts ())
   (:suite "graph-import-parity" :file "tests/graph-import-parity-test.lisp" :sha256 "59bf40b4b122b20bad8f59e7f4cf046f78fa09ed8d9925f1c5ae9eb7c8792eb5"
    :gated t :exit 0 :checks-passed 31 :checks-failed 0 :seconds 9.0
    :corpus-write-attempts ("deployment/data/version-graph/gr-kodikas-1984-456.vgraph.sexp" "deployment/data/version-graph/gr-kodikas-1984-456.vgraph.sexp.lock" "deployment/data/version-graph/gr-kodikas-1985-503.vgraph.sexp" "deployment/data/version-graph/gr-kodikas-1985-503.vgraph.sexp.lock" "deployment/data/version-graph/gr-kodikas-1999-2717.vgraph.sexp" "deployment/data/version-graph/gr-kodikas-1999-2717.vgraph.sexp.lock" "deployment/data/version-graph/gr-kodikas-2019-4619.vgraph.sexp" "deployment/data/version-graph/gr-kodikas-2019-4619.vgraph.sexp.lock" "deployment/data/version-graph/gr-kodikas-2019-4620.vgraph.sexp" "deployment/data/version-graph/gr-kodikas-2019-4620.vgraph.sexp.lock"))
   (:suite "greek-homoglyph" :file "tests/greek-homoglyph-test.lisp" :sha256 "9cbed698071f34e5dae3217a58726e1d69d48ba3ad86b0ac086b7d219183c386"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "greek-morphology" :file "tests/greek-morphology-test.lisp" :sha256 "f597694ac0ab471df8cf866fe67415d99e7cca8fdde37fc0ab28620bece82024"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "greek-nlp" :file "tests/greek-nlp-test.lisp" :sha256 "834ff5bf16869512ba70c3ce388215d5e9beac77fbcbf88bfe161f5ec8582886"
    :gated t :exit 0 :checks-passed 21 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "hash-authority" :file "tests/hash-authority-test.lisp" :sha256 "7969f699309ecfbb6b04c773e76c60b0308b8fd3f8eb08d0da0e3adce2081932"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "hash-seat-registry" :file "tests/hash-seat-registry-test.lisp" :sha256 "8b49b08681742594c5e45cb91b9090478623f3ce1fffd9c81c7b91732fd9388f"
    :gated t :exit 1 :checks-passed 14 :checks-failed 1 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "incremental-emit" :file "tests/incremental-emit-test.lisp" :sha256 "a1cfee61877f3e5f30452e1f390b6e790b6b3f474745fffd9c3bb5c06a7c5ff5"
    :gated t :exit 0 :checks-passed 15 :checks-failed 0 :seconds 5.4
    :corpus-write-attempts ())
   (:suite "ingestion-daemon" :file "tests/ingestion-daemon-test.lisp" :sha256 "14126a4094113b66aa261d760c2cf2c56e361213bd8ae977ca49d38cd3268fd0"
    :gated t :exit 0 :checks-passed 8 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "ingestion-e2e" :file "tests/ingestion-e2e-test.lisp" :sha256 "90cde538549441f3659fbd0037da752b7eef62b6ead8756240fe91d6b2fcbbd9"
    :gated t :exit 0 :checks-passed 10 :checks-failed 0 :seconds 4.0
    :corpus-write-attempts ())
   (:suite "isokratis-amended" :file "tests/isokratis-amended-test.lisp" :sha256 "e8cb974dedba8be32bb14aefd1efa2d962053f5a6fc340acdf299a37a37ba892"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.7
    :corpus-write-attempts ())
   (:suite "isokratis-parser" :file "tests/isokratis-parser-test.lisp" :sha256 "8e10c7884aab7a9a96642aa620d1d892cfe0d2d50d86bdc5ce1ca5424ea868f8"
    :gated t :exit 0 :checks-passed 23 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "journal-integrity" :file "tests/journal-integrity-test.lisp" :sha256 "a0990f9ed636da088b96d67b36c28a0eea0f09c21b9600ec2f475fcbd04f0f22"
    :gated t :exit 0 :checks-passed 52 :checks-failed 0 :seconds 4.5
    :corpus-write-attempts ())
   (:suite "json-emit" :file "tests/json-emit-test.lisp" :sha256 "fe327c2700ea2ba8f1e4a2ee4cce03f39a4c1b234ac6f40fecd1b097c5395ded"
    :gated t :exit 0 :checks-passed 22 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "json-escape-seat" :file "tests/json-escape-seat-test.lisp" :sha256 "a5ae20763779faef13fc87d4c6bd926c282822754a5d2ea73602306ad53167e9"
    :gated t :exit 0 :checks-passed 9 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "jws-strict-grammar" :file "tests/jws-strict-grammar-test.lisp" :sha256 "098ccb841c2f317f201eb0cdbe7bf1071266d3200c5de520add79f80efd11d45"
    :gated t :exit 0 :checks-passed 13 :checks-failed 0 :seconds 3.7
    :corpus-write-attempts ())
   (:suite "kernel-conformance" :file "tests/kernel-conformance-test.lisp" :sha256 "6697dbf3ab3f688d9da64fe28a01a6ef10335c2fd58d5c33f31071ccd2b6d5c3"
    :gated t :exit 0 :checks-passed :unknown :checks-failed :unknown :seconds 3.8
    :corpus-write-attempts ())
   (:suite "layout-extraction" :file "tests/layout-extraction-test.lisp" :sha256 "811efa35077434ce9d79d6dcb13a3246c57b274e71c962eff9b27075dd5466a5"
    :gated t :exit 0 :checks-passed 9 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "layout-persistence" :file "tests/layout-persistence-test.lisp" :sha256 "244ee9a1340a0570b8a758ed534311294997988fcd73a6e48abd33bacb1a6c0b"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "legal-authority-receipt" :file "tests/legal-authority-receipt-test.lisp" :sha256 "1deee843f6d6b0b0e7a2d328331118eef2889f006a2f6b7ddeb8083ad43a0545"
    :gated t :exit 0 :checks-passed 21 :checks-failed 0 :seconds 3.6
    :corpus-write-attempts ())
   (:suite "legal-eval" :file "tests/legal-eval-test.lisp" :sha256 "ad8754312a00692ee103532deffa495a95b0b6b3193cb43c2797f1b470716de9"
    :gated t :exit 0 :checks-passed 8 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "legal-id-registry" :file "tests/legal-id-registry-test.lisp" :sha256 "9a43d576109c84f9c4017f9bd01855bc489213539e43dfc3a523af388ef52666"
    :gated t :exit 0 :checks-passed 27 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "legal-id-routing" :file "tests/legal-id-routing-test.lisp" :sha256 "4995f9fa20bf55b80bcd16324d2bf2573af945b1ec736f47bb3a3543224dffdb"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "legal-identity" :file "tests/legal-identity-test.lisp" :sha256 "86d707a47d013fde88e1481f0125cdb68a634763d07e1713a05ea8bff53f449d"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "legal-qa" :file "tests/legal-qa-test.lisp" :sha256 "d29cd4b6acb0f3f7b025e133af2a89d8facfaf05bef98cb55f7a305f4c230c08"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "legal-references" :file "tests/legal-references-test.lisp" :sha256 "d480236a49d23a7f3e2ed0fb4299238f86198ea8484db8a337facdb02ba1d406"
    :gated t :exit 0 :checks-passed 14 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "legislation-ingestion" :file "tests/legislation-ingestion-test.lisp" :sha256 "53885acf8406af1ec812cc4b2fc3b7e9453c484fdd6bab1ed9f068fd5294eb49"
    :gated t :exit 0 :checks-passed 17 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "level7-disarm" :file "tests/level7-disarm-test.lisp" :sha256 "4b36181796c57f0eb6deef50c73adc2e6e386e36fb7bc87b5b307ea70e14dd72"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "mcp-live-resolver" :file "tests/mcp-live-resolver-test.lisp" :sha256 "134a575d8401dfd902e2cb67586064fcf24000d677c5d10cb0156d86576944e7"
    :gated t :exit 1 :checks-passed :unknown :checks-failed :unknown :seconds 3.0
    :corpus-write-attempts ())
   (:suite "mcp-server" :file "tests/mcp-server-test.lisp" :sha256 "b394e50e025c773122d2173c410b0a1956bfd088ce77259b865bdd8bc06b7ac2"
    :gated t :exit 0 :checks-passed 32 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "merkle-authority" :file "tests/merkle-authority-test.lisp" :sha256 "186a050bd3f9876d13832942fabcc688852fbbf2c9e2e3619af1d5a68d503e88"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "merkle-single-truth" :file "tests/merkle-single-truth-test.lisp" :sha256 "c38cbb174e51710dc66fb86d865a37b649340c872a291b4c3e12d089c343bae8"
    :gated t :exit 1 :checks-passed 47 :checks-failed 1 :seconds 4.3
    :corpus-write-attempts ())
   (:suite "multi-corpus-service" :file "tests/multi-corpus-service-test.lisp" :sha256 "667c8cafa17466fa2d9996b629f617b6d3ebc4f227b39fce24b5dade31cd716d"
    :gated t :exit 0 :checks-passed 13 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "orthography" :file "tests/orthography-test.lisp" :sha256 "2e205efbd8570d5c0ea2690f90dd122ee1303e1fe07b2fc928fa236a5ddb47df"
    :gated t :exit 0 :checks-passed 22 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "param-type-coercion" :file "tests/param-type-coercion-test.lisp" :sha256 "c68ddf329083fd5caaa0286d5805fe5b4e45776b063bb0ff3e0f4eccf8b3f593"
    :gated t :exit 0 :checks-passed 17 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "param-type-roundtrip" :file "tests/param-type-roundtrip-test.lisp" :sha256 "0f0cb5d87268debefe26559ad333988f3fd4aa87428085a261c8c432e67c641d"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "parliament-html-wiring" :file "tests/parliament-html-wiring-test.lisp" :sha256 "0ec5c7d73a2e722dfe3429f2a935029fdf634f37877152f0c442ea60d47ac201"
    :gated t :exit 0 :checks-passed 8 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "pdf-column-reflow" :file "tests/pdf-column-reflow-test.lisp" :sha256 "e9ae177bc40aafeb554ed161f65fb9bf4a57ea6d356907639ba99b6b3a7482e9"
    :gated t :exit 0 :checks-passed 8 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "proof-carrying" :file "tests/proof-carrying-test.lisp" :sha256 "9b82147539a87effd72943a7c1286a0c0645a531e9ba2f39df90a585d1a4f4ac"
    :gated t :exit 1 :checks-passed 44 :checks-failed 1 :seconds 8.3
    :corpus-write-attempts ())
   (:suite "reader-census" :file "tests/reader-census-test.lisp" :sha256 "aa257ee2186e963b55e3ba0ba48538e55e0b90e1f77b7695dbebedec63f1e208"
    :gated t :exit 0 :checks-passed 133 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "reasoning-authority" :file "tests/reasoning-authority-test.lisp" :sha256 "eb7666508d60adb130fe47e1adf54c5f7fd803f82158a7f576ae94ab6d978dfe"
    :gated t :exit 0 :checks-passed 12 :checks-failed 0 :seconds 2.6
    :corpus-write-attempts ())
   (:suite "release-authority" :file "tests/release-authority-test.lisp" :sha256 "ccfe6bc5b35cfb0c0106bcddb6eb932340197e5e30d88bb4175e23e2c543d0f2"
    :gated t :exit 0 :checks-passed 14 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "release-vector-conformance" :file "tests/release-vector-conformance-test.lisp" :sha256 "b50fbfded630ba86ff92dcab83388b1cfb87ae8fc41ac659a76cfc367d1b3651"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "repeal-polish" :file "tests/repeal-polish-test.lisp" :sha256 "a774f024658b496ff6a69f74bc1fbe904df05a3f51c6c8d52d8bfe0adc8eb310"
    :gated t :exit 0 :checks-passed 30 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "retired-entrypoint" :file "tests/retired-entrypoint-test.lisp" :sha256 "2bf82d97574d9fc41f02a84b77029c91404d2f9489a0082402f8bd2f45615168"
    :gated t :exit 0 :checks-passed 10 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "review-queue-safe-read" :file "tests/review-queue-safe-read-test.lisp" :sha256 "314c2de43aefddf41585f80c6f1c2fd9efc7f276c2d5c17db42323ff22d29fb0"
    :gated t :exit 0 :checks-passed 22 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "review-queue" :file "tests/review-queue-test.lisp" :sha256 "d46ef0b40375f8cf5183a4474abae246c356c1fa0c95e85f401fd399ec0b03c5"
    :gated t :exit 0 :checks-passed 66 :checks-failed 0 :seconds 6.6
    :corpus-write-attempts ())
   (:suite "review-service" :file "tests/review-service-test.lisp" :sha256 "cef9ca69b2534bf8b384a288cf97ea175d7265450f569edbd0edbfe80510a4bf"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "safe-read" :file "tests/safe-read-test.lisp" :sha256 "6308c41d09685887d1604f723c03965185f73c6b9bb82585c9c059b7e153cf56"
    :gated t :exit 0 :checks-passed 73 :checks-failed 0 :seconds 3.6
    :corpus-write-attempts ())
   (:suite "seam-detector" :file "tests/seam-detector-test.lisp" :sha256 "35f28e668d4cf908b04631851d0bf64a0dc5e12c827fc4ef98b3113b34709945"
    :gated t :exit 0 :checks-passed 7 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "seat-integrity" :file "tests/seat-integrity-test.lisp" :sha256 "77cf859034742f768fdfa1034a98f35f967b7d3e09d7aab40ef893699f7e61a9"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "self-identity" :file "tests/self-identity-test.lisp" :sha256 "6bea74b28973e6829f067a25e0e37064aa3bec735f67fde5ed75e1d6f754d842"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "semantic-validity" :file "tests/semantic-validity-test.lisp" :sha256 "1308d9adb96477d3745bca9b62416a1f5e51b8753ea960bac59269b186a226fd"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 3.5
    :corpus-write-attempts ())
   (:suite "shacl-validator" :file "tests/shacl-validator-test.lisp" :sha256 "7beabfefddb34156a3220e7fdf9d66144d521d1a8b01876f6037b31223b2fabd"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "source-detect" :file "tests/source-detect-test.lisp" :sha256 "ad885bd7ab9b8b5093fa1c6fa9ffb5ca631472605f11c5a6e853238ac9095a01"
    :gated t :exit 0 :checks-passed 9 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ())
   (:suite "source-materialize" :file "tests/source-materialize-test.lisp" :sha256 "58375a65ce2d41a98e04d1d713d632c8198b163b836afcd24f222b0d085f5586"
    :gated t :exit 0 :checks-passed 13 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "source-profile" :file "tests/source-profile-test.lisp" :sha256 "e94d05c4c389a1c794c158ec61c4ab739bb74f6ce87e1328e1db019813e1472d"
    :gated t :exit 0 :checks-passed 51 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
   (:suite "static-site" :file "tests/static-site-test.lisp" :sha256 "2bf32f50c58762bfcf33268ef77f60567708b7f7edcd4e5249a673bf4138e197"
    :gated t :exit 0 :checks-passed 45 :checks-failed 0 :seconds 2.8
    :corpus-write-attempts ())
   (:suite "temporal-semantics" :file "tests/temporal-semantics-test.lisp" :sha256 "fa255efece065841602d80263675ec20fb832b3e288dbf3a764cbe937960cb2b"
    :gated t :exit 0 :checks-passed 111 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ("deployment/data/version-graph/gr-nomos-2020-9995.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9995.vgraph.sexp.lock" "deployment/data/version-graph/gr-nomos-2020-9996.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9996.vgraph.sexp.lock" "deployment/data/version-graph/gr-nomos-2020-9997.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9997.vgraph.sexp.lock"))
   (:suite "temporal-verifier" :file "tests/temporal-verifier-test.lisp" :sha256 "131ddd162dcaba94aedef76c5ddcc64eb37aaf77cc3c10812af6af3e519750f8"
    :gated t :exit 0 :checks-passed 2 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ("deployment/data/version-graph/gr-nomos-2020-9993.vgraph.sexp" "deployment/data/version-graph/gr-nomos-2020-9993.vgraph.sexp.lock"))
   (:suite "text-admission" :file "tests/text-admission-test.lisp" :sha256 "e6abbe6fccf0c4e22105e7e78479298dc7a28ac2a0e774e0e1225664c2ca969e"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ("deployment/data/version-graph/test-ta-3996562522-main.vgraph.sexp" "deployment/data/version-graph/test-ta-3996562522-main.vgraph.sexp.lock" "deployment/data/version-graph/test-ta-3996562522-tamper.vgraph.sexp" "deployment/data/version-graph/test-ta-3996562522-tamper.vgraph.sexp.lock"))
   (:suite "text-sovereignty" :file "tests/text-sovereignty-test.lisp" :sha256 "154f609b79483eaffb8c973e53a6782e7a768e6e4c749a78760a9c71bc370150"
    :gated t :exit 0 :checks-passed 11 :checks-failed 0 :seconds 3.1
    :corpus-write-attempts ())
   (:suite "time-unified" :file "tests/time-unified-test.lisp" :sha256 "5b2320bd5f5c9f9810bcd024f5c02a21fed25dc868560eb48d9debac50f69439"
    :gated t :exit 0 :checks-passed 20 :checks-failed 0 :seconds 3.0
    :corpus-write-attempts ())
   (:suite "trace-persistence" :file "tests/trace-persistence-test.lisp" :sha256 "2595b188e22e09ef9f6909c5d062723b16a70b13dd86f5fa49e1e9045326ba33"
    :gated t :exit 0 :checks-passed 27 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "transparency-log" :file "tests/transparency-log-test.lisp" :sha256 "d898803ebf34f73dcf67048332c62767c999dec5fd41893246fbea818cf44dfe"
    :gated t :exit 0 :checks-passed 21 :checks-failed 0 :seconds 3.3
    :corpus-write-attempts ())
   (:suite "tsr-crypto-verify" :file "tests/tsr-crypto-verify-test.lisp" :sha256 "67f2b199c97a2cef8244f4b8b59ff3b6901490ea7f8f1c93e055996019fd070e"
    :gated t :exit 0 :checks-passed 19 :checks-failed 0 :seconds 3.4
    :corpus-write-attempts ())
   (:suite "turtle-nil-omit" :file "tests/turtle-nil-omit-test.lisp" :sha256 "f7b6086bd52af9d1a529ca8f7b3c2d734ae3a6e1f66ad8442c850d3c6c871426"
    :gated t :exit 0 :checks-passed :unknown :checks-failed :unknown :seconds 3.2
    :corpus-write-attempts ())
   (:suite "version-chain-tc2" :file "tests/version-chain-tc2-test.lisp" :sha256 "ac8264ef78dc2628d3413f5608e5b44e6347aa268d3dcb407e91286902a8d45e"
    :gated t :exit 0 :checks-passed 3 :checks-failed 0 :seconds 2.9
    :corpus-write-attempts ("deployment/data/version-graph/test-vg-tc2-2540001.vgraph.sexp" "deployment/data/version-graph/test-vg-tc2-2540001.vgraph.sexp.lock"))
   (:suite "version-graph" :file "tests/version-graph-test.lisp" :sha256 "6756e53e276bd9e863145522c818e696c367c06ba50bcdc42afcfc216ccc390c"
    :gated t :exit 0 :checks-passed 18 :checks-failed 0 :seconds 4.3
    :corpus-write-attempts ("deployment/data/version-graph/test-vg-3996562547-det-a.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-det-a.vgraph.sexp.lock" "deployment/data/version-graph/test-vg-3996562547-det-b.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-det-b.vgraph.sexp.lock" "deployment/data/version-graph/test-vg-3996562547-main.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-main.vgraph.sexp.lock" "deployment/data/version-graph/test-vg-3996562547-quar.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-quar.vgraph.sexp.lock" "deployment/data/version-graph/test-vg-3996562547-repeal.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-repeal.vgraph.sexp.lock" "deployment/data/version-graph/test-vg-3996562547-tamper.vgraph.sexp" "deployment/data/version-graph/test-vg-3996562547-tamper.vgraph.sexp.lock"))
   (:suite "write-authority" :file "tests/write-authority-test.lisp" :sha256 "f86ecca636efc91106510de98e5aabc5975335a0d27ab4feff546b0b4524efde"
    :gated t :exit 0 :checks-passed 16 :checks-failed 0 :seconds 3.2
    :corpus-write-attempts ())
  ))
