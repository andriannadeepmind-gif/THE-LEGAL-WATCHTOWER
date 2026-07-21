;;;; tests/ast-persistence-test.lisp
;;;; ============================================================================
;;;; DATA-ONLY AST PERSISTENCE — data ≠ code ([ARCH Phase 1])
;;;; ============================================================================
;;;; Κλειδώνει την αναβάθμιση του AST homoiconic seat: το παλιό ζεύγος έγραφε
;;;; (make-instance …)/(make-X-node …) ΚΩΔΙΚΑ + (in-package …) και το φόρτωνε με
;;;; form-to-ast=(eval form) / load-ast-from-file=(eval (read stream)) — «the file IS a
;;;; Lisp program» = RCE seat. Τώρα: DATA-ONLY versioned plists· save μέσω write-file-atomic·
;;;; load μέσω safe-read read-data-file (pre-scanned) + STRICT typed decoder (closed+required
;;;; schema, deep element validation, class allowlist) ΧΩΡΙΣ eval. Αποδεικνύει:
;;;;   (α) in-memory round-trip (document→preamble/article→paragraph→point, char marker)·
;;;;   (β) file save→load round-trip (atomic write + safe read)·
;;;;   (γ) #. reader-eval στο αρχείο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (safe-read denies #)·
;;;;   (δ) εκτελέσιμο (make-instance …)/άγνωστο tag ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (schema, όχι eval)·
;;;;   (ε) λείπον υποχρεωτικό πεδίο / λάθος τύπος / διπλό κλειδί / μη-allowlisted class ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ.
;;;; Gated: τρέχει στο full build (in-package orchestrator.legal-ast).

(in-package :orchestrator.legal-ast)

