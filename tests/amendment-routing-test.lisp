;;;; tests/amendment-routing-test.lisp
;;;; [FEK-COMPILER] Ο τροποποιητικός νόμος ως πρόγραμμα: ενότητες («Άρθρο Ν» του
;;;; τροποποιητικού), ΔΟΜΙΚΗ κληρονομιά scope, δρομολόγηση ΜΟΝΟ από το registry
;;;; (configs — καμία hardcoded λίστα), επαλήθευση κατά ταυτότητας (census eIds).
;;;; Κλειδώνει την κλάση αποτυχίας των ΦΕΚ Α'103/Α'105 2026: κωδικοποιημένη
;;;; μεταρρύθμιση που ονομάζει τον κώδικα ΜΙΑ φορά στην κεφαλίδα.

(in-package :orchestrator.amendment-extractor)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun op-for (ops target)
  (find target ops :key (lambda (o) (getf o :target)) :test #'equal))

;;; Registry ΟΠΩΣ το παράγει build-legal-id-registry από τα configs (δείγμα) —
;;; το τεστ αποδεικνύει ότι η δρομολόγηση κατάγεται ΜΟΝΟ από αυτά τα δεδομένα.
(defvar *reg*
  (list (orchestrator.legal-id:make-registry-entry "poinikos"
         :law-number 4619 :year 2019 :name "Ποινικός Κώδικας"
         :aliases '("Ποινικό Κώδικα" "Ποινικού Κώδικα"))
        (orchestrator.legal-id:make-registry-entry "kpolitikis"
         :law-number 503 :year 1985 :name "Κώδικας Πολιτικής Δικονομίας"
         :aliases '("Πολιτικής Δικονομίας"))
        (orchestrator.legal-id:make-registry-entry "astikos"
         :law-number 2250 :year 1940 :name "Αστικός Κώδικας"
         :aliases '("Αστικό Κώδικα" "Αστικού Κώδικα"))))

(defvar *rr* (make-registry-resolver *reg*))

(defun xops (text &key exists)
  (extract-operations text :code-resolver *rr* :article-exists-fn exists))

;;; (1) inline ονομασία δίπλα στην πράξη (η εύκολη περίπτωση — Α'239 style)
(format t "~%== (1) inline: ονομασία κώδικα δίπλα σε κάθε πράξη ==~%")
(let* ((fek "Άρθρο 1. Το άρθρο 5 του Ποινικού Κώδικα (ν. 4619/2019) αντικαθίσταται ως εξής: «Άρθρο 5. Όποιος τελεί την πράξη τιμωρείται με κάθειρξη.» Άρθρο 2. Το άρθρο 10 του Ποινικού Κώδικα καταργείται. Άρθρο 3. Στο άρθρο 8 του Ποινικού Κώδικα προστίθεται παράγραφος 4 ως εξής: «4. Η νέα παράγραφος.»")
       (ops (xops fek)))
  (check "three operations extracted" (= 3 (length ops)))
  (check "art_5 → REPLACE-TEXT, code poinikos, high"
         (let ((o (op-for ops "art_5")))
           (and o (eq :replace-text (getf o :op)) (equal "poinikos" (getf o :code))
                (eq :high (getf o :confidence)))))
  (check "art_5 carries the NEW text"
         (search "τιμωρείται με κάθειρξη" (or (getf (op-for ops "art_5") :text) "")))
  (check "art_10 → REPEAL, code poinikos"
         (let ((o (op-for ops "art_10"))) (and o (eq :repeal (getf o :op)) (equal "poinikos" (getf o :code)))))
  (check "art_8 → INSERT (new paragraph), flagged medium"
         (let ((o (op-for ops "art_8"))) (and o (eq :insert (getf o :op)) (eq :medium (getf o :confidence)))))
  (let ((summary (summarize-operations ops)))
    (check "summary: όλα σε ΕΝΑΝ κουβά poinikos"
           (and (= 1 (length summary)) (equal "poinikos" (caar summary))))))

;;; (2) ΔΟΜΙΚΗ κληρονομιά — η κλάση Α'103/Α'105: ο κώδικας ονομάζεται ΜΙΑ φορά
(format t "~%== (2) ΔΟΜΙΚΟ scope: κωδικοποιημένη μεταρρύθμιση (Α'103 class) ==~%")
(let* ((fek (format nil "Άρθρο 4~%Τροποποιήσεις Κώδικα Πολιτικής Δικονομίας~%1. Το άρθρο 773 καταργείται.~%2. Το άρθρο 727 καταργείται.~%3. Το άρθρο 768 τροποποιείται.~%4. Το άρθρο 537 καταργείται.~%Άρθρο 5~%Τροποποιήσεις Αστικού Κώδικα~%1. Το άρθρο 241 καταργείται.~%Άρθρο 6~%Έναρξη ισχύος~%Το άρθρο 3 τροποποιείται."))
       (ops (xops fek))
       (summary (summarize-operations ops)))
  (check "ΟΛΕΣ οι πράξεις της ενότητας ΚΠολΔ κληρονόμησαν το scope"
         (every (lambda (tgt) (equal "kpolitikis" (getf (op-for ops tgt) :code)))
                '("art_773" "art_727" "art_768" "art_537")))
  (check "η ενότητα ΑΚ δρομολογήθηκε χωριστά (art_241 → astikos)"
         (equal "astikos" (getf (op-for ops "art_241") :code)))
  (check "ενότητα ΧΩΡΙΣ ονομασία κώδικα ⇒ αδρομολόγητη (τίμια, ΟΧΙ διαρροή scope)"
         (null (getf (op-for ops "art_3") :code)))
  (check "3 κουβάδες: kpolitikis, astikos, ΚΑΙ ρητός NIL (το αδρομολόγητο ΥΠΑΡΧΕΙ)"
         (and (= 3 (length summary))
              (equal '("kpolitikis" "astikos") (remove nil (mapcar #'car summary)))
              (member nil (mapcar #'car summary)))))

;;; (3) το scope ΔΕΝ διαρρέει μέσα από παράθεση «…»
(format t "~%== (3) μάσκα παράθεσης: «…» δεν ορίζει scope ==~%")
(let* ((fek (format nil "Άρθρο 1~%Τροποποιήσεις Ποινικού Κώδικα~%1. Το άρθρο 5 αντικαθίσταται ως εξής: «Άρθρο 5. Κατά τον Αστικό Κώδικα κρίνεται η αποζημίωση.»~%2. Το άρθρο 6 καταργείται."))
       (ops (xops fek)))
  (check "art_6 έμεινε στο poinikos (η μνεία «Αστικό Κώδικα» ΜΕΣΑ στο «…» δεν μετρά)"
         (equal "poinikos" (getf (op-for ops "art_6") :code))))

;;; (4) αλλαγή scope ΜΕΣΑ στην ενότητα (ρητή νέα ονομασία)
(format t "~%== (4) ρητή νέα ονομασία μέσα στην ενότητα αλλάζει το scope ==~%")
(let* ((fek (format nil "Άρθρο 1~%1. Το άρθρο 12 του Ποινικού Κώδικα καταργείται.~%2. Στον Αστικό Κώδικα, το άρθρο 200 τροποποιείται."))
       (ops (xops fek)))
  (check "art_12 → poinikos" (equal "poinikos" (getf (op-for ops "art_12") :code)))
  (check "art_200 → astikos (rightmost ρητή ονομασία υπερισχύει)"
         (equal "astikos" (getf (op-for ops "art_200") :code))))

;;; (5) ΧΩΡΙΣ resolver ⇒ ΚΑΜΙΑ δρομολόγηση (τίμια — καμία κρυφή λίστα)
(format t "~%== (5) χωρίς resolver ⇒ :code NIL παντού ==~%")
(let ((ops (extract-operations "Το άρθρο 5 του Ποινικού Κώδικα καταργείται.")))
  (check "χωρίς resolver: πράξη εξάγεται, code NIL"
         (and (= 1 (length ops)) (null (getf (first ops) :code)))))

;;; (6) επαλήθευση κατά ταυτότητας (census oracle)
(format t "~%== (6) ταυτότητα: το άρθρο υπάρχει/δεν υπάρχει στον κώδικα ==~%")
(let* ((oracle (lambda (code base)
                 (cond ((not (equal code "kpolitikis")) :unknown)
                       ((member base '("773" "727") :test #'equal) t)
                       (t nil))))
       (fek (format nil "Άρθρο 1~%Τροποποιήσεις Κώδικα Πολιτικής Δικονομίας~%1. Το άρθρο 773 καταργείται.~%2. Το άρθρο 9999 καταργείται."))
       (ops (xops fek :exists oracle)))
  (check "υπαρκτό άρθρο ⇒ :identity :verified, μένει :high"
         (let ((o (op-for ops "art_773")))
           (and (eq :verified (getf o :identity)) (eq :high (getf o :confidence)))))
  (check "ΑΝΥΠΑΡΚΤΟ άρθρο ⇒ :identity :contradicted + ΥΠΟΒΙΒΑΣΜΟΣ σε :low (όχι αυτο-εφαρμογή)"
         (let ((o (op-for ops "art_9999")))
           (and (eq :contradicted (getf o :identity)) (eq :low (getf o :confidence))
                (not (operation-applicable-p o)))))
  (check ":unknown ⇒ καμία αξίωση ταυτότητας"
         (let* ((fek2 "Το άρθρο 5 του Ποινικού Κώδικα καταργείται.")
                (o (first (xops fek2 :exists oracle))))
           (and (null (getf o :identity)) (eq :high (getf o :confidence))))))

;;; (7) δρομολόγηση από αναφορά νόμου (ν. 4619/2019) με αριθμητικά όρια
(format t "~%== (7) law-number routing + όρια ==~%")
(let ((ops (xops "Στον ν. 4619/2019, το άρθρο 187 τροποποιείται.")))
  (check "ν. 4619/2019 → poinikos" (equal "poinikos" (getf (op-for ops "art_187") :code))))
(let ((ops (xops "Στον ν. 14619/2019, το άρθρο 187 τροποποιείται.")))
  (check "14619/2019 ΔΕΝ είναι 4619/2019 (όρια αριθμών) ⇒ αδρομολόγητο"
         (null (getf (op-for ops "art_187") :code))))

;;; (8) μη-τροποποιητικό κείμενο ⇒ τίποτα
(format t "~%== (9) κριτής #9: κεφαλίδα ΑΡΘΡΟ/ΆΡΘΡΟ κεφαλαία ⇒ όριο ενότητας ==~%")
(let* ((fek (format nil "ΑΡΘΡΟ 4~%Τροποποιήσεις Κώδικα Πολιτικής Δικονομίας~%1. Το άρθρο 773 καταργείται.~%ΆΡΘΡΟ 5~%Τροποποιήσεις Αστικού Κώδικα~%1. Το άρθρο 241 καταργείται."))
       (ops (xops fek)))
  (check "ΑΡΘΡΟ (άτονα κεφαλαία) κεφαλίδα ⇒ scope kpolitikis"
         (equal "kpolitikis" (getf (op-for ops "art_773") :code)))
  (check "ΆΡΘΡΟ (τονισμένα κεφαλαία) κεφαλίδα ⇒ νέα ενότητα, scope astikos"
         (equal "astikos" (getf (op-for ops "art_241") :code))))

(format t "~%== (10) κριτής #4: «Άρθρο Ν» ΜΕΣΑ σε πολύγραμμη παράθεση ≠ κεφαλίδα ==~%")
(let* ((fek (format nil "Άρθρο 1~%Τροποποιήσεις Ποινικού Κώδικα~%1. Το άρθρο 5 αντικαθίσταται ως εξής: «Άρθρο 5.~%Νέο κείμενο πρώτης παραγράφου.~%2. Δεύτερη παράγραφος.»~%2. Το άρθρο 6 καταργείται."))
       (ops (xops fek)))
  (check "quoted «Άρθρο 5.» σε αρχή γραμμής ΔΕΝ άνοιξε ψευδο-ενότητα — art_6 → poinikos"
         (equal "poinikos" (getf (op-for ops "art_6") :code))))

(format t "~%== (11) κριτής #6: παραπομπή σε ξένη ρήτρα ΔΕΝ κάνει hijack ==~%")
(let* ((fek (format nil "Άρθρο 1~%Τροποποιήσεις Ποινικού Κώδικα~%1. Το άρθρο 5 αντικαθίσταται ως εξής: «Νέο.»~%2. Η εκτέλεση χωρεί κατά τα άρθρα 176 του Κώδικα Πολιτικής Δικονομίας όπως ισχύουν.~%3. Το άρθρο 20 καταργείται."))
       (ops (xops fek)))
  (check "art_20 → poinikos (η παραπομπή σε ΚΠολΔ σε ΑΛΛΗ ρήτρα δεν ορίζει scope)"
         (equal "poinikos" (getf (op-for ops "art_20") :code))))

(format t "~%== (12) κριτής #1: ΑΔΡΟΜΟΛΟΓΗΤΕΣ ρήτρες ίδιου art_N ΔΕΝ συγχωνεύονται ==~%")
(let ((ops (extract-operations
            (concatenate 'string
              "Άρθρο 1. Το άρθρο 92 αντικαθίσταται ως εξής: «Πρώτο.» "
              "Άρθρο 2. Το άρθρο 92 αντικαθίσταται ως εξής: «Δεύτερο.»"))))
  (check "2 πράξεις επιβιώνουν χωρίς resolver (καμία σιωπηλή συγχώνευση)"
         (and (= 2 (length ops))
              (equal '("Πρώτο." "Δεύτερο.")
                     (mapcar (lambda (o) (getf o :text)) ops)))))

(format t "~%== (13) κριτής #5: «ν.» συντομογραφία δεν κόβει το παράθυρο ==~%")
(let ((ops (xops "Το άρθρο 5 του ν. 4619/2019 (Α' 95) αντικαθίσταται ως εξής: «Χ.»")))
  (check "law-citation με «ν.» τελεία ⇒ δρομολογείται (poinikos)"
         (equal "poinikos" (getf (op-for ops "art_5") :code))))

(format t "~%== (14) ΑΥΤΟ-ΑΝΑΦΟΡΑ — το μάθημα του ΠΡΑΓΜΑΤΙΚΟΥ ΦΕΚ Α'103/2026 ==~%")
;; ΠΡΑΓΜΑΤΙΚΕΣ γραμμές από το a103.txt (pdftotext, owner run 2026-07-12):
;; νέος Κώδικας Τοπ. Αυτοδιοίκησης με ΔΙΚΑ του άρθρα — «καταργείται με το
;; άρθρο 773» είναι αυτο-αναφορά στο δικό του άρθρο καταργουμένων.
(let* ((fek (format nil "Άρθρο 241 Ενημέρωση δημοτικών συμβουλίων~%~
Άρθρο 772 Παράταση διάρκειας ισχύος της Μονάδας Σύνταξης και Εφαρμογής Κώδικα Τοπικής Αυτοδιοίκησης~%~
ΜΕΡΟΣ Ε'~%ΚΑΤΑΡΓΟΥΜΕΝΕΣ ΔΙΑΤΑΞΕΙΣ~%~
Άρθρο 773 Καταργούμενες διατάξεις~%~
Άρθρο 183~%Μεταβατικές διατάξεις~%~
1. Μέχρι τη λήξη της τρέχουσας αυτοδιοικητικής περιόδου, ο ανώτατος αριθμός των αντιδημάρχων του άρθρου 59 του ν. 3852/2010 (Α' 87), όπως αυτό καταργείται με το άρθρο 773, περί καταργούμενων διατάξεων, διατηρείται αμετάβλητος."))
       (ops (xops fek))
       (o773 (op-for ops "art_773")))
  (check "art_773 αναγνωρίζεται ΩΣ ΑΥΤΟ-ΑΝΑΦΟΡΑ (άρθρο του ΙΔΙΟΥ του νόμου)"
         (and o773 (getf o773 :self-reference)))
  (check "αυτο-αναφορά ⇒ :low, ΠΟΤΕ auto-εφαρμόσιμη"
         (and (eq :low (getf o773 :confidence))
              (not (operation-applicable-p o773)))))

(let* ((fek "Άρθρο 1. Το άρθρο 1527 του Αστικού Κώδικα αντικαθίσταται ως εξής: «Νέο.» Άρθρο 2. Έναρξη ισχύος.")
       (o (op-for (xops fek) "art_1527")))
  (check "γνήσια πράξη σε ΞΕΝΟ κώδικα (Α'81 class): ΔΕΝ είναι self-reference, μένει :high"
         (and o (null (getf o :self-reference)) (eq :high (getf o :confidence))
              (equal "astikos" (getf o :code)))))

(format t "~%== (8) ordinary text → no operations ==~%")
(check "plain article text yields no operations"
       (null (xops "Άρθρο 1. Η Ελλάδα είναι Προεδρευόμενη Κοινοβουλευτική Δημοκρατία.")))
(check "summary of nothing is empty" (null (summarize-operations '())))

(format t "~%========================================~%")
(format t "Amendment routing tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
