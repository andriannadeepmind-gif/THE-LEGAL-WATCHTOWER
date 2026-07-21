;;;; tests/cockpit-test.lisp
;;;; ============================================================================
;;;; COCKPIT — regression lock της ενοποιημένης επιφάνειας (--cockpit)
;;;; ============================================================================
;;;; Κλειδώνει ΚΑΘΕ συμπεριφορά που κρίθηκε από τους αντιπαλικούς κριτές [0072]:
;;;;   · routing/status matrix (/ , /api/*, 403, 404)
;;;;   · CSRF: απαιτείται X-LAWMAX-Cockpit (θάνατος simple-CORS CSRF)
;;;;   · Host-allowlist: loopback bind ⇒ μόνο localhost/127.0.0.1 (θάνατος rebinding)
;;;;   · require-trust: advisor δυνατότητα ΔΕΝ εκτελείται στην trusted επιφάνεια (403)
;;;;   · catalog trusted-only: δεν διαφημίζει advisor caps
;;;;   · :decide round-trip σε ΥΠΑΡΚΤΟ item ⇒ status APPROVED (το bug :approved→ecase)
;;;;   · %cockpit-json: object/array/bool/scalar μέσω της ΜΙΑΣ έδρας %json-scalar
;;;;   · auth με token: χωρίς/λάθος key ⇒ 403· σωστό key ⇒ 200
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

;; Ο cockpit διαβάζει την ουρά από REVIEW_QUEUE_FILE — δείξε την σε temp αρχείο.
(sb-posix:setenv "REVIEW_QUEUE_FILE" "/tmp/cockpit-test-queue.sexp" 1)
(ignore-errors (delete-file "/tmp/cockpit-test-queue.sexp"))
;; Καμία προϋπάρχουσα token στο περιβάλλον του test (καθαρή τοπική εγκατάσταση).
(ignore-errors (sb-posix:unsetenv "LAWMAX_CREATOR_TOKEN"))
(ignore-errors (sb-posix:unsetenv "COCKPIT_HOST"))
(ignore-errors (sb-posix:unsetenv "COCKPIT_ALLOWED_HOSTS"))

(defun req (path &key (query nil) (headers nil))
  (orchestrator.http:make-http-request :method "GET" :path path
                                       :query query :headers headers))
(defun st (resp) (orchestrator.http:http-response-status resp))
(defun bd (resp) (orchestrator.http:http-response-body resp))

;; Οι νόμιμες κεφαλίδες που στέλνει η σελίδα (loopback Host + custom CSRF header).
(defparameter *ok-headers* '(("host" . "127.0.0.1") ("x-lawmax-cockpit" . "1")))

(format t "~%== routing / page ==~%")
(let ((r (%cockpit-handler (req "/"))))
  (check "GET / → 200" (= 200 (st r)))
  (check "GET / → σελίδα LAWMAX" (and (search "LAWMAX" (bd r)) t))
  (check "GET / → κανένα inline onclick με παρεμβολή id" (null (search "onclick=\"decide" (bd r))))
  (check "GET / → στέλνει X-LAWMAX-Cockpit" (and (search "X-LAWMAX-Cockpit" (bd r)) t)))

(format t "~%== CSRF: το custom header είναι υποχρεωτικό ==~%")
(check "χωρίς X-LAWMAX-Cockpit → 403"
       (= 403 (st (%cockpit-handler (req "/api/pending" :headers '(("host" . "127.0.0.1")))))))
(check "με X-LAWMAX-Cockpit → 200"
       (= 200 (st (%cockpit-handler (req "/api/pending" :headers *ok-headers*)))))

(format t "~%== Host-allowlist: loopback bind ⇒ θάνατος DNS-rebinding ==~%")
(check "Host=evil.com (loopback bind) → 403"
       (= 403 (st (%cockpit-handler
                   (req "/api/pending"
                        :headers '(("host" . "evil.com") ("x-lawmax-cockpit" . "1")))))))
(check "Host=localhost → 200"
       (= 200 (st (%cockpit-handler
                   (req "/api/pending"
                        :headers '(("host" . "localhost") ("x-lawmax-cockpit" . "1")))))))

(format t "~%== catalog: trusted-only + require-trust ==~%")
(let ((r (%cockpit-handler (req "/api/catalog" :headers *ok-headers*))))
  (check "/api/catalog → 200" (= 200 (st r)))
  (check "catalog φέρει :ask" (and (search "\"ask\"" (bd r)) t))
  (check "catalog φέρει :decide" (and (search "\"decide\"" (bd r)) t)))

;; Δήλωσε ΠΡΟΣΩΡΙΝΗ advisor δυνατότητα — η trusted επιφάνεια ΔΕΝ την εκτελεί/διαφημίζει.
(orchestrator.capability:define-capability :advtest
  :summary "advisor δοκιμαστικό (δεν πρέπει να εκτελεστεί στην trusted επιφάνεια)"
  :params () :result :string :trust :advisor
  :fn (lambda () "ΔΕΝ ΠΡΕΠΕΙ ΝΑ ΦΑΝΕΙ"))
(check "advisor cap ΔΕΝ εκτελείται (require-trust) → 403"
       (= 403 (st (%cockpit-handler (req "/api/advtest" :headers *ok-headers*)))))
(check "catalog ΔΕΝ διαφημίζει advisor cap"
       (null (search "advtest" (bd (%cockpit-handler (req "/api/catalog" :headers *ok-headers*))))))

(format t "~%== unknown api → 404 (fail-closed) ==~%")
(check "/api/δεν-υπάρχει → 404"
       (= 404 (st (%cockpit-handler (req "/api/does-not-exist" :headers *ok-headers*)))))
(check "μη-api διαδρομή → 404"
       (= 404 (st (%cockpit-handler (req "/whatever" :headers *ok-headers*)))))

(format t "~%== :decide round-trip σε ΥΠΑΡΚΤΟ item (το bug :approved→ecase) ==~%")
;; Φτιάξε πραγματικό εκκρεμές item, σώσ' το στην ουρά (temp file), απόφαση μέσω cockpit.
;; [κύκλος-3] Το item-id είναι CONTENT-DERIVED (%item-key, δένει payload — το restore-queue-state
;; το ΕΠΑΝΥΠΟΛΟΓΙΖΕΙ, δομικό id↔payload binding). Το UI σε production εμφανίζει+περνά ΑΥΤΟ το id·
;; άρα το test αποφασίζει με το ΠΡΑΓΜΑΤΙΚΟ id (όχι fake string άσχετο με την ταυτότητα περιεχομένου).
(defparameter *ck-decide-id*
  (let* ((mk (find-symbol "MAKE-REVIEW-QUEUE" :orchestrator.review))
         (cls (find-symbol "AMENDMENT-REVIEW" :orchestrator.review))
         (q (funcall mk))
         (it (make-instance cls :source "L1" :target "art_5"
                            :payload (list :op :repeal :target "art_5"))))
    (orchestrator.review:enqueue q it)          ; θέτει item-id = %item-key
    (save-review-queue q)
    (orchestrator.review:item-id it)))
(let ((r (%cockpit-handler (req "/api/decide"
                                :query `(("id" . ,*ck-decide-id*) ("action" . "approve"))
                                :headers *ok-headers*))))
  (check "decide approve → 200" (= 200 (st r)))
  (check "decide approve → status approved (όχι 500/ecase)" (and (search "approved" (bd r)) t)))
;; Επαλήθευση ότι ΟΝΤΩΣ γράφτηκε (persistence + status)
(let* ((q2 (load-review-queue))
       (items (orchestrator.review:queue-items q2)))
  (check "item επιμένει ως :approved"
         (some (lambda (i) (eq :approved (orchestrator.review:item-status i))) items))
  (check "καμία εκκρεμότητα πια" (null (orchestrator.review:pending-items q2))))
(let ((r (%cockpit-handler (req "/api/decide"
                                :query '(("id" . "ΔΕΝ-ΥΠΑΡΧΕΙ") ("action" . "approve"))
                                :headers *ok-headers*))))
  (check "decide σε άγνωστο id → 200 «δεν βρέθηκε» (όχι σφάλμα)"
         (and (= 200 (st r)) (search "δεν βρέθηκε" (bd r)))))
(let ((r (%cockpit-handler (req "/api/decide"
                                :query `(("id" . ,*ck-decide-id*) ("action" . "λάθος"))
                                :headers *ok-headers*))))
  (check "decide με άκυρο action → 500 (fail-closed, όχι σιωπηλό)" (= 500 (st r))))

(format t "~%== %cockpit-json: μέσω της ΜΙΑΣ έδρας %json-scalar ==~%")
(check "object+array+bool+scalar"
       (string= "{\"result\":\"ok\",\"n\":3,\"items\":[{\"id\":\"1\",\"ok\":true}]}"
                (%cockpit-json (list :result "ok" :n 3 :items (list (list :id "1" :ok t))))))
(check "nil → null" (string= "null" (%cockpit-json nil)))
(check "keyword → πεζό string" (string= "\"trusted\"" (%cockpit-json :trusted)))
(check "string με \" → escaped (καμία διαφυγή JSON)"
       (string= "\"a\\\"b\"" (%cockpit-json "a\"b")))

(format t "~%== auth με LAWMAX_CREATOR_TOKEN (η ΜΙΑ έδρα) ==~%")
(sb-posix:setenv "LAWMAX_CREATOR_TOKEN" "s3cr3t" 1)
(check "token set, χωρίς key → 403"
       (= 403 (st (%cockpit-handler (req "/api/pending" :headers *ok-headers*)))))
(check "token set, λάθος key → 403"
       (= 403 (st (%cockpit-handler (req "/api/pending" :query '(("key" . "wrong"))
                                         :headers *ok-headers*)))))
(check "token set, σωστό key → 200"
       (= 200 (st (%cockpit-handler (req "/api/pending" :query '(("key" . "s3cr3t"))
                                         :headers *ok-headers*)))))
(ignore-errors (sb-posix:unsetenv "LAWMAX_CREATOR_TOKEN"))

(format t "~%== δημόσιο bind FAIL-CLOSED (verify V1) ==~%")
(sb-posix:setenv "COCKPIT_HOST" "0.0.0.0" 1)
;; μη-loopback bind χωρίς token/allowlist ⇒ ΑΡΝΗΣΗ ακόμη και με header+Host (το
;; custom header ΔΕΝ είναι auth: ένας curl το θέτει ελεύθερα).
(check "0.0.0.0 χωρίς token/allowlist → 403 (καμία δημόσια θύρα ανοιχτή)"
       (= 403 (st (%cockpit-handler
                   (req "/api/pending"
                        :headers '(("host" . "any.example") ("x-lawmax-cockpit" . "1")))))))
(sb-posix:setenv "LAWMAX_CREATOR_TOKEN" "s3cr3t" 1)
(check "0.0.0.0 + token + σωστό key → 200 (το token αυθεντικοποιεί)"
       (= 200 (st (%cockpit-handler
                   (req "/api/pending" :query '(("key" . "s3cr3t"))
                        :headers '(("host" . "any.example") ("x-lawmax-cockpit" . "1")))))))
(check "0.0.0.0 + token + λάθος key → 403"
       (= 403 (st (%cockpit-handler
                   (req "/api/pending" :query '(("key" . "no"))
                        :headers '(("host" . "any.example") ("x-lawmax-cockpit" . "1")))))))
(ignore-errors (sb-posix:unsetenv "LAWMAX_CREATOR_TOKEN"))
(sb-posix:setenv "COCKPIT_ALLOWED_HOSTS" "cockpit.internal," 1)   ; trailing comma (verify V2)
(check "allowlist: δηλωμένο host → 200"
       (= 200 (st (%cockpit-handler
                   (req "/api/pending"
                        :headers '(("host" . "cockpit.internal") ("x-lawmax-cockpit" . "1")))))))
(check "allowlist: άλλο host → 403"
       (= 403 (st (%cockpit-handler
                   (req "/api/pending"
                        :headers '(("host" . "evil.com") ("x-lawmax-cockpit" . "1")))))))
(check "allowlist: κενή καταχώρηση ΔΕΝ ανοίγει σε άδειο Host (V2)"
       (= 403 (st (%cockpit-handler
                   (req "/api/pending" :headers '(("x-lawmax-cockpit" . "1")))))))
(ignore-errors (sb-posix:unsetenv "COCKPIT_ALLOWED_HOSTS"))
(ignore-errors (sb-posix:unsetenv "COCKPIT_HOST"))

(format t "~%== corrupt queue ⇒ FAIL-CLOSED, όχι σιωπηλά άδειο (verify V3) ==~%")
(with-open-file (s "/tmp/cockpit-test-queue.sexp" :direction :output :if-exists :supersede
                     :if-does-not-exist :create)
  (write-string "(:this is ( unbalanced" s))
(check "αλλοιωμένο REVIEW_QUEUE_FILE ⇒ /api/pending → 500 (όχι 200 άδειο)"
       (= 500 (st (%cockpit-handler (req "/api/pending" :headers *ok-headers*)))))
(ignore-errors (delete-file "/tmp/cockpit-test-queue.sexp"))

(format t "~%== hybrid: ensure-artifacts γράφει το corpus.jsonl όταν λείπει, ΠΟΤΕ overwrite ==~%")
;; (α) υπάρχον αρχείο ⇒ ο provider ΔΕΝ καλείται (golden άθικτο)
(let* ((dir (merge-pathnames "output/__cockpit_test_corpus__/" (uiop:getcwd)))
       (path (merge-pathnames "corpus.jsonl" dir)))
  (ensure-directories-exist path)
  (with-open-file (s path :direction :output :if-exists :supersede :if-does-not-exist :create)
    (write-string "GOLDEN" s))
  (%cockpit-ensure-corpus-artifacts
   (list (cons "__cockpit_test_corpus__"
               (lambda () (error "ο provider κλήθηκε ενώ υπήρχε golden αρχείο!")))))
  (check "υπάρχον corpus.jsonl ΔΕΝ ξαναγράφεται (golden άθικτο)"
         (string= "GOLDEN" (with-open-file (s path) (read-line s))))
  (ignore-errors (delete-file path))
  (ignore-errors (uiop:delete-empty-directory dir)))
;; (β) λείπον αρχείο ⇒ γράφεται από emit-corpus-jsonl, με το «number» που διαβάζει το /ask
(let* ((mp (find-symbol "MAKE-PROVISION" :orchestrator.consolidation))
       (md (find-symbol "MAKE-LEGAL-DOCUMENT" :orchestrator.consolidation))
       (doc (funcall md :id "tc" :title "Δοκιμαστικός" :language "el"
                     :provisions (list (funcall mp :eid "art_288" :kind :article
                                                :num "288" :heading "Καλή πίστη"
                                                :text "Ο οφειλέτης εκπληρώνει με καλή πίστη."))))
       (dir (merge-pathnames "output/__cockpit_test_corpus__/" (uiop:getcwd)))
       (path (merge-pathnames "corpus.jsonl" dir)))
  (ignore-errors (delete-file path))
  (%cockpit-ensure-corpus-artifacts (list (cons "__cockpit_test_corpus__" (lambda () doc))))
  (check "λείπον corpus.jsonl γράφεται με number 288 (το /ask θα το βρει)"
         (and (probe-file path)
              (with-open-file (s path)
                (loop for line = (read-line s nil nil) while line
                      thereis (search "\"number\":\"288\"" line)))))
  (ignore-errors (delete-file path))
  (ignore-errors (uiop:delete-empty-directory dir)))

(format t "~%========================================~%")
(format t "COCKPIT tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
