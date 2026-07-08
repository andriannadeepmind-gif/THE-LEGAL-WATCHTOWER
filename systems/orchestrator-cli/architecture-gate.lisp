;;;; systems/orchestrator-cli/architecture-gate.lisp
;;;; ============================================================================
;;;; Η ΠΥΛΗ ΤΟΥ ΑΡΧΙΤΕΚΤΟΝΙΚΟΥ ΣΥΝΤΑΓΜΑΤΟΣ — read-only ontological closure
;;;; ============================================================================
;;;;
;;;; ΔΕΝ αλλάζει καμία λειτουργία. Διαβάζει (data-only, *read-eval* NIL) το
;;;; deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp και το αντιπαραθέτει στα
;;;; ΖΩΝΤΑΝΑ μητρώα. Κοκκινίζει σε: αχαρτογράφητη εντολή, εντολή χωρίς owner/
;;;; primitive, έξοδο χωρίς envelope-δήλωση, παράκαμψη της μηχανής υιοθεσίας,
;;;; bootstrap χωρίς σήμανση, άγνωστο store, σπασμένο κλείδωμα των 13 primitives.
;;;; Έτσι ο χάρτης δεν είναι νεκρό κείμενο: νέα εντολή/έδρα χωρίς οντολογική
;;;; δήλωση = κόκκινη ολομέλεια.

(in-package :orchestrator.cli)

(defun %load-architecture-constitution ()
  "Data-only ανάγνωση του συντάγματος. (values plist error)."
  (let ((path (merge-pathnames "deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp"
                               (uiop:getcwd))))
    (if (not (probe-file path))
        (values nil (format nil "ΔΕΝ βρέθηκε: ~A" path))
        (handler-case
            (with-open-file (s path :external-format :utf-8)
              (let ((*read-eval* nil) (*package* (find-package :keyword)))
                (values (rest (read s)) nil)))
          (error (e) (values nil (format nil "μη αναγνώσιμο σύνταγμα: ~A" e)))))))

(defparameter +the-13-primitives+
  '(:self :law :authority :fact :proof :hypothesis :argument :matter
    :output-trust :evolution :institution :memory :substrate)
  "ΚΛΕΙΔΩΜΕΝΑ. Αλλαγή εδώ = συνταγματική τροποποίηση με έγκριση δημιουργού.")

;;; ── FF1: μία έδρα ρίζας — καμία δεύτερη root αλήθεια στον κώδικα ──────────
;;;
;;; Κανόνας Κριτή (0021): «η πύλη FF1 πρέπει να κόβει κάθε runtime path
;;; decision που κρατά δικό του literal /app Ή δική του compile-time root
;;; αλήθεια εκτός της μίας έδρας.» ΟΧΙ τυφλό grep (§2.1): allowlist ΜΕ
;;; αιτιολογία — comment-aware, string-aware.

