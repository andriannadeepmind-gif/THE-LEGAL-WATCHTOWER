;;;; systems/orchestrator-cli/graph-import.lisp
;;;; ============================================================================
;;;; ΕΙΣΑΓΩΓΗ ΣΤΟΝ ΕΝΙΑΙΟ ΓΡΑΦΟ — εαυτός + κόσμος, με τα τρία αναλλοίωτα
;;;; ============================================================================
;;;;
;;;; Τώρα που κάθε ακμή γεννιέται με προέλευση+χρόνο+αιτιολόγηση, χύνουμε τα
;;;; πραγματικά δεδομένα ΜΙΑ φορά, σωστά:
;;;;   • ΕΑΥΤΟΣ (:self)  — σύνταγμα (άρθρα), αποστολές· βιογραφία (:meta)
;;;;   • ΚΟΣΜΟΣ (:world) — άρθρα κάθε κώδικα· αποφάσεις + σχέσεις «εφαρμόζει»
;;;;     (αιτιολόγηση :derived — η απόφαση παράγει την εφαρμογή του άρθρου)
;;;; Ο φραγμός Self/World τηρείται εκ κατασκευής (ο εαυτός γράφεται ως :creator).

(in-package :orchestrator.cli)

(defun %graph-import-self ()
  "Ο εαυτός στον γράφο: σύνταγμα+αποστολές (:self), βιογραφία (:meta)."
  (orchestrator.graph:with-origin (:creator)
    (orchestrator.graph:add-node "self:core" :label "LAWMAX" :layer orchestrator.graph:+self+)
    (dolist (a (orchestrator.self:articles))
      (destructuring-bind (n title text) a
        (let ((id (format nil "self:art:~D" n)))
          (orchestrator.graph:add-node id :label title :layer orchestrator.graph:+self+
                                       :props (list :text text))
          (orchestrator.graph:relate id :part-of "self:core"))))
    (loop for m in (orchestrator.self:missions) for i from 1 do
      (let ((id (format nil "self:mission:~D" i)))
        (orchestrator.graph:add-node id :label (second m) :layer orchestrator.graph:+self+)
        (orchestrator.graph:relate id :declared-by "self:core")))
    (dolist (e (orchestrator.self-history:entries))
      (orchestrator.graph:add-node (format nil "self:bio:~D" (getf e :seq))
                                   :label (string-downcase (symbol-name (getf e :kind)))
                                   :layer orchestrator.graph:+meta+
                                   :props (list :text (getf e :text) :at (getf e :at))))))

