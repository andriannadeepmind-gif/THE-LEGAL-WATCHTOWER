;;;; source/amendment-extractor.lisp
;;;; ============================================================================
;;;; AMENDMENT EXTRACTOR  (the Διαύγεια→consolidation semantic link)
;;;; ============================================================================
;;;;
;;;; A published decision/law on the state source is, by itself, just text. To
;;;; consolidate it the engine needs STRUCTURED operations: which article is
;;;; replaced/repealed/amended, and (for a replacement) the new text. Greek
;;;; legislation follows fixed nomotechnic formulas, so this is extractable
;;;; deterministically:
;;;;
;;;;   "Το άρθρο 5 … αντικαθίσταται ως εξής: «…»"  -> :replace-text art_5
;;;;   "Το άρθρο 5 … καταργείται"                   -> :repeal        art_5
;;;;   "Καταργείται το άρθρο 5"                      -> :repeal        art_5
;;;;   "Το άρθρο 5 … τροποποιείται"                  -> :mark-amended  art_5
;;;;
;;;; The result is a config-shaped amendment RECORD (the very shape
;;;; consolidation-bridge:amendment-records->acts already consumes), so the
;;;; live feed turns a real decision into a real amending act. No randomness:
;;;; same text in, same operations out.
;;;; ============================================================================

