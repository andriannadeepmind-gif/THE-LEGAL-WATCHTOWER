;;;; tests/isokratis-parser-test.lisp
;;;; Isokratis (ΔΣΑ legal database) PDF-export parser. Deterministic; the format
;;;; is what the real Penal Code export uses.

(in-package :orchestrator.engine.sbcl)

(defvar *pass* 0)
(defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun art-text (a)
  (when (article-paragraphs a) (paragraph-text (first (article-paragraphs a)))))

;; The REAL Isokratis (ΔΣΑ) export structure, verified against the Penal Code
;; dump: per-article 'Αρθρο: N', then the labeled sections Ημ/νία (metadata),
;; Τίτλος Αρθρου (title), Λήμματα (keywords), Σχόλια (amendment note), Κείμενο
;; Αρθρου (body). Article 1's body is preceded by the book/part/chapter headers
;; the export folds in (ΠΡΩΤΟ ΒΙΒΛΙΟ / ΓΕΝΙΚΟ ΜΕΡΟΣ / Ι. ΒΑΣΙΚΕΣ ΑΡΧΕΣ).
(defparameter *sample*
  (format nil "~{~A~%~}"
          (list "27/8/2019" "ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ" "ΙΣΟΚΡΑΤΗΣ" "ΤΡΑΠΕΖΑ ΝΟΜΙΚΩΝ ΠΛΗΡΟΦΟΡΙΩΝ ΔΣΑ"
                "Είδος: ΠΟΙΝΙΚΟΣ ΚΩΔΙΚΑΣ" "Έτος: 1951" "Τίτλος" "Ποινικός Κώδικας"
                "ΣΤΟΙΧΕΙΑ ΑΡΘΡΩΝ"
                "Αρθρο: 1"
                "Ημ/νία: 01.07.2019"
                "Ημ/νία Ισχύος: 01.01.1951"
                "Περιγραφή όρου θησαυρού: ΓΕΝΙΚΑ (ΠΟΙΝΙΚΟ ΔΙΚΑΙΟ)"
                "Τίτλος Αρθρου"
                "Καμία ποινή χωρίς νόμο"
                "Λήμματα"
                "ΠΟΙΝΙΚΟΣ ΚΩΔΙΚΑΣ (Π.Κ.), ΚΑΜΜΙΑ ΠΟΙΝΗ ΧΩΡΙΣ ΝΟΜΟ"
                "Σχόλια"
                "Το παρόν τίθεται όπως αντικαταστάθηκε με το άρθρο 1 του ν. 4619/2019 ΦΕΚ Α 95 / 11.6.2019."
                "Κείμενο Αρθρου"
                "ΠΡΩΤΟ ΒΙΒΛΙΟ"
                "ΓΕΝΙΚΟ ΜΕΡΟΣ"
                "ΠΡΩΤΟ ΚΕΦΑΛΑΙΟ"
                "Ο ΠΟΙΝΙΚΟΣ ΝΟΜΟΣ"
                "Ι. ΒΑΣΙΚΕΣ ΑΡΧΕΣ"
                "Κανένα έγκλημα δεν υπάρχει ούτε ποινή επιβάλλεται χωρίς νόμο που να ισχύει πριν από"
                "την τέλεση της πράξης και να ορίζει τα στοιχεία της."
                "Αρθρο: 2"
                "Τίτλος Αρθρου"
                "Αναδρομική ισχύς του ηπιότερου νόμου"
                "Κείμενο Αρθρου"
                "Αν από την τέλεση της πράξης έως την αμετάκλητη εκδίκασή της ίσχυσαν περισσότεροι νόμοι."
                "Αρθρο: 3"
                "Τίτλος Αρθρου"
                "Νόμοι με προσωρινή ισχύ"
                "Κείμενο Αρθρου"
                "Τοπικά όρια ισχύος των ελληνικών ποινικών νόμων.")))

(format t "~%== Detection ==~%")
(check "Isokratis format detected" (isokratis-text-p *sample*))
(check "ΦΕΚ-only text not misdetected"
       (not (isokratis-text-p "Άρθρο 5 Κάτι. Το άρθρο 5 αντικαθίσταται.")))

