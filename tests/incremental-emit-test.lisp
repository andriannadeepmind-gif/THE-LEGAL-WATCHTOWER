;;;; tests/incremental-emit-test.lisp
;;;; ============================================================================
;;;; ΑΥΞΗΤΙΚΗ ΣΤΑΤΙΚΗ ΕΞΟΔΟΣ — write-if-changed στη ΜΙΑ έδρα εγγραφής
;;;; ============================================================================
;;;; Κλειδώνει: (α) write-utf8-file: :written σε νέα/αλλαγμένα bytes, :unchanged
;;;; σε ταυτόσημα — και ΞΑΝΑ :written όταν το περιεχόμενο αλλάξει ξανά·
;;;; (β) write-article-formats: μετρητές (written, unchanged) ακριβείς ανά άρθρο·
;;;; (γ) αμετάβλητο άρθρο ⇒ mtime ΑΝΕΓΓΙΧΤΟ (το IO πραγματικά πέθανε)·
;;;; (δ) στοχευμένη αλλαγή ⇒ ΜΟΝΟ τα αλλαγμένα αρχεία ξαναγράφονται·
;;;; (ε) ισοδυναμία εκ κατασκευής: μετά από κάθε γύρο, τα bytes στον δίσκο
;;;;     ταυτίζονται με ό,τι θα έγραφε πλήρης επανεγγραφή (ίδιο περιεχόμενο).
;;;; ΚΑΜΙΑ λογική invalidation/εκδόσεων δεν υπάρχει να ξεσυγχρονιστεί — η κρίση
;;;; γίνεται στα πραγματικά bytes.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *ie-dir*
  (merge-pathnames (format nil "incremental-emit-~D/" (get-universal-time))
                   (uiop:temporary-directory)))

(defun %ie-article (num text)
  (let ((a (make-instance 'orchestrator.model:article
                          :number num :title (format nil "Άρθρο ~D" num)
                          :content text)))
    (setf (orchestrator.model:article-rdf-turtle a) (format nil "# ttl ~D~%~A~%" num text)
          (orchestrator.model:article-json-ld a) (format nil "{\"n\":~D,\"t\":\"~A\"}" num text)
          (orchestrator.model:article-html a) (format nil "<html>~D:~A</html>" num text)
          (orchestrator.model:article-hash a) (format nil "hash-~D-~A" num text))
    a))

(format t "~%== (α) write-utf8-file: η έδρα write-if-changed ==~%")
(let ((p (merge-pathnames "seat.txt" *ie-dir*)))
  (check "1η εγγραφή ⇒ :written"
         (eq :written (nth-value 1 (write-utf8-file p "αλφα"))))
  (check "ίδια bytes ⇒ :unchanged"
         (eq :unchanged (nth-value 1 (write-utf8-file p "αλφα"))))
  (check "αλλαγμένα bytes ⇒ :written"
         (eq :written (nth-value 1 (write-utf8-file p "βητα"))))
  (check "ίδιο ΜΗΚΟΣ, άλλα bytes ⇒ :written (όχι μόνο stat μήκους)"
         (eq :written (nth-value 1 (write-utf8-file p "γητα"))))
  (check "unicode ταυτόσημο ⇒ :unchanged (σύγκριση σε UTF-8 bytes)"
         (eq :unchanged (nth-value 1 (write-utf8-file p "γητα"))))
  (check "στον δίσκο τα ΣΩΣΤΑ bytes μετά τους γύρους"
         (string= "γητα" (uiop:read-file-string p))))

