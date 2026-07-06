;;;; systems/orchestrator-cli/generation-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΗΣ ΓΡΑΜΜΑΤΙΚΗΣ — η ορθή ελληνική, κλειδωμένη για πάντα
;;;; ============================================================================
;;;;
;;;; Κάθε μορφή που παράγει η γένεση λόγου ελέγχεται εδώ κατά την ΠΑΡΑΔΟΣΙΑΚΗ
;;;; γραμματική — με τον ΚΑΝΟΝΑ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ ρητό: το τελικό ν στο
;;;; «τον/την/στον/στην» ΔΕΝ πέφτει ποτέ (στον δικηγόρο, στην σύζυγο, στο παιδί —
;;;; τα ίδια του τα παραδείγματα). Και ο κύκλος κλείνει: ό,τι λέει η γένεση,
;;;; η κατανόηση το αναγνωρίζει (ίδιο λεξικό, δύο κατευθύνσεις).

(in-package :orchestrator.cli)

(defparameter *generation-suite*
  `(;; Ο ΚΑΝΟΝΑΣ ΤΟΥ ΔΗΜΙΟΥΡΓΟΥ: τελικό ν ΠΑΝΤΑ — τα δικά του παραδείγματα
    ("στον δικηγόρο"   ,(lambda () (orchestrator.generation:pp-se "δικηγόρος")))
    ("στην σύζυγο"     ,(lambda () (orchestrator.generation:pp-se "σύζυγος")))
    ("στο παιδί"       ,(lambda () (orchestrator.generation:pp-se "παιδί")))
    ("τον νόμο"        ,(lambda () (orchestrator.generation:np "νόμος" :case :acc)))
    ("την απόφαση"     ,(lambda () (orchestrator.generation:np "απόφαση" :case :acc)))
    ("την διάταξη"     ,(lambda () (orchestrator.generation:np "διάταξη" :case :acc)))
    ;; μετακίνηση τόνου — η παραδοσιακή κλίση, όχι η τεμπέλικη
    ("της συζύγου"     ,(lambda () (orchestrator.generation:np "σύζυγος" :case :gen)))
    ("των αποφάσεων"   ,(lambda () (orchestrator.generation:np "απόφαση" :case :gen :number :pl)))
    ("των κωδίκων"     ,(lambda () (orchestrator.generation:np "κώδικας" :case :gen :number :pl)))
    ("των επεισοδίων"  ,(lambda () (orchestrator.generation:np "επεισόδιο" :case :gen :number :pl)))
    ("του δικαίου"     ,(lambda () (orchestrator.generation:np "δίκαιο" :case :gen)))
    ("των εθίμων"      ,(lambda () (orchestrator.generation:np "έθιμο" :case :gen :number :pl)))
    ("τους νόμους"     ,(lambda () (orchestrator.generation:np "νόμος" :case :acc :number :pl)))
    ;; αριθμητικά με συμφωνία γένους
    ("τρεις αποφάσεις" ,(lambda () (orchestrator.generation:count-np 3 "απόφαση")))
    ("τρία άρθρα"      ,(lambda () (orchestrator.generation:count-np 3 "άρθρο")))
    ("τέσσερις κανόνες" ,(lambda () (orchestrator.generation:count-np 4 "κανόνας")))
    ("μία διάταξη"     ,(lambda () (orchestrator.generation:count-np 1 "διάταξη")))
    ("ένα παιδί"       ,(lambda () (orchestrator.generation:count-np 1 "παιδί")))
    ("τρία παιδιά"     ,(lambda () (orchestrator.generation:count-np 3 "παιδί")))
    ;; ρηματική συμφωνία
    ("παραπέμπουν"     ,(lambda () (orchestrator.generation:vp "παραπέμπω" :pl)))
    ("εφάρμοσε"        ,(lambda () (orchestrator.generation:vp "εφαρμόζω" :sg))))
  "αναμενόμενη μορφή · παραγωγός — η ορθή γραμματική ως εκτελέσιμη αλήθεια.")

(defun run-generation-gate ()
  "--generation-gate : η πύλη της γραμματικής. Ελέγχει ΚΑΙ τον κύκλο
   γένεση→κατανόηση (ό,τι λέει, το αναγνωρίζει). Μία αποτυχία ⇒ exit 1."
  (let ((fails 0) (total 0))
    (dolist (case-entry *generation-suite*)
      (destructuring-bind (expected fn) case-entry
        (incf total)
        (let ((got (funcall fn)))
          (if (string= got expected)
              (format t "  ✓ ~A~%" got)
              (progn (incf fails)
                     (format t "  ✗ περίμενα «~A», πήρα «~A»~%" expected got))))))
    ;; Ο ΚΥΚΛΟΣ: κάθε μορφή που παράγεται πρέπει να ΑΝΑΓΝΩΡΙΖΕΤΑΙ (ίδιο λεξικό)
    (dolist (probe '(("αποφάσεων" . "απόφαση") ("συζύγου" . "σύζυγος")
                     ("παιδιά" . "παιδί") ("νόμους" . "νόμος")))
      (incf total)
      (let ((lemma (orchestrator.citation-authority:known-lemma (car probe))))
        (if (equal lemma (cdr probe))
            (format t "  ✓ κατανόηση: ~A → ~A~%" (car probe) lemma)
            (progn (incf fails)
                   (format t "  ✗ κατανόηση: ~A → ~A (περίμενα ~A)~%"
                           (car probe) lemma (cdr probe))))))
    ;; Φάση 4: το ΛΕΞΙΛΟΓΙΟ ΩΣ ΓΝΩΣΗ — σκιώδης εγκατάσταση πακέτου :lexicon:
    ;; νέο ουσιαστικό κλίνεται ΚΑΙ αναγνωρίζεται, νέο λήμμα αναγνωρίζεται, και
    ;; μετά την επαναφορά ΔΕΝ μένει ίχνος (η υποψήφια γνώση δεν μολύνει)
    (let ((tmp (merge-pathnames (format nil "gengate-lex-~D.sexp" (get-universal-time))
                                (uiop:temporary-directory))))
      (with-open-file (s tmp :direction :output :if-exists :supersede
                         :external-format :utf-8)
        (write-string "(:knowledge-pack :lexicon 1
 (:noun \"πληρεξούσιο\" :n :n-o \"πληρεξούσι\" \"πληρεξουσί\")
 (:lemma \"αντέφεση\" (\"αντέφεσης\" \"αντεφέσεις\" \"αντεφέσεων\")))" s))
      (orchestrator.knowledge-packs:with-packs-overlay (list tmp)
        (lambda ()
          (incf total)
          (let ((got (orchestrator.generation:noun-form "πληρεξούσιο" :gen :pl)))
            (if (string= got "πληρεξουσίων")
                (format t "  ✓ πακέτο :lexicon — κλίση: των πληρεξουσίων~%")
                (progn (incf fails) (format t "  ✗ πακέτο :lexicon κλίση: πήρα «~A»~%" got))))
          (incf total)
          (if (and (equal "πληρεξούσιο" (orchestrator.citation-authority:known-lemma "πληρεξουσίων"))
                   (equal "αντέφεση" (orchestrator.citation-authority:known-lemma "αντεφέσεων")))
              (format t "  ✓ πακέτο :lexicon — κατανόηση: πληρεξουσίων/αντεφέσεων~%")
              (progn (incf fails) (format t "  ✗ πακέτο :lexicon — η κατανόηση δεν βλέπει τη νέα γνώση~%")))))
      (incf total)
      (if (and (null (orchestrator.citation-authority:known-lemma "αντεφέσεων"))
               (null (gethash "πληρεξούσιο" orchestrator.generation:*generation-lexicon*)))
          (format t "  ✓ πακέτο :lexicon — η επαναφορά ΔΕΝ αφήνει ίχνος~%")
          (progn (incf fails) (format t "  ✗ πακέτο :lexicon — έμεινε ίχνος μετά την επαναφορά~%")))
      (ignore-errors (delete-file tmp)))
    (format t "~%── ΠΥΛΗ ΓΡΑΜΜΑΤΙΚΗΣ: ~D/~D πέρασαν ──~%" (- total fails) total)
    (if (plusp fails) 1 0)))

(register-command "--generation-gate" (lambda (a) (declare (ignore a)) (run-generation-gate)))

(orchestrator.self-model:declare-capability! "γένεση-ελληνικών"
 :description "ορθή κλίση/συμφωνία/τελικό-ν + κύκλος γένεση→κατανόηση"
 :package :orchestrator.generation :functions '("inflect" "agree")
 :gate "--generation-gate" :depends-on '())

;;; ── ΣΥΜΒΟΛΑΙΑ ΠΑΡΟΧΩΝ (δεσμευτική αυτοπεριγραφή — βλ. --contract-gate) ──

(orchestrator.contracts:defcontract "greek-generation-protocol" :protocol
 :package :orchestrator.generation :system "orchestrator-infrastructure"
 :capability "γένεση-ελληνικών" :role "γλώσσα"
 :purpose "ορθή κλίση/συμφωνία/τελικό-ν (inflect, agree) — ο δικηγόρος μιλά σωστά"
 :postconditions '("κύκλος γένεση→κατανόηση κλείνει: ό,τι παράγει το ξανακαταλαβαίνει")
 :policy-level :συμβουλευτικό :tests '("--generation-gate"))
