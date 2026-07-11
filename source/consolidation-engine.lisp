;;;; source/consolidation-engine.lisp
;;;; ============================================================================
;;;; LEGAL CONSOLIDATION ENGINE
;;;; ============================================================================
;;;;
;;;; The heart of "codification": given a base legal text and a chronologically
;;;; ordered set of amending acts (each carrying fine-grained textual
;;;; operations), produce the CONSOLIDATED, in-force version of the text as it
;;;; stands on a given date.
;;;;
;;;; This is what lets an AI answer "what does Article 5 say TODAY (after all
;;;; amendments)?" rather than only "Article 5 was amended by law X".
;;;;
;;;; Design guarantees:
;;;;   - Provision-level granularity (article / paragraph / point), addressed by
;;;;     an Akoma-Ntoso-style eId (e.g. "art_5__para_2__point_a").
;;;;   - Point-in-time: consolidate as-of any date.
;;;;   - Deterministic: deep copy of the base + a total order over operations
;;;;     means identical input -> identical output. No wall-clock, no hashing of
;;;;     mutable state, no nondeterministic traversal.
;;;;   - Provenance: every provision records which act last changed it and when,
;;;;     so the consolidated output is self-describing (eli:amended_by chains).
;;;;
;;;; Dependencies: pure Common Lisp only. ISO-8601 date strings ("YYYY-MM-DD")
;;;; are compared lexically, which coincides with chronological order, so no
;;;; date library is required and comparison is total and deterministic.
;;;; ============================================================================