(format t "~%== (β)+(γ) write-article-formats: μετρητές + ανέγγιχτο mtime ==~%")
(let ((a (%ie-article 901 "κείμενο-Α"))
      (b (%ie-article 902 "κείμενο-Β")))
  ;; Γύρος 1: όλα γράφονται
  (multiple-value-bind (files w u) (write-article-formats a *ie-dir* :verbose nil)
    (check "Γ1 άρθρο-Α: 5 artifacts, 5 written, 0 unchanged"
           (and (= 5 (length files)) (= 5 w) (= 0 u))))
  (multiple-value-bind (files w u) (write-article-formats b *ie-dir* :verbose nil)
    (declare (ignore files))
    (check "Γ1 άρθρο-Β: 5 written" (and (= 5 w) (= 0 u))))
  ;; mtimes του A πριν τον γύρο 2 (1.1s ώστε αλλαγή mtime να ήταν ορατή)
  (let ((mtimes (mapcar (lambda (ext)
                          (file-write-date
                           (article-filepath a ext *ie-dir*)))
                        '("ttl" "jsonld" "html" "hash" "txt"))))
    (sleep 1.1)
    ;; Γύρος 2: ΤΙΠΟΤΑ δεν άλλαξε ⇒ 0 written, mtimes ταυτόσημα
    (multiple-value-bind (files w u) (write-article-formats a *ie-dir* :verbose nil)
      (check "Γ2 άρθρο-Α αμετάβλητο: 0 written, 5 unchanged, 5 artifacts παρόντα"
             (and (= 5 (length files)) (= 0 w) (= 5 u))))
    (check "Γ2: mtimes ΑΝΕΓΓΙΧΤΑ (το IO πραγματικά παρακάμφθηκε)"
           (equal mtimes
                  (mapcar (lambda (ext)
                            (file-write-date (article-filepath a ext *ie-dir*)))
                          '("ttl" "jsonld" "html" "hash" "txt"))))
    ;; Γύρος 3: στοχευμένη αλλαγή ΜΟΝΟ σε html+hash του A
    (setf (orchestrator.model:article-html a) "<html>901:ΝΕΟ</html>"
          (orchestrator.model:article-hash a) "hash-901-ΝΕΟ")
    (multiple-value-bind (files w u) (write-article-formats a *ie-dir* :verbose nil)
      (declare (ignore files))
      (check "Γ3 στοχευμένη αλλαγή: ΑΚΡΙΒΩΣ 2 written (html+hash), 3 unchanged"
             (and (= 2 w) (= 3 u))))
    (check "Γ3: ttl mtime ΑΚΟΜΑ ανέγγιχτο (μόνο τα αλλαγμένα γράφτηκαν)"
           (eql (first mtimes)
                (file-write-date (article-filepath a "ttl" *ie-dir*))))
    (check "Γ3: το νέο html ΣΤΟΝ ΔΙΣΚΟ (ισοδυναμία με πλήρη επανεγγραφή)"
           (search "901:ΝΕΟ" (uiop:read-file-string
                              (article-filepath a "html" *ie-dir*))))))

(format t "~%== (δ) write-corpus-files: αυξητικό πάνω από ΟΛΟ το σώμα ==~%")
(let ((arts (list (%ie-article 903 "x") (%ie-article 904 "y"))))
  (write-corpus-files arts *ie-dir*)
  (check "corpus-level: όλα τα artifacts των 2 άρθρων παρόντα"
         (every (lambda (n) (probe-file (merge-pathnames n *ie-dir*)))
                '("article-903.ttl" "article-903.html" "article-904.ttl" "article-904.html")))
  ;; δεύτερο πέρασμα χωρίς αλλαγές — δεν πρέπει να σκάσει και να μην ξαναγράψει
  (let ((m (file-write-date (merge-pathnames "article-903.html" *ie-dir*))))
    (sleep 1.1)
    (write-corpus-files arts *ie-dir*)
    (check "corpus-level 2ο πέρασμα: mtime ανέγγιχτο (0 επανεγγραφές)"
           (eql m (file-write-date (merge-pathnames "article-903.html" *ie-dir*))))))

(ignore-errors (uiop:delete-directory-tree *ie-dir* :validate t))

(format t "~%========================================~%")
(format t "INCREMENTAL-EMIT tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
