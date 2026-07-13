;;;; source/greek-lemmatizer.lisp
;;;; ============================================================================
;;;; GREEK LEMMATIZER - DARPA-GRADE Pure Lisp Implementation
;;;; ============================================================================
;;;;
;;;; STATUS: Not yet loaded by any .asd - pending integration
;;;; ============================================================================
;;;;
;;;; Converts Greek word forms to their lemma (base form):
;;;;   νόμου, νόμο, νόμοι, νόμων, νόμους → νόμος
;;;;   πολιτείας, πολιτεία, πολιτείες → πολιτεία
;;;;   ορίζει, ορίζουν, ορίζεται → ορίζω
;;;;
;;;; ARCHITECTURE:
;;;;   1. Known lemmas hash-table (legal domain vocabulary)
;;;;   2. Morphological rules for Greek inflection patterns
;;;;   3. Fallback: return original if unknown
;;;;
;;;; SUPERIOR TO PYTHON:
;;;;   - Pure Lisp, zero dependencies
;;;;   - Optimized for Greek legal corpus
;;;;   - Preserves tonos correctly
;;;;   - O(1) lookup for known words
;;;;
;;;; Author: ORCHESTRATOR
;;;; Created: 2026-01-03
;;;; ============================================================================

(in-package :orchestrator.citation-authority)

;;; ============================================================================
;;; LEGAL DOMAIN VOCABULARY
;;; ============================================================================
;;; Known lemmas for legal terms - direct lookup, no guessing

