;;;; source/consolidation-proof.lisp
;;;; ============================================================================
;;;; LEVEL 2 — REPLAYABLE AMENDMENT PROOF (provably-correct consolidation)
;;;; ============================================================================
;;;;
;;;; The consolidation engine turns a base code + amending acts into the in-force
;;;; consolidated text. This module makes that transformation PROVABLE: as CONSOLIDATE
;;;; runs, every applied operation is recorded — which act (ΦΕΚ), which operation, the
;;;; SHA-256 of the target text BEFORE and AFTER — into a CONSOLIDATION-LEDGER. A third
;;;; party (or --verify) can then REPLAY the ledger on the base and confirm the exact
;;;; consolidated result. Truth derived by a verifiable function from the primary acts,
;;;; not asserted.
;;;;
;;;; NO DUPLICATION: the recording rides CONSOLIDATE itself via the engine's
;;;; *CONSOLIDATION-LEDGER* / RECORD-STEP hook — the driver loop (select-acts →
;;;; apply-operation) is never re-implemented. Hashing reuses the shared ironclad
;;;; primitive in the module's own "sha256:hex" format (same as the epistemic layer).
;;;;
;;;; CLOS: an AMENDMENT-STEP per operation and a CONSOLIDATION-LEDGER accumulate the
;;;; proof; RECORD-STEP specialises the engine's no-op generic; PRINT-OBJECT is
;;;; self-documenting. Deterministic: same inputs ⇒ identical ledger + hashes.

(in-package :orchestrator.consolidation)

;;; ----------------------------------------------------------------------------
;;; hash (shared ironclad primitive; "sha256:hex", uniform with the epistemic layer)
;;; ----------------------------------------------------------------------------

