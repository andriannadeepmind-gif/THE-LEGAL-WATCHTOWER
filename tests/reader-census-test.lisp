;;;; tests/reader-census-test.lisp
;;;; ============================================================================
;;;; READER CENSUS RATCHET — enforcing, comment/string-aware ([κύκλος-2] ARCH Phase 1)
;;;; ============================================================================
;;;; Μετά τη migration ΟΛΩΝ των data readers στη ΜΙΑ safe-read έδρα, αυτός ο ΕΠΙΒΑΛΛΩΝ
;;;; έλεγχος κάνει την επανεισαγωγή bare reader/eval/load ΔΟΜΙΚΑ αδύνατη: σαρώνει ΟΛΑ τα
;;;; source/*.lisp (comment/string/char-literal-aware — ΟΧΙ εύθραυστο grep) και ΑΠΟΤΥΓΧΑΝΕΙ
;;;; αν εμφανιστεί επικίνδυνος operator ως list-head σε ΜΗ-δηλωμένο αρχείο, ή αν μια δηλωμένη
;;;; εξαίρεση ΠΑΨΕΙ να τον έχει (stale ⇒ αναγκαστική επανεξέταση). Ratchet, ΟΧΙ υποκατάστατο
;;;; της migration — η migration ΕΓΙΝΕ, εδώ κλειδώνεται.
;;;;
;;;; Self-contained (in-package cl-user, καμία εξάρτηση): τρέχει και σε bare SBCL.

(in-package :cl-user)

;; Επικίνδυνοι operators (list-heads) — Lisp readers/eval/load. Τα read-line/read-char/
;; read-byte/read-sequence/read-data-*/read-file-* ΔΕΝ είναι sexp-readers (εξαιρούνται).
(defparameter *dangerous*
  '("read" "read-from-string" "read-preserving-whitespace" "read-delimited-list"
    "eval" "load" "compile-file"))
(defparameter *excluded-read*
  '("read-line" "read-char" "read-char-no-hang" "read-byte" "read-sequence"
    "read-data-file" "read-data-string" "read-data-form" "read-data-file-sequence"
    "read-file-string" "read-file-lines" "read-file-forms"))

;; ΔΗΛΩΜΕΝΗ ΕΞΑΙΡΕΣΗ ανά αρχείο → (operators… . αιτιολόγηση). ΚΑΘΕ άλλο = FAIL.
(defparameter *census*
  '(("safe-read.lisp" ("read")
     "Η ΜΙΑ έδρα ασφαλούς αποσεριαλοποίησης: *read-eval* nil + wholesale #-deny + depth/atom/"
     "byte pre-scan + total data-only. ΟΛΟΙ οι data readers δρομολογούνται ΕΔΩ.")
    ("journal.lisp" ("read" "read-from-string")
     "Substrate append-only ledger (self-written). Guarded (*read-eval* nil + keyword +"
     "double-float)· tolerant per-line resync που η single-form/sequence safe-read ΔΕΝ"
     "προσφέρει· + %validate-serializable pre-write re-read. Δηλωμένη εξαίρεση [0094]."))
  "keyed by basename· ο πρώτος υπο-πίνακας = επιτρεπόμενοι operators.")

(defun census-entry (basename) (assoc basename *census* :test #'string=))

;; ── Comment/string/char-literal-aware λεξικός σαρωτής: (file . operator) hits ──
(defun sym-char-p (d)
  (or (alphanumericp d) (member d '(#\- #\. #\+ #\* #\% #\/ #\< #\> #\= #\_ #\! #\?))))

(defun scan-file (path)
  "Επιστρέφει λίστα operator-strings (dangerous, ΟΧΙ excluded) που εμφανίζονται ως list-head."
  (let* ((text (with-open-file (s path :external-format :utf-8)
                 (let ((buf (make-string (file-length s))))
                   (subseq buf 0 (read-sequence buf s)))))
         (i 0) (n (length text)) (hits '()))
    (loop while (< i n) do
      (let ((c (char text i)))
        (cond
          ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\\)) (incf i 3)) ; #\X
          ((and (char= c #\#) (< (1+ i) n) (char= (char text (1+ i)) #\|))            ; #| … |#
           (incf i 2)
           (loop while (and (< (1+ i) n)
                            (not (and (char= (char text i) #\|) (char= (char text (1+ i)) #\#))))
                 do (incf i))
           (incf i 2))
          ((char= c #\")                                                             ; "string"
           (incf i)
           (loop while (and (< i n) (not (char= (char text i) #\")))
                 do (when (char= (char text i) #\\) (incf i)) (incf i))
           (incf i))
          ((char= c #\;)                                                             ; ; comment
           (loop while (and (< i n) (not (char= (char text i) #\Newline))) do (incf i)))
          ((char= c #\()                                                             ; ( head
           (incf i)
           (loop while (and (< i n) (member (char text i) '(#\Space #\Tab #\Newline #\Return))) do (incf i))
           (let ((start i))
             (loop while (and (< i n) (sym-char-p (char text i))) do (incf i))
             (let ((tok (string-downcase (subseq text start i))))
               (when (and (member tok *dangerous* :test #'string=)
                          (not (member tok *excluded-read* :test #'string=)))
                 (pushnew tok hits :test #'string=)))))
          (t (incf i)))))
    (nreverse hits)))

;; ── enforcement ──
(defun list-source-files ()
  (directory (merge-pathnames "source/*.lisp" (truename "./"))))

(let ((violations '()) (stale '()) (scanned 0))
  (dolist (path (list-source-files))
    (incf scanned)
    (let* ((base (file-namestring path))
           (hits (scan-file path))
           (entry (census-entry base)))
      (cond
        ((null entry)
         (when hits (push (list base hits) violations)))
        (t
         (let ((allowed (second entry)))
           ;; undeclared operator στο δηλωμένο αρχείο
           (let ((extra (set-difference hits allowed :test #'string=)))
             (when extra (push (list base extra :undeclared-op) violations)))
           ;; stale: δηλωμένος operator που ΔΕΝ εμφανίζεται πια ⇒ επανεξέταση
           (let ((missing (set-difference allowed hits :test #'string=)))
             (when missing (push (list base missing) stale))))))))
  (format t "~&reader-census: σαρώθηκαν ~D source αρχεία· ~D δηλωμένες εξαιρέσεις~%"
          scanned (length *census*))
  (dolist (v (reverse violations))
    (format t "  VIOLATION ~A: αδήλωτος reader/eval/load ~S~%" (first v) (second v)))
  (dolist (s (reverse stale))
    (format t "  STALE ~A: δηλωμένος operator ~S δεν εμφανίζεται πια (ενημέρωσε το *census*)~%"
            (first s) (second s)))
  (if (and (null violations) (null stale))
      (progn (format t "~&reader-census: PASS — κάθε sexp-reader/eval/load είναι η safe-read έδρα ή δηλωμένη εξαίρεση~%")
             (sb-ext:exit :code 0))
      (progn (format t "~&reader-census: FAIL (~D violations, ~D stale)~%" (length violations) (length stale))
             (sb-ext:exit :code 1))))