(defun %graph-import-corpus ()
  "Τα άρθρα κάθε κώδικα ως κόμβοι :world (art:<corpus>:<number>)."
  (let ((seen '()) (n 0))
    (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
      (let ((corpus (cdr entry)))
        (unless (member corpus seen :test #'string=)
          (push corpus seen)
          (let ((path (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir corpus))
                                       (uiop:getcwd))))
            (when (probe-file path)
              (orchestrator.graph:with-origin (:world)
                (with-open-file (s path :external-format :utf-8)
                  (loop for line = (read-line s nil) while line do
                    (let ((rec (ignore-errors (jonathan:parse line :as :alist))))
                      (when rec
                        (let ((num (cdr (assoc "number" rec :test #'string=)))
                              (head (cdr (assoc "heading" rec :test #'string=))))
                          (when num
                            (orchestrator.graph:add-node (format nil "art:~A:~A" corpus num)
                                                         :label head :layer orchestrator.graph:+world+
                                                         :props (list :corpus corpus :number num))
                            (incf n)))))))))))))
    n))

(defun %graph-import-decisions ()
  "Αποφάσεις ως κόμβοι :world + σχέσεις «εφαρμόζει» (αιτιολόγηση :derived)."
  (let ((n 0) (e 0))
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (and (string= (pathname-type f) "json") (not (search ".prov" (pathname-name f))))
          (let ((rec (ignore-errors (jonathan:parse (uiop:read-file-string f :external-format :utf-8)
                                                    :as :alist))))
            (when rec
              (let* ((court (cdr (assoc "court" rec :test #'string=)))
                     (num (cdr (assoc "number" rec :test #'string=)))
                     (year (cdr (assoc "year" rec :test #'string=)))
                     (id (format nil "dec:~A:~A/~A" court num year)))
                (orchestrator.graph:with-origin (:world)
                  (orchestrator.graph:add-node id :label (format nil "~A ~A/~A" court num year)
                                               :layer orchestrator.graph:+world+
                                               :props (list :court court :year year))
                  (incf n)
                  (dolist (c (cdr (assoc "citations" rec :test #'string=)))
                    (let ((corpus (cdr (assoc "corpus" c :test #'string=)))
                          (art (cdr (assoc "article" c :test #'string=))))
                      (when (and corpus art)
                        (orchestrator.graph:relate id :applies (format nil "art:~A:~A" corpus art)
                          :justification (orchestrator.graph:derived (format nil "απόφαση ~A/~A" num year)))
                        (incf e)))))))))))
    (values n e)))

(defun %prefix-p (prefix s)
  (and (stringp s) (>= (length s) (length prefix)) (string= prefix (subseq s 0 (length prefix)))))

(defun %eid->num (eid)
  (if (%prefix-p "art_" eid) (subseq eid 4) eid))

(defun %graph-import-citations ()
  "Παραπομπές άρθρο→άρθρο (:cites) ανά κώδικα, μέσω orchestrator.references. Μόνο
   όπου ΚΑΙ οι δύο κόμβοι υπάρχουν — ώστε το impact να αλυσιδώνει σε πραγματικές
   διατάξεις. Επιστρέφει πλήθος ακμών."
  (let ((seen '()) (n 0))
    (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
      (let ((corpus (cdr entry)))
        (unless (member corpus seen :test #'string=)
          (push corpus seen)
          (handler-case
              (multiple-value-bind (short doc) (build-consolidated-for corpus)
                (declare (ignore short))
                (when doc
                  (let ((g (orchestrator.references:reference-graph doc))
                        (ids (orchestrator.references:document-article-ids doc)))
                    (orchestrator.graph:with-origin (:world)
                      (maphash
                       (lambda (id present) (declare (ignore present))
                         (let ((from-id (format nil "art:~A:~A" corpus (%eid->num id))))
                           (when (orchestrator.graph:node from-id)
                             (dolist (tgt (orchestrator.references:graph-edges g id))
                               (let ((to-id (format nil "art:~A:~A" corpus (%eid->num tgt))))
                                 (when (orchestrator.graph:node to-id)
                                   (orchestrator.graph:relate from-id :cites to-id
                                     :justification (orchestrator.graph:derived "παραπομπή κειμένου"))
                                   (incf n)))))))
                       ids)))))
            (error () nil)))))
    n))

(defun %structural-impact-report (id affected &optional (beyond 0))
  "Έξοδος επίπτωσης — ΜΟΝΟ δομικά γεγονότα από τον γράφο (από τους νόμους),
   ΧΩΡΙΣ δόγμα σε λόγια μου: ποιες διατάξεις παραπέμπουν σε αυτό, ποιες
   αποφάσεις το εφάρμοσαν. Η νομική συνέπεια (ΑΚ 2 μη-αναδρομικότητα, ΠΚ 2,
   δεδικασμένο) θα προστεθεί ΩΣ ΠΑΡΑΠΟΜΠΗ στις ίδιες τις διατάξεις.
   BEYOND: πόσοι κόμβοι έμειναν πέραν του ορίζοντα βάθους — ΔΗΛΩΝΕΤΑΙ."
  (let ((provisions '()) (decisions '()))
    (dolist (a affected)
      (let ((aid (car a)))
        (cond ((%prefix-p "art:" aid) (push aid provisions))
              ((%prefix-p "dec:" aid) (push aid decisions)))))
    (setf provisions (nreverse provisions) decisions (nreverse decisions))
    (let ((nd (orchestrator.graph:node id)))
      (format t "~%── Στον γράφο, στο «~A» παραπέμπουν/το εφαρμόζουν ──~%"
              (if nd (or (orchestrator.graph:node-label nd) id) id)))
    (when provisions
      (format t "~%  Διατάξεις που παραπέμπουν σε αυτό (~D):~%" (length provisions))
      (dolist (p (subseq provisions 0 (min 12 (length provisions))))
        (let ((pn (orchestrator.graph:node p)))
          (format t "    • ~A~@[ — ~A~]~%" p (and pn (orchestrator.graph:node-label pn))))))
    (when decisions
      (format t "~%  Αποφάσεις που το εφάρμοσαν (~D):~%" (length decisions))
      (dolist (d (subseq decisions 0 (min 8 (length decisions))))
        (format t "    • ~A~%" d)))
    (unless (or provisions decisions)
      (format t "~%  Καμία παραπομπή/εφαρμογή στον γράφο.~%"))
    (when (plusp beyond)
      (format t "~%  ⚠ τουλάχιστον ~D κόμβοι ΑΜΕΣΩΣ πέραν του ορίζοντα βάθους — η κάλυψη ΔΕΝ είναι πλήρης (δώσε βάθος: --impact <id> <βάθος>, 0 = χωρίς όριο).~%"
              beyond))
    0))

(defun %graph-import-episodes ()
  "Η ΕΜΠΕΙΡΙΑ στον ίδιο γράφο: κάθε επεισόδιο του υποστρώματος μνήμης γίνεται
   κόμβος :meta (ep:<id>), με ακμές :about προς ό,τι κόμβο αφορά (πχ art:*) —
   ώστε ο ΙΔΙΟΣ συλλογιστής (γιατί;/τι επηρεάζεται;) να δουλεύει και πάνω σε
   ό,τι το σύστημα έζησε. Ένα υπόστρωμα, όχι δεύτερη πραγματικότητα."
  (let ((n 0))
    (orchestrator.graph:with-origin (:self)
      (dolist (e (orchestrator.memory:episodes))
        (let ((id (format nil "ep:~A" (orchestrator.memory:episode-id e))))
          (orchestrator.graph:add-node id
            :label (format nil "~(~A~): ~A"
                           (orchestrator.memory:episode-kind e)
                           (let ((tx (or (orchestrator.memory:episode-text e) "")))
                             (subseq tx 0 (min 60 (length tx)))))
            :layer orchestrator.graph:+meta+
            :props (list :kind (orchestrator.memory:episode-kind e)
                         :status (orchestrator.memory:episode-status e)
                         :at (orchestrator.memory:episode-at e)))
          (incf n)
          (dolist (topic (orchestrator.memory:episode-topic e))
            (when (and (stringp topic) (orchestrator.graph:node topic))
              (orchestrator.graph:relate id :about topic
                :justification (orchestrator.graph:derived "βιωματικό ρεύμα")))))))
    n))

;;; ── ΣΤΙΓΜΙΟΤΥΠΟ ΓΡΑΦΟΥ (Φάση 3): ο γράφος επιβιώνει της διεργασίας ──
;;; Το βαρύ στρώμα (εαυτός+κόσμος: άρθρα, αποφάσεις, παραπομπές — απαιτεί πλήρη
;;; ενοποίηση 6 κωδίκων) σειριοποιείται με ΑΠΟΤΥΠΩΜΑ εισόδων· η ΕΜΠΕΙΡΙΑ
;;; (επεισόδια/βιογραφία, :meta) εισάγεται ΠΑΝΤΑ φρέσκια στη φόρτωση — φθηνή
;;; και διαρκώς μεταβαλλόμενη, δεν σφραγίζεται. Είσοδοι άλλαξαν ⇒ το στιγμιότυπο
;;; αγνοείται και ο γράφος ξαναχτίζεται — ποτέ μπαγιάτικη αλήθεια σιωπηλά.

(defparameter *graph-snapshot-path*
  (merge-pathnames "deployment/self/graph-snapshot.sexp" (uiop:getcwd))
  "Runtime κατάσταση του αντιτύπου (gitignored) — όχι του repo.")

(defun %graph-input-files ()
  "Οι είσοδοι του κοσμο-στρώματος: corpus.jsonl ανά κώδικα + JSON αποφάσεων."
  (let ((files '()) (seen '()))
    (dolist (entry orchestrator.decisions:+law-tag-corpus-map+)
      (let ((corpus (cdr entry)))
        (unless (member corpus seen :test #'string=)
          (push corpus seen)
          (let ((p (merge-pathnames (format nil "output/~A/corpus.jsonl" (%corpus-outdir corpus))
                                    (uiop:getcwd))))
            (when (probe-file p) (push p files))))))
    (dolist (dir (uiop:subdirectories (merge-pathnames "deployment/data/decisions/" (uiop:getcwd))))
      (dolist (f (uiop:directory-files dir))
        (when (string= (pathname-type f) "json") (push f files))))
    files))

(defun %graph-stamp ()
  "Αποτύπωμα εισόδων: (path mtime μέγεθος) ανά αρχείο, ταξινομημένο — ίδιο
   αποτύπωμα ⇔ ίδιες είσοδοι (το φθηνό κριτήριο φρεσκάδας του συστήματος)."
  (sort (loop for f in (%graph-input-files)
              for st = (ignore-errors (sb-posix:stat (namestring f)))
              when st collect (list (namestring f)
                                    (sb-posix:stat-mtime st)
                                    (sb-posix:stat-size st)))
        #'string< :key #'first))

(defun %graph-build ()
  "Πλήρες χτίσιμο του ενιαίου γράφου από τις πηγές + νέο στιγμιότυπο στον δίσκο."
  (setf orchestrator.graph:*graph* (orchestrator.graph:make-graph))
  (%graph-import-self)
  (%graph-import-corpus)
  (%graph-import-decisions)
  (%graph-import-citations)   ; παραπομπές άρθρο→άρθρο (από τους ίδιους τους νόμους)
  ;; στιγμιότυπο ΠΡΙΝ την εμπειρία — αυτή εισάγεται φρέσκια σε κάθε φόρτωση
  (handler-case
      (orchestrator.graph:save-graph *graph-snapshot-path*
                                     :meta (list :stamp (%graph-stamp)))
    (error (e)
      (format t "  ⚠ το στιγμιότυπο γράφου ΔΕΝ γράφτηκε (~A) — ο γράφος ζει μόνο σε αυτή τη διεργασία~%" e)))
  (%graph-import-episodes)    ; η ΕΜΠΕΙΡΙΑ στο :meta — ίδιος συλλογιστής και για ό,τι έζησε
  orchestrator.graph:*graph*)

(defun %graph-ensure ()
  "Ο γράφος ΖΩΝΤΑΝΟΣ σε αυτή τη διεργασία: αν είναι άδειος, φόρτωσε το
   στιγμιότυπο εφόσον το αποτύπωμα εισόδων ταιριάζει (και βάλε φρέσκια την
   εμπειρία)· αλλιώς πλήρες χτίσιμο. Επιστρέφει τον γράφο."
  (when (zerop (orchestrator.graph:node-count))
    (let ((loaded nil))
      (handler-case
          (multiple-value-bind (g nn ne meta)
              (orchestrator.graph:load-graph *graph-snapshot-path*)
            (when (and g (equal (getf meta :stamp) (%graph-stamp)))
              (setf orchestrator.graph:*graph* g)
              (%graph-import-episodes)
              (setf loaded t)
              (format t "  ↺ γράφος από στιγμιότυπο: ~D κόμβοι · ~D ακμές (είσοδοι αμετάβλητες)~%"
                      nn ne)))
        (error (e)
          (format t "  ⚠ στιγμιότυπο γράφου μη αναγνώσιμο (~A) — πλήρες ξαναχτίσιμο~%" e)))
      (unless loaded (%graph-build))))
  orchestrator.graph:*graph*)

(defun run-graph ()
  "--graph : Χτίσε τον ΕΝΙΑΙΟ γράφο από τα πραγματικά δεδομένα (εαυτός+κόσμος+
   εμπειρία), γράψε φρέσκο στιγμιότυπο, και δείξε τη σύνθεσή του + δείγμα
   ερωτήματος «γιατί» (αιτιολόγηση)."
  (%graph-build)
  (let ((self 0) (world 0) (meta 0))
    (dolist (nd (orchestrator.graph:query-nodes (constantly t)))
      (case (orchestrator.graph:node-layer nd)
        (:self (incf self)) (:world (incf world)) (:meta (incf meta))))
    (format t "~%── ΕΝΙΑΙΟΣ ΓΡΑΦΟΣ (εαυτός + κόσμος, ένα υπόστρωμα) ──~%")
    (format t "  κόμβοι: ~D  (:self ~D · :world ~D · :meta ~D)~%"
            (orchestrator.graph:node-count) self world meta)
    (format t "  ακμές:  ~D~%" (orchestrator.graph:edge-count)))
  ;; δείγμα «γιατί»: μια απόφαση και τι εφαρμόζει, με την αιτιολόγηση κάθε σχέσης
  (let ((dec (find-if (lambda (n) (search "dec:" (orchestrator.graph:node-id n)))
                      (orchestrator.graph:query-nodes (constantly t)))))
    (when dec
      (let ((es (orchestrator.graph:edges (orchestrator.graph:node-id dec))))
        (when es
          (format t "~%  ΓΙΑΤΙ; — η «~A» εφαρμόζει:~%" (orchestrator.graph:node-label dec))
          (dolist (e (subseq es 0 (min 4 (length es))))
            (format t "    → ~A   [~A]~%" (orchestrator.graph:edge-to e)
                    (orchestrator.graph:why e)))))))
  ;; δείγμα εαυτού (self-as-data)
  (let ((selves (orchestrator.graph:query-nodes
                 (lambda (n) (eq (orchestrator.graph:node-layer n) :self)))))
    (format t "~%  ΕΑΥΤΟΣ (self-as-data, ερωτήσιμος): ~D κόμβοι — πχ ~{~A~^, ~}~%"
            (length selves)
            (mapcar #'orchestrator.graph:node-id
                    (subseq selves 0 (min 3 (length selves))))))
  ;; δείγμα ΣΥΛΛΟΓΙΣΜΟΥ (δομικά γεγονότα, από τους νόμους — όχι δόγμα σε λόγια μου)
  (let ((art (find-if (lambda (n) (and (%prefix-p "art:" (orchestrator.graph:node-id n))
                                       (orchestrator.graph:in-edges (orchestrator.graph:node-id n))))
                      (orchestrator.graph:query-nodes (constantly t)))))
    (when art
      (multiple-value-bind (affected beyond)
          (orchestrator.graph-reason:impact (orchestrator.graph:node-id art))
        (%structural-impact-report (orchestrator.graph:node-id art) affected beyond))))
  0)

(defun %graph-query (id thunk)
  "Ζωντανός γράφος (στιγμιότυπο ή χτίσιμο) και τρέξε το ερώτημα THUNK στον ID."
  (%graph-ensure)
  (let ((nd (orchestrator.graph:node id)))
    (if nd (funcall thunk nd)
        (progn (format t "Δεν βρέθηκε κόμβος «~A» στον γράφο.~%" id) 1))))

(defun run-graph-impact (args)
  "--impact <node-id> [βάθος] : τι επηρεάζεται αν αλλάξει ο κόμβος (μεταβατική
   εξάρτηση). Προαιρετικό βάθος ορίζοντα (προεπιλογή 6, 0 = χωρίς όριο)."
  (let ((id (first args))
        (depth (and (second args) (parse-integer (second args) :junk-allowed t))))
    (if (null id) (progn (format t "χρήση: --impact <node-id> [βάθος] (πχ art:poinikos:510 12, 0=χωρίς όριο)~%") 1)
        (%graph-query id (lambda (nd) (declare (ignore nd))
                           (multiple-value-bind (affected beyond)
                               (orchestrator.graph-reason:impact
                                id :max-depth (cond ((null depth) 6)
                                                    ((zerop depth) nil)
                                                    (t depth)))
                             (%structural-impact-report id affected beyond))
                           0)))))

(defun run-graph-why (args)
  "--why <node-id> : η αιτιολόγηση ενός κόμβου (δέντρο απόδειξης)."
  (let ((id (first args)))
    (if (null id) (progn (format t "χρήση: --why <node-id>~%") 1)
        (%graph-query id (lambda (nd)
                           (format t "~%ΓΙΑΤΙ «~A»:~%~A"
                                   (or (orchestrator.graph:node-label nd) id)
                                   (orchestrator.graph-reason:explanation->string
                                    (orchestrator.graph-reason:explain nd)))
                           0)))))

(register-command "--graph"   (lambda (a) (declare (ignore a)) (run-graph)))
(register-command "--γράφος"  (lambda (a) (declare (ignore a)) (run-graph)))
(register-command "--impact"  (lambda (a) (run-graph-impact a)))
(register-command "--why"     (lambda (a) (run-graph-why a)))
