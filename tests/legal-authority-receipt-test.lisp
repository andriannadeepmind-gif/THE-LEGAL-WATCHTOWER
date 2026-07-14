;;;; tests/legal-authority-receipt-test.lisp
;;;; ============================================================================
;;;; [0088] Φ4α — LegalAuthorityReceipt: receipt-id δεσμεύει ΟΛΟΚΛΗΡΟ το receipt
;;;; (PCL-01 νεκρό στο νέο μονοπάτι), γενεαλογία ΠΛΗΡΗΣ και replay-ελεγμένη
;;;; (PROV-01 νεκρό), verify fail-closed σε ΚΑΘΕ αλλοίωση, 0 verification
;;;; failures σε ΟΛΟΚΛΗΡΟ σώμα, trust-status ΠΟΤΕ σιωπηλό.
;;;; ============================================================================

(in-package :orchestrator.cli)

(defvar *lr-pass* 0)
(defvar *lr-fail* 0)

(defmacro lr-check (name form)
  `(handler-case
       (if ,form
           (progn (incf *lr-pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *lr-fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e)
       (incf *lr-fail*)
       (format t "  FAIL ~A  (error: ~A)~%" ,name e))))

(format t "~%── [0088] Φ4α LEGAL AUTHORITY RECEIPT ──~%")

;; καθαρό store + φρέσκο import Συντάγματος (το gated περιβάλλον είναι εφήμερο)
(let ((dir (orchestrator.paths:institution-dir "deployment/data/version-graph/")))
  (when (probe-file dir)
    (uiop:delete-directory-tree (uiop:ensure-directory-pathname dir)
                                :validate (constantly t) :if-does-not-exist :ignore)))
(defparameter *lr-graph* (import-corpus->graph! "syntagma"))
(defparameter *lr-today* (subseq (orchestrator.journal:iso-now) 0 10))
(defparameter *lr-now* "9999-12-31T23:59:59Z")

;; source-artifact από το prov stamp (η αλήθεια της πηγής μέσα στο receipt)
(defparameter *lr-src*
  (let* ((jp (provenance-checked-json-source "syntagma"))
         (prov (jonathan:parse
                (uiop:read-file-string (format nil "~A.prov.json" (namestring jp))
                                       :external-format :utf-8) :as :alist)))
    (list (cons "content_sha256" (cdr (assoc "content_sha256" prov :test #'string=)))
          (cons "source_digest" (cdr (assoc "source_digest" prov :test #'string=))))))

;;; ① Receipts για ΟΛΟ το σώμα στη σημερινή τομή — 0 verification failures
(multiple-value-bind (receipts uncertain)
    (orchestrator.legal-receipt:build-receipts-for-graph
     *lr-graph* :source-artifact *lr-src* :valid-at *lr-today* :known-at *lr-now*)
  (defparameter *lr-receipts* receipts)
  (lr-check (format nil "① 124 receipts στη σημερινή τομή (βγήκαν ~D, αβέβαια ~D)"
                    (length receipts) (length uncertain))
            (and (= 124 (length receipts)) (null uncertain)))
  (let ((failures '()))
    (dolist (r receipts)
      (multiple-value-bind (ok why) (orchestrator.legal-receipt:verify-receipt *lr-graph* r)
        (unless ok (push (list (orchestrator.legal-receipt:lr-provision-id r) why) failures))))
    (dolist (f (subseq failures 0 (min 5 (length failures))))
      (format t "    ✗ ~S~%" f))
    (lr-check "①β verify-receipt ΚΑΘΕ receipt: receipt_verification_failures = 0"
              (null failures))))

;;; ② Το receipt-id δεσμεύει ΟΛΑ τα πεδία — κάθε αλλοίωση ⇒ FAIL με λόγο
(defun lr-tamper (mutator)
  (let ((r (orchestrator.legal-receipt:build-receipt
            *lr-graph*
            (orchestrator.version-graph:version-at *lr-graph* "gr/syntagma#art:16"
                                                   :valid-at *lr-today* :known-at *lr-now*)
            :source-artifact *lr-src*)))
    (funcall mutator r)
    (multiple-value-bind (ok why) (orchestrator.legal-receipt:verify-receipt *lr-graph* r)
      (declare (ignore why)) (not ok))))

(lr-check "② αλλαγμένο provision-id ⇒ FAIL (relabeling αδύνατο — θάνατος PCL-01)"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-provision-id r)
                                       "gr/syntagma#art:17"))))
(lr-check "②β αλλαγμένο valid-from ⇒ FAIL (χρονική παραχάραξη αδύνατη)"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-valid-from r)
                                       "1975-06-11"))))
(lr-check "②γ αλλαγμένο content-hash ⇒ FAIL"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-content-hash r)
                                       (make-string 64 :initial-element #\0)))))
(lr-check "②δ παραποιημένη γενεαλογία (ψεύτικος κρίκος) ⇒ FAIL (last-touch/πλαστή ιστορία αδύνατη — θάνατος PROV-01)"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-genealogy r)
                                       (cons "fake-edge-id"
                                             (orchestrator.legal-receipt:lr-genealogy r))))))
(lr-check "②ε αλλαγμένο trust-status (unsigned→signed) ⇒ FAIL (καμία σιωπηλή αναβάθμιση)"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-trust-status r) :signed))))
(lr-check "②στ αλλαγμένο source-artifact ⇒ FAIL (η πηγή ΜΕΣΑ στη δέσμευση — AUTH-02 ροή)"
          (lr-tamper (lambda (r) (setf (orchestrator.legal-receipt::lr-source-artifact r)
                                       '(("content_sha256" . "sha256:ξένο"))))))

;;; ③ Ντετερμινισμός + γενεαλογία με πραγματική ακμή
(lr-check "③ ίδιο version ⇒ ίδιο receipt-id (αναπαραγωγιμότητα)"
          (let ((v (orchestrator.version-graph:version-at *lr-graph* "gr/syntagma#art:2"
                                                          :valid-at *lr-today* :known-at *lr-now*)))
            (equal (orchestrator.legal-receipt:lr-receipt-id
                    (orchestrator.legal-receipt:build-receipt *lr-graph* v :source-artifact *lr-src*))
                   (orchestrator.legal-receipt:lr-receipt-id
                    (orchestrator.legal-receipt:build-receipt *lr-graph* v :source-artifact *lr-src*)))))
(lr-check "③β μετά από admit-edge!: γενεαλογία = (bootstrap, edge-id) — ΠΛΗΡΗΣ αλυσίδα στο receipt"
          (let* ((pid "gr/syntagma#art:2")
                 (v (orchestrator.version-graph:version-at *lr-graph* pid
                                                           :valid-at *lr-today* :known-at *lr-now*)))
            (multiple-value-bind (edge vs)
                (orchestrator.version-graph:admit-edge!
                 *lr-graph*
                 (orchestrator.version-graph:make-edge-spec
                  :op :replace :target pid
                  :from-versions (list (orchestrator.version-graph:tv-version-hash v))
                  :to-specs (list (orchestrator.version-graph:make-version-spec
                                   :provision-id pid :text "Δοκιμαστική νέα διατύπωση."
                                   :valid-from "2030-01-01" :assurance :extracted-verified))
                  :act-ref "test/act" :act-internal-seq '(1 1)
                  :enacted "2029-12-01" :effective "2030-01-01" :fek-date "2029-12-01"))
              (let ((r (orchestrator.legal-receipt:build-receipt *lr-graph* (first vs)
                                                                 :source-artifact *lr-src*)))
                (and (= 2 (length (orchestrator.legal-receipt:lr-genealogy r)))
                     (equal (orchestrator.version-graph:ae-edge-id edge)
                            (second (orchestrator.legal-receipt:lr-genealogy r)))
                     (multiple-value-bind (ok why)
                         (orchestrator.legal-receipt:verify-receipt *lr-graph* r)
                       (declare (ignore why)) ok))))))

;;; ④ trust-status: γεννιέται ΡΗΤΑ :unsigned-explicit — ποτέ σιωπηλό/ψευδές :signed
(lr-check "④ κάθε receipt γεννιέται :unsigned-explicit (η υπογραφή είναι πράξη του attest, όχι default)"
          (every (lambda (r) (eq :unsigned-explicit (orchestrator.legal-receipt:lr-trust-status r)))
                 *lr-receipts*))

;;; ⑤ [Φ4β] PCL-03 — οι σιωπηλές υποβαθμίσεις είναι ΝΕΚΡΕΣ (locks)
(lr-check "⑤ %pcl-signing-material ΧΩΡΙΣ κλειδιά/χωρίς παράκαμψη ⇒ ΣΦΑΛΜΑ (όχι σιωπηλό unsigned)"
          (progn (sb-posix:unsetenv "PCL_SIGNING_KEY")
                 (sb-posix:unsetenv "PCL_PUBLIC_KEY")
                 (sb-posix:unsetenv "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS")
                 (handler-case (progn (orchestrator.cli::%pcl-signing-material) nil)
                   (error () t))))
(lr-check "⑤β με ΡΗΤΟ ORCHESTRATOR_ALLOW_DEGRADED_PROOFS=1 ⇒ (values NIL NIL) — δηλωμένη υποβάθμιση"
          (unwind-protect
               (progn (sb-posix:setenv "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS" "1" 1)
                      (multiple-value-bind (priv jwk) (orchestrator.cli::%pcl-signing-material)
                        (and (null priv) (null jwk))))
            (sb-posix:unsetenv "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS")))
(lr-check "⑤γ corpus-proof.json: ΡΗΤΟ trust_status — unsigned ⇒ «unsigned-explicit», signed ⇒ «signed»"
          (let ((u (orchestrator.proof-carrying:corpus-proof-json "r00t" 3 :anchored-at "2026-01-01T00:00:00Z"))
                (s (orchestrator.proof-carrying:corpus-proof-json "r00t" 3 :anchored-at "2026-01-01T00:00:00Z"
                                                                  :signature "sig")))
            (and (search "\"trust_status\":\"unsigned-explicit\"" u)
                 (search "\"trust_status\":\"signed\"" s))))
(lr-check "⑤δ source-scan: το ignore-errors στο %emit-corpus-proofs και το (error () nil) στο anchor ΠΕΘΑΝΑΝ"
          (let ((site (uiop:read-file-string
                       (orchestrator.paths:institution-dir "source/static-site.lisp")
                       :external-format :utf-8))
                (main (uiop:read-file-string
                       (orchestrator.paths:institution-dir "systems/orchestrator-cli/main.lisp")
                       :external-format :utf-8)))
            (flet ((defun-body (src name)
                     (let* ((start (search (format nil "(defun ~A" name) src))
                            (end (search "(defun " src :start2 (1+ start))))
                       (subseq src start (or end (length src))))))
              (and (not (search "(ignore-errors" (defun-body site "%emit-corpus-proofs")))
                   (not (search "(error () nil)" (defun-body main "%corpus-anchor-plist")))
                   (search "ORCHESTRATOR_ALLOW_DEGRADED_PROOFS" (defun-body main "%pcl-signing-material"))))))

(format t "~%========================================~%")
(format t "LEGAL-AUTHORITY-RECEIPT [0088 Φ4]: ~D passed, ~D failed~%" *lr-pass* *lr-fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *lr-fail*) 0 1))
