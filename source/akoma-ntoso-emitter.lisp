;;;; source/akoma-ntoso-emitter.lisp
;;;; ============================================================================
;;;; AKOMA NTOSO (LegalDocML) EMITTER
;;;; ============================================================================
;;;;
;;;; Serializes a consolidated legal document (orchestrator.consolidation:
;;;; legal-document / provision tree) into Akoma Ntoso 3.0 — the OASIS
;;;; LegalDocML standard and the lingua franca of machine-readable legislation
;;;; (EUR-Lex, legislation.gov.uk, Normattiva, ...). This is the structured
;;;; format AI systems and legal tooling expect, and the one the corpus
;;;; previously did not speak.
;;;;
;;;; What it emits:
;;;;   - <akomaNtoso>/<act> with FRBR Work/Expression/Manifestation metadata
;;;;   - <meta>/<lifecycle> with one <eventRef> per distinct amending act,
;;;;     derived from the consolidation provenance carried on each provision
;;;;   - <body> with hierarchical elements (article/paragraph/point) carrying
;;;;     stable eIds. Repealed provisions get status="repealed"; amended or
;;;;     inserted provisions get @refersTo pointing at the amending event.
;;;;
;;;; Deterministic: provisions and events are emitted in document order; no
;;;; wall-clock is read (dates come from the document / caller).
;;;;
;;;; Dependencies: pure Common Lisp.
;;;; ============================================================================