(defvar *pt* 0) (defvar *ft* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *pt*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *ft*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *ft*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))
(defmacro ck-rejected (name form)
  `(ck ,name (handler-case (progn ,form nil)
               (ast-decode-error () t) (orchestrator.safe-read:safe-read-error () t))))

(let* ((pt1 (make-point-node :marker "α" :content "point alpha"))
       (pt2 (make-point-node :marker #\β :content "point beta"))   ; char marker → (:char/1 …)
       (par (make-paragraph-node :number 1 :content "para content" :points (list pt1 pt2)))
       (art (make-article-node :number "5α" :title "Άρθρο" :paragraphs (list par) :text "art text"))
       (pre (make-preamble-node :text "preamble text"))            ; base ast-node path + allowlist
       (doc (make-document-node :title "Doc" :preamble pre :articles (list art)))
       (tmp (format nil "/tmp/ast-persist-~D.sexp" (get-internal-real-time))))
  (unwind-protect
       (progn
         ;; (α) in-memory round-trip
         (let ((r (form-to-ast (ast-to-form doc))))
           (ck "in-mem: document-title" (string= "Doc" (document-title r)))
           (ck "in-mem: preamble ανακτήθηκε (base ast-node + allowlist)"
               (typep (document-preamble r) 'preamble-node))
           (let* ((a (first (document-articles r)))
                  (p (first (article-paragraphs a)))
                  (pts (paragraph-points p)))
             (ck "in-mem: article-number '5α'" (equal "5α" (article-number a)))
             (ck "in-mem: paragraph-number 1" (eql 1 (paragraph-number p)))
             (ck "in-mem: string marker α" (equal "α" (point-marker (first pts))))
             (ck "in-mem: char marker β round-trips ΩΣ character"
                 (eql #\β (point-marker (second pts))))))
         ;; (α2) [κύκλος-2] LOSSLESS coverage ΚΑΘΕ πρώην-ακάλυπτου node type (id + type-specific slots)
         (flet ((rt (n) (form-to-ast (ast-to-form n))))
           (let ((xr (make-instance 'cross-reference-node :id "XR" :xref-type :law
                                    :target-number "1" :target-year 2020 :original-text "ν.1/2020" :confidence 0.9)))
             (let ((r (rt xr)))
               (ck "cross-reference: id+type+year+confidence lossless"
                   (and (string= "XR" (ast-id r)) (eq :law (xref-type r))
                        (eql 2020 (xref-target-year r)) (= 0.9 (xref-confidence r)))))
             (let ((r (rt (make-instance 'amendment-node :id "AM" :amendment-type :repeal
                                         :target-law xr :target-article "5" :new-text "νέο"))))
               (ck "amendment: id+type+nested-xref(target-law)+new-text lossless"
                   (and (string= "AM" (ast-id r)) (eq :repeal (amendment-type r))
                        (typep (amendment-target-law r) 'cross-reference-node)
                        (string= "νέο" (amendment-new-text r)))))
             (let ((r (rt (make-instance 'amendment-node :id "AM2" :target-law "raw-law-string"))))
               (ck "amendment: target-law ΩΣ raw string (node-or-str union)"
                   (string= "raw-law-string" (amendment-target-law r)))))
           (let ((sig (make-instance 'signature-node :id "SG" :name "Ν. Παπ." :role "Υπουργός")))
             (let ((r (rt sig)))
               (ck "signature: name+role lossless" (and (string= "Ν. Παπ." (signature-name r))
                                                        (string= "Υπουργός" (signature-role r)))))
             (let ((r (rt (make-instance 'closing-node :id "CL" :signatures (list sig)))))
               (ck "closing: signatures nodelist lossless"
                   (and (string= "CL" (ast-id r)) (= 1 (length (closing-signatures r)))
                        (typep (first (closing-signatures r)) 'signature-node)))))
           (let ((r (rt (make-instance 'part-node :id "PT" :part-number "Α" :part-title "Μέρος" :sections '()))))
             (ck "part: number+title lossless" (and (string= "Α" (part-number r)) (string= "Μέρος" (part-title r)))))
           (let ((r (rt (make-instance 'division-node :id "DV" :division-number "Β" :division-title "Τμήμα" :chapters '()))))
             (ck "division: number+title lossless" (and (string= "Β" (division-number r)) (string= "Τμήμα" (division-title r)))))
           (let ((r (rt (make-instance 'chapter-node :id "CH" :chapter-number "Γ" :chapter-title "Κεφ" :articles '()))))
             (ck "chapter: number+title lossless" (and (string= "Γ" (chapter-number r)) (string= "Κεφ" (chapter-title r)))))
           (let ((r (rt (make-instance 'transitional-node :id "TR" :duration "6 μήνες" :conditions '("c1" "c2")))))
             (ck "transitional: duration+conditions(strlist) lossless"
                 (and (string= "6 μήνες" (transitional-duration r)) (equal '("c1" "c2") (transitional-conditions r)))))
           (let ((r (rt (make-instance 'effective-date-node :id "ED" :effective-date "2026-01-01" :conditions '("μετά ΦΕΚ")))))
             (ck "effective-date: date+conditions lossless"
                 (and (string= "2026-01-01" (effective-date r)) (equal '("μετά ΦΕΚ") (effective-conditions r)))))
           (let ((r (rt (make-instance 'sub-point-node :id "SP" :marker "i" :level 2 :content "υπο" :children '()))))
             (ck "sub-point: marker+level(int)+content lossless"
                 (and (string= "i" (sub-point-marker r)) (eql 2 (sub-point-level r)) (string= "υπο" (sub-point-content r)))))
           (let ((r (rt (make-instance 'case-node :id "CS" :marker "α" :content "περίπτωση"))))
             (ck "case: marker+content lossless"
                 (and (string= "α" (case-marker r)) (string= "περίπτωση" (case-content r)))))
           (let ((r (rt (make-instance 'preamble-node :id "PR" :text "προοίμιο" :source-blocks '("b1" "b2")))))
             (ck "preamble: id+text+source-blocks(idlist) lossless"
                 (and (string= "PR" (ast-id r)) (string= "προοίμιο" (ast-text r))
                      (equal '("b1" "b2") (ast-source-blocks r))))))
         ;; (β) file round-trip: atomic write + safe read
         (save-ast-to-file doc tmp)
         (let ((r (load-ast-from-file tmp)))
           (ck "file: document-title" (string= "Doc" (document-title r)))
           (ck "file: article-title Άρθρο"
               (string= "Άρθρο" (article-title (first (document-articles r)))))
           (ck "file: το αρχείο είναι data-only (κανένα make-instance/in-package)"
               (with-open-file (s tmp)
                 (let ((txt (make-string (file-length s))))
                   (read-sequence txt s)
                   (and (not (search "make-instance" txt)) (not (search "in-package" txt)))))))
         ;; (γ) #. reader-eval ⇒ rejected
         (with-open-file (s tmp :direction :output :if-exists :supersede)
           (format s "#.(error \"PWNED\")~%"))
         (ck-rejected "ATTACK #. reader-eval ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ (καμία εκτέλεση)" (load-ast-from-file tmp))
         ;; (δ) εκτελέσιμο / άγνωστο tag ⇒ rejected (schema, όχι eval)
         (ck-rejected "ATTACK (make-instance 'article-node …) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(make-instance article-node :id "x")))
         (ck-rejected "ATTACK άγνωστο tag ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ" (form-to-ast '(:evil-node/1 :x 1)))
         ;; (ε) STRICT schema: λείπον πεδίο / λάθος τύπος / διπλό κλειδί / μη-allowlisted class
         (ck-rejected "ATTACK λείπει υποχρεωτικό :content ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(:point-node/1 :marker "α")))
         (ck-rejected "ATTACK λάθος τύπος marker (int) ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(:point-node/1 :marker 123 :content "x")))
         (ck-rejected "ATTACK διπλό κλειδί ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(:point-node/1 :marker "α" :marker "β" :content "x")))
         (ck-rejected "ATTACK μη-allowlisted class ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(:ast-node/1 :type :evil-node :id "x" :node-type :x
                                     :text "" :source-blocks ())))
         (ck-rejected "ATTACK άγνωστο πεδίο ⇒ ΑΠΟΡΡΙΠΤΕΤΑΙ"
                      (form-to-ast '(:point-node/1 :marker "α" :content "x" :evil 1))))
    (ignore-errors (delete-file tmp))))

(format t "~%ast-persistence: ~D passed, ~D failed~%" *pt* *ft*)
(sb-ext:exit :code (if (zerop *ft*) 0 1))