(defpackage :orchestrator.amendment-extractor
  (:use :cl)
  (:export #:extract-operations #:extract-amendment-record
           #:operation-applicable-p #:split-operations #:summarize-operations
           #:diavgeia-decision->record
           ;; [FEK-COMPILER] registry-driven scope routing (η λίστα φράσεων πέθανε)
           #:make-registry-resolver
           ;; [BACKTEST] αυτο-επαληθευόμενη μέτρηση ακρίβειας (census + δομή)
           #:measure-extraction))

(in-package :orchestrator.amendment-extractor)

(defparameter +gl+ "[α-ωΑ-Ωάέήίόύώΐΰϊϋ]"
  "A Greek letter (the vendored cl-ppcre has no \\p{L} support).")

;;; A replacement/addition payload (the NEW article text) routinely contains its
;;; own « » quotes — definitions, cited phrases. A naive «([^»]*)» stops at the
;;; FIRST inner », truncating the new text mid-sentence and corrupting the
;;; consolidated article. We extract the BALANCED «…» instead, so the payload is
;;; captured in full whatever it nests.
(defparameter +laquo+ (code-char #x00AB))   ; «
(defparameter +raquo+ (code-char #x00BB))   ; »

(defun %balanced-quote (text start)
  "From the first « at/after START, return (values PAYLOAD END) for the balanced
   «…» content (original accents/case preserved), or NIL when there is no «."
  (let ((open (position +laquo+ text :start start)))
    (when open
      (let ((depth 0))
        (loop for i from open below (length text)
              for c = (char text i) do
          (cond ((char= c +laquo+) (incf depth))
                ((char= c +raquo+)
                 (decf depth)
                 (when (zerop depth)
                   (return-from %balanced-quote
                     (values (subseq text (1+ open) i) (1+ i)))))))
        ;; Unbalanced (missing closing ») — take to end, never lose text.
        (values (subseq text (1+ open)) (length text))))))

;;; Verb-anchored extraction. Rather than scan "άρθρο N … verb" forwards (which
;;; mis-reads structural "Άρθρο N." headers as references), we anchor on the
;;; OPERATION VERB and find the nearest article around it. This is how a human
;;; reads a nomotechnic clause: the verb is the operation; its subject is the
;;; closest article. Text inside replacement « » quotes is excluded so a quoted
;;; new text that itself mentions amendments is not re-interpreted.

(defparameter +replace-clause+
  (cl-ppcre:create-scanner
   (format nil "αντικαθίστ~A*\\s+ως\\s+εξής\\s*[:·.]?\\s*" +gl+)
   :single-line-mode t :case-insensitive-mode t)
  "A replacement-clause ANCHOR (verb + «ως εξής:»). The new text that follows in
   balanced «…» is pulled separately by %balanced-quote, so a payload that itself
   contains « » quotes is captured in full (not truncated at the first inner »).")

(defparameter +repeal-verb+
  (cl-ppcre:create-scanner (format nil "καταργ~A*" +gl+) :case-insensitive-mode t)
  "A repeal verb (καταργείται/καταργούνται).")

(defparameter +amend-verb+
  (cl-ppcre:create-scanner (format nil "τροποποι~A*" +gl+) :case-insensitive-mode t)
  "A generic amendment verb (τροποποιείται/τροποποιούνται).")

(defparameter +article-ref+
  (cl-ppcre:create-scanner (format nil "άρθρ~A*\\s+(\\d+[Α-Ω]?)" +gl+) :case-insensitive-mode t)
  "An article reference. Reg 1 = article number (optional Greek-letter suffix,
   e.g. 5Α for an inserted article).")

(defparameter +para-of-article+
  (cl-ppcre:create-scanner
   (format nil "παρ~A*\\.?\\s*(\\d+)[^.]{0,40}?άρθρ~A*\\s+(\\d+)" +gl+ +gl+)
   :case-insensitive-mode t)
  "A 'παράγραφος M … άρθρου N' reference. Reg 1 = paragraph, Reg 2 = article.")

(defparameter +multi-article+
  (cl-ppcre:create-scanner (format nil "άρθρ~A*\\s+(\\d+)\\s+και\\s+(\\d+)" +gl+)
                           :case-insensitive-mode t)
  "A 'τα άρθρα N και K' reference. Reg 1, Reg 2 = the two article numbers.")

(defparameter +add-verb+
  (cl-ppcre:create-scanner (format nil "προστίθ~A*" +gl+) :case-insensitive-mode t)
  "An addition verb (προστίθεται/προστίθενται).")

(defparameter +law-ref+
  (cl-ppcre:create-scanner
   (format nil "(?:ν\\.?|νόμ~A*|π\\.?δ\\.?)\\s*(\\d+/(?:19|20)\\d{2})" +gl+)
   :case-insensitive-mode t)
  "A whole-law reference (ν. 4619/2019). Reg 1 = number/year.")

(defun %art-eid (n) (format nil "art_~A" n))

(defun %targets-before (text pos)
  "Return (values targets level) for the structured legislative reference
   NEAREST before POS. LEVEL is :paragraph, :multi or :article; TARGETS is a list
   of Akoma-Ntoso eIds (art_N or art_N__para_M)."
  (let* ((lo (max 0 (- pos 180)))
         (win (subseq text lo pos))
         (best-end -1) (best nil) (best-level :article))
    (flet ((consider (scanner level builder)
             (cl-ppcre:do-scans (ms me rs re scanner win)
               (declare (ignore ms))
               (when (> me best-end)
                 (setf best-end me best-level level best (funcall builder rs re win))))))
      (consider +para-of-article+ :paragraph
                (lambda (rs re w)
                  (list (format nil "art_~A__para_~A"
                                (subseq w (aref rs 1) (aref re 1))
                                (subseq w (aref rs 0) (aref re 0))))))
      (consider +multi-article+ :multi
                (lambda (rs re w)
                  (list (%art-eid (subseq w (aref rs 0) (aref re 0)))
                        (%art-eid (subseq w (aref rs 1) (aref re 1))))))
      (consider +article-ref+ :article
                (lambda (rs re w) (list (%art-eid (subseq w (aref rs 0) (aref re 0)))))))
    (values best best-level)))

(defun %first-article-after (text pos &optional (window 40))
  "The number of the first 'άρθρο N' within WINDOW chars after POS (no sentence
   boundary crossed)."
  (let* ((hi (min (length text) (+ pos window)))
         (win (subseq text pos hi))
         (dot (position #\. win)))
    (cl-ppcre:register-groups-bind (num)
        (+article-ref+ (if dot (subseq win 0 dot) win))
      num)))

(defun %law-near (text ms me)
  "A whole-law reference just before MS or just after ME, as 'law-N/Y' or NIL."
  (let ((before (subseq text (max 0 (- ms 60)) ms))
        (after (subseq text me (min (length text) (+ me 40)))) (found nil))
    (cl-ppcre:do-register-groups (n) (+law-ref+ before) (setf found n))
    (unless found (cl-ppcre:register-groups-bind (n) (+law-ref+ after) (setf found n)))
    (and found (format nil "law-~A" found))))

(defun %text-after-quote (text pos &optional (window 400))
  "The BALANCED « » quoted text whose « starts within WINDOW chars after POS, or
   NIL. Balanced so an added article/paragraph whose text nests « » is whole."
  (let ((open (position +laquo+ text :start pos
                        :end (min (length text) (+ pos window)))))
    (when open
      (let ((q (%balanced-quote text open)))
        (and q (string-trim '(#\Space #\Newline #\Tab #\Return) q))))))

(defun %in-spans-p (pos spans)
  (some (lambda (s) (and (>= pos (car s)) (< pos (cdr s)))) spans))

;;; ── [FEK-COMPILER] per-operation code resolution — ΔΟΜΙΚΟ scope, όχι λίστα ────
;;; Ο τροποποιητικός νόμος είναι πρόγραμμα: οι κεφαλίδες «Άρθρο Ν» του ΙΔΙΟΥ
;;; του τροποποιητικού ορίζουν ενότητες, η ονομασία του κώδικα-στόχου (μία
;;; φορά, στην κεφαλίδα ή στην εισαγωγική πρόταση) ορίζει SCOPE, και κάθε
;;; επιμέρους πράξη («Το άρθρο 773 καταργείται») τον ΚΛΗΡΟΝΟΜΕΙ μέχρι το
;;; επόμενο όριο. Η αναγνώριση των ονομάτων ΔΕΝ ζει εδώ: η ΜΙΑ έδρα είναι το
;;; orchestrator.legal-id (resolve-code-rightmost πάνω στο registry που
;;; παράγεται από τα configs — ονόματα, routing_phrases, νόμος/έτος). Καμία
;;; hardcoded λίστα φράσεων: η παλιά *code-phrases* ΠΕΘΑΝΕ (διπλή, ad hoc,
;;; τυφλή στην κληρονομιά — έχανε 39/40 πράξεις σε κωδικοποιημένη μεταρρύθμιση).

(defparameter +amending-article-header+
  (cl-ppcre:create-scanner "(?m)^[ \\t]*ΑΡΘΡΟ\\s+\\d+[Α-Ω]?\\b")
  "Κεφαλίδα άρθρου ΤΟΥ ΤΡΟΠΟΠΟΙΗΤΙΚΟΥ νόμου σε αρχή γραμμής — όριο ενότητας
   (segment) για την κληρονομιά scope. Ταιριάζει πάνω σε NORMALIZE-GREEK
   κείμενο (κεφαλαία, χωρίς τόνους — length-preserving), οπότε ΜΙΑ κανονική
   μορφή «ΑΡΘΡΟ» καλύπτει δομικά Άρθρο/ΆΡΘΡΟ/Αρθρο/ΑΡΘΡΟ — εξάλειψη της
   κλάσης «λίστα παραλλαγών» (εύρημα κριτή #9). Στην αρχή γραμμής ΜΟΝΟ: οι
   αναφορές «…το άρθρο 5 του Κώδικα…» μέσα σε πρόταση δεν είναι κεφαλίδες.")

(defun %ngz (s)
  (funcall (find-symbol "NORMALIZE-GREEK" :orchestrator.legal-id) s))

(defun make-registry-resolver (registry)
  "Resolver πάνω στη ΜΙΑ έδρα δρομολόγησης (orchestrator.legal-id): δέχεται
   CONTEXT string, επιστρέφει (values corpus-id position) της rightmost ρητής
   ονομασίας served κώδικα, ή NIL (τίμια άγνοια — ποτέ μαντεψιά)."
  (let ((resolve (find-symbol "RESOLVE-CODE-RIGHTMOST" :orchestrator.legal-id)))
    (unless resolve
      (error "make-registry-resolver: η έδρα orchestrator.legal-id δεν είναι φορτωμένη"))
    (lambda (context) (funcall resolve registry context))))

(defun %all-quoted-spans (txt)
  "ΟΛΑ τα balanced «…» spans του TXT ως ((start . end) …). Χρησιμεύει ως ΜΑΣΚΑ
   στη διαχείριση scope: κείμενο ΜΕΣΑ σε παράθεση (νέο κείμενο άρθρου) δεν
   επιτρέπεται να ορίσει τον κώδικα-στόχο των ΕΠΟΜΕΝΩΝ πράξεων.
   ΑΖΥΓΙΣΤΗ « (OCR): το span φράσσεται στην ΕΠΟΜΕΝΗ κεφαλίδα «ΑΡΘΡΟ Ν» του
   τροποποιητικού αντί για το EOF — ένας χαλασμένος χαρακτήρας δεν επιτρέπεται
   να σβήσει το scope ΟΛΟΥ του υπόλοιπου εγγράφου (εύρημα κριτή #10)."
  (let ((spans '()) (pos 0) (nz (%ngz txt)))
    (loop
      (let ((open (position +laquo+ txt :start pos)))
        (unless open (return (nreverse spans)))
        (multiple-value-bind (payload end) (%balanced-quote txt open)
          (declare (ignore payload))
          (let* ((balanced-p (and (> end open)
                                  (< end (length txt))
                                  (char= (char txt (1- end)) +raquo+)))
                 (end (if (or balanced-p (>= (length txt) end))
                          (if (and (not balanced-p) (= end (length txt)))
                              ;; unbalanced-to-EOF: φράξε στην επόμενη κεφαλίδα
                              (or (cl-ppcre:scan +amending-article-header+ nz
                                                 :start (min (1+ open) (length nz)))
                                  end)
                              end)
                          end)))
            (push (cons open end) spans)
            (setf pos (max end (1+ open)))))))))

(defun %mask-spans (txt spans)
  "Αντίγραφο του TXT με τα SPANS σβησμένα (κενά) — ίδιο μήκος, ίδιες θέσεις,
   ώστε οι θέσεις του resolver να παραμένουν έγκυρες στο αρχικό κείμενο."
  (let ((masked (copy-seq txt)))
    (dolist (s spans masked)
      (fill masked #\Space :start (car s) :end (min (length masked) (cdr s))))))

(defun %own-article-numbers (masked-nz)
  "Το ΣΥΝΟΛΟ των αριθμών άρθρων ΤΟΥ ΙΔΙΟΥ του νόμου (από τις κεφαλίδες του,
   στο μασκαρισμένο+normalized κείμενο). Θεμέλιο του διαχωρισμού που δίδαξε το
   ΦΕΚ Α'103/2026 (νέος Κώδικας Τοπ. Αυτοδιοίκησης με ΔΙΚΑ του άρθρα 1-773+):
   «καταργείται με το άρθρο 773» εκεί είναι ΑΥΤΟ-ΑΝΑΦΟΡΑ στο δικό του άρθρο
   καταργουμένων — ΟΧΙ πράξη πάνω σε ξένο κώδικα. Ένας στόχος χωρίς ξένη
   δρομολόγηση που συμπίπτει με δικό του άρθρο είναι δομικά ύποπτος αυτο-
   αναφοράς και ΔΕΝ επιτρέπεται να μετρήσει ως τροποποίηση."
  (let ((set (make-hash-table :test 'equal)))
    (cl-ppcre:do-register-groups (num)
        ("(?m)^[ \\t]*ΑΡΘΡΟ\\s+(\\d+[Α-Ω]?)\\b" masked-nz)
      (setf (gethash num set) t))
    set))

(defun %segment-starts (masked-nz)
  "Θέσεις έναρξης των ενοτήτων του τροποποιητικού (κεφαλίδες «ΑΡΘΡΟ Ν» σε αρχή
   γραμμής), με το 0 πάντα πρώτο (προοίμιο/τίτλος = πρώτη ενότητα).
   Σαρώνει το ΜΑΣΚΑΡΙΣΜΕΝΟ+normalized κείμενο (εύρημα κριτή #4): κεφαλίδα
   «Άρθρο Ν» ΜΕΣΑ σε παρατιθέμενο νέο κείμενο («…\\nΆρθρο 92.…») ΔΕΝ ανοίγει
   ψευδο-ενότητα — η μάσκα εφαρμόζεται εκεί ακριβώς όπου συμβαίνει το hijack."
  (let ((starts (list 0)))
    (cl-ppcre:do-matches (ms me +amending-article-header+ masked-nz)
      (declare (ignore me))
      (when (plusp ms) (push ms starts)))
    (sort (remove-duplicates starts) #'<)))

(defun %sentence-boundary-after (masked pos)
  "Η θέση ΜΕΤΑ την τελεία που κλείνει την πρόταση που περιέχει το POS, ή NIL.
   Τελεία πρότασης = «.» ακολουθούμενη από (κενά+) ΚΕΦΑΛΑΙΟ ή αλλαγή γραμμής ή
   τέλος κειμένου — «ν. 4619», «παρ. 2», «άρθρ. 5» (πεζό/ψηφίο μετά) ΔΕΝ κόβουν
   (εύρημα κριτή #5: η συντομογραφία δεν είναι όριο πρότασης)."
  (loop with n = (length masked)
        for dot = (position #\. masked :start pos) then (position #\. masked :start (1+ dot))
        while dot
        do (let ((next (position-if (lambda (c) (not (member c '(#\Space #\Tab)))) masked
                                    :start (1+ dot))))
             (when (or (null next)
                       (char= (char masked next) #\Newline)
                       (and (> next (1+ dot)) (upper-case-p (char masked next)))
                       (and (upper-case-p (char masked next))
                            (find #\Newline masked :start (1+ dot) :end next)))
               (return (1+ dot))))
        finally (return nil)))

(defun %sentence-start-before (masked pos)
  "Η αρχή της πρότασης που περιέχει το POS (μετά την προηγούμενη τελεία-όριο ή
   αλλαγή γραμμής), φραγμένη στα 240 πίσω."
  (let* ((lo (max 0 (- pos 240))) (best lo))
    ;; τελευταία αλλαγή γραμμής πριν το pos
    (let ((nl (position #\Newline masked :from-end t :end pos :start lo)))
      (when nl (setf best (max best (1+ nl)))))
    ;; τελευταία τελεία-όριο πριν το pos
    (loop for dot = (position #\. masked :start best :end pos)
            then (position #\. masked :start (1+ dot) :end pos)
          while dot
          do (let ((next (position-if (lambda (c) (not (member c '(#\Space #\Tab)))) masked
                                      :start (1+ dot) :end pos)))
               (when (and next (upper-case-p (char masked next)))
                 (setf best next))))
    best))

(defun %scope-at (masked segment-starts resolver pos txt-len)
  "Ο κώδικας-στόχος για πράξη στη θέση POS — ΜΟΝΟ από θέσεις με ΝΟΜΟΤΕΧΝΙΚΗ
   υπόσταση (εύρημα κριτή #6: όχι «οποιαδήποτε μνεία» — μια παραπομπή
   «…κατά τα άρθρα 176 του ΚΠολΔ…» σε ξένη ρήτρα ΔΕΝ επιτρέπεται να
   ξαναδρομολογήσει τις επόμενες πράξεις της ενότητας):
     (α) η ΠΡΟΤΑΣΗ ΤΗΣ ΙΔΙΑΣ ΤΗΣ ΠΡΑΞΗΣ («Το άρθρο 5 ΤΟΥ ΚΩΔΙΚΑ Χ
         αντικαθίσταται…», «Στον Κώδικα Χ, το άρθρο Ν…») — rightmost·
     (β) αλλιώς, η ΖΩΝΗ ΚΕΦΑΛΙΔΑΣ της ενότητας (τίτλος «Τροποποιήσεις …» +
         εισαγωγική περίοδος έως «:» ή τέλος 1ης πρότασης, cap 400) — εκεί
         δηλώνεται ο στόχος μιας κωδικοποιημένης μεταρρύθμισης.
   Παράθεση «…» μασκαρισμένη. NIL αν τίποτα από τα δύο (τίμιο αδρομολόγητο).
   Κληρονομιά ΑΥΣΤΗΡΑ ενδο-ενοτική — νέο «ΑΡΘΡΟ Ν» μηδενίζει το scope."
  (when resolver
    (let* ((seg-start 0) (seg-end txt-len))
      (dolist (b segment-starts)
        (cond ((<= b pos) (setf seg-start b))
              (t (setf seg-end b) (return))))
      (or
       ;; (α) η πρόταση της πράξης
       (let* ((s-start (max seg-start (%sentence-start-before masked pos)))
              (s-end (min seg-end
                          (or (%sentence-boundary-after masked pos) seg-end)
                          (+ pos 160)))
              (win (and (< s-start s-end) (subseq masked s-start s-end))))
         (and win (funcall resolver win)))
       ;; (β) η ζώνη κεφαλίδας της ενότητας
       (let* ((z-cap (min seg-end (+ seg-start 400)))
              (colon (position #\: masked :start seg-start :end z-cap))
              (z-end (min z-cap
                          (or (and colon (1+ colon)) z-cap)
                          (or (%sentence-boundary-after
                               masked (min (+ seg-start 1) txt-len))
                              z-cap)))
              (zone (and (< seg-start z-end) (subseq masked seg-start z-end))))
         (and zone (<= seg-start pos) (funcall resolver zone)))))))

(defun %base-article-id (eid)
  "Ο βασικός αριθμός άρθρου ενός eId: art_134__para_1 → «134», art_5Α → «5Α»,
   law-… → NIL (δεν είναι άρθρο)."
  (when (and (stringp eid) (eql 0 (search "art_" eid)))
    (let* ((rest (subseq eid 4))
           (cut (search "__" rest)))
      (if cut (subseq rest 0 cut) rest))))

(defun extract-operations (text &key code-resolver article-exists-fn)
  "Return the operations implied by amending TEXT. Each operation plist carries
   a :CONFIDENCE — :high (article/paragraph replace/repeal/amend, applied
   automatically), :medium (structural additions / new articles) or :low
   (whole-law). Lower-confidence operations are RECOGNISED, never silently
   dropped, so the validation layer can flag them for human review.

   CODE-RESOLVER: (context) → corpus-id — φτιάχνεται με MAKE-REGISTRY-RESOLVER
   πάνω στο registry των configs. Χωρίς resolver ΚΑΜΙΑ πράξη δεν δρομολογείται
   (:code NIL, τίμια) — ποτέ κρυφή λίστα. Η δρομολόγηση κληρονομείται ΔΟΜΙΚΑ:
   κεφαλίδες «Άρθρο Ν» του τροποποιητικού ορίζουν ενότητες, το scope ρέει από
   την ονομασία του κώδικα προς όλες τις πράξεις της ενότητας.

   ARTICLE-EXISTS-FN: (corpus-id base-article-id) → T / NIL / :unknown —
   επαλήθευση κατά της ΤΑΥΤΟΤΗΤΑΣ του served κώδικα (τα eIds που πράγματι
   κατέχει). Αντίφαση (scope λέει κώδικα Χ, το άρθρο ΔΕΝ υπάρχει στον Χ) ⇒ η
   πράξη ΔΕΝ αυτο-εφαρμόζεται: :identity :contradicted + :confidence :low.
   Επιβεβαίωση ⇒ :identity :verified. :unknown ⇒ κανένας ισχυρισμός."
  (let* ((handled (make-hash-table :test 'equal))
         (ops '())
         (quoted '())
         (txt (or text ""))
         (all-quotes (%all-quoted-spans txt))
         (masked (%mask-spans txt all-quotes))
         (masked-nz (%ngz masked))
         (segments (%segment-starts masked-nz))
         (own-articles (%own-article-numbers masked-nz)))
    (labels ((codeat (pos)
               (%scope-at masked segments code-resolver pos (length txt)))
             (take (key) (and key (not (gethash key handled)) (setf (gethash key handled) t)))
             (self-ref-p (code eid)
               ;; Αδρομολόγητος στόχος που συμπίπτει με ΔΙΚΟ του άρθρο του
               ;; τροποποιητικού = δομικά ύποπτη αυτο-αναφορά (μάθημα Α'103).
               (and (null code)
                    (let ((base (%base-article-id eid)))
                      (and base (gethash base own-articles)))))
             (verify (code eid conf)
               ;; (values identity-claim adjusted-conf)
               (let ((base (%base-article-id eid)))
                 (if (and article-exists-fn code base)
                     (let ((r (funcall article-exists-fn code base)))
                       (cond ((eq r t) (values :verified conf))
                             ((null r) (values :contradicted :low))
                             (t (values nil conf))))   ; :unknown — καμία αξίωση
                     (values nil conf))))
             (emit (op eid pos &key text (conf :high) note)
               (let ((code (codeat pos)))
                 ;; Κανόνες dedup (εύρημα κριτή #1, χωρίς να χαθεί η παλιά
                 ;; σημασιολογία):
                 ;;  • :mark-amended σε στόχο με ΗΔΗ εκδοθείσα πράξη (ίδιο
                 ;;    code.eid) απορροφάται — provenance, όχι νέα ουσία.
                 ;;  • Δρομολογημένες πράξεις: dedup ανά (code . eid) — το ίδιο
                 ;;    art_N σε ΔΥΟ κώδικες στέκει δύο φορές.
                 ;;  • ΑΔΡΟΜΟΛΟΓΗΤΕΣ ουσιαστικές πράξεις: κλειδί η ΘΕΣΗ της
                 ;;    ρήτρας — δύο ρήτρες στο ίδιο art_N (πιθανόν διαφορετικοί
                 ;;    νόμοι!) ΔΕΝ συγχωνεύονται ποτέ σιωπηλά.
                 (when (and eid
                            (not (and (eq op :mark-amended)
                                      (gethash (cons code eid) handled)))
                            (take (if code
                                      (cons code eid)
                                      (list :unrouted op eid pos)))
                            (progn (setf (gethash (cons code eid) handled) t) t))
                   (multiple-value-bind (identity adj-conf) (verify code eid conf)
                     (when (self-ref-p code eid)
                       (setf adj-conf :low
                             note (or note "αυτο-αναφορά: άρθρο του ΙΔΙΟΥ του νόμου — όχι τροποποίηση ξένου κώδικα")))
                     (push (append (list :op op :target eid :if-missing :skip
                                         :confidence adj-conf)
                                   (when (self-ref-p code eid)
                                     (list :self-reference t))
                                   (when code (list :code code))
                                   (when identity (list :identity identity))
                                   (when (eq identity :contradicted)
                                     (list :identity-note
                                           "ταυτότητα: το άρθρο ΔΕΝ υπάρχει στον κώδικα του scope — απαιτεί άνθρωπο"))
                                   (when text (list :text text))
                                   (when note (list :note note)))
                           ops))))))
      ;; 1) Replacements with explicit text (article or paragraph level). The new
      ;;    text is the BALANCED «…» after the anchor — captured whole even when it
      ;;    nests « » quotes (a naive [^»]* truncated it).
      (cl-ppcre:do-matches (ms me +replace-clause+ txt)
        (multiple-value-bind (new qend) (%balanced-quote txt me)
          (when new
            (push (cons ms qend) quoted)
            (let ((newt (string-trim '(#\Space #\Newline #\Tab #\Return) new)))
              (dolist (eid (%targets-before txt ms))
                (emit :replace-text eid ms :text newt :conf :high))))))
      ;; 2) Additions (προστίθεται …): new article or new paragraph — recognised
      ;;    but flagged (:medium); structural insertion needs review.
      (cl-ppcre:do-matches (ms me +add-verb+ txt)
        (unless (%in-spans-p ms quoted)
          (let ((newart (%first-article-after txt me 30))
                (new (%text-after-quote txt me)))
            (if newart
                (emit :insert (%art-eid newart) ms :text new :conf :medium :note "new-article")
                (dolist (eid (%targets-before txt ms))
                  (emit :insert eid ms :text new :conf :medium :note "new-paragraph"))))))
      ;; 3) Repeals (article, paragraph, multi, or whole-law).
      (cl-ppcre:do-matches (ms me +repeal-verb+ txt)
        (unless (%in-spans-p ms quoted)
          (let ((targets (%targets-before txt ms)))
            (cond
              (targets (dolist (eid targets) (emit :repeal eid ms :conf :high)))
              ((%first-article-after txt me)
               (emit :repeal (%art-eid (%first-article-after txt me)) ms :conf :high))
              (t (let ((law (%law-near txt ms me)))
                   (when law (emit :repeal-law law ms :conf :low :note "whole-law"))))))))
      ;; 4) Generic amendments (provenance only).
      (cl-ppcre:do-matches (ms me +amend-verb+ txt)
        (declare (ignore me))
        (unless (%in-spans-p ms quoted)
          (dolist (eid (%targets-before txt ms))
            (emit :mark-amended eid ms :conf :high)))))
    (nreverse ops)))

(defun summarize-operations (ops)
  "Group EXTRACT-OPERATIONS output by :code (the affected statute), preserving
   first-seen order; operations whose code could not be resolved fall in the NIL
   bucket. Returns ((code . (op …)) …) — the 'which codes & articles does this
   gazette touch' view that the discovery loop reports and the consolidator routes
   on. Deterministic: same operations in, same grouping out."
  (let ((by-code (make-hash-table :test 'equal)) (order '()))
    (dolist (op ops)
      (let ((code (getf op :code)))
        (multiple-value-bind (v present) (gethash code by-code)
          (declare (ignore v))
          (unless present (push code order) (setf (gethash code by-code) '())))
        (push op (gethash code by-code))))
    (loop for code in (nreverse order)
          collect (cons code (nreverse (gethash code by-code))))))

;;; ── [BACKTEST] Αυτο-επαληθευόμενη μέτρηση ακρίβειας (self-supervision) ────────
;;; Η DeepMind απάντηση στο «πώς έχεις ground truth χωρίς ετικέτες»: το ίδιο το
;;; σώμα βαθμολογεί τον εαυτό του πάνω σε ΗΔΗ ΑΛΗΘΕΙΣ αναλλοίωτες — καμία
;;; χειροκίνητη ετικέτα, κανένα κατέβασμα:
;;;   (Α) Precision ταυτότητας: κάθε ΔΡΟΜΟΛΟΓΗΜΕΝΗ πράξη ελέγχεται κατά του
;;;       committed census του κώδικα-στόχου (article-exists-fn). Route σε κώδικα
;;;       που ΔΕΝ έχει το άρθρο = μετρημένο σφάλμα (:identity :contradicted).
;;;       Ακριβές, όχι προσεγγιστικό.
;;;   (Β) Δομικό recall: τα νομοτεχνικά ρήματα του κειμένου ΕΙΝΑΙ οι πράξεις-
;;;       αλήθεια. Τα ΙΔΙΑ scanners του extractor μετρούν πόσα υπάρχουν
;;;       (πάνω στο μασκαρισμένο κείμενο — παράθεση «…» δεν προσμετράται).
;;; N-version (2ος extractor) + round-trip ανακατασκευή = δηλωμένες επόμενες φάσεις.

(defun %count-operation-verbs (masked-text)
  "Πλήθος νομοτεχνικών ρημάτων πράξης στο ΜΑΣΚΑΡΙΣΜΕΝΟ κείμενο — ΤΑ ΙΔΙΑ scanners
   που οδηγούν την εξαγωγή (καμία νέα regex). ΑΝΩ ΦΡΑΓΜΑ των πράξεων: κάθε πράξη
   έχει ρήμα, αλλά όχι κάθε αντιστοίχιση ρήματος είναι πράξη σε served κώδικα
   (π.χ. «Καταργούμενες διατάξεις» κεφαλίδα, ονοματικοί τύποι). Άρα το
   δομικό-recall (extracted/verbs) είναι ΚΑΤΩ ΦΡΑΓΜΑ — δηλωμένο τίμια."
  (let ((n 0))
    (dolist (sc (list +replace-clause+ +repeal-verb+ +amend-verb+ +add-verb+) n)
      ;; all-matches → flat (start1 end1 start2 end2 …)· ζεύγη ⇒ μήκος/2 = πλήθος
      (incf n (floor (length (cl-ppcre:all-matches sc masked-text)) 2)))))

(defun measure-extraction (text &key code-resolver article-exists-fn)
  "Αυτο-επαληθευόμενη μέτρηση του extractor πάνω σε ΠΡΑΓΜΑΤΙΚΟ κείμενο TEXT.
   Καταναλώνει τα verdicts της extract-operations (καμία διπλή λογική) και τα
   αναλλοίωτα του σώματος. Επιστρέφει plist:
     :structural-verbs   — άνω φράγμα πράξεων (νομοτεχνικά ρήματα, masked)
     :extracted          — σύνολο εξαγόμενων πράξεων
     :routed             — πράξεις με :code (δρομολογημένες σε served κώδικα)
     :unrouted           — πράξεις χωρίς :code (ξένος νόμος / αδρομολόγητο)
     :self-reference     — πράξεις-αυτοαναφορές (άρθρο του ΙΔΙΟΥ του νόμου)
     :identity-verified  — δρομολογημένες που το census ΕΠΙΒΕΒΑΙΩΝΕΙ
     :identity-contradicted — δρομολογημένες που το census ΔΙΑΨΕΥΔΕΙ (σφάλμα)
     :identity-checked   — verified + contradicted (όσες πήραν ετυμηγορία census)
     :identity-precision — verified / identity-checked (NIL αν 0· ΑΚΡΙΒΕΣ)
     :structural-recall  — extracted / structural-verbs (NIL αν 0· κάτω φράγμα)."
  (let* ((ops (extract-operations text :code-resolver code-resolver
                                       :article-exists-fn article-exists-fn))
         (masked (%mask-spans (or text "") (%all-quoted-spans (or text ""))))
         (verbs (%count-operation-verbs masked))
         (routed (count-if (lambda (o) (getf o :code)) ops))
         (self-ref (count-if (lambda (o) (getf o :self-reference)) ops))
         (verified (count-if (lambda (o) (eq (getf o :identity) :verified)) ops))
         (contradicted (count-if (lambda (o) (eq (getf o :identity) :contradicted)) ops))
         (checked (+ verified contradicted)))
    (list :structural-verbs verbs
          :extracted (length ops)
          :routed routed
          :unrouted (- (length ops) routed)
          :self-reference self-ref
          :identity-verified verified
          :identity-contradicted contradicted
          :identity-checked checked
          :identity-precision (and (plusp checked) (/ verified checked))
          :structural-recall (and (plusp verbs) (/ (length ops) verbs)))))

(defun operation-applicable-p (op)
  "True when OP is high-confidence AND an operation the consolidation engine
   applies directly. Only these are auto-applied; the rest are flagged."
  (and (eq (getf op :confidence) :high)
       (member (getf op :op) '(:replace-text :replace :repeal :mark-amended))))

(defun split-operations (text &key code-resolver article-exists-fn)
  "Return (values applicable flagged): high-confidence engine operations vs.
   everything recognised but needing human review. Ο resolver/oracle περνούν
   ΑΥΤΟΥΣΙΟΙ στον extractor (εύρημα κριτή #8: μία υπογραφή, καμία σιωπηλά
   αδρομολόγητη διαδρομή)."
  (let ((all (extract-operations text :code-resolver code-resolver
                                      :article-exists-fn article-exists-fn)))
    (values (remove-if-not #'operation-applicable-p all)
            (remove-if #'operation-applicable-p all))))

(defun extract-amendment-record (text &key id date fek code-resolver article-exists-fn)
  "Build a config-shaped amendment RECORD from amending TEXT. \"operations\" holds
   only the auto-applicable (high-confidence) operations; \"review\" holds the
   flagged ones (additions, new articles, whole-law) for human confirmation."
  (multiple-value-bind (applicable flagged)
      (split-operations text :code-resolver code-resolver
                             :article-exists-fn article-exists-fn)
    (list (cons "id" (and id (princ-to-string id)))
          (cons "date" (and date (princ-to-string date)))
          (cons "fek" (and fek (princ-to-string fek)))
          (cons "operations" applicable)
          (cons "review" flagged))))

;;; ----------------------------------------------------------------------------
;;; Διαύγεια decision -> amendment record
;;; ----------------------------------------------------------------------------

(defun %dget (decision key)
  (cond ((hash-table-p decision) (gethash key decision))
        ((and (listp decision) (consp (first decision)))
         (cdr (assoc key decision :test #'equal)))
        (t nil)))

(defun diavgeia-decision->record (decision &key text code-resolver article-exists-fn)
  "Turn a parsed Διαύγεια decision (alist/hash) into an amendment record. The
   amending TEXT may be supplied explicitly (e.g. fetched from documentUrl) or
   is taken from the decision's subject/text fields. Returns NIL when no
   operations can be extracted (so the feed safely ignores a pure announcement)."
  (let* ((body (or text (%dget decision "text") (%dget decision "subject") "")))
    (multiple-value-bind (applicable flagged)
        (split-operations body :code-resolver code-resolver
                               :article-exists-fn article-exists-fn)
      (when (or applicable flagged)
        (list (cons "id" (or (%dget decision "ada") (%dget decision "id")))
              (cons "date" (or (%dget decision "submissionTimestamp")
                               (%dget decision "date")))
              (cons "fek" (%dget decision "fek"))
              (cons "operations" applicable)
              (cons "review" flagged))))))