(defparameter +ff1-root-seat+ "source/paths.lisp"
  "Η ΜΙΑ έδρα ρίζας. ΜΟΝΟ εδώ επιτρέπεται ο δηλωμένος deployment default
   + compile-time root candidate.")

(defparameter +ff1-app-needle+ (coerce (list #\/ #\a #\p #\p) 'string)
  "Το μοτίβο ρίζας-default, ΚΑΤΑΣΚΕΥΑΣΜΕΝΟ από χαρακτήρες ώστε ΑΥΤΟ το αρχείο
   (ο ανιχνευτής FF1) να ΜΗΝ περιέχει το ίδιο literal που απαγορεύει — μηδέν
   self-exemption, καμία ανάγκη να allowlistάρει τον εαυτό του.")

(defparameter +ff1-app-allowlist+
  '(("source/paths.lisp"
     . "η έδρα ρίζας: ο δηλωμένος deployment default + τα docstrings της"))
  "(σχετικό-path . αιτιολογία): τα ΜΟΝΑ αρχεία όπου literal ρίζα-path
   επιτρέπεται. Ελάχιστο· κάθε εγγραφή φέρει αιτιολογία (κανόνας Κριτή §2.1).")

(defun %ff1-string-literals (text)
  "Τα ΠΕΡΙΕΧΟΜΕΝΑ όλων των string literals του TEXT (Lisp), με σεβασμό σε
   escapes και σε ; comments (comment έξω από string ⇒ αγνοείται ως το EOL).
   Έτσι /app σε σχόλιο ΔΕΝ μετριέται — μόνο πραγματικά string literals."
  (let ((out '()) (i 0) (n (length text)) (in-str nil) (buf nil))
    (loop while (< i n) for ch = (char text i) do
      (cond
        (in-str
         (cond ((char= ch #\\) (push ch buf)
                                (when (< (1+ i) n) (push (char text (1+ i)) buf))
                                (incf i))
               ((char= ch #\") (push (coerce (nreverse buf) 'string) out)
                               (setf in-str nil buf nil))
               (t (push ch buf))))
        ((char= ch #\") (setf in-str t buf nil))
        ((char= ch #\;) (loop while (and (< i n) (char/= (char text i) #\Newline))
                              do (incf i))
                        (decf i)))
      (incf i))
    (nreverse out)))

(defun %ff1-code-without-strings (text)
  "Το TEXT με strings ΚΑΙ comments αφαιρεμένα — για σάρωση συμβόλων κώδικα
   (π.χ. compile-time root) χωρίς ψευδώς-θετικά μέσα σε strings/σχόλια."
  (let ((out (make-string-output-stream)) (i 0) (n (length text)) (in-str nil))
    (loop while (< i n) for ch = (char text i) do
      (cond
        (in-str (cond ((char= ch #\\) (incf i))
                      ((char= ch #\") (setf in-str nil))))
        ((char= ch #\") (setf in-str t))
        ((char= ch #\;) (loop while (and (< i n) (char/= (char text i) #\Newline))
                              do (incf i))
                        (decf i))
        (t (write-char ch out)))
      (incf i))
    (get-output-stream-string out)))

(defun %ff1-app-path-p (s)
  "Περιέχει το S τη ρίζα-default ΩΣ path segment (ακολουθεί «/» ή τέλος-string);
   — ΟΧΙ λέξεις όπως approve/application. Το μοτίβο κατασκευάζεται (needle)."
  (let ((needle +ff1-app-needle+))
    (loop for p = (search needle s) then (search needle s :start2 (1+ p))
          while p
          thereis (let ((after (+ p (length needle))))
                    (or (>= after (length s))
                        (char= (char s after) #\/))))))

(defun %ff1-lisp-sources (root)
  "Όλα τα .lisp κάτω από systems/ και source/ της ρίζας."
  (append (directory (merge-pathnames "systems/**/*.lisp" root))
          (directory (merge-pathnames "source/**/*.lisp" root))))

(defun %ff1-rel (path root)
  "Σχετικό (posix) path ενός αρχείου ως προς τη ρίζα."
  (let ((rp (enough-namestring path root)))
    (substitute #\/ #\\ rp)))

(defun %prefix-p (prefix s)
  "Ξεκινά το S με το PREFIX;"
  (and (>= (length s) (length prefix))
       (string= prefix s :end2 (length prefix))))

(defun %yaml-abs-path-value-p (trimmed-line)
  "Η τιμή ενός YAML key:value γραμμής είναι ABSOLUTE filesystem path (ξεκινά με
   «/»); — ΟΧΙ URL/URI, ΟΧΙ σχετική, ΟΧΙ κενή. Απομονώνει τη τιμή μέσα στα «\"»
   (ή μετά το «:») και κοιτά τον πρώτο χαρακτήρα. Web ids (http…, urn:) ΔΕΝ
   ξεκινούν με «/» ⇒ δεν πιάνονται (διάκριση path vs identifier)."
  (let* ((colon (position #\: trimmed-line))
         (rest (and colon (string-trim '(#\Space #\Tab #\Return)
                                       (subseq trimmed-line (1+ colon)))))
         ;; ξεκόλλα εισαγωγικά αν υπάρχουν
         (val (and rest (plusp (length rest))
                   (if (char= (char rest 0) #\")
                       (let ((end (position #\" rest :start 1)))
                         (and end (subseq rest 1 end)))
                       rest))))
    (and val (plusp (length val)) (char= (char val 0) #\/))))

(defun run-architecture-constitution-gate ()
  "--architecture-constitution-gate : ontological closure, read-only."
  (multiple-value-bind (c err) (%load-architecture-constitution)
    (when err
      (format t "~%✗ ΣΥΝΤΑΓΜΑ: ~A~%" err)
      (return-from run-architecture-constitution-gate 1))
    (let ((fails '()) (total 0)
          (cmd-map (getf c :command-map))
          (cap-map (getf c :capability-map))
          (live-cmds (sort (loop for k being the hash-keys of *commands* collect k)
                           #'string<)))
      (flet ((chk (label ok &optional detail)
               (incf total)
               (if ok (format t "  ✓ ~A~%" label)
                   (progn (push label fails)
                          (format t "  ✗ ~A~@[~%      → ~A~]~%" label detail))))
             (map-entry (cmd)
               (find cmd cmd-map
                     :key (lambda (e) (getf e :command)) :test #'equal)))
        (format t "~%── ΠΥΛΗ ΑΡΧΙΤΕΚΤΟΝΙΚΟΥ ΣΥΝΤΑΓΜΑΤΟΣ (read-only) ──~%")
        ;; ① τα 13 primitives: ακριβώς αυτά, με αυτή τη σειρά — κλειδωμένα
        (chk "① τα 13 primitives κλειδωμένα (σύνταγμα ≡ πύλη, ακριβής λίστα)"
             (equal (getf c :primitives) +the-13-primitives+)
             (format nil "σύνταγμα: ~S" (getf c :primitives)))
        ;; ② κάθε ΖΩΝΤΑΝΗ εντολή χαρτογραφημένη (ο ratchet της οντολογίας)
        (let ((unmapped (remove-if #'map-entry live-cmds)))
          (chk (format nil "② καμία αχαρτογράφητη εντολή (ζωντανές: ~D)" (length live-cmds))
               (null unmapped) (format nil "αχαρτογράφητες: ~{~A~^ ~}" unmapped)))
        ;; ③ καμία ΞΕΠΕΡΑΣΜΕΝΗ εγγραφή (σύνταγμα ⊆ ζωντανό μητρώο)
        (let ((stale (remove-if (lambda (e) (member (getf e :command) live-cmds
                                                    :test #'equal))
                                cmd-map)))
          (chk "③ καμία ξεπερασμένη εγγραφή στο σύνταγμα"
               (null stale)
               (format nil "ξεπερασμένες: ~{~A~^ ~}"
                       (mapcar (lambda (e) (getf e :command)) stale))))
        ;; ④ κάθε εντολή με owner ΚΑΙ primitive ∈ 13 ΚΑΙ envelope-δήλωση
        (let ((bad '()))
          (dolist (e cmd-map)
            (let ((f (getf e :owner-file)))
              (unless (and (stringp f)
                           (or (probe-file (merge-pathnames f (uiop:getcwd)))
                               (orchestrator.component-scan:known-file-hash f)))
                (push (format nil "~A(owner:~A)" (getf e :command) f) bad))
              (unless (member (getf e :primitive) +the-13-primitives+)
                (push (format nil "~A(primitive:~S)" (getf e :command)
                              (getf e :primitive)) bad))
              (let ((env (getf e :envelope)))
                (unless (and (consp env)
                             (member (first env)
                                     '(:required :structured
                                       :untrusted-declaration :exception))
                             (stringp (second env)))
                  (push (format nil "~A(envelope:~S)" (getf e :command) env) bad)))))
          (chk "④ κάθε εντολή: owner επιλύσιμος (δίσκος ή manifest) + primitive + envelope-δήλωση"
               (null bad) (format nil "~{~A~^ · ~}" (subseq bad 0 (min 6 (length bad))))))
        ;; ⑤ ικανότητες ↔ σύνταγμα αμφίδρομα, primitives έγκυρα
        (let* ((live-caps (mapcar #'orchestrator.self-model:capability-name
                                  (orchestrator.self-model:all-capabilities)))
               (mapped (mapcar (lambda (e) (getf e :capability)) cap-map))
               (unmapped (set-difference live-caps mapped :test #'string=))
               (stale (set-difference mapped live-caps :test #'string=))
               (badp (remove-if (lambda (e) (member (getf e :primitive)
                                                    +the-13-primitives+))
                                cap-map)))
          (chk (format nil "⑤ ικανότητες ↔ σύνταγμα αμφίδρομα (~D ζωντανές)" (length live-caps))
               (and (null unmapped) (null stale) (null badp))
               (format nil "αχαρτ:~S ξεπερ:~S κακό-primitive:~S"
                       unmapped stale
                       (mapcar (lambda (e) (getf e :capability)) badp))))
        ;; ⑥ κάθε πύλη (τεστ) δεμένη σε primitive· κάθε δηλωμένη πύλη ικανότητας ζωντανή
        (let* ((gates (remove-if-not
                       (lambda (k) (and (> (length k) 5)
                                        (string= "-gate" k :start2 (- (length k) 5))))
                       live-cmds))
               (bad (remove-if (lambda (g)
                                 (let ((e (map-entry g)))
                                   (and e (member (getf e :primitive)
                                                  +the-13-primitives+))))
                               gates))
               (dead-gates (remove-if
                            (lambda (g) (or (null g) (member g live-cmds :test #'equal)))
                            (mapcar #'orchestrator.self-model:capability-gate
                                    (orchestrator.self-model:all-capabilities)))))
          (chk (format nil "⑥ κάθε πύλη→primitive (~D πύλες)· καμία κρεμασμένη πύλη ικανότητας"
                       (length gates))
               (and (null bad) (null dead-gates))
               (format nil "χωρίς primitive: ~S · κρεμασμένες: ~S" bad dead-gates)))
        ;; ⑦ envelope canary: το --ask εκπέμπει ΠΡΑΓΜΑΤΙΚΑ envelope+mode τώρα
        ;; read-only ΓΝΗΣΙΑ (όρος δημιουργού): το canary δεσμεύει το μονοπάτι
        ;; επεισοδίων σε scratch αρχείο — καμία εγγραφή στα κανονικά stores.
        (let* ((scratch (merge-pathnames
                         (format nil "arch-canary-~D.sexp" (get-universal-time))
                         (uiop:temporary-directory)))
               (out (unwind-protect
                         (let ((orchestrator.memory:*episodes-path* scratch))
                           (with-output-to-string (*standard-output*)
                             (run-ask '("ποιος" "είσαι;"))))
                      (ignore-errors (delete-file scratch)))))
          (chk "⑦ envelope canary: --ask εκπέμπει TRUST ENVELOPE + mode (ζωντανή απόδειξη, όχι δήλωση)"
               (and (search "TRUST ENVELOPE" out) (search "mode:" out))))
        ;; ⑧ ΜΙΑ μηχανή υιοθεσίας: σύμβολα fbound + επιφάνεια υιοθεσίας κλειστή
        (let* ((engine (getf c :adoption-engine))
               (surface (getf c :adoption-surface))
               (dec (getf engine :decision))
               (sym (and (stringp dec)
                         (let* ((pos (search ":" dec))
                                (pkg (find-package (string-upcase (subseq dec 0 pos))))
                                (nm (string-upcase (subseq dec (1+ pos)))))
                           (and pkg (find-symbol nm pkg)))))
               (adoptish (remove-if-not
                          (lambda (k) (or (search "adopt" k) (search "approve" k)
                                          (search "reject" k)))
                          live-cmds))
               (outside (set-difference adoptish surface :test #'equal)))
          (chk "⑧ μηχανή υιοθεσίας: can-adopt fbound + κάθε adopt/approve/reject εντολή στη δηλωμένη επιφάνεια"
               (and sym (fboundp sym) (null outside))
               (format nil "εκτός επιφάνειας: ~S" outside)))
        ;; ⑨ κανονικά stores: μοναδικοί ρόλοι + κανένα ΑΓΝΩΣΤΟ store στον δίσκο
        (let* ((stores (getf c :canonical-stores))
               (roles (mapcar (lambda (s) (getf s :role)) stores))
               (declared (mapcar (lambda (s) (getf s :path)) stores))
               (on-disk (append
                         (mapcar (lambda (p) (enough-namestring p (uiop:getcwd)))
                                 (append (directory (merge-pathnames "deployment/self/*.sexp" (uiop:getcwd)))
                                         (directory (merge-pathnames "deployment/state/*.jsonl" (uiop:getcwd)))))))
               (unknown (remove-if (lambda (p) (member p declared :test #'equal))
                                   on-disk)))
          (chk "⑨ stores: ένας ρόλος ανά store, κανένα αδήλωτο store στον δίσκο"
               (and (= (length roles) (length (remove-duplicates roles)))
                    (null unknown))
               (format nil "αδήλωτα: ~S" unknown)))
        ;; ⑩ bootstrap: κάθε artifact σημασμένο (όπου η πηγή διαβάζεται· αλλιώς τίμια σημείωση)
        (let ((bad '()) (unverifiable 0))
          (dolist (b (getf c :bootstrap-artifacts))
            (let* ((f (getf b :artifact))
                   (path (merge-pathnames f (uiop:getcwd)))
                   (marker (getf b :marker)))
              (cond ((not (probe-file path))
                     (incf unverifiable))   ; source-less runtime: δηλωμένο, μη επαληθεύσιμο εδώ
                    ((not (search marker (uiop:read-file-string path)))
                     (push f bad)))))
          (when (plusp unverifiable)
            (format t "  ⚠ ~D bootstrap artifacts μη επαληθεύσιμα εδώ (source-less runtime) — δηλωμένα στο σύνταγμα~%"
                    unverifiable))
          (chk "⑩ κάθε bootstrap artifact φέρει σήμανση BOOTSTRAP στην πηγή του"
               (null bad) (format nil "χωρίς σήμανση: ~S" bad)))
        ;; ⑪ concept-mapping: κάθε μελλοντική έννοια δεμένη ΜΟΝΟ στα 13
        (let ((bad (remove-if
                    (lambda (cm)
                      (every (lambda (p) (member p +the-13-primitives+))
                             (getf cm :belongs-to)))
                    (getf c :concept-mapping))))
          (chk "⑪ concept-mapping: κάθε δηλωμένη έννοια ∈ 13 primitives, με έδρες & does-not-duplicate"
               (and (null bad)
                    (every (lambda (cm) (and (getf cm :extends-existing)
                                             (getf cm :does-not-duplicate)))
                           (getf c :concept-mapping)))))
        ;; ⑫ δηλωμένη πολλαπλότητα: κάθε εγγραφή με αιτιολόγηση (ρητό :why)
        (chk "⑫ κάθε justified-multiplicity εγγραφή φέρει ρητή αιτιολόγηση"
             (every (lambda (j) (and (getf j :area) (stringp (getf j :why))
                                     (getf j :implementations)))
                    (getf c :justified-multiplicity)))
        ;; ── FF1: μία έδρα ρίζας του Ιδρύματος (κανόνας Κριτή 0021) ──
        (let* ((root (orchestrator.paths:institution-root))
               (sources (%ff1-lisp-sources root))
               (app-violations '())
               (root-truth-violations '()))
          (dolist (f sources)
            (let* ((rel (%ff1-rel f root))
                   (text (ignore-errors (uiop:read-file-string f))))
              (when text
                ;; (α) literal /app-path σε string literal, εκτός allowlist
                (unless (assoc rel +ff1-app-allowlist+ :test #'string=)
                  (when (some #'%ff1-app-path-p (%ff1-string-literals text))
                    (push rel app-violations)))
                ;; (β) compile-time root truth εκτός της έδρας
                (unless (string= rel +ff1-root-seat+)
                  (let ((code (%ff1-code-without-strings text)))
                    (when (or (search "*compile-file-truename*" code)
                              (search "*load-truename*" code)
                              (search "*load-pathname*" code))
                      (push rel root-truth-violations)))))))
          ;; ⑬ καμία δεύτερη literal /app-αλήθεια σε runtime κώδικα
          (chk "⑬ FF1: κανένα literal /app-path εκτός της έδρας+allowlist (μία ρίζα)"
               (null app-violations)
               (when app-violations
                 (format nil "παραβάσεις: ~{~A~^, ~}" app-violations)))
          ;; ⑭ καμία δεύτερη compile-time root αλήθεια εκτός της έδρας
          (chk "⑭ FF1: καμία compile-time root αλήθεια (#./load-truename) εκτός source/paths.lisp"
               (null root-truth-violations)
               (when root-truth-violations
                 (format nil "παραβάσεις: ~{~A~^, ~}" root-truth-violations)))
          ;; ⑮ η έδρα ΑΠΟΔΕΙΚΝΥΕΙ ταυτότητα: η επιλυμένη ρίζα φέρει τα sentinels
          (chk "⑮ FF1: institution-root περνά έλεγχο ΤΑΥΤΟΤΗΤΑΣ (sentinel αρχεία, όχι απλή ύπαρξη)"
               (every (lambda (s) (probe-file (merge-pathnames s root)))
                      orchestrator.paths::+institution-sentinels+))
          ;; ⑯ committed YAML: τα filesystem-path keys είναι ΣΧΕΤΙΚΑ (όχι
          ;;    absolute /... ούτε /app)· URLs/format ΔΙΑΚΡΙΝΟΝΤΑΙ και δεν
          ;;    ελέγχονται (κανόνας Κριτή: πύλη ξεχωρίζει paths από web ids).
          (let ((yaml-abs '()))
            (dolist (y (directory (merge-pathnames "configs/*.yaml" root)))
              (let ((txt (ignore-errors (uiop:read-file-string y))))
                (when txt
                  (dolist (line (uiop:split-string txt :separator '(#\Newline)))
                    (let ((tl (string-left-trim '(#\Space #\Tab) line)))
                      (when (and (or (%prefix-p "json:" tl) (%prefix-p "pdf:" tl)
                                     (%prefix-p "docx:" tl))
                                 (%yaml-abs-path-value-p tl))
                        (push (%ff1-rel y root) yaml-abs)))))))
            (chk "⑯ FF1: committed YAML source paths ΣΧΕΤΙΚΑ (όχι absolute /app)· URLs άθικτα"
                 (null yaml-abs)
                 (when yaml-abs (format nil "absolute σε: ~{~A~^, ~}"
                                        (remove-duplicates yaml-abs :test #'string=)))))
          ;; ⑰ ΑΠΟΔΕΙΞΗ ΔΙΑΚΡΙΣΗΣ path-vs-webid: ο διαχωριστής πιάνει absolute
          ;;    filesystem path, αγνοεί relative, αγνοεί URL, αγνοεί metadata.
          ;;    (κανόνας Κριτή: η πύλη πρέπει να ΑΠΟΔΕΙΚΝΥΕΙ τη διάκριση.)
          (chk "⑰ FF1: ο διαχωριστής path/web-id αποδεδειγμένος (absolute=κόκκινο, relative/URL/metadata=OK)"
               (and (%yaml-abs-path-value-p "json: \"/some/abs/data/x.json\"")   ; absolute path ⇒ T
                    (not (%yaml-abs-path-value-p "json: \"deployment/data/x.json\"")) ; relative ⇒ NIL
                    (not (%yaml-abs-path-value-p "url: \"https://example.com/a/b\"")) ; URL ⇒ NIL
                    (not (%yaml-abs-path-value-p "pdf_url: \"https://x/y.pdf\""))     ; web id ⇒ NIL
                    (not (%yaml-abs-path-value-p "format: \"json\"")))))            ; metadata ⇒ NIL
        (format t "~%── ΠΥΛΗ ΑΡΧΙΤΕΚΤΟΝΙΚΟΥ ΣΥΝΤΑΓΜΑΤΟΣ: ~D/~D πέρασαν ──~%"
                (- total (length fails)) total)
        (if fails 1 0)))))

(register-command "--architecture-constitution-gate"
  (lambda (a) (declare (ignore a)) (run-architecture-constitution-gate)))

(orchestrator.self-model:declare-capability! "αρχιτεκτονική-περιφρούρηση"
 :description "ontological closure: 13 κλειδωμένα primitives, πλήρης χαρτογράφηση εντολών/ικανοτήτων, μία μηχανή υιοθεσίας, σημασμένο bootstrap, κανένα αδήλωτο store — read-only επιβολή του αρχιτεκτονικού συντάγματος"
 :package :orchestrator.cli
 :functions '("run-architecture-constitution-gate" "%load-architecture-constitution")
 :gate "--architecture-constitution-gate"
 :depends-on '("αυτοεπίγνωση" "συστατικά" "συμβόλαια"))

(orchestrator.contracts:defcontract "architecture-constitution" :protocol
 :package :orchestrator.cli :system "orchestrator-cli"
 :capability "αρχιτεκτονική-περιφρούρηση" :role "σύνταγμα"
 :purpose "καμία νέα έδρα/εντολή/έννοια χωρίς οντολογική δήλωση στα 13 primitives — ο χάρτης επιβάλλεται, δεν περιγράφει"
 :inputs '("deployment/LAWMAX-ARCHITECTURE-CONSTITUTION.sexp (data-only)" "ζωντανά μητρώα")
 :outputs '("ετυμηγορία ολομέλειας — αχαρτογράφητο = κόκκινο")
 :preconditions '("το σύνταγμα διαβάζεται με *read-eval* NIL")
 :postconditions '("νέα εντολή χωρίς χαρτογράφηση ⇒ πύλη κόκκινη"
                   "bootstrap χωρίς σήμανση ⇒ πύλη κόκκινη"
                   "δεύτερο μονοπάτι υιοθεσίας ⇒ πύλη κόκκινη")
 :side-effects '("καμία — read-only πύλη")
 :legal-critical nil :policy-level :συμβουλευτικό
 :audit "κάθε έλεγχος ονομαστικός με λεπτομέρεια αποτυχίας"
 :rollback "n/a — read-only"
 :tests '("--architecture-constitution-gate"))