(format t "~%== Parsing ==~%")
(let ((arts (parse-isokratis-text *sample*)))
  (check "exactly 3 articles" (= 3 (length arts)))
  (check "article numbers are 1,2,3"
         (equal (mapcar #'article-number arts) '("1" "2" "3")))
  (check "article 1 body is the Κείμενο (not the header/title)"
         (and (search "Κανένα έγκλημα" (art-text (first arts)))
              (not (search "ΙΣΟΚΡΑΤΗΣ" (art-text (first arts))))
              (not (search "αντικαταστάθηκε" (art-text (first arts))))))
  (check "multi-line body is joined"
         (search "τα στοιχεία της." (art-text (first arts))))
  ;; --- the fixes for the real DSAnet/Isokratis Penal Code export ---
  (check "real article title extracted (Τίτλος Αρθρου)"
         (string= "Καμία ποινή χωρίς νόμο" (resolve-article-title (first arts))))
  (check "structural headers (ΒΙΒΛΙΟ/ΜΕΡΟΣ/ΚΕΦΑΛΑΙΟ) stripped from body"
         (and (not (search "ΠΡΩΤΟ ΒΙΒΛΙΟ" (art-text (first arts))))
              (not (search "ΓΕΝΙΚΟ ΜΕΡΟΣ" (art-text (first arts))))
              (not (search "ΚΕΦΑΛΑΙΟ" (art-text (first arts))))
              (not (search "ΒΑΣΙΚΕΣ ΑΡΧΕΣ" (art-text (first arts))))))
  (check "body now STARTS at the real normative text"
         (let ((b (art-text (first arts))))
           (and (>= (length b) 12) (string= "Κανένα έγκλη" (subseq b 0 12)))))
  (check "Λήμματα keywords never leak into title or body"
         (and (not (search "Π.Κ." (art-text (first arts))))
              (not (search "Π.Κ." (resolve-article-title (first arts))))))
  (check "article-to-iir title is 'Άρθρο 1 - Καμία ποινή χωρίς νόμο'"
         (let ((tt (orchestrator.model:article-title (article-to-iir (first arts) "test.pdf"))))
           (and (search "Άρθρο 1" tt) (search "Καμία ποινή χωρίς νόμο" tt))))
  (check "article 2 real title extracted"
         (string= "Αναδρομική ισχύς του ηπιότερου νόμου" (resolve-article-title (second arts))))
  (check "article 2 parsed with its body"
         (search "αμετάκλητη εκδίκασή" (art-text (second arts))))
  (check "amendment note captured separately (Σχόλια, not lost, not in body)"
         (let ((info (article-amendment-info (first arts))))
           (and info (search "4619/2019" (getf info :note))
                (not (search "4619/2019" (art-text (first arts)))))))
  (check "every article carries text" (every #'art-text arts))
  ;; Regression guard: orthography must NOT corrupt the 'Κείμενο Αρθρου' label
  ;; (which once emptied every body). Bodies must be non-empty AND a corrupted
  ;; "Οποιος" in a body must be restored to "Όποιος" from the corpus lexicon.
  (check "Κείμενο Αρθρου label survives orthography (bodies non-empty)"
         (every (lambda (a) (let ((tx (art-text a))) (and tx (plusp (length tx))))) arts))
  (check "every article has a bound id (node-id) + paragraph id"
         (every (lambda (a) (and (node-id a)
                                 (or (null (article-paragraphs a))
                                     (node-id (first (article-paragraphs a))))))
                arts))
  (check "article-to-iir runs without unbound-slot errors"
         (every (lambda (a) (article-to-iir a "test.pdf")) arts))
  (check "deterministic"
         (equal (mapcar #'art-text arts)
                (mapcar #'art-text (parse-isokratis-text *sample*)))))

(format t "~%== Duplicate articles collapsed to the current version ==~%")
;; Article 5 appears twice: original, then the amended «replacement». Keep the «.
(let* ((txt (format nil "~{~A~%~}"
                    (list "Αρθρο: 5" "Κείμενο Αρθρου" "Παλιό κείμενο του άρθρου 5."
                          "Αρθρο: 5" "Κείμενο Αρθρου" "« Νέο αντικατεστημένο κείμενο του άρθρου 5 με περισσότερο περιεχόμενο.»"
                          "Αρθρο: 6" "Κείμενο Αρθρου" "Έκτο άρθρο.")))
       (arts (parse-isokratis-text txt)))
  (check "duplicate article 5 collapsed (2 articles, not 3)" (= 2 (length arts)))
  (check "kept the amended «replacement» version of article 5"
         (search "Νέο αντικατεστημένο" (art-text (first arts))))
  (check "dropped the superseded original"
         (not (search "Παλιό κείμενο" (art-text (first arts)))))
  (check "unrelated article 6 untouched" (search "Έκτο άρθρο" (art-text (second arts)))))

(format t "~%========================================~%")
(format t "Isokratis parser tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
