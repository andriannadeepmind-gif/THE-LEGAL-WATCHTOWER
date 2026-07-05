;;;; tests/amended-split-test.lisp
;;;; ROOT fix: the Isokratis source ships an amended article as ONE guillemet block
;;;; «1. … 2. …» with the paragraph numbers baked into the text. The parser must
;;;; split it into real paragraphs (clean text, number in :number) — otherwise the
;;;; renderer prepends the paragraph number onto text that already starts with it,
;;;; producing the corrupt «1. «1. …» seen in Penal Code art. 345 (Αιμομιξία).
;;;; Uses the EXACT string observed in the materialised corpus.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defparameter *amended-345*
  "«1. Η συνουσία μεταξύ συγγενών εξ αίματος, ανιούσας και κατιούσας γραμμής, τιμωρείται: «α. ως προς τους ανιόντες με κάθειρξη τουλάχιστον δέκα ετών αν ο κατιών δεν είχε συμπληρώσει το δέκατο πέμπτο έτος της ηλικίας του, με κάθειρξη αν ο κατιών είχε συμπληρώσει το δέκατο πέμπτο αλλά όχι το δέκατο όγδοο έτος της ηλικίας του, με φυλάκιση μέχρι δύο ετών αν ο κατιών έχει συμπληρώσει το δέκατο όγδοο έτος της ηλικίας του,». β) ως προς τους κατιόντες, με φυλάκιση μέχρι δύο ετών γ) μεταξύ αμφιθαλών ή ετεροθαλών αδελφών, με φυλάκιση μέχρι δύο ετών. 2. Συγγενείς κατιούσας γραμμής ή αδελφοί μπορούν να απαλλαγούν από κάθε ποινή, αν κατά το χρόνο της πράξης δεν είχαν συμπληρώσει το δέκατο όγδοο έτος της ηλικίας τους.».")

;;; (1) the splitter, on the real string
(format t "~%== (1) splitter on real art. 345 ==~%")
(let ((r (%split-amended-paragraphs *amended-345*)))
  (check "splits into exactly 2 paragraphs" (= 2 (length r)))
  (check "para 1 numbered 1, para 2 numbered 2"
         (and (= 1 (car (first r))) (= 2 (car (second r)))))
  (check "para 1 starts clean (no leading «/number)"
         (let ((p1 (cdr (first r)))) (and (search "Η συνουσία μεταξύ συγγενών" p1)
                                          (not (eql #\« (char p1 0)))
                                          (not (eql #\1 (char p1 0))))))
  (check "para 1 KEEPS its nested «α …» and lettered β) γ)"
         (let ((p1 (cdr (first r)))) (and (search "«α." p1) (search "β)" p1) (search "γ)" p1))))
  (check "para 2 is the second rule, clean"
         (let ((p2 (cdr (second r))))
           (and (search "Συγγενείς κατιούσας γραμμής" p2)
                (not (eql #\2 (char p2 0)))))))

;;; (2) safety: never over-split
(format t "~%== (2) safety — no false splits ==~%")
(check "single-paragraph amended block is NOT split"
       (null (%split-amended-paragraphs "«Καταργήθηκε με το άρθρο 5 του ν. 4619/2019.»")))
(check "non-guillemet text is left to the normal parser"
       (null (%split-amended-paragraphs "1. Κάτι ορίζεται. 2. Άλλο ορίζεται.")))
(check "nil/empty is safe"
       (null (%split-amended-paragraphs "")))

;;; (3) end-to-end through the FEK parser
(format t "~%== (3) end-to-end parse ==~%")
(let* ((a (first (parse-fek-text (format nil "Άρθρο 345~%Αιμομιξία~%~A" *amended-345*))))
       (paras (article-paragraphs a)))
  (check "article has 2 paragraphs (was 1)" (= 2 (length paras)))
  (check "no paragraph text still opens with «1./«2."
         (notany (lambda (p) (let ((tx (string-left-trim '(#\Space) (paragraph-text p))))
                               (and (>= (length tx) 2) (char= (char tx 0) #\«)
                                    (digit-char-p (char tx 1)))))
                 paras))
  (check "rubric still captured as title"
         (search "Αιμομιξία" (or (resolve-article-title a) ""))))

(format t "~%========================================~%")
(format t "Amended-block split tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