(defun %cp-sha256 (string)
  (format nil "sha256:~(~{~2,'0x~}~)"
          (coerce (ironclad:digest-sequence
                   :sha256 (babel:string-to-octets (or string "") :encoding :utf-8))
                  'list)))

;;; ----------------------------------------------------------------------------
;;; a single replayable step
;;; ----------------------------------------------------------------------------

(defclass amendment-step ()
  ((index       :initarg :index       :reader step-index       :initform 0)
   (act-id      :initarg :act-id      :reader step-act-id      :initform nil)
   (fek         :initarg :fek         :reader step-fek         :initform nil)
   (effective   :initarg :effective   :reader step-effective   :initform nil)
   (op-kind     :initarg :op-kind     :reader step-op-kind     :initform nil)
   (target      :initarg :target      :reader step-target      :initform nil)
   (before-hash :initarg :before-hash :reader step-before-hash :initform nil)
   (after-hash  :initarg :after-hash  :reader step-after-hash  :initform nil))
  (:documentation "One applied amendment operation, hashed before/after: applying
   OP-KIND (from ACT/ΦΕΚ) to the BEFORE text yields the AFTER text — a replayable unit."))

(defmethod print-object ((s amendment-step) stream)
  (print-unreadable-object (s stream :type t)
    (format stream "#~D ~A ~A~@[ @~A~]"
            (step-index s) (step-op-kind s) (or (step-act-id s) "?") (step-target s))))

;;; ----------------------------------------------------------------------------
;;; the ledger — the proof of one consolidation
;;; ----------------------------------------------------------------------------

(defclass consolidation-ledger ()
  ((doc-id      :initarg :doc-id      :reader   ledger-doc-id      :initform nil)
   (as-of       :initarg :as-of       :reader   ledger-as-of       :initform nil)
   (base-hash   :initarg :base-hash   :reader   ledger-base-hash   :initform nil)
   (result-hash :initarg :result-hash :accessor ledger-result-hash :initform nil)
   (steps       :initform nil         :accessor ledger-steps)   ; push-order → nreverse
   (counter     :initform 0           :accessor %ledger-counter))
  (:documentation "The replayable proof of a consolidation: base + result content
   hashes and the ordered amendment steps. Replaying the steps on the base reproduces
   the result — the provably-correct guarantee."))

(defun consolidation-ledger-p (x) (typep x 'consolidation-ledger))

(defmethod print-object ((l consolidation-ledger) stream)
  (print-unreadable-object (l stream :type t)
    (format stream "~A ~D steps~@[ @~A~]"
            (or (ledger-doc-id l) "?") (length (ledger-steps l)) (ledger-as-of l))))

;;; The concrete recorder — specialises the engine's no-op RECORD-STEP. Called by
;;; CONSOLIDATE for every operation when *CONSOLIDATION-LEDGER* is bound to a ledger.
(defmethod record-step ((ledger consolidation-ledger) act op before after)
  (push (make-instance 'amendment-step
                       :index       (incf (%ledger-counter ledger))
                       :act-id      (amending-act-id act)
                       :fek         (amending-act-fek act)
                       :effective   (amending-act-effective act)
                       :op-kind     (getf op :op)
                       :target      (or (getf op :target) (getf op :parent))
                       :before-hash (and before (%cp-sha256 before))
                       :after-hash  (and after  (%cp-sha256 after)))
        (ledger-steps ledger)))

;;; ----------------------------------------------------------------------------
;;; build + verify
;;; ----------------------------------------------------------------------------

(defun build-consolidation-ledger (document amendments &key as-of-date)
  "Consolidate DOCUMENT under AMENDMENTS while RECORDING every applied operation;
   return (values LEDGER RESULT-DOCUMENT). Reuses CONSOLIDATE via the
   *CONSOLIDATION-LEDGER* hook — the driver logic is never duplicated. Deterministic."
  (let* ((ledger (make-instance 'consolidation-ledger
                                :doc-id (legal-document-id document)
                                :as-of as-of-date
                                :base-hash (%cp-sha256
                                            (render-consolidated-text document
                                                                      :include-repealed t))))
         (*consolidation-ledger* ledger)
         (result (consolidate document amendments :as-of-date as-of-date)))
    (setf (ledger-result-hash ledger)
          (%cp-sha256 (render-consolidated-text result :include-repealed t)))
    (setf (ledger-steps ledger) (nreverse (ledger-steps ledger)))
    (values ledger result)))

(defun verify-consolidation-ledger (document amendments ledger &key as-of-date)
  "Independently REPLAY: re-consolidate DOCUMENT under AMENDMENTS and confirm the base
   hash, result hash and step count reproduce LEDGER. Returns (values ok-p reason).
   This is the provably-correct guarantee — base + recorded ops deterministically
   yield the consolidated text; a single divergence is caught."
  (let ((fresh (build-consolidation-ledger document amendments :as-of-date as-of-date)))
    (cond
      ((not (equal (ledger-base-hash fresh)   (ledger-base-hash ledger)))   (values nil :base-mismatch))
      ((not (equal (ledger-result-hash fresh) (ledger-result-hash ledger))) (values nil :result-mismatch))
      ((/= (length (ledger-steps fresh)) (length (ledger-steps ledger)))    (values nil :step-count-mismatch))
      (t (values t :ok)))))

;;; ----------------------------------------------------------------------------
;;; serialization (pure plists; JSON/RDF projection done by the proof-emission wiring)
;;; ----------------------------------------------------------------------------

(defun step->plist (s)
  (list :index (step-index s) :act (step-act-id s) :fek (step-fek s)
        :effective (step-effective s) :op (step-op-kind s) :target (step-target s)
        :before (step-before-hash s) :after (step-after-hash s)))

(defun ledger->plist (l)
  (list :doc-id (ledger-doc-id l) :as-of (ledger-as-of l)
        :base-hash (ledger-base-hash l) :result-hash (ledger-result-hash l)
        :step-count (length (ledger-steps l))
        :steps (mapcar #'step->plist (ledger-steps l))))
