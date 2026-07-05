;;;; tests/isokratis-amended-test.lisp
;;;; The Isokratis (ΔΣΑ) parser — the one that actually feeds poinikos/astikos/
;;;; kdioikitikis — stores each article body as ONE paragraph. It must therefore
;;;; ALSO (a) strip the editorial preamble the export prepends at the body head
;;;; («προσοχή && "…"», «ΠΡΟΣΟΧΗ!!! Βλ. σχόλια "…"»), and (b) split a guillemet
;;;; amended block «1. … 2. …» into real paragraphs — exactly as observed in the
;;;; live corpus for Penal Code art. 122 (Αναμορφωτικά μέτρα) and art. 345 (Αιμομιξία).

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun iso-article (num title body)
  "Build a minimal Isokratis block and parse it; return the first article."
  (first (parse-isokratis-text
          (format nil "Αρθρο: ~A~%Τίτλος Αρθρου~%~A~%Κείμενο Αρθρου~%~A" num title body))))

(defun body-text (art)
  (format nil "~{~A~^ ~}" (mapcar #'paragraph-text (article-paragraphs art))))

;;; art. 122 — ASCII-quote editorial wrapper «προσοχή && "…"»
(format t "~%== art. 122: editorial preamble stripped ==~%")
(let ((a (iso-article "122" "Αναμορφωτικά μέτρα"
                      "προσοχή && \"1. Αναμορφωτικά μέτρα είναι: α) η επίπληξη. 2. Σε κάθε περίπτωση ισχύει ο κανόνας. 3. Στην απόφαση ορίζεται η διάρκεια.\"")))
  (check "no «προσοχή» left in body"   (not (search "προσοχή" (body-text a))))
  (check "no «&&» left in body"         (not (search "&&" (body-text a))))
  (check "no stray ASCII quote at head" (not (eql #\" (char (string-left-trim '(#\Space) (paragraph-text (first (article-paragraphs a)))) 0))))
  (check "real legal text retained"     (search "Αναμορφωτικά μέτρα είναι" (body-text a))))

;;; art. 345 — guillemet amended block «1. … 2. …» split into 2 paragraphs
(format t "~%== art. 345: amended block split ==~%")
(let ((a (iso-article "345" "Αιμομιξία"
                      "«1. Η συνουσία μεταξύ συγγενών εξ αίματος τιμωρείται: «α. ως προς τους ανιόντες με κάθειρξη,». β) ως προς τους κατιόντες, με φυλάκιση μέχρι δύο ετών. 2. Συγγενείς κατιούσας γραμμής μπορούν να απαλλαγούν από κάθε ποινή.»")))
  (check "split into 2 paragraphs" (= 2 (length (article-paragraphs a))))
  (check "paragraphs numbered 1 and 2"
         (equal '(1 2) (mapcar #'paragraph-number (article-paragraphs a))))
  (check "para 1 clean (no leading «/digit)"
         (let ((p1 (paragraph-text (first (article-paragraphs a)))))
           (and (search "Η συνουσία" p1) (not (eql #\« (char p1 0))) (not (eql #\1 (char p1 0))))))
  (check "para 1 keeps nested «α …» and β)"
         (let ((p1 (paragraph-text (first (article-paragraphs a))))) (and (search "«α." p1) (search "β)" p1))))
  (check "para 2 clean"
         (let ((p2 (paragraph-text (second (article-paragraphs a)))))
           (and (search "Συγγενείς κατιούσας" p2) (not (eql #\2 (char p2 0)))))))

;;; safety: an ordinary single-rule article is untouched (one paragraph)
(format t "~%== safety: ordinary article unchanged ==~%")
(let ((a (iso-article "1" "Πηγές του δικαίου"
                      "Οι κανόνες του δικαίου περιλαμβάνονται στους νόμους και στα έθιμα.")))
  (check "stays a single paragraph" (= 1 (length (article-paragraphs a))))
  (check "text intact" (search "Οι κανόνες του δικαίου" (body-text a))))

(format t "~%========================================~%")
(format t "Isokratis amended/editorial tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