(defpackage :orchestrator.akoma-ntoso
  (:use :cl)
  (:import-from :orchestrator.consolidation
                #:legal-document-id #:legal-document-title #:legal-document-language
                #:legal-document-provisions
                #:provision-eid #:provision-kind #:provision-num #:provision-heading
                #:provision-text #:provision-children
                #:provision-status #:provision-source-act #:provision-source-date)
  (:export #:emit-akoma-ntoso))

(in-package :orchestrator.akoma-ntoso)

(defparameter +akn-namespace+ "http://docs.oasis-open.org/legaldocml/ns/akn/3.0")

;;; ============================================================================
;;; XML ESCAPING
;;; ============================================================================

(defun xml-text-escape (string)
  (with-output-to-string (s)
    (loop for ch across (or string "")
          do (case ch
               (#\& (write-string "&amp;" s))
               (#\< (write-string "&lt;" s))
               (#\> (write-string "&gt;" s))
               (t (write-char ch s))))))

(defun xml-attr-escape (string)
  (with-output-to-string (s)
    (loop for ch across (or string "")
          do (case ch
               (#\& (write-string "&amp;" s))
               (#\< (write-string "&lt;" s))
               (#\> (write-string "&gt;" s))
               (#\" (write-string "&quot;" s))
               (t (write-char ch s))))))

(defun indent (depth) (make-string (* 2 depth) :initial-element #\Space))

;;; ============================================================================
;;; ELEMENT MAPPING
;;; ============================================================================

(defun akn-element-name (kind)
  "Map a provision kind to its Akoma Ntoso hierarchy element name."
  (ecase kind
    (:article "article")
    (:paragraph "paragraph")
    (:point "point")
    (:subpoint "point")
    (:section "section")
    (:chapter "chapter")
    (otherwise "hcontainer")))

(defun event-eid (act-id)
  (format nil "e_~A" act-id))

;;; ============================================================================
;;; LIFECYCLE: collect distinct amending events from provenance
;;; ============================================================================

(defun collect-events (document)
  "Return distinct (act-id . date) amending events found on provisions, in a
   deterministic order (by date, then act id)."
  (let ((seen (make-hash-table :test 'equal))
        (events '()))
    (labels ((walk (p)
               (let ((act (provision-source-act p)))
                 (when (and act (not (gethash act seen)))
                   (setf (gethash act seen) t)
                   (push (cons act (provision-source-date p)) events)))
               (dolist (c (provision-children p)) (walk c))))
      (dolist (r (legal-document-provisions document)) (walk r)))
    (sort events (lambda (a b)
                   (let ((da (or (cdr a) "")) (db (or (cdr b) "")))
                     (cond ((string< da db) t)
                           ((string> da db) nil)
                           (t (string< (car a) (car b)))))))))

;;; ============================================================================
;;; BODY: provision tree
;;; ============================================================================

(defun emit-provision (p depth out)
  (let* ((el (akn-element-name (provision-kind p)))
         (status (provision-status p))
         (repealed (eq status :repealed))
         (act (provision-source-act p))
         (ind (indent depth)))
    (format out "~A<~A eId=\"~A\"" ind el (xml-attr-escape (provision-eid p)))
    (when repealed
      (format out " status=\"repealed\""))
    (when (and act (member status '(:amended :inserted :repealed)))
      (format out " refersTo=\"#~A\"" (xml-attr-escape (event-eid act))))
    (format out ">~%")
    (when (provision-num p)
      (format out "~A  <num>~A</num>~%" ind (xml-text-escape (provision-num p))))
    (when (provision-heading p)
      (format out "~A  <heading>~A</heading>~%" ind (xml-text-escape (provision-heading p))))
    (cond
      ((provision-children p)
       (dolist (c (provision-children p)) (emit-provision c (1+ depth) out)))
      ((provision-text p)
       (format out "~A  <content>~%" ind)
       (format out "~A    <p>~A</p>~%" ind (xml-text-escape (provision-text p)))
       (format out "~A  </content>~%" ind)))
    (format out "~A</~A>~%" ind el)))

;;; ============================================================================
;;; META: FRBR identification + lifecycle
;;; ============================================================================

(defun emit-meta (document out &key country author-href work-date source)
  (let* ((id (or (legal-document-id document) "act"))
         (lang (or (legal-document-language document) "el"))
         (work-uri (format nil "/akn/~A/act/~A" country id))
         (expr-uri (format nil "~A/~A@" work-uri lang))
         (manif-uri (format nil "~A/~A@/main.xml" work-uri lang))
         (events (collect-events document)))
    (format out "    <meta>~%")
    (format out "      <identification source=\"~A\">~%" (xml-attr-escape source))
    ;; FRBRWork
    (format out "        <FRBRWork>~%")
    (format out "          <FRBRthis value=\"~A/main\"/>~%" (xml-attr-escape work-uri))
    (format out "          <FRBRuri value=\"~A\"/>~%" (xml-attr-escape work-uri))
    (format out "          <FRBRdate date=\"~A\" name=\"generation\"/>~%" (xml-attr-escape work-date))
    (format out "          <FRBRauthor href=\"~A\"/>~%" (xml-attr-escape author-href))
    (format out "          <FRBRcountry value=\"~A\"/>~%" (xml-attr-escape country))
    (format out "        </FRBRWork>~%")
    ;; FRBRExpression
    (format out "        <FRBRExpression>~%")
    (format out "          <FRBRthis value=\"~A/main\"/>~%" (xml-attr-escape expr-uri))
    (format out "          <FRBRuri value=\"~A\"/>~%" (xml-attr-escape expr-uri))
    (format out "          <FRBRdate date=\"~A\" name=\"generation\"/>~%" (xml-attr-escape work-date))
    (format out "          <FRBRauthor href=\"~A\"/>~%" (xml-attr-escape author-href))
    (format out "          <FRBRlanguage language=\"~A\"/>~%" (xml-attr-escape lang))
    (format out "        </FRBRExpression>~%")
    ;; FRBRManifestation
    (format out "        <FRBRManifestation>~%")
    (format out "          <FRBRthis value=\"~A\"/>~%" (xml-attr-escape manif-uri))
    (format out "          <FRBRuri value=\"~A\"/>~%" (xml-attr-escape manif-uri))
    (format out "          <FRBRdate date=\"~A\" name=\"generation\"/>~%" (xml-attr-escape work-date))
    (format out "          <FRBRauthor href=\"~A\"/>~%" (xml-attr-escape author-href))
    (format out "          <FRBRformat value=\"application/akn+xml\"/>~%")
    (format out "        </FRBRManifestation>~%")
    (format out "      </identification>~%")
    ;; Lifecycle (one event per amending act found in the consolidation)
    (when events
      (format out "      <lifecycle source=\"~A\">~%" (xml-attr-escape source))
      (dolist (e events)
        (format out "        <eventRef eId=\"~A\" date=\"~A\" source=\"~A\" type=\"amendment\"/>~%"
                (xml-attr-escape (event-eid (car e)))
                (xml-attr-escape (or (cdr e) ""))
                (xml-attr-escape source)))
      (format out "      </lifecycle>~%"))
    (format out "    </meta>~%")))

;;; ============================================================================
;;; PUBLIC ENTRY POINT
;;; ============================================================================

(defun emit-akoma-ntoso (document &key (country "gr")
                                       (author-href "#stavropoulosLaw")
                                       (work-date (error "emit-akoma-ntoso: :work-date ΑΠΑΙΤΕΙΤΑΙ — καμία φαβρικαρισμένη «1970-01-01» ημερομηνία στο FRBRdate αυθεντικού Akoma Ntoso [0092/silent-fallback]"))
                                       (source "#stavropoulosLaw"))
  "Serialize DOCUMENT (a consolidation legal-document) to an Akoma Ntoso 3.0
   <act> XML string. Deterministic for a given document and arguments."
  (with-output-to-string (out)
    (format out "<?xml version=\"1.0\" encoding=\"UTF-8\"?>~%")
    (format out "<akomaNtoso xmlns=\"~A\">~%" +akn-namespace+)
    (format out "  <act name=\"act\">~%")
    (emit-meta document out :country country :author-href author-href
                            :work-date work-date :source source)
    (when (legal-document-title document)
      (format out "    <preface>~%")
      (format out "      <p class=\"docTitle\"><docTitle>~A</docTitle></p>~%"
              (xml-text-escape (legal-document-title document)))
      (format out "    </preface>~%"))
    (format out "    <body>~%")
    (dolist (article (legal-document-provisions document))
      (emit-provision article 3 out))
    (format out "    </body>~%")
    (format out "  </act>~%")
    (format out "</akomaNtoso>~%")))