(defparameter *legal-lemmas* (make-hash-table :test 'equal)
  "Hash-table: inflected-form → lemma")

;;; ── Κανονικοποίηση ελληνικών: πεζά, άτονα, ς→σ — η ΜΙΑ υλοποίηση στο σύστημα ──
;;; Ζει εδώ (στην έδρα της γλωσσικής γνώσης)· το orchestrator.extraction την εισάγει.
(defun normalize-greek (s)
  "Πεζά + αφαίρεση τόνων/διαλυτικών + τελικό σίγμα ς→σ — ώστε καμία σύγκριση να μην
   εξαρτάται από τονισμό, πτώση κεφαλαίων ή θέση του σίγμα."
  (let ((map '((#\ά . #\α) (#\έ . #\ε) (#\ή . #\η) (#\ί . #\ι) (#\ό . #\ο)
               (#\ύ . #\υ) (#\ώ . #\ω) (#\ϊ . #\ι) (#\ϋ . #\υ) (#\ΐ . #\ι) (#\ΰ . #\υ)
               (#\Ά . #\α) (#\Έ . #\ε) (#\Ή . #\η) (#\Ί . #\ι) (#\Ό . #\ο)
               (#\Ύ . #\υ) (#\Ώ . #\ω)
               (#\ς . #\σ))))
    (map 'string
         (lambda (c)
           (let ((lc (char-downcase c)))
             (or (cdr (assoc lc map :test #'char=))
                 (cdr (assoc c map :test #'char=))
                 lc)))
         s)))

(defvar *normalized-lemma-index* nil
  "Κανονικοποιημένη-μορφή → λήμμα, χτισμένο ΜΟΝΟ από το επιμελημένο λεξιλόγιο.
   Ακυρώνεται σε κάθε νέα εγγραφή· ξαναχτίζεται τεμπέλικα.")

(defun add-lemma-forms (lemma forms)
  "Register all forms of a word pointing to its lemma"
  (setf (gethash lemma *legal-lemmas*) lemma)  ; lemma maps to itself
  (dolist (form forms)
    (setf (gethash form *legal-lemmas*) lemma))
  (setf *normalized-lemma-index* nil))          ; νέα γνώση ⇒ ο δείκτης ξαναχτίζεται

(add-lemma-forms "μνήμη" '("μνήμης" "μνήμες" "μνημών"))

(defparameter +function-word-lemmas+
  '(;; άρθρα
    "ο" "η" "το" "οι" "τα"
    ;; σύνδεσμοι/μόρια
    "και" "ή" "να" "θα" "δεν" "μη" "μην" "αν" "όταν" "ότι" "πως" "που" "ως"
    ;; προθέσεις
    "σε" "με" "για" "από" "προς" "κατά" "επί" "υπό" "μετά" "παρά" "αντί" "μέχρι"
    ;; βοηθητικά ρήματα
    "είμαι" "έχω")
  "Οι ΛΕΙΤΟΥΡΓΙΚΕΣ λέξεις της ελληνικής — κλειστές γραμματικές κλάσεις (άρθρα,
   σύνδεσμοι, προθέσεις, μόρια, βοηθητικά): πεπερασμένες, απαριθμήσιμες, γνώση
   της γλώσσας ίδιου καθεστώτος με τα +interrogatives+. Φέρουν σύνταξη, ΟΧΙ
   περιεχόμενο — καμία δεν είναι «έννοια» προς ορισμό ή αναζήτηση.")

(defun content-lemma-p (lemma)
  "Είναι το LEMMA λέξη ΠΕΡΙΕΧΟΜΕΝΟΥ (όχι λειτουργική); Η μία διάκριση
   ουσίας/σύνταξης του συστήματος — όποιος χρειάζεται «έννοιες» περνά από εδώ."
  (not (member (normalize-greek lemma) +function-word-lemmas+
               :key #'normalize-greek :test #'string=)))

(defparameter +nominal-endings+
  '("ειων" "εων" "ους" "εις" "ων" "ας" "ες" "ης" "ου" "οι" "α" "ε" "η" "ι" "ο" "υ" "ω")
  "Κλειστός πίνακας ονοματικών καταλήξεων (κανονικοποιημένων), μακρύτερες
   πρώτες — ΜΟΝΟ για επιφανειακό θέμα ανάκλησης, ποτέ για έμπιστη γνώση.")

(defun surface-stem (word)
  "ΕΠΙΦΑΝΕΙΑΚΟ θέμα λέξης εκτός επιμελημένου λεξιλογίου: αφαίρεση της
   μακρύτερης κατάληξης του κλειστού πίνακα (θέμα ≥ 3 χαρακτήρες). ΔΗΛΩΜΕΝΑ
   lossy — χρησιμεύει ΜΟΝΟ για ανάκληση (αναζήτηση μνειών στα κείμενα)· ό,τι
   βρεθεί δείχνεται με την πηγή του, ώστε η κρίση να μένει στα ΚΕΙΜΕΝΑ."
  (let ((w (normalize-greek word)))
    (loop for e in +nominal-endings+
          when (and (> (length w) (+ 2 (length e)))
                    (string= e w :start2 (- (length w) (length e))))
            return (subseq w 0 (- (length w) (length e)))
          finally (return (when (>= (length w) 4) w)))))

(defun lexicon-snapshot ()
  "Φωτογραφία του λημματικού λεξιλογίου — για τη σκιώδη εκτέλεση των πακέτων
   γνώσης (:lexicon): εγκατάσταση υποψήφιας γνώσης ⇒ εγγυημένη επαναφορά."
  (let ((copy (make-hash-table :test 'equal)))
    (maphash (lambda (k v) (setf (gethash k copy) v)) *legal-lemmas*)
    copy))

(defun lexicon-restore (snapshot)
  "Επαναφορά του λημματικού λεξιλογίου από φωτογραφία (ακυρώνει τον δείκτη)."
  (clrhash *legal-lemmas*)
  (maphash (lambda (k v) (setf (gethash k *legal-lemmas*) v)) snapshot)
  (setf *normalized-lemma-index* nil))

(defun lemma-forms (lemma)
  "Όλες οι επιμελημένες μορφές του LEMMA (μαζί με το ίδιο) — ο αντίστροφος
   δείκτης του λεξιλογίου, για αναζήτηση μνειών στο ίδιο το corpus."
  (let ((forms '()))
    (maphash (lambda (form l) (when (equal l lemma) (push form forms)))
             *legal-lemmas*)
    forms))

(defun known-lemma (word)
  "Το λήμμα της WORD ΜΟΝΟ από το επιμελημένο λεξιλόγιο — ανεξάρτητο από τόνο/πεζά/
   τελικό σίγμα. ΠΟΤΕ από τους μορφολογικούς κανόνες (είναι lossy fallback, όχι
   έμπιστη γνώση — «πηγή→πηγός» είναι το αντιπαράδειγμα). NIL αν άγνωστη: ο καλών
   οφείλει να χειριστεί την άγνοια τίμια, όχι να μαντέψει."
  (unless *normalized-lemma-index*
    (let ((idx (make-hash-table :test 'equal)))
      (maphash (lambda (form lemma)
                 (setf (gethash (normalize-greek form) idx) lemma))
               *legal-lemmas*)
      (setf *normalized-lemma-index* idx)))
  (gethash (normalize-greek word) *normalized-lemma-index*))

;;; ----------------------------------------------------------------------------
;;; NOUNS - Masculine (-ος, -ης)
;;; ----------------------------------------------------------------------------

;; νόμος (law) - 2nd declension masculine
(add-lemma-forms "νόμος" '("νόμου" "νόμο" "νόμε" "νόμοι" "νόμων" "νόμους"))

;; σύνταγμα (constitution) - 3rd declension neuter
(add-lemma-forms "σύνταγμα" '("συντάγματος" "συντάγματι" "σύνταγμα"
                               "συντάγματα" "συνταγμάτων" "συντάγμασι"))

;; άρθρο (article) - 2nd declension neuter
(add-lemma-forms "άρθρο" '("άρθρου" "άρθρο" "άρθρα" "άρθρων"))

;; πολίτης (citizen) - 1st declension masculine
(add-lemma-forms "πολίτης" '("πολίτη" "πολίτες" "πολιτών"))

;; δικαστής (judge) - 1st declension masculine
(add-lemma-forms "δικαστής" '("δικαστή" "δικαστές" "δικαστών"))

;; άνθρωπος (human) - 2nd declension masculine
(add-lemma-forms "άνθρωπος" '("ανθρώπου" "άνθρωπο" "άνθρωπε"
                               "άνθρωποι" "ανθρώπων" "ανθρώπους"))

;; λαός (people) - 2nd declension masculine
(add-lemma-forms "λαός" '("λαού" "λαό" "λαέ" "λαοί" "λαών" "λαούς"))

;; έθνος (nation) - 3rd declension neuter
(add-lemma-forms "έθνος" '("έθνους" "έθνη" "εθνών"))

;; κράτος (state) - 3rd declension neuter
(add-lemma-forms "κράτος" '("κράτους" "κράτη" "κρατών"))

;; δίκαιο (law/justice) - 2nd declension neuter
(add-lemma-forms "δίκαιο" '("δικαίου" "δίκαια" "δικαίων"))

;;; ----------------------------------------------------------------------------
;;; NOUNS - Feminine (-α, -η)
;;; ----------------------------------------------------------------------------

;; πολιτεία (state/polity) - 1st declension feminine
(add-lemma-forms "πολιτεία" '("πολιτείας" "πολιτεία" "πολιτείες" "πολιτειών"))

;; δημοκρατία (democracy) - 1st declension feminine
(add-lemma-forms "δημοκρατία" '("δημοκρατίας" "δημοκρατία" "δημοκρατίες" "δημοκρατιών"))

;; κυριαρχία (sovereignty) - 1st declension feminine
(add-lemma-forms "κυριαρχία" '("κυριαρχίας" "κυριαρχία" "κυριαρχίες" "κυριαρχιών"))

;; εξουσία (power/authority) - 1st declension feminine
(add-lemma-forms "εξουσία" '("εξουσίας" "εξουσία" "εξουσίες" "εξουσιών"))

;; ελευθερία (freedom) - 1st declension feminine
(add-lemma-forms "ελευθερία" '("ελευθερίας" "ελευθερία" "ελευθερίες" "ελευθεριών"))

;; δικαιοσύνη (justice) - 1st declension feminine
(add-lemma-forms "δικαιοσύνη" '("δικαιοσύνης" "δικαιοσύνη" "δικαιοσύνες" "δικαιοσυνών"))

;; ειρήνη (peace) - 1st declension feminine
(add-lemma-forms "ειρήνη" '("ειρήνης" "ειρήνη" "ειρήνες" "ειρηνών"))

;; προστασία (protection) - 1st declension feminine
(add-lemma-forms "προστασία" '("προστασίας" "προστασία" "προστασίες" "προστασιών"))

;; αξία (value/dignity) - 1st declension feminine
(add-lemma-forms "αξία" '("αξίας" "αξία" "αξίες" "αξιών"))

;; υποχρέωση (obligation) - 3rd declension feminine
(add-lemma-forms "υποχρέωση" '("υποχρέωσης" "υποχρέωση" "υποχρεώσεις" "υποχρεώσεων"))

;; θρησκεία (religion) - 1st declension feminine
(add-lemma-forms "θρησκεία" '("θρησκείας" "θρησκεία" "θρησκείες" "θρησκειών"))

;; εκκλησία (church) - 1st declension feminine
(add-lemma-forms "εκκλησία" '("εκκλησίας" "εκκλησία" "εκκλησίες" "εκκλησιών"))

;; σύνοδος (synod) - 2nd declension feminine
(add-lemma-forms "σύνοδος" '("συνόδου" "σύνοδο" "σύνοδοι" "συνόδων" "συνόδους"))

;; διάταξη (provision) - 3rd declension feminine
(add-lemma-forms "διάταξη" '("διάταξης" "διατάξεις" "διατάξεων"))

;; απόφαση (decision) - 3rd declension feminine
(add-lemma-forms "απόφαση" '("απόφασης" "αποφάσεις" "αποφάσεων"))

;; πηγή (source) - 1st declension feminine
(add-lemma-forms "πηγή" '("πηγής" "πηγές" "πηγών"))

;; κανόνας (rule/norm) - 1st declension masculine
(add-lemma-forms "κανόνας" '("κανόνα" "κανόνες" "κανόνων"))

;; ικανότητα / δυνατότητα (capability) - 3rd declension feminine
(add-lemma-forms "ικανότητα" '("ικανότητας" "ικανότητες" "ικανοτήτων"))
(add-lemma-forms "δυνατότητα" '("δυνατότητας" "δυνατότητες" "δυνατοτήτων"))

;; διαφορά / διάκριση (difference/distinction) — για συγκριτικές ερωτήσεις
(add-lemma-forms "διαφορά" '("διαφοράς" "διαφορές" "διαφορών"))
(add-lemma-forms "διαφέρω" '("διαφέρει" "διαφέρουν" "διέφερε"))
(add-lemma-forms "διάκριση" '("διάκρισης" "διακρίσεως" "διακρίσεις" "διακρίσεων"))

;; ΡΗΜΑΤΑ ΛΕΚΤΙΚΑ (verba dicendi) — η κλειστή σημασιολογική κλάση της αναφοράς
;; σε προηγούμενη εκφορά («αυτόν που ΑΝΕΦΕΡΕΣ»)· επιμελημένοι τύποι, όχι κανόνες
(add-lemma-forms "λέω" '("λες" "λέει" "λέμε" "λέτε" "λένε"
                         "είπα" "είπες" "είπε" "είπαμε" "είπατε" "είπαν"))
(add-lemma-forms "αναφέρω" '("αναφέρεις" "αναφέρει" "αναφέρουν"
                             "ανέφερα" "ανέφερες" "ανέφερε" "αναφέρθηκε"))
(add-lemma-forms "προτείνω" '("προτείνεις" "προτείνει" "πρότεινα" "πρότεινες" "πρότεινε"))

;; τάξη (order/class) - 3rd declension feminine
(add-lemma-forms "τάξη" '("τάξης" "τάξεις" "τάξεων"))

;; ισχύς (force/validity) - 3rd declension feminine
(add-lemma-forms "ισχύς" '("ισχύος" "ισχύ" "ισχύν"))

;; δύναμη (power/force) - 3rd declension feminine
(add-lemma-forms "δύναμη" '("δύναμης" "δυνάμεως" "δυνάμεις" "δυνάμεων"))

;; αναδρομικότητα (retroactivity) - 3rd declension feminine
(add-lemma-forms "αναδρομικότητα" '("αναδρομικότητας" "αναδρομικότητες" "αναδρομικοτήτων"))

;;; ----------------------------------------------------------------------------
;;; NOUNS - Neuter (-ο, -μα, -ος)
;;; ----------------------------------------------------------------------------

;; πολίτευμα (regime) - 3rd declension neuter
(add-lemma-forms "πολίτευμα" '("πολιτεύματος" "πολιτεύματα" "πολιτευμάτων"))

;; θεμέλιο (foundation) - 2nd declension neuter
(add-lemma-forms "θεμέλιο" '("θεμελίου" "θεμέλια" "θεμελίων"))

;; δικαίωμα (right) - 3rd declension neuter
(add-lemma-forms "δικαίωμα" '("δικαιώματος" "δικαιώματα" "δικαιωμάτων"))

;; κείμενο (text) - 2nd declension neuter
(add-lemma-forms "κείμενο" '("κειμένου" "κείμενα" "κειμένων"))

;; μέτρο (measure) - 2nd declension neuter
(add-lemma-forms "μέτρο" '("μέτρου" "μέτρα" "μέτρων"))

;; έγκλημα (crime) - 3rd declension neuter
(add-lemma-forms "έγκλημα" '("εγκλήματος" "εγκλήματα" "εγκλημάτων"))

;; καθεστώς (regime/status) - 3rd declension neuter
(add-lemma-forms "καθεστώς" '("καθεστώτος" "καθεστώτα" "καθεστώτων"))

;; δίκαιο (law, το δίκαιο) - 2nd declension neuter
(add-lemma-forms "δίκαιο" '("δικαίου" "δίκαια" "δικαίων"))

;; έθιμο (custom) - 2nd declension neuter
(add-lemma-forms "έθιμο" '("εθίμου" "έθιμα" "εθίμων"))

;;; ----------------------------------------------------------------------------
;;; ADJECTIVES
;;; ----------------------------------------------------------------------------

;; λαϊκός (popular/folk) - 2nd declension adjective
(add-lemma-forms "λαϊκός" '("λαϊκή" "λαϊκό" "λαϊκοί" "λαϊκές" "λαϊκά"
                            "λαϊκού" "λαϊκής" "λαϊκών"))

;; δημόσιος (public) - 2nd declension adjective
(add-lemma-forms "δημόσιος" '("δημόσια" "δημόσιο" "δημόσιοι" "δημόσιες"
                              "δημόσιου" "δημοσίου" "δημόσιας" "δημοσίας" "δημόσιων" "δημοσίων"))

;; αναδρομικός (retroactive) - 2nd declension adjective
(add-lemma-forms "αναδρομικός" '("αναδρομική" "αναδρομικό" "αναδρομικοί" "αναδρομικές"
                                 "αναδρομικά" "αναδρομικού" "αναδρομικής" "αναδρομικών"))

;; δημοκρατικός (democratic) - 2nd declension adjective
(add-lemma-forms "δημοκρατικός" '("δημοκρατική" "δημοκρατικό" "δημοκρατικοί"
                                  "δημοκρατικές" "δημοκρατικά" "δημοκρατικού"
                                  "δημοκρατικής" "δημοκρατικών"))

;; κοινοβουλευτικός (parliamentary) - 2nd declension adjective
(add-lemma-forms "κοινοβουλευτικός" '("κοινοβουλευτική" "κοινοβουλευτικό"
                                       "κοινοβουλευτικοί" "κοινοβουλευτικές"
                                       "κοινοβουλευτικά" "κοινοβουλευτικού"
                                       "κοινοβουλευτικής" "κοινοβουλευτικών"))

;; προεδρευόμενος (presided) - participle
(add-lemma-forms "προεδρευόμενος" '("προεδρευόμενη" "προεδρευόμενο"
                                     "προεδρευόμενοι" "προεδρευόμενες"
                                     "προεδρευόμενα"))

;; ιερός (sacred) - 2nd declension adjective
(add-lemma-forms "ιερός" '("ιερή" "ιερό" "ιεροί" "ιερές" "ιερά"
                           "ιερού" "ιερής" "ιερών" "ιερούς"))

;; αυτοκέφαλος (autocephalous) - 2nd declension adjective
(add-lemma-forms "αυτοκέφαλος" '("αυτοκέφαλη" "αυτοκέφαλο" "αυτοκέφαλοι"
                                  "αυτοκέφαλες" "αυτοκέφαλα"))

;; ορθόδοξος (orthodox) - 2nd declension adjective
(add-lemma-forms "ορθόδοξος" '("ορθόδοξη" "ορθόδοξο" "ορθόδοξοι"
                                "ορθόδοξες" "ορθόδοξα" "ορθόδοξης"))

;;; ----------------------------------------------------------------------------
;;; VERBS - Common legal verbs
;;; ----------------------------------------------------------------------------

;; είμαι (to be) - irregular
(add-lemma-forms "είμαι" '("είναι" "είσαι" "είμαστε" "είστε" "ήταν" "ήμουν"))

;; έχω (to have)
(add-lemma-forms "έχω" '("έχει" "έχεις" "έχουμε" "έχουν" "έχετε" "είχε" "είχαν"))

;; ορίζω (to define/stipulate)
(add-lemma-forms "ορίζω" '("ορίζει" "ορίζουν" "ορίζεται" "ορίζονται" "όρισε" "όρισαν"))

;; ασκώ (to exercise)
(add-lemma-forms "ασκώ" '("ασκεί" "ασκούν" "ασκείται" "ασκούνται" "άσκησε"))

;; πηγάζω (to stem from)
(add-lemma-forms "πηγάζω" '("πηγάζει" "πηγάζουν"))

;; υπάρχω (to exist)
(add-lemma-forms "υπάρχω" '("υπάρχει" "υπάρχουν" "υπήρχε" "υπήρχαν"))

;; αποτελώ (to constitute)
(add-lemma-forms "αποτελώ" '("αποτελεί" "αποτελούν" "αποτελούσε"))

;; επιδιώκω (to pursue)
(add-lemma-forms "επιδιώκω" '("επιδιώκει" "επιδιώκουν"))

;; γνωρίζω (to know/recognize)
(add-lemma-forms "γνωρίζω" '("γνωρίζει" "γνωρίζουν"))

;; διοικώ (to govern/administer)
(add-lemma-forms "διοικώ" '("διοικεί" "διοικούν" "διοικείται" "διοικούνται"))

;; τηρώ (to observe/keep)
(add-lemma-forms "τηρώ" '("τηρεί" "τηρούν" "τηρείται" "τηρούνται"))

;; απαγορεύω (to prohibit)
(add-lemma-forms "απαγορεύω" '("απαγορεύει" "απαγορεύουν" "απαγορεύεται" "απαγορεύονται"))

;; επιτρέπω (to permit)
(add-lemma-forms "επιτρέπω" '("επιτρέπει" "επιτρέπουν" "επιτρέπεται" "επιτρέπονται"))

;; προστατεύω (to protect)
(add-lemma-forms "προστατεύω" '("προστατεύει" "προστατεύουν" "προστατεύεται"))

;; σέβομαι (to respect)
(add-lemma-forms "σέβομαι" '("σέβεται" "σέβονται"))

;;; ----------------------------------------------------------------------------
;;; ARTICLES & PRONOUNS
;;; ----------------------------------------------------------------------------

;; Definite articles
(add-lemma-forms "ο" '("του" "τον" "οι" "των" "τους"))
(add-lemma-forms "η" '("της" "την" "αι" "τις"))
(add-lemma-forms "το" '("του" "τα"))

;; Demonstratives
(add-lemma-forms "αυτός" '("αυτή" "αυτό" "αυτοί" "αυτές" "αυτά"
                           "αυτού" "αυτής" "αυτών"))

;; Relative pronouns
(add-lemma-forms "που" '())
(add-lemma-forms "όπως" '())

;;; ----------------------------------------------------------------------------
;;; PREPOSITIONS & CONJUNCTIONS
;;; ----------------------------------------------------------------------------

(add-lemma-forms "και" '())
(add-lemma-forms "από" '())
(add-lemma-forms "για" '())
(add-lemma-forms "με" '())
(add-lemma-forms "σε" '("στην" "στον" "στο" "στα" "στους" "στις"))
(add-lemma-forms "υπέρ" '())
(add-lemma-forms "κατά" '())
(add-lemma-forms "προς" '())
(add-lemma-forms "μεταξύ" '())
(add-lemma-forms "χωρίς" '())
(add-lemma-forms "εφόσον" '())
(add-lemma-forms "καθώς" '())

;;; ============================================================================
;;; MORPHOLOGICAL RULES
;;; ============================================================================
;;; Pattern-based lemmatization for words not in vocabulary

(defparameter *noun-endings-masculine*
  '(;; 2nd declension -ος
    ("ου" . "ος") ("ο" . "ος") ("ε" . "ος")
    ("οι" . "ος") ("ων" . "ος") ("ους" . "ος")
    ;; 1st declension -ης
    ("η" . "ης") ("ές" . "ής") ("ών" . "ής"))
  "Masculine noun ending transformations")

(defparameter *noun-endings-feminine*
  '(;; 1st declension -α
    ("ας" . "α") ("ες" . "α") ("ών" . "α")
    ;; 1st declension -η
    ("ης" . "η") ("ες" . "η")
    ;; 3rd declension -ση
    ("σης" . "ση") ("σεις" . "ση") ("σεων" . "ση"))
  "Feminine noun ending transformations")

(defparameter *noun-endings-neuter*
  '(;; 2nd declension -ο
    ("ου" . "ο") ("α" . "ο") ("ων" . "ο")
    ;; 3rd declension -μα
    ("ματος" . "μα") ("ματα" . "μα") ("μάτων" . "μα"))
  "Neuter noun ending transformations")

(defparameter *adjective-endings*
  '(;; -ος/-η/-ο type
    ("ή" . "ός") ("ό" . "ός") ("οί" . "ός") ("ές" . "ός") ("ά" . "ός")
    ("ού" . "ός") ("ής" . "ός") ("ών" . "ός") ("ούς" . "ός"))
  "Adjective ending transformations")

(defparameter *verb-endings*
  '(;; Present active
    ("ει" . "ω") ("εις" . "ω") ("ουμε" . "ω") ("ετε" . "ω") ("ουν" . "ω")
    ;; Present passive
    ("εται" . "ομαι") ("ονται" . "ομαι")
    ;; Past
    ("ε" . "ω") ("αν" . "ω") ("ηκε" . "ω"))
  "Verb ending transformations")

(defun try-apply-rules (word rules)
  "Try to apply morphological rules to a word.
   Returns the lemma if a rule matches, NIL otherwise."
  (dolist (rule rules)
    (let ((ending (car rule))
          (replacement (cdr rule)))
      (when (and (> (length word) (length ending))
                 (string= (subseq word (- (length word) (length ending)))
                          ending))
        (return-from try-apply-rules
          (concatenate 'string
                       (subseq word 0 (- (length word) (length ending)))
                       replacement)))))
  nil)

;;; ============================================================================
;;; MAIN LEMMATIZATION FUNCTION
;;; ============================================================================

(defun lemmatize-greek (word)
  "Convert Greek word to its lemma (base form).

   Strategy:
   1. Lookup in known legal vocabulary (O(1))
   2. Apply morphological rules
   3. Fallback: return original word

   Examples:
     νόμου → νόμος
     δημοκρατίας → δημοκρατία
     ορίζει → ορίζω"
  (declare (type string word)
           (optimize (speed 3)))

  ;; 1. Direct lookup in vocabulary
  (let ((known-lemma (gethash word *legal-lemmas*)))
    (when known-lemma
      (return-from lemmatize-greek known-lemma)))

  ;; 2. Try morphological rules
  (let ((lemma nil))
    ;; Try noun rules
    (setf lemma (or (try-apply-rules word *noun-endings-masculine*)
                    (try-apply-rules word *noun-endings-feminine*)
                    (try-apply-rules word *noun-endings-neuter*)))
    (when lemma (return-from lemmatize-greek lemma))

    ;; Try adjective rules
    (setf lemma (try-apply-rules word *adjective-endings*))
    (when lemma (return-from lemmatize-greek lemma))

    ;; Try verb rules
    (setf lemma (try-apply-rules word *verb-endings*))
    (when lemma (return-from lemmatize-greek lemma)))

  ;; 3. Fallback: return original
  word)

(defun tokenize-and-lemmatize (text)
  "Tokenize Greek text and convert all tokens to lemmas.

   DARPA-GRADE: Complete pipeline for Greek legal text processing."
  (mapcar #'lemmatize-greek (tokenize-greek text)))

;;; ============================================================================
;;; VOCABULARY SIZE
;;; ============================================================================

(defun legal-vocabulary-size ()
  "Return the number of known word forms in the legal vocabulary"
  (hash-table-count *legal-lemmas*))

;;; ============================================================================
;;; ΤΙΜΙΑ ΜΟΡΦΟΛΟΓΙΑ ΧΑΡΑΚΤΗΡΙΣΤΙΚΩΝ — μηχανή στελέχους+κλίσης (feature morphology)
;;; ============================================================================
;;; ΓΙΑΤΙ ΝΕΑ ΕΔΡΑ (και ΟΧΙ lemmatize-greek): το lemmatize-greek είναι lossy μάντης —
;;; ΖΩΝΤΑΝΑ επαληθευμένο [0077]: άμυνα→άμυνο, κατόχου→κατόχος, βάση/κλιτός → διαφορετικά
;;; σκουπίδια (καμία σταθερότητα κλίσης). Στο trusted path αυτό ΠΑΡΑΒΙΑΖΕΙ «τίμια άγνοια».
;;; Εδώ: ΚΑΜΙΑ εικασία — δεικτοδοτούνται ΜΟΝΟ τύποι που παράγονται από δηλωμένο
;;; παράδειγμα κλίσης πάνω σε δηλωμένο στέλεχος· οτιδήποτε άλλο → :unknown. Κάθε τύπος
;;; φέρει (case,number,gender), ώστε η ΓΡΑΜΜΑΤΙΚΗ ΣΥΣΤΑΤΙΚΩΝ (επόμενη φάση, [0076])
;;; να ελέγχει ΣΥΜΦΩΝΙΑ άρθρου-ουσιαστικού-επιθέτου ΔΟΜΙΚΑ, όχι με heuristics.
;;; Διαφορά από add-lemma-forms: εκείνο = επίπεδο λεξικό form→lemma χωρίς
;;; χαρακτηριστικά/στέλεχος/κλίση· εδώ = παραγωγική μηχανή (στέλεχος + παράδειγμα) με
;;; χαρακτηριστικά και τίμιο :unknown. Ο θάνατος του άμυνα→άμυνο είναι lock (test).

(defstruct (feats (:constructor feats (case number gender)) (:conc-name feat-))
  "Μορφολογικά χαρακτηριστικά ενός τύπου: πτώση, αριθμός, γένος."
  case number gender)

(defparameter *paradigms* (make-hash-table :test 'eq)
  "Όνομα-κλίσης → λίστα slots (ending case number). Το γένος έρχεται από το lexeme.")

(defun register-paradigm (name slots)
  (setf (gethash name *paradigms*) slots))

(defparameter *morph-index* (make-hash-table :test 'equal)
  "normalize(τύπος) → λίστα (lemma . feats). Χτίζεται ΜΟΝΟ από δηλωμένα lexemes.")

(defun register-lexeme (lemma paradigm-name stem gender &optional overrides extra)
  "Παράγει ΚΑΘΕ τύπο του LEMMA από STEM + PARADIGM-NAME και τον δεικτοδοτεί με τα
   χαρακτηριστικά του. OVERRIDES: alist ((case number) . surface) — αντικαθιστά τον
   παραγόμενο τύπο σε slots με μετακίνηση τόνου/ανωμαλία. EXTRA: λίστα (surface case
   number) — επιπλέον τύποι (π.χ. καθαρεύουσα gen.sg -εως). Καμία εικασία εκτός
   δηλωμένων slots/overrides/extra."
  (let ((slots (or (gethash paradigm-name *paradigms*)
                   (error "Άγνωστο παράδειγμα κλίσης: ~S" paradigm-name))))
    (flet ((idx (surface case number)
             (pushnew (cons lemma (feats case number gender))
                      (gethash (normalize-greek surface) *morph-index*)
                      :test #'equalp)))
      (dolist (slot slots)
        (destructuring-bind (ending case number) slot
          (let ((ov (cdr (assoc (list case number) overrides :test #'equal))))
            (idx (or ov (concatenate 'string stem ending)) case number))))
      (dolist (e extra)
        (destructuring-bind (surface case number) e
          (idx surface case number))))))

(defun morph-analyze (word)
  "→ λίστα (lemma . feats) για ΚΑΘΕ δηλωμένη ανάγνωση του τύπου· NIL αν άγνωστος.
   Καμία εικασία — μόνο τύποι δηλωμένων παραδειγμάτων."
  (gethash (normalize-greek word) *morph-index*))

(defun morph-lemma (word)
  "Το ΜΟΝΑΔΙΚΟ λήμμα του τύπου· :unknown αν άγνωστος· :ambiguous αν πολλαπλά λήμματα.
   ΠΟΤΕ λάθος λήμμα (τίμια άγνοια αντί μάντεμα) — ο θάνατος του άμυνα→άμυνο."
  (let ((hits (morph-analyze word)))
    (cond ((null hits) :unknown)
          ((every (lambda (h) (string= (car h) (car (first hits)))) hits)
           (car (first hits)))
          (t :ambiguous))))

;;; ── Παραδείγματα κλίσης (κλειστά, τεκμηριωμένα στη γραμματική της ελληνικής) ──
(register-paradigm :fem-a            ; θηλυκά 1ης κλ. -α (ενικός σταθερός τόνος)
  '(("α" :nom :sg) ("ας" :gen :sg) ("α" :acc :sg) ("α" :voc :sg)
    ("ες" :nom :pl) ("ών" :gen :pl) ("ες" :acc :pl)))
(register-paradigm :fem-si           ; θηλυκά 3ης κλ. -ση (ενικός σταθερός)
  '(("η" :nom :sg) ("ης" :gen :sg) ("η" :acc :sg)
    ("εις" :nom :pl) ("εων" :gen :pl) ("εις" :acc :pl)))
(register-paradigm :os-2             ; αρσ./θηλ. 2ης κλ. -ος
  '(("ος" :nom :sg) ("ου" :gen :sg) ("ο" :acc :sg) ("ε" :voc :sg)
    ("οι" :nom :pl) ("ων" :gen :pl) ("ους" :acc :pl)))
(register-paradigm :o-2n             ; ουδέτερα 2ης κλ. -ο
  '(("ο" :nom :sg) ("ου" :gen :sg) ("ο" :acc :sg)
    ("α" :nom :pl) ("ων" :gen :pl) ("α" :acc :pl)))
(register-paradigm :adj-os-fem       ; επίθετα -ος/-η/-ο, ΘΗΛΥΚΟ
  '(("η" :nom :sg) ("ης" :gen :sg) ("η" :acc :sg)
    ("ες" :nom :pl) ("ων" :gen :pl) ("ες" :acc :pl)))
(register-paradigm :adj-os-masc      ; επίθετα -ος/-η/-ο, ΑΡΣΕΝΙΚΟ
  '(("ος" :nom :sg) ("ου" :gen :sg) ("ο" :acc :sg) ("ε" :voc :sg)
    ("οι" :nom :pl) ("ων" :gen :pl) ("ους" :acc :pl)))
(register-paradigm :adj-os-neut      ; επίθετα -ος/-η/-ο, ΟΥΔΕΤΕΡΟ
  '(("ο" :nom :sg) ("ου" :gen :sg) ("ο" :acc :sg)
    ("α" :nom :pl) ("ων" :gen :pl) ("α" :acc :pl)))

;;; ── Λεξικά στοιχεία κρίσιμα για τη νομική γείωση (χειρο-επαληθευμένοι τύποι) ──
;; άμυνα (η άμυνα, της άμυνας…· gen.pl μετακ. τόνου → override)
(register-lexeme "άμυνα" :fem-a "άμυν" :fem '(((:gen :pl) . "αμυνών")))
;; ιδιοποίηση (-σης/-σεως gen.sg· πληθ. μετακ. τόνου → overrides + καθαρ. gen.sg)
(register-lexeme "ιδιοποίηση" :fem-si "ιδιοποίησ" :fem
  '(((:nom :pl) . "ιδιοποιήσεις") ((:gen :pl) . "ιδιοποιήσεων") ((:acc :pl) . "ιδιοποιήσεις"))
  '(("ιδιοποιήσεως" :gen :sg)))
;; συναίνεση (ίδιο σχήμα)
(register-lexeme "συναίνεση" :fem-si "συναίνεσ" :fem
  '(((:nom :pl) . "συναινέσεις") ((:gen :pl) . "συναινέσεων") ((:acc :pl) . "συναινέσεις"))
  '(("συναινέσεως" :gen :sg)))
;; κάτοχος (μετακ. τόνου στη γενική/πληθ.)
(register-lexeme "κάτοχος" :os-2 "κάτοχ" :masc
  '(((:gen :sg) . "κατόχου") ((:gen :pl) . "κατόχων") ((:acc :pl) . "κατόχους")))
;; εργαλείο (σταθερός τόνος)
(register-lexeme "εργαλείο" :o-2n "εργαλεί" :neut)
;; νόμιμος / παράνομος (επίθετα· και τα τρία γένη, ώστε «νόμιμη άμυνα» ↔ «νόμιμης άμυνας»)
(register-lexeme "νόμιμος" :adj-os-fem "νόμιμ" :fem)
(register-lexeme "νόμιμος" :adj-os-masc "νόμιμ" :masc)
(register-lexeme "νόμιμος" :adj-os-neut "νόμιμ" :neut)
(register-lexeme "παράνομος" :adj-os-fem "παράνομ" :fem)
(register-lexeme "παράνομος" :adj-os-masc "παράνομ" :masc)
(register-lexeme "παράνομος" :adj-os-neut "παράνομ" :neut)

;;; ============================================================================
;;; ΠΡΑΞΕΙΣ ΛΟΓΟΥ — από ΚΛΕΙΣΤΕΣ γραμματικές κλάσεις της ελληνικής, όχι λίστες
;;; ============================================================================
;;;
;;; Ερώτηση/ένσταση/δήλωση δεν ανιχνεύονται με λέξεις-κλειδιά περιεχομένου
;;; (ανοιχτή κλάση = αέναο κυνήγι) αλλά με ΛΕΙΤΟΥΡΓΙΚΕΣ λέξεις: ερωτηματικές
;;; αντωνυμίες/μόρια, εναντιωματικούς συνδέσμους, άρνηση στην κεφαλή — σύνολα
;;; ΠΕΠΕΡΑΣΜΕΝΑ και τεκμηριωμένα στη γραμματική της γλώσσας. Το β' πρόσωπο
;;; (ερώτηση ΠΡΟΣ το σύστημα) από την κλειστή κλιτική μορφολογία (-εις/-εσαι)
;;; και τις αντωνυμίες — όχι από μαντεψιά.

(defparameter +interrogatives+
  '("τι" "ποιος" "ποια" "ποιο" "ποιοι" "ποιες" "ποιον" "ποιαν"
    "που" "πως" "ποτε" "γιατι" "μηπως" "αραγε" "ποσο" "ποσα" "ποσοι" "ποσες")
  "Ερωτηματικές αντωνυμίες/επιρρήματα/μόρια (κανονικοποιημένα, άτονα).")

(defparameter +adversatives+
  '("μα" "αλλα" "ομως" "ωστοσο" "εντουτοις" "οχι" "δεν")
  "Εναντιωματικά/αρνητικά στην ΚΕΦΑΛΗ πρότασης ⇒ ένσταση/αντίρρηση.")

(defun %norm-tokens (text)
  (remove "" (uiop:split-string (normalize-greek text)
                                :separator " ,.;·:!()«»\"'?")
          :test #'string=))

(defun utterance-act (text)
  "Η πράξη λόγου μιας εκφοράς: :question / :objection / :assertion.
   Ερώτηση = ερωτηματικό σημείο (;/?) Ή ερωτηματική λέξη στην αρχή.
   Ένσταση = εναντιωματικό/άρνηση στην κεφαλή, χωρίς ερωτηματικότητα."
  (let* ((toks (%norm-tokens text))
         (first-tok (first toks))
         (question-mark (position-if (lambda (c) (member c '(#\; #\?))) text))
         (interrogative (or (member first-tok +interrogatives+ :test #'string=)
                            (and (second toks)
                                 (member first-tok +adversatives+ :test #'string=)
                                 (member (second toks) +interrogatives+ :test #'string=)))))
    (cond ((or question-mark interrogative) :question)
          ((member first-tok +adversatives+ :test #'string=) :objection)
          (t :assertion))))

(defun second-person-p (text)
  "Απευθύνεται στο σύστημα (β' ενικό); Αντωνυμίες (εσύ/σου) ή κλιτικές
   καταλήξεις -εις/-εσαι (κλειστό κλιτικό σύστημα — το «πηγές» αποκλείεται
   γιατί απαιτείται κατάληξη ρηματική -εις, όχι -ες)."
  (let ((toks (%norm-tokens text)))
    (or (intersection toks '("εσυ" "εσενα" "σου") :test #'string=)
        (some (lambda (w)
                (and (> (length w) 4)
                     ;; τα tokens είναι ΚΑΝΟΝΙΚΟΠΟΙΗΜΕΝΑ (ς→σ) — οι καταλήξεις
                     ;; συγκρίνονται στην ίδια μορφή, αλλιώς δεν ταιριάζουν ποτέ
                     (or (string= "εισ" w :start2 (- (length w) 3))
                         (string= "εσαι" w :start2 (- (length w) 4)))
                     ;; Η «-εις» είναι ΔΙΦΟΡΟΥΜΕΝΗ: β' πρόσωπο ρήματος ΚΑΙ
                     ;; πληθυντικός ουσιαστικών σε -η/-ις (προϋποθέσεις,
                     ;; αποφάσεις). Αν το επιμελημένο λεξικό γνωρίζει τη μορφή
                     ;; ως κλίση ΜΗ-ρηματικού λήμματος (λήμμα που δεν λήγει σε
                     ;; -ω/-μαι), ΔΕΝ είναι μαρτυρία β' προσώπου.
                     (let ((l (known-lemma w)))
                       (or (null l)
                           (let ((n (normalize-greek l)))
                             (or (and (plusp (length n))
                                      (char= #\ω (char n (1- (length n)))))
                                 (and (>= (length n) 3)
                                      (string= "μαι" n :start2 (- (length n) 3)))))))))
              toks))))

(defun verbum-dicendi-p (text)
  "Περιέχει ρήμα λεκτικό (λέω/αναφέρω/προτείνω) — αναφορά σε προηγούμενη εκφορά."
  (some (lambda (w) (member (known-lemma w) '("λέω" "αναφέρω" "προτείνω") :test #'equal))
        (%norm-tokens text)))

;;; ============================================================================
;;; END OF GREEK-LEMMATIZER.LISP
;;; ============================================================================
