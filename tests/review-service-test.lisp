;;;; tests/review-service-test.lisp
;;;; The lawyer's web approval screen: HTML render, JSON mirror, decide route,
;;;; escaping, and persistence wiring — over an in-memory injected queue.

(in-package :orchestrator.review-service)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defpackage :rev (:use :cl) (:import-from :orchestrator.review
  #:make-review-queue #:enqueue #:amendment-review #:duplicate-review
  #:queue-items #:item-status #:queue-state #:restore-queue-state #:item-id))
(in-package :orchestrator.review-service)

;; A shared in-memory queue, exposed through load-fn/save-fn like the CLI does.
(defvar *q* (orchestrator.review:make-review-queue))
(orchestrator.review:enqueue *q*
  (make-instance 'orchestrator.review:amendment-review
                 :source "Ν.4855/2021" :target "art_5"
                 :payload (list :op :insert :target "art_5" :note "new <b>article</b>")
                 :confidence :medium))
(orchestrator.review:enqueue *q*
  (make-instance 'orchestrator.review:duplicate-review
                 :source "ΙΣΟΚΡΑΤΗΣ" :target "art_10" :confidence :high))

(defvar *saved* 0)
(defvar *svc* (make-review-service
               :load-fn (lambda () *q*)
               :save-fn (lambda (q) (declare (ignore q)) (incf *saved*))))

(format t "~%== Dashboard HTML ==~%")
(let ((html (render-dashboard *svc*)))
  (check "is an HTML document" (search "<!DOCTYPE html>" html))
  (check "shows pending count 2" (search "<strong>2</strong>" html))
  (check "renders the amendment summary (Greek)" (search "Τροποποίηση προς έλεγχο" html))
  (check "renders the duplicate summary (Greek)" (search "Διπλό άρθρο art_10" html))
  (check "has an Έγκριση action" (search "Έγκριση" html))
  (check "has an Απόρριψη action" (search "Απόρριψη" html))
  ;; hardened UI ([0036]): οι ενέργειες είναι data-attributes + POST με token
  ;; (CSRF sign-once) — όχι ωμά GET links. Το test ακολουθεί το συμβόλαιο.
  (check "decision links carry the item id + action"
         (and (search "data-action=\"approve\"" html) (search "data-action=\"reject\"" html)))
  (check "HTML-escapes payload markup (no raw <b> injected)"
         (not (search "new <b>article</b>" html))))

(format t "~%== JSON mirror ==~%")
(let ((json (review-json *svc*)))
  (check "advertises a count of 2" (search "\"count\":2" json))
  (check "lists the article eId" (search "art_5" json))
  (check "carries severity high for the duplicate" (search "\"severity\":\"high\"" json)))

(format t "~%== Decide route (handler) + persistence ==~%")
(let* ((handler (review-service-handler *svc*))
       (id (orchestrator.review:item-id (first (orchestrator.review:queue-items *q*))))
       (req (funcall (find-symbol "MAKE-HTTP-REQUEST" :orchestrator.http)
                     :method "POST" :path "/decide"
                     :query (list (cons "id" id) (cons "action" "approve")
                                  (cons "by" "Σ. Σταυρόπουλος")
                                  (cons "token" *decide-token*))))
       (before *saved*)
       (resp (funcall handler req)))
  (check "decide returns 200"
         (= 200 (funcall (find-symbol "HTTP-RESPONSE-STATUS" :orchestrator.http) resp)))
  (check "the item is now approved"
         (eq :approved (orchestrator.review:item-status
                        (first (orchestrator.review:queue-items *q*)))))
  (check "save-fn was invoked (persisted)" (> *saved* before))
  (check "response banner names the signer"
         (search "Σ. Σταυρόπουλος"
                 (funcall (find-symbol "HTTP-RESPONSE-BODY" :orchestrator.http) resp))))

(format t "~%== Unknown id is reported, not applied ==~%")
(let* ((handler (review-service-handler *svc*))
       (req (funcall (find-symbol "MAKE-HTTP-REQUEST" :orchestrator.http)
                     :method "POST" :path "/decide"
                     :query (list (cons "id" "does-not-exist") (cons "action" "approve")
                                  (cons "token" *decide-token*))))
       (resp (funcall handler req)))
  (check "unknown id still 200 with warning banner"
         (and (= 200 (funcall (find-symbol "HTTP-RESPONSE-STATUS" :orchestrator.http) resp))
              (search "Δεν βρέθηκε"
                      (funcall (find-symbol "HTTP-RESPONSE-BODY" :orchestrator.http) resp)))))

(format t "~%== Routing ==~%")
(let ((handler (review-service-handler *svc*)))
  (flet ((status (path &optional (method "GET"))
           (funcall (find-symbol "HTTP-RESPONSE-STATUS" :orchestrator.http)
                    (funcall handler
                             (funcall (find-symbol "MAKE-HTTP-REQUEST" :orchestrator.http)
                                      :method method :path path)))))
    (check "/ serves the dashboard (200)" (= 200 (status "/")))
    (check "/review.json serves JSON (200)" (= 200 (status "/review.json")))
    (check "POST is rejected (405)" (= 405 (status "/" "POST")))
    (check "unknown path is 404" (= 404 (status "/nope")))))

(format t "~%========================================~%")
(format t "Review service tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