(defpackage :orchestrator.consolidation
  (:use :cl)
  (:export
   ;; Data model
   #:provision #:make-provision #:provision-p
   #:provision-eid #:provision-kind #:provision-num #:provision-heading
   #:provision-text #:provision-children
   #:provision-status #:provision-source-act #:provision-source-date
   #:legal-document #:make-legal-document #:legal-document-p
   #:legal-document-id #:legal-document-title #:legal-document-language
   #:legal-document-provisions
   #:amending-act #:make-amending-act #:amending-act-p
   #:amending-act-id #:amending-act-fek #:amending-act-enacted
   #:amending-act-effective #:amending-act-recorded #:amending-act-operations
   ;; Tree utilities
   #:find-provision #:copy-document
   ;; Engine
   #:consolidate #:consolidation-error
   ;; Level-2 replay ledger (provably-correct consolidation)
   #:*consolidation-ledger* #:record-step
   #:build-consolidation-ledger #:verify-consolidation-ledger
   #:consolidation-ledger #:consolidation-ledger-p #:amendment-step
   #:ledger-doc-id #:ledger-as-of #:ledger-base-hash #:ledger-result-hash #:ledger-steps
   #:step-index #:step-act-id #:step-fek #:step-effective #:step-op-kind
   #:step-target #:step-before-hash #:step-after-hash
   #:ledger->plist #:step->plist
   ;; Rendering
   #:render-consolidated-text #:render-consolidation-provenance-ttl))

(in-package :orchestrator.consolidation)

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition consolidation-error (error)
  ((message :initarg :message :reader consolidation-error-message)
   (act     :initarg :act     :reader consolidation-error-act :initform nil)
   (op      :initarg :op      :reader consolidation-error-op  :initform nil))
  (:report (lambda (c stream)
             (format stream "Consolidation error: ~A~@[ (act ~A)~]~@[ op ~S~]"
                     (consolidation-error-message c)
                     (let ((a (consolidation-error-act c)))
                       (and a (amending-act-id a)))
                     (consolidation-error-op c)))))

;;; ============================================================================
;;; DATA MODEL
;;; ============================================================================

(defstruct (provision (:copier nil))
  "A single legal provision node (article, paragraph, point, ...).

   EID is a stable Akoma-Ntoso-style element identifier, unique within a
   document, e.g. \"art_5\", \"art_5__para_2\", \"art_5__para_2__point_a\".

   STATUS / SOURCE-ACT / SOURCE-DATE carry consolidation provenance:
     :original  - present in the base text, never amended
     :amended   - text or subtree changed by an amending act
     :inserted  - added by an amending act
     :repealed  - removed from the in-force text by an amending act
                  (kept in the tree so history / point-in-time stay answerable)"
  (eid      nil :type (or null string))
  (kind     :article :type keyword)
  (num      nil :type (or null string))
  (heading  nil :type (or null string))
  (text     nil :type (or null string))
  (children nil :type list)
  (status      :original :type keyword)
  (source-act  nil :type (or null string))
  (source-date nil :type (or null string)))

(defstruct (legal-document (:copier nil))
  "An ordered collection of top-level provisions (articles) plus identity."
  (id         nil :type (or null string))
  (title      nil :type (or null string))
  (language   "el" :type string)
  (provisions nil :type list))

(defstruct (amending-act (:copier nil))
  "An act that amends a base text.

   ΔΙΤΕΜΠΟΡΙΚΟΙ ΑΞΟΝΕΣ (P1.4 [0054]#7, θεμέλιο Ω2):
     EFFECTIVE  = valid-time: πότε ΙΣΧΥΕΙ η τροπολογία (ELI date_applicability)·
                  οδηγεί το point-in-time consolidation και τη total order.
     ENACTED    = πότε ΨΗΦΙΣΤΗΚΕ (ΦΕΚ).
     RECORDED   = transaction-time: πότε ΜΑΘΑΜΕ/εισήχθη το γεγονός στο σύστημα.
                  Ρητό record field «recorded_at» αν υπάρχει (η αληθινή στιγμή
                  γνώσης), αλλιώς σφραγίζεται από την ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ έδρα
                  χρόνου κατά την εισαγωγή — ο χρόνος γνώσης δεν χάνεται ποτέ.
   OPERATIONS είναι ordered list operation plists (βλ. APPLY-OPERATION)."
  (id         nil :type (or null string))
  (fek        nil :type (or null string))
  (enacted    nil :type (or null string))
  (effective  nil :type (or null string))
  (recorded   nil :type (or null string))
  (operations nil :type list))

;;; ============================================================================
;;; DEEP COPY (deterministic, structural)
;;; ============================================================================

(defun copy-provision-tree (p)
  "Recursively copy a provision and all of its children."
  (make-provision
   :eid (provision-eid p)
   :kind (provision-kind p)
   :num (provision-num p)
   :heading (provision-heading p)
   :text (provision-text p)
   :children (mapcar #'copy-provision-tree (provision-children p))
   :status (provision-status p)
   :source-act (provision-source-act p)
   :source-date (provision-source-date p)))

(defun copy-document (doc)
  "Deep copy a legal document so that consolidation never mutates the base."
  (make-legal-document
   :id (legal-document-id doc)
   :title (legal-document-title doc)
   :language (legal-document-language doc)
   :provisions (mapcar #'copy-provision-tree (legal-document-provisions doc))))

;;; ============================================================================
;;; TREE ADDRESSING (by eId)
;;; ============================================================================

(defun find-provision (node eid)
  "Find the provision with EID anywhere under NODE (a provision or document).
   Returns the provision, or NIL. Deterministic depth-first search."
  (labels ((walk (p)
             (cond ((string= (provision-eid p) eid) p)
                   (t (dolist (c (provision-children p) nil)
                        (let ((hit (walk c)))
                          (when hit (return hit))))))))
    (let ((roots (if (legal-document-p node)
                     (legal-document-provisions node)
                     (list node))))
      (dolist (r roots nil)
        (let ((hit (walk r)))
          (when hit (return hit)))))))

(defun find-parent-and-index (doc eid)
  "Return (values parent-list-holder index) locating EID's position.

   The 'holder' is either the document (for top-level articles) or the parent
   provision (for nested provisions). INDEX is the position within that holder's
   ordered child list. Returns (values nil nil) if EID is not found."
  ;; Top-level (articles live directly on the document).
  (let ((top (position eid (legal-document-provisions doc)
                       :key #'provision-eid :test #'string=)))
    (when top
      (return-from find-parent-and-index (values doc top))))
  ;; Nested: search every subtree for a child whose eId matches.
  (labels ((walk (parent)
             (let ((idx (position eid (provision-children parent)
                                  :key #'provision-eid :test #'string=)))
               (when idx
                 (return-from find-parent-and-index (values parent idx))))
             (dolist (c (provision-children parent))
               (walk c))))
    (dolist (r (legal-document-provisions doc))
      (walk r)))
  (values nil nil))

(defun holder-children (holder)
  "Read the ordered child list of a holder (document or provision)."
  (if (legal-document-p holder)
      (legal-document-provisions holder)
      (provision-children holder)))

(defun (setf holder-children) (new-children holder)
  "Write the ordered child list of a holder (document or provision)."
  (if (legal-document-p holder)
      (setf (legal-document-provisions holder) new-children)
      (setf (provision-children holder) new-children)))

;;; ============================================================================
;;; PROVENANCE STAMPING
;;; ============================================================================

(defun stamp-provenance (p act status)
  "Record that ACT changed provision P, setting STATUS and source metadata."
  (setf (provision-status p) status
        (provision-source-act p) (amending-act-id act)
        (provision-source-date p) (amending-act-effective act))
  p)

(defun stamp-subtree-inserted (p act)
  "Mark a freshly inserted subtree (and its descendants) as inserted by ACT,
   unless a descendant already carries explicit provenance."
  (when (eq (provision-status p) :original)
    (stamp-provenance p act :inserted))
  (dolist (c (provision-children p)) (stamp-subtree-inserted c act))
  p)

;;; ============================================================================
;;; OPERATIONS
;;; ============================================================================
;;;
;;; Each operation is a plist. Supported forms:
;;;
;;;   (:op :replace-text :target EID :text "new text")
;;;        Replace the textual content of an existing provision in place.
;;;
;;;   (:op :replace :target EID :node PROVISION)
;;;        Replace an entire provision subtree with PROVISION.
;;;
;;;   (:op :insert :parent EID :position POS :node PROVISION)
;;;        Insert PROVISION as a child of EID. POS is :start, :end, or
;;;        (:after EID-OF-SIBLING) / (:before EID-OF-SIBLING).
;;;        :parent may be :document to insert a top-level article.
;;;
;;;   (:op :repeal :target EID)
;;;        Mark a provision as repealed (removed from in-force text, retained
;;;        for history and point-in-time queries).
;;;
;;;   (:op :mark-amended :target EID)
;;;        Record that an act amended a provision WITHOUT changing its text.
;;;        Used when an amendment's metadata is known (which act touched which
;;;        article) but its consolidated text is not yet available, so that
;;;        provenance (eli:amended_by) is captured without fabricating text.
;;; ============================================================================

(defun %require (plist key act op)
  (let ((v (getf plist key 'absent)))
    (when (eq v 'absent)
      (error 'consolidation-error
             :message (format nil "operation missing required key ~S" key)
             :act act :op op))
    v))

(defun resolve-position (children pos act op)
  "Translate POS into an integer insertion index within CHILDREN."
  (cond
    ((eq pos :start) 0)
    ((or (eq pos :end) (null pos)) (length children))
    ((and (consp pos) (eq (first pos) :after))
     (let ((i (position (second pos) children
                        :key #'provision-eid :test #'string=)))
       (unless i
         (error 'consolidation-error
                :message (format nil ":after sibling ~S not found" (second pos))
                :act act :op op))
       (1+ i)))
    ((and (consp pos) (eq (first pos) :before))
     (let ((i (position (second pos) children
                        :key #'provision-eid :test #'string=)))
       (unless i
         (error 'consolidation-error
                :message (format nil ":before sibling ~S not found" (second pos))
                :act act :op op))
       i))
    (t (error 'consolidation-error
              :message (format nil "unknown :position ~S" pos)
              :act act :op op))))

(defun %target-missing (eid act op what)
  "Apply the operation's :if-missing policy when a target/parent is absent.
   :error (the default) signals; :skip is tolerated and the operation no-ops."
  (ecase (getf op :if-missing :error)
    (:skip :skip)
    (:error
     (error 'consolidation-error
            :message (format nil "~A target ~S not found" what eid)
            :act act :op op))))

(defun apply-operation (doc op act)
  "Apply a single amendment operation OP (from ACT) to document DOC in place.

   A missing target is handled per the op's :if-missing policy: :error (the
   default, used for explicit text-bearing operations where a missing target is
   a real defect) or :skip (used for operations auto-derived from amendment
   metadata, where the corpus may legitimately be a subset of all articles)."
  (let ((kind (getf op :op)))
    (ecase kind
      (:replace-text
       (let* ((eid (%require op :target act op))
              (target (find-provision doc eid)))
         (cond
           ((null target) (%target-missing eid act op "replace-text"))
           (t (setf (provision-text target) (%require op :text act op))
              (stamp-provenance target act :amended)))))

      (:replace
       (let ((eid (%require op :target act op)))
         (multiple-value-bind (holder idx) (find-parent-and-index doc eid)
           (cond
             ((null holder) (%target-missing eid act op "replace"))
             (t (let ((node (copy-provision-tree (%require op :node act op))))
                  ;; Preserve the original eId so cross-references remain valid.
                  (setf (provision-eid node) eid)
                  (stamp-provenance node act :amended)
                  (let ((kids (copy-list (holder-children holder))))
                    (setf (nth idx kids) node)
                    (setf (holder-children holder) kids))))))))

      (:insert
       (let* ((parent-eid (%require op :parent act op))
              (holder (if (eq parent-eid :document)
                          doc
                          (find-provision doc parent-eid))))
         (cond
           ((null holder) (%target-missing parent-eid act op "insert parent"))
           (t (let ((node (copy-provision-tree (%require op :node act op))))
                (stamp-subtree-inserted node act)
                (let* ((kids (copy-list (holder-children holder)))
                       (idx (resolve-position kids (getf op :position :end) act op)))
                  (setf (holder-children holder)
                        (append (subseq kids 0 idx) (list node) (subseq kids idx)))))))))

      (:repeal
       (let* ((eid (%require op :target act op))
              (target (find-provision doc eid)))
         (cond
           ((null target) (%target-missing eid act op "repeal"))
           (t (stamp-provenance target act :repealed)))))

      (:mark-amended
       (let* ((eid (%require op :target act op))
              (target (find-provision doc eid)))
         (cond
           ((null target) (%target-missing eid act op "mark-amended"))
           ;; Do not overwrite a stronger status (an already-repealed provision
           ;; stays repealed); only record amendment provenance.
           ((not (eq (provision-status target) :repealed))
            (stamp-provenance target act :amended))))))))

;;; ============================================================================
;;; REPLAY-LEDGER HOOK — provably-correct consolidation (Level 2)
;;;
;;; CONSOLIDATE is instrumented with a special-variable hook: when
;;; *CONSOLIDATION-LEDGER* is bound, every applied operation is recorded (act, op,
;;; before/after target text) so the whole consolidation can be REPLAYED and verified
;;; step by step. Unbound (the default) ⇒ ZERO behaviour change, determinism intact.
;;; The concrete ledger lives in consolidation-proof.lisp; the engine only owns the
;;; hook + a no-op RECORD-STEP, so it never depends on the proof layer.
;;; ============================================================================

(defvar *consolidation-ledger* nil
  "When bound to a ledger object, CONSOLIDATE records each applied operation for
   replay-verification. NIL (default) ⇒ no recording, no behaviour change.")

(defgeneric record-step (ledger act op before-text after-text)
  (:documentation "Record one applied amendment step into LEDGER. No-op by default so
   the engine carries the hook without depending on the concrete ledger.")
  (:method (ledger act op before-text after-text)
    (declare (ignore ledger act op before-text after-text))
    nil))

(defun %op-target-text (doc op)
  "Best-effort text of OP's target provision in DOC (NIL for structural ops with no
   single :target). Snapshots before/after state for the replay ledger."
  (let ((eid (getf op :target)))
    (when eid
      (let ((p (find-provision doc eid)))
        (and p (provision-text p))))))

;;; ============================================================================
;;; TOTAL ORDER OVER ACTS
;;; ============================================================================

(defun act-order-key (act)
  "Sort key giving a deterministic total order: effective date, then act id.
   ISO-8601 date strings sort lexically in chronological order."
  (cons (or (amending-act-effective act) "")
        (or (amending-act-id act) "")))

(defun act< (a b)
  (let ((ka (act-order-key a)) (kb (act-order-key b)))
    (cond ((string< (car ka) (car kb)) t)
          ((string> (car ka) (car kb)) nil)
          (t (string< (cdr ka) (cdr kb))))))

(defun select-acts (acts as-of-date)
  "Return ACTS effective on or before AS-OF-DATE (or all if NIL), in total order."
  (let ((selected (if as-of-date
                      (remove-if (lambda (a)
                                   (let ((e (amending-act-effective a)))
                                     (and e (string> e as-of-date))))
                                 acts)
                      (copy-list acts))))
    (sort (copy-list selected) #'act<)))

;;; ============================================================================
;;; CONSOLIDATION (public entry point)
;;; ============================================================================

(defun consolidate (document amendments &key as-of-date)
  "Produce the consolidated, in-force version of DOCUMENT after applying
   AMENDMENTS (a list of AMENDING-ACT) effective on or before AS-OF-DATE.

   When AS-OF-DATE is NIL, all amendments are applied (current consolidated
   text). The base DOCUMENT is never mutated; a fresh consolidated document is
   returned. Deterministic: same inputs always yield an identical result."
  (let ((consolidated (copy-document document)))
    (dolist (act (select-acts amendments as-of-date))
      (dolist (op (amending-act-operations act))
        (let ((before (and *consolidation-ledger* (%op-target-text consolidated op))))
          (apply-operation consolidated op act)
          (when *consolidation-ledger*
            (record-step *consolidation-ledger* act op before
                         (%op-target-text consolidated op))))))
    consolidated))

;;; ============================================================================
;;; RENDERING — plain text (in-force)
;;; ============================================================================

(defun render-consolidated-text (document &key include-repealed)
  "Render DOCUMENT as plain consolidated text. Repealed provisions are omitted
   unless INCLUDE-REPEALED is true (then marked as repealed)."
  (with-output-to-string (s)
    (labels ((emit (p depth)
               (let ((repealed (eq (provision-status p) :repealed)))
                 (when (or (not repealed) include-repealed)
                   (let ((indent (make-string (* 2 depth) :initial-element #\Space)))
                     (format s "~A~@[~A ~]~@[~A~]~@[ [ΚΑΤΑΡΓΗΘΗΚΕ]~]~%"
                             indent
                             (provision-num p)
                             (provision-heading p)
                             (and repealed include-repealed))
                     (when (and (provision-text p) (not repealed))
                       (format s "~A~A~%" indent (provision-text p)))
                     (dolist (c (provision-children p))
                       (emit c (1+ depth))))))))
      (dolist (article (legal-document-provisions document))
        (emit article 0)
        (terpri s)))))

;;; ============================================================================
;;; RENDERING — consolidation provenance (ELI-aligned Turtle)
;;; ============================================================================

(defun %ttl-escape (string)
  "Escape STRING for a double-quoted Turtle literal. Covers every character that
   would otherwise terminate the literal or break the grammar: quote, backslash,
   and the control chars newline/return/tab (a raw newline inside a \"...\" literal
   is itself a Turtle syntax error and an injection vector)."
  (with-output-to-string (s)
    (loop for ch across (or string "")
          do (case ch
               (#\" (write-string "\\\"" s))
               (#\\ (write-string "\\\\" s))
               (#\Newline (write-string "\\n" s))
               (#\Return (write-string "\\r" s))
               (#\Tab (write-string "\\t" s))
               (t (write-char ch s))))))

(defun %xsd-date-or-nil (string)
  "Return STRING iff it is a syntactically valid xsd:date (YYYY-MM-DD, optionally
   with a timezone), else NIL. Amendment metadata is untrusted; emitting it raw
   into `\"...\"^^xsd:date` lets a crafted value close the literal and inject
   arbitrary triples (e.g. forge eli:in_force). Validate before it is trusted as a
   typed literal."
  (when (and string
             (>= (length string) 10)
             (every (lambda (i)
                      (let ((c (char string i)))
                        (case i ((4 7) (char= c #\-)) (t (digit-char-p c)))))
                    '(0 1 2 3 4 5 6 7 8 9))
             ;; anything past the date core must be a legal tz suffix, never a quote
             (notany (lambda (c) (member c '(#\" #\\ #\Newline #\Return #\Tab)))
                     string))
    string))

(defun render-consolidation-provenance-ttl (document &key (base-uri "https://stavropouloslaw.com/eli"))
  "Emit ELI-aligned Turtle describing the consolidation status of each
   provision: in-force flag, date of applicability, and the amending act that
   produced the current text. Deterministic (provisions emitted in document
   order; no timestamps)."
  (with-output-to-string (s)
    (format s "@prefix eli: <http://data.europa.eu/eli/ontology#> .~%")
    (format s "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .~%")
    (format s "@prefix prov: <http://www.w3.org/ns/prov#> .~%~%")
    (labels ((emit (p)
               (let* ((eid (provision-eid p))
                      (uri (format nil "~A/~A" base-uri eid))
                      (repealed (eq (provision-status p) :repealed)))
                 (format s "<~A>~%" uri)
                 (format s "    eli:in_force ~A ;~%" (if repealed "false" "true"))
                 (let ((d (%xsd-date-or-nil (provision-source-date p))))
                   (when d
                     (format s "    eli:date_applicability \"~A\"^^xsd:date ;~%" d)))
                 (when (provision-source-act p)
                   (format s "    eli:~A <~A/act/~A> ;~%"
                           (if repealed "repealed_by" "amended_by")
                           base-uri (provision-source-act p)))
                 (format s "    prov:value \"~A\" .~%~%"
                         (%ttl-escape (case (provision-status p)
                                        (:original "original")
                                        (:amended "amended")
                                        (:inserted "inserted")
                                        (:repealed "repealed")
                                        (t "unknown"))))
                 (dolist (c (provision-children p)) (emit c)))))
      (dolist (article (legal-document-provisions document))
        (emit article)))))
