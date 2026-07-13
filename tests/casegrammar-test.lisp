;;;; tests/casegrammar-test.lisp
;;;; ============================================================================
;;;; ΓΡΑΜΜΑΤΙΚΗ ΠΤΩΣΕΩΝ — regression lock της ανάθεσης ρόλων (θέμα=ΚΕΦΑΛΗ)
;;;; ============================================================================
;;;; Κλειδώνει το [0074] bug + τη μη-παλινδρόμηση:
;;;;   · «τα ξένα κινητά εργαλεία» ⇒ θέμα = ΕΡΓΑΛΕΙΑ (κεφαλή), ΟΧΙ «ξένα» (επίθετο)·
;;;;     τα επίθετα → κατηγορήματα κλάσης του θέματος (:είναι :ξένο ∧ :κινητό)·
;;;;   · OVS «Τον Γιώργο σκότωσε ο Νίκος» ⇒ δράστης=Νίκος, θέμα=Γιώργος (ΑΜΕΤΑΒΛΗΤΟ)·
;;;;   · κτήτορας μόνο από ΓΕΝΙΚΗ «το πορτοφόλι της Μαρίας» ⇒ θέμα=πορτοφόλι, :ξένο·
;;;;   · μεταγενέστερο ΠΛΑΓΙΟ αιτιατικό («την παράνομη ιδιοποίηση») ΔΕΝ κλέβει το θέμα.
;;;; ============================================================================

(in-package :orchestrator.casegrammar)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(orchestrator.knowledge-packs:ensure-fresh)

(defun facts (text) (values (parse-narrative text)))
(defun has (fs subj pred obj) (member (list :γεγονός subj pred obj) fs :test #'equal))
(defun pred-obj (fs pred) ; το αντικείμενο της ΠΡΩΤΗΣ πράξης με το δοθέν κατηγόρημα
  (let ((f (find-if (lambda (x) (and (eq (first x) :γεγονός) (eq (third x) pred))) fs)))
    (and f (fourth f))))
(defun nm (kw) (and (keywordp kw) (symbol-name kw)))

(format t "~%== θέμα = ΚΕΦΑΛΗ (όχι επίθετο) + επίθετα → κλάσεις ==~%")
(let* ((fs (facts "Ο δράστης αφαίρεσε τα ξένα κινητά εργαλεία."))
       (theme (pred-obj fs :αφαιρεί)))
  (check "υπάρχει πράξη :αφαιρεί" theme)
  (check "θέμα ΔΕΝ είναι επίθετο (:ξένο/:κινητό/:παράνομο)"
         (not (member theme '(:ξένο :κινητό :παράνομο :ξένος :κινητός))))
  (check "θέμα = κεφαλή «εργαλεία»" (and theme (search "ΕΡΓΑΛΕΙ" (nm theme))))
  (check "επίθετο «ξένα» → κλάση :ξένο του θέματος" (has fs theme :είναι :ξένο))
  (check "«κινητά»/noun-class → κλάση :κινητό του θέματος" (has fs theme :είναι :κινητό)))

(format t "~%== OVS: «Τον Γιώργο σκότωσε ο Νίκος» (ΑΜΕΤΑΒΛΗΤΟ) ==~%")
(let* ((fs (facts "Τον Γιώργο σκότωσε ο Νίκος."))
       (f (find-if (lambda (x) (eq (third x) :θανατώνει)) fs)))
  (check "υπάρχει πράξη :θανατώνει" f)
  (check "δράστης = Νίκος" (and f (search "ΝΙΚ" (nm (second f)))))
  (check "θύμα = Γιώργος" (and f (search "ΓΙΩΡΓ" (nm (fourth f))))))

(format t "~%== κτήτορας από ΓΕΝΙΚΗ: «το πορτοφόλι της Μαρίας» ==~%")
(let* ((fs (facts "Ο Ανδρέας αφαίρεσε το πορτοφόλι της Μαρίας για να το ιδιοποιηθεί."))
       (theme (pred-obj fs :αφαιρεί)))
  (check "θέμα = πορτοφόλι (όχι Μαρίας/κτήτορας)" (and theme (search "ΠΟΡΤΟΦ" (nm theme))))
  (check "κτήτορας ≠ δράστης ⇒ :ξένο" (has fs theme :είναι :ξένο))
  (check "σκοπός ιδιοποίησης (ρήμα «ιδιοποιηθεί»)"
         (find-if (lambda (x) (and (eq (third x) :σκοπός))) fs)))

(format t "~%== μεταγενέστερο πλάγιο αιτιατικό ΔΕΝ κλέβει το θέμα ==~%")
(let* ((fs (facts "Ο δράστης αφαίρεσε τα ξένα κινητά εργαλεία με σκοπό την παράνομη ιδιοποίηση."))
       (theme (pred-obj fs :αφαιρεί)))
  (check "θέμα παραμένει «εργαλεία» παρά το «την παράνομη»"
         (and theme (search "ΕΡΓΑΛΕΙ" (nm theme)))))

(format t "~%== άρνηση ΑΜΕΤΑΒΛΗΤΗ ==~%")
(check "«δεν αφαίρεσε» ⇒ :άρνηση, κανένα καταφατικό :αφαιρεί"
       (let ((fs (facts "Ο δράστης δεν αφαίρεσε τα εργαλεία.")))
         (and (find-if (lambda (x) (eq (first x) :άρνηση)) fs)
              (not (find-if (lambda (x) (and (eq (first x) :γεγονός) (eq (third x) :αφαιρεί))) fs)))))

(format t "~%========================================~%")
(format t "CASEGRAMMAR tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
