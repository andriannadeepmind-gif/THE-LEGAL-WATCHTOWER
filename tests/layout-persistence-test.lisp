;;;; tests/layout-persistence-test.lisp
;;;; ============================================================================
;;;; DATA-ONLY LAYOUT SERIALIZATION — data ≠ code ([ARCH Phase 1])
;;;; ============================================================================
;;;; Κλειδώνει την αναβάθμιση του layout homoiconic seat: το παλιό element-to-form
;;;; παρήγαγε (make-instance …) ΚΩΔΙΚΑ και form-to-element = (eval form) τον ΕΚΤΕΛΟΥΣΕ
;;;; («Data becomes code becomes data» = RCE seat). Τώρα: element-to-form → DATA-ONLY
;;;; versioned plist· form-to-element → TYPED DECODER (καμία eval). Αποδεικνύει:
;;;;   (α) element→form→element round-trip διατηρεί τα πεδία (αναδρομικά)·
;;;;   (β) το form-to-element ΔΕΝ εκτελεί: αυθαίρετο (constructor/κλήση) form ⇒ decode-error·
;;;;   (γ) το serialized είναι data-only (μόνο keyword tag + keyword κλειδιά)·
;;;;   (δ) λάθος τύπος slot ⇒ decode-error.
;;;; Gated: τρέχει στο full build (in-package orchestrator.layout-types).

(in-package :orchestrator.layout-types)

(defvar *pt* 0) (defvar *ft* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *pt*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *ft*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ft*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro ck-rejected (name form)
  `(ck ,name (handler-case (progn ,form nil) (layout-decode-error () t))))

(let* ((bb (make-bbox :x 1.0 :y 2.0 :width 3.0 :height 4.0))
       (ft (make-font-info :name "Serif" :size 12.0 :bold-p t :italic-p nil :monospace-p nil))
       (sp (make-instance 'layout-span :id "s1" :text "hello|\"x" :bbox bb :font ft
                          :color :black :baseline 0.5 :char-spacing 0.1))
       (ln (make-instance 'layout-line :id "l1" :spans (list sp) :bbox bb
                          :baseline 0.5 :reading-order 0))
       (bl (make-instance 'layout-block :id "b1" :lines (list ln) :bbox bb
                          :reading-order 0 :column-index 0))
       (pg (make-instance 'layout-page :page-number 1 :blocks (list bl)
                          :width 600.0 :height 800.0 :rotation 0))
       (doc (make-instance 'layout-document :id "d1" :source-file "/x/y.pdf" :pages (list pg))))
  ;; (α) round-trip
  (let* ((data (element-to-form doc))
         (r (form-to-element data)))
    (ck "round-trip: document-id" (string= "d1" (document-id r)))
    (ck "round-trip: source-file" (string= "/x/y.pdf" (namestring (document-source-file r))))
    (ck "round-trip: 1 page → 1 block → 1 line → 1 span"
        (let* ((p (first (document-pages r))) (b (first (page-blocks p)))
               (l (first (block-lines b))) (s (first (line-spans l))))
          (and p b l s (string= "hello|\"x" (span-text s)))))
    (ck "round-trip: bbox αριθμοί ακέραιοι"
        (let ((b (span-bbox (first (line-spans (first (block-lines (first (page-blocks (first (document-pages r)))))))))))
          (and (= 1.0 (bbox-x b)) (= 4.0 (bbox-height b)))))
    (ck "round-trip: font bold-p διατηρήθηκε"
        (font-info-bold-p (span-font (first (line-spans (first (block-lines (first (page-blocks (first (document-pages r)))))))))))
    ;; (γ) data-only: tag keyword, όλα τα κλειδιά keywords, ΚΑΝΕΝΑ constructor symbol
    (ck "serialized: tag = :layout-document/1" (eq :layout-document/1 (first data)))
    (ck "serialized: όλα τα top-level κλειδιά keywords"
        (loop for (k) on (rest data) by #'cddr always (keywordp k)))
    (ck "serialized: κανένα 'make-instance/'make-bbox symbol πουθενά (data-only)"
        (labels ((clean (x) (typecase x
                              (cons (and (clean (car x)) (clean (cdr x))))
                              (symbol (or (keywordp x) (null x) (eq x t)))
                              (t t))))
          (clean data))))
  ;; (β) form-to-element ΔΕΝ εκτελεί: αυθαίρετα forms ⇒ decode-error (καμία eval)
  (ck-rejected "ATTACK (make-instance 'layout-span …) ως input ⇒ decode-error (όχι eval)"
               (form-to-element '(make-instance 'layout-span :id "x")))
  (ck-rejected "ATTACK γυμνή κλήση (error \"PWNED\") ⇒ decode-error (καμία εκτέλεση)"
               (form-to-element '(error "PWNED")))
  (ck-rejected "ATTACK άγνωστο tag ⇒ decode-error"
               (form-to-element '(:layout-evil/1 :x 1)))
  ;; (δ) λάθος τύπος slot ⇒ decode-error
  (ck-rejected "ATTACK bbox :x όχι αριθμός ⇒ decode-error"
               (form-to-element '(:layout-bbox/1 :x "nope" :y 0 :width 0 :height 0)))
  (ck-rejected "ATTACK διπλό κλειδί ⇒ decode-error"
               (form-to-element '(:layout-bbox/1 :x 0 :x 1 :y 0 :width 0 :height 0)))
  ;; (ε) [κύκλος-2 STRICT] closed+required key set / strict bool / tag-specific children
  (ck-rejected "STRICT: άγνωστο πεδίο στο bbox ⇒ decode-error"
               (form-to-element '(:layout-bbox/1 :x 0 :y 0 :width 0 :height 0 :evil 1)))
  (ck-rejected "STRICT: λείπει υποχρεωτικό :height ⇒ decode-error"
               (form-to-element '(:layout-bbox/1 :x 0 :y 0 :width 0)))
  (ck-rejected "STRICT bool: :bold-p :evil ⇒ decode-error (όχι σιωπηλά false)"
               (form-to-element '(:layout-font/1 :name "F" :size 10 :bold-p :evil
                                  :italic-p nil :monospace-p nil)))
  (ck-rejected "STRICT bool: :bold-p \"yes\" ⇒ decode-error"
               (form-to-element '(:layout-font/1 :name "F" :size 10 :bold-p "yes"
                                  :italic-p nil :monospace-p nil)))
  (ck-rejected "STRICT bool: :bold-p 123 ⇒ decode-error"
               (form-to-element '(:layout-font/1 :name "F" :size 10 :bold-p 123
                                  :italic-p nil :monospace-p nil)))
  (ck-rejected "STRICT child type: layout-line με page αντί για span ⇒ decode-error"
               (form-to-element '(:layout-line/1 :id "l" :baseline 0 :reading-order 0 :bbox nil
                                  :spans ((:layout-page/1 :page-number 1 :blocks () :width 0 :height 0 :rotation 0)))))
  (ck "OK: strict bool δέχεται :t και :nil"
      (let ((f (form-to-element '(:layout-font/1 :name "F" :size 10 :bold-p :t
                                  :italic-p :nil :monospace-p nil))))
        (and (font-info-bold-p f) (not (font-info-italic-p f))))))

(format t "~%layout-persistence: ~D passed, ~D failed~%" *pt* *ft*)
(sb-ext:exit :code (if (zerop *ft*) 0 1))
