;;;; model-law-kernel.lisp — the ARCHITECTURE-LAW KERNEL. Reads only internal, hash-pinned model files with
;;;; *read-eval* nil under with-standard-io-syntax (standard readtable; NO project reader macros; no eval, no
;;;; compilation of model content) and explicit size/depth/collection limits. Checks the model laws, returns typed
;;;; violations with causes+locations, exits non-zero on any unknown/malformed/violated law.
;;;;
;;;; SHA-256 comes from ONE pinned EXTERNAL digest program (KERNEL/hash-provider.lisp). Review-2 N-1 removed the
;;;; vendored ironclad/ASDF closure: this process no longer compiles or loads a single line of third-party Lisp.
;;;; The only subprocess this kernel ever starts is that pinned digest program, by absolute path, never via a
;;;; shell and never resolved through PATH. No regex, no grep, no substring is structural proof anywhere here.
;;;;
;;;; What the schema now buys (Review-2 N-8/N-9/N-10): the allowed field set of every fact type is CLOSED, every
;;;; declared field has a declared value kind, every id must satisfy its declared id-space, state-dependent field
;;;; rules and uniqueness laws are read from the schema as data, and ROOT.sexp is held to the same
;;;; complete-consumption discipline as every module instead of being the one file nobody checked.
;;;; This is NOT semantic, legal, security, behavioral, operational or qualification proof.
(defpackage :aml-kernel (:use :cl))
(in-package :aml-kernel)
(load (merge-pathnames "hash-provider.lisp" *load-pathname*))
(defparameter +max-file-bytes+ 4000000) (defparameter +max-depth+ 40) (defparameter +max-list+ 60000)
(defvar *dir*) (defvar *facts* (make-hash-table :test 'equal)) (defvar *by-type* (make-hash-table :test 'equal))
(defvar *id-owner* (make-hash-table :test 'equal)) (defvar *ftypes* (make-hash-table :test 'equal))
(defvar *enums* (make-hash-table :test 'equal)) (defvar *spaces* (make-hash-table :test 'equal))
(defvar *conds* '()) (defvar *uniques* '()) (defvar *renders* '()) (defvar *viol* '()) (defvar *schema-version* nil)
(defun v! (law reason loc) (push (list law reason loc) *viol*))
(defun sname (x) (cond ((symbolp x) (symbol-name x)) ((stringp x) x) (t (princ-to-string x))))
(defun kwname (x) (and (keywordp x) (symbol-name x)))
(defun fget (plist name) (loop for (k val) on plist by #'cddr when (and (keywordp k) (string-equal (kwname k) name)) return val))
(defun ulist (x) (mapcar (lambda (s) (string-upcase (sname s))) x))
(defun vkind (v)                        ; the declared value kinds STRING/INTEGER/SYMBOL and the ONE canonical
  (cond ((and (stringp v)               ; rendering of each. A control character inside a string would make the
              (every (lambda (c) (and (char<= #\Space c) (char/= c #\Rubout))) v)) (values "STRING" v))
        ((integerp v) (values "INTEGER" (princ-to-string v)))
        ((and v (symbolp v) (not (keywordp v)) (plusp (length (symbol-name v)))
              (every (lambda (c) (or (char<= #\A c #\Z) (char<= #\0 c #\9) (find c "_.+/-"))) (symbol-name v)))
         (values "SYMBOL" (symbol-name v)))))
(defun vrender (v) (nth-value 1 (vkind v)))  ; the canonical rendering alone; NIL exactly when the value is illegal
(defun depth-ok (form d)                ; walks cons cells; tolerates improper lists defensively
  (cond ((> d +max-depth+) nil)
        ((consp form)
         (let ((n 0) (cur form))
           (loop while (consp cur) do
             (incf n) (when (> n +max-list+) (return-from depth-ok nil))
             (unless (depth-ok (car cur) (1+ d)) (return-from depth-ok nil))
             (setf cur (cdr cur)))
           (depth-ok cur (1+ d))))
        (t t)))
(defun forms-of (path &key (missing-law "L1"))
  "Every top-level form of PATH. A missing or unreadable file is a typed, named violation — never a traceback."
  (unless (probe-file path)             ; Review-2 N-17
    (v! missing-law (format nil "MISSING-MODEL-FILE: ~a" (file-namestring path)) (file-namestring path))
    (return-from forms-of '()))
  (when (> (with-open-file (s path :element-type '(unsigned-byte 8)) (file-length s)) +max-file-bytes+)
    (v! "L1" "file exceeds size limit" path) (return-from forms-of '()))
  (with-standard-io-syntax
    (let ((*read-eval* nil) (*read-default-float-format* 'double-float) (out '()))
      (handler-case
          (with-open-file (s path :external-format :utf-8)
            (loop for f = (read s nil :eof) until (eq f :eof) do
              (unless (depth-ok f 0) (v! "L1" "form exceeds nesting/collection limit" path) (return))
              (push f out)))
        (error (e) (v! "L1" (format nil "unreadable model file (~a)" (type-of e)) path)))
      (nreverse out))))

;;; ─────────────────────────────────────────────────────────────────────── schema
(defun spairs (x) (mapcar (lambda (r) (cons (string-upcase (sname (first r))) (string-upcase (sname (second r))))) x))
(defun load-schema ()
  "Read MODEL-SCHEMA.sexp into the five generic tables the laws consult. No fact type is known to this code."
  (dolist (form (forms-of (merge-pathnames "MODEL-SCHEMA.sexp" *dir*)))
    (when (and (consp form) (string-equal (sname (car form)) "DEFINE-MODEL-SCHEMA"))
      (setf *schema-version* (sname (fget (cddr form) "VERSION")))
      (dolist (sub (cddr form))
        (when (consp sub)
          (let ((h (string-upcase (sname (car sub)))) (nm (string-upcase (sname (second sub)))) (pl (cddr sub)))
            (cond
              ((string= h "DEFINE-ENUM") (setf (gethash nm *enums*) (ulist (third sub))))
              ((string= h "DEFINE-ID-SPACE")
               (setf (gethash nm *spaces*)
                     (list (string-upcase (sname (fget pl "CHARSET"))) (let ((x (fget pl "PREFIX"))) (and x (sname x)))
                           (or (fget pl "MIN") 1) (or (fget pl "MAX") 1000))))
              ((string= h "DEFINE-CONDITIONAL")
               (push (list (string-upcase (sname (fget pl "TYPE"))) (string-upcase (sname (fget pl "WHEN-KEY")))
                           (string-upcase (sname (fget pl "WHEN-VALUE")))
                           (ulist (fget pl "REQUIRE")) (ulist (fget pl "FORBID")) nm)
                     *conds*))
              ((string= h "DEFINE-UNIQUE")
               (push (list (string-upcase (sname (fget pl "TYPE"))) (string-upcase (sname (fget pl "FIELD"))) nm)
                     *uniques*))
              ((string= h "DEFINE-FACT-TYPE")
               (setf (gethash nm *ftypes*)
                     (list (ulist (fget pl "REQUIRED"))
                           (mapcar (lambda (r) (cons (string-upcase (sname (car r))) (ulist (cdr r)))) (fget pl "REF"))
                           (spairs (fget pl "ENUM")) (ulist (fget pl "OPTIONAL")) (spairs (fget pl "TYPES"))
                           (string-upcase (sname (fget pl "ID-SPACE")))))))))))))
(defun ft (spec n) (nth n spec))         ; 0 required, 1 refs, 2 enums, 3 optional, 4 types, 5 id-space

(defun token-char-p (c) (or (char<= #\A c #\Z) (char<= #\a c #\z) (char<= #\0 c #\9) (find c "_.+/-")))
(defun id-space-ok (space id)
  "NIL when ID satisfies the declared id-space SPACE, otherwise the reason it does not."
  (let ((s (gethash space *spaces*)))
    (if (null s) (format nil "cites undeclared id-space ~a" space)
        (destructuring-bind (charset prefix minl maxl) s
          (cond ((not (<= minl (length id) maxl))
                 (format nil "is ~a characters, outside the ~a range ~a..~a" (length id) space minl maxl))
                ((and prefix (not (and (>= (length id) (length prefix)) (string= prefix (subseq id 0 (length prefix))))))
                 (format nil "does not start with the ~a prefix ~s" space prefix))
                ((and (string= charset "TOKEN") (notevery #'token-char-p id))
                 (format nil "contains a character outside the ~a token charset" space))
                ((and (string= charset "PATH") (some (lambda (c) (< (char-code c) 32)) id))
                 (format nil "contains a control character, which the ~a charset forbids" space)))))))

;;; ─────────────────────────────────────────────────────────────────────── facts
(defun add-fact (type id plist loc)
  (let* ((tn (string-upcase (sname type))) (idn (vrender id)) (key (cons tn (or idn (sname id))))
         (spec (gethash tn *ftypes*)))
    (unless idn (v! "L1" (format nil "~a: illegal id value kind" tn) loc) (setf idn (sname id)))
    (unless spec (v! "L1" (format nil "undeclared fact type ~a" tn) loc))
    (when spec
      (let ((r (id-space-ok (ft spec 5) idn)))
        (when r (v! "L1" (format nil "~a ~a: the id ~a" tn idn r) loc))))
    (when (nth-value 1 (gethash key *facts*)) (v! "L2" (format nil "duplicate seat ~a ~a" tn idn) loc))
    (let ((prev (gethash idn *id-owner*)))
      (when (and prev (not (string= prev tn))) (v! "L2" (format nil "id ~a declared under both ~a and ~a" idn prev tn) loc))
      (unless prev (setf (gethash idn *id-owner*) tn)))
    (setf (gethash key *facts*) plist) (push idn (gethash tn *by-type*))
    (let ((req (ft spec 0)) (enums (ft spec 2)) (opt (ft spec 3)) (types (ft spec 4)) (keys '()) (pairs '()))
      (loop for (k val) on plist by #'cddr do
        (let ((kn (kwname k)))
          (unless kn (v! "L1" (format nil "~a ~a: non-keyword plist key" tn idn) loc) (return))
          (when (member kn keys :test #'string-equal) (v! "L2" (format nil "duplicate key ~a in ~a ~a" kn tn idn) loc))
          (push kn keys)
          ;; CLOSED FIELD SET (Review-2 N-8): required ∪ optional is the whole permitted vocabulary.
          (when (and spec (not (member kn (append req opt) :test #'string-equal)))
            (v! "L1" (format nil "~a ~a: :~a is not a declared field (permitted: ~{:~a~^ ~})"
                             tn idn (string-downcase kn) (mapcar #'string-downcase (append req opt))) loc))
          (let ((vr (vrender val)) (want (cdr (assoc kn types :test #'string-equal))))
            (if (null vr)
                (v! "L1" (format nil "~a ~a: :~a has an illegal value kind (permitted: control-character-free string, integer, plain symbol)"
                                 tn idn (string-downcase kn)) loc)
                (progn
                  (push (format nil "~a=~a" (string-upcase kn) vr) pairs)
                  (when (and want (not (string= want (vkind val))))
                    (v! "L1" (format nil "~a ~a: :~a must be ~a, found ~a"
                                     tn idn (string-downcase kn) (string-downcase want)
                                     (string-downcase (vkind val))) loc))
                  (let ((ed (cdr (assoc kn enums :test #'string-equal))))
                    (when ed
                      (let ((dom (gethash ed *enums*)))
                        (cond ((null dom) (v! "L1" (format nil "~a ~a: :~a cites undeclared enum ~a"
                                                          tn idn (string-downcase kn) ed) loc))
                              ((not (member (string-upcase vr) dom :test #'string=))
                               (v! "L1" (format nil "~a ~a: :~a = ~a is outside enum ~a domain {~{~a~^ ~}}"
                                                tn idn (string-downcase kn) vr (string-downcase ed) dom) loc)))))))))))
      (dolist (rk req) (unless (fget plist rk) (v! "L1" (format nil "~a ~a missing required key :~a" tn idn (string-downcase rk)) loc)))
      ;; state-dependent field rules, read from the schema as data (Review-2 N-10)
      (dolist (c *conds*)
        (destructuring-bind (ctype ckey cval creq cforbid cname) c
          (when (and (string= ctype tn) (equal (and (fget plist ckey) (string-upcase (vrender (fget plist ckey)))) cval))
            (dolist (k creq) (unless (fget plist k)
                               (v! "L1" (format nil "~a ~a: ~a=~a requires :~a (rule ~a)"
                                                tn idn (string-downcase ckey) cval (string-downcase k) cname) loc)))
            (dolist (k cforbid) (when (fget plist k)
                                  (v! "L1" (format nil "~a ~a: ~a=~a forbids :~a (rule ~a)"
                                                   tn idn (string-downcase ckey) cval (string-downcase k) cname) loc))))))
      (push (list loc tn (format nil "~a|~a|~{~a~^|~}" tn idn (sort pairs #'string<))) *renders*))))

(defun root-forms () (forms-of (merge-pathnames "ROOT.sexp" *dir*) :missing-law "L7"))
(defun root-form ()
  (let ((roots (remove-if-not (lambda (f) (and (consp f) (string-equal (sname (car f)) "DEFINE-MODEL-ROOT")))
                              (root-forms))))
    (car roots)))
(defun root-composition ()              ; single source of the module universe = ROOT.sexp composition, in order
  (let ((root (root-form)))
    (when root (loop for entry in (fget (cddr root) "COMPOSITION")
                     collect (cons (fget entry "MODULE") (fget entry "SHA256"))))))
(defun load-facts ()
  (dolist (mod (mapcar #'car (root-composition)))
    (dolist (form (forms-of (merge-pathnames mod *dir*) :missing-law "L7"))
      (cond ((and (consp form) (string-equal (sname (car form)) "FACT"))
             (if (>= (length form) 3) (add-fact (second form) (third form) (cdddr form) mod)
                 (v! "L1" "malformed fact (needs type+id)" mod)))
            ((and (consp form) (member (sname (car form)) '("DEFINE-MODEL-SCHEMA" "DEFINE-MODEL-ROOT") :test #'string-equal)))
            (t (v! "L1" (format nil "unexpected top-level form in ~a" mod) mod))))))
(defun fact-exists (type id) (nth-value 1 (gethash (cons (string-upcase type) (sname id)) *facts*)))
(defun fact-plist (type id) (gethash (cons (string-upcase type) (sname id)) *facts*))
(defun each-fact (tn fn) (maphash (lambda (k pl) (when (string= (car k) tn) (funcall fn (cdr k) pl))) *facts*))

;;; ─────────────────────────────────────────────────────────────────────── laws
(defun law2-unique ()                   ; declared uniqueness laws, e.g. one owner seat per store
  (dolist (u *uniques*)
    (destructuring-bind (tn field uname) u
      (let ((seen (make-hash-table :test 'equal)))
        (each-fact tn (lambda (id plist)
          (let ((v (and (fget plist field) (vrender (fget plist field)))))
            (when v (let ((prev (gethash v seen)))
                      (if prev (v! "L2" (format nil "~a: ~a ~a and ~a both declare :~a = ~a"
                                                 uname (string-downcase tn) prev id (string-downcase field) v) tn)
                          (setf (gethash v seen) id)))))))))))
(defun law3-closed-refs ()
  (maphash (lambda (key plist)
             (let ((tn (car key)))
               (dolist (r (ft (gethash tn *ftypes*) 1))
                 (let ((val (fget plist (car r))))
                   (when val
                     (let ((vr (or (vrender val) (sname val))))
                       (unless (some (lambda (tgt) (fact-exists tgt vr)) (cdr r))
                         (v! "L3" (format nil "~a ~a: :~a = ~a resolves to no declared ~{~a~^ or ~}"
                                          tn (cdr key) (string-downcase (car r)) vr (mapcar #'string-downcase (cdr r))) tn))))))))
           *facts*))
(defun edge-relations ()                ; every declared FROM/TO relation over one node type is an acyclicity duty
  (let ((out '()))
    (maphash (lambda (tn spec)
               (let* ((refs (ft spec 1)) (f (assoc "FROM" refs :test #'string=)) (tt (assoc "TO" refs :test #'string=)))
                 (when (and f tt (= 1 (length (cdr f))) (equal (cdr f) (cdr tt)))
                   (push (cons tn (first (cdr f))) out))))
             *ftypes*)
    out))
(defun law4-acyclic ()
  (dolist (rel (edge-relations))
    (let ((adj (make-hash-table :test 'equal)) (color (make-hash-table :test 'equal)) (cyc nil))
      (each-fact (car rel) (lambda (id plist) (declare (ignore id))
        (push (sname (fget plist "TO")) (gethash (sname (fget plist "FROM")) adj))))
      (labels ((dfs (u) (setf (gethash u color) :grey)
                 (dolist (w (gethash u adj)) (case (gethash w color) (:grey (setf cyc u)) ((nil) (dfs w))))
                 (setf (gethash u color) :black)))
        (dolist (s (gethash (cdr rel) *by-type*)) (when (null (gethash s color)) (dfs s))))
      (when cyc (v! "L4" (format nil "cycle in the ~a graph over ~a at ~a"
                                 (string-downcase (car rel)) (string-downcase (cdr rel)) cyc) (car rel))))))
(defun classification (type id) (and (fact-exists type id) (sname (fget (fact-plist type id) "CLASSIFICATION"))))
(defun consumer-kind (c)                ; :public | :private | :unpermitted | :unknown — never a silent "not public"
  (cond ((fact-exists "SUBSYSTEM" c) (if (string= (classification "SUBSYSTEM" c) "PUBLIC") :public :private))
        ((fact-exists "COMPONENT" c)
         (let ((o (sname (fget (fact-plist "COMPONENT" c) "OWNER-SUBSYSTEM"))))
           (cond ((not (fact-exists "SUBSYSTEM" o)) :unknown)
                 ((string= (classification "SUBSYSTEM" o) "PUBLIC") :public)
                 (t :private))))
        ((fact-exists "TYPE" c)
         (if (fget (fact-plist "TYPE" c) "CONSUMER-ROLE")
             (if (string= (classification "TYPE" c) "PUBLIC") :public :private)
             :unpermitted))
        (t :unknown)))
(defun law5-isolation ()
  (each-fact "CONSUMES"
    (lambda (id plist) (declare (ignore id))
             (let* ((prov (sname (fget plist "PROVIDES"))) (cns (sname (fget plist "CONSUMER"))) (kind (consumer-kind cns)))
               (case kind
                 (:unknown (v! "L5" (format nil "consumer ~a of ~a is of unknown kind — isolation cannot be decided" cns prov)
                               "dependencies-and-boundaries.sexp"))
                 (:unpermitted (v! "L5" (format nil "type ~a is used as a consumer of ~a but declares no :consumer-role" cns prov)
                                   "dependencies-and-boundaries.sexp"))
                 (:public (when (string= (classification "TYPE" prov) "PRIVATE")
                            (v! "L5" (format nil "public/private leak: PUBLIC ~a consumes PRIVATE type ~a" cns prov)
                                "dependencies-and-boundaries.sexp"))))))))
(defun law6-reqmap ()                   ; requirement -> SEAT -> test -> WP; the seat is part of the chain now
  (let ((covered (make-hash-table :test 'equal)))
    (each-fact "REQ-MAP" (lambda (id plist)
      (let* ((s (sname (fget plist "SUBSYSTEM"))) (seat (and (fget plist "SEAT") (sname (fget plist "SEAT"))))
             (own (and (fact-exists "SUBSYSTEM" s) (sname (fget (fact-plist "SUBSYSTEM" s) "OWNER-SEAT")))))
        (setf (gethash s covered) t)
        (when (and own seat (not (string= own seat)))
          (v! "L6" (format nil "req-map ~a maps subsystem ~a to seat ~a but the subsystem's owner seat is ~a"
                           id s seat own) "requirements-tests-workpackets.sexp")))))
    (dolist (s (gethash "SUBSYSTEM" *by-type*))
      (unless (gethash s covered)
        (v! "L6" (format nil "subsystem ~a has no requirement->seat->test->WP mapping" s)
            "requirements-tests-workpackets.sexp")))))
(defun hexp (s n) (and (stringp s) (= (length s) n)
                       (every (lambda (c) (or (char<= #\0 c #\9) (char<= #\a c #\f))) s)))
(defun law7-hash-universe ()
  (let* ((all (root-forms)) (root (root-form)) (comp (root-composition)) (declared '()) (rows '()))
    (unless root
      (v! "L7" "ROOT.sexp declares no define-model-root form" "ROOT.sexp") (return-from law7-hash-universe))
    ;; Review-2 N-9 — ROOT.sexp gets the module discipline: exactly one root form, nothing else, no duplicate keys.
    (let ((n (count-if (lambda (f) (and (consp f) (string-equal (sname (car f)) "DEFINE-MODEL-ROOT"))) all)))
      (unless (and (= n 1) (= (length all) 1))
        (v! "L7" (format nil "ROOT.sexp must hold exactly one define-model-root form and nothing else; found ~a root form(s) among ~a top-level form(s)"
                         n (length all)) "ROOT.sexp")))
    (let ((seen '()))
      (loop for (k nil) on (cddr root) by #'cddr do
        (let ((kn (kwname k)))
          (cond ((null kn) (v! "L7" "ROOT.sexp has a non-keyword key in the root plist" "ROOT.sexp"))
                ((member kn seen :test #'string-equal)
                 (v! "L7" (format nil "ROOT.sexp declares :~a more than once" (string-downcase kn)) "ROOT.sexp"))
                (t (push kn seen))))))
    (let ((sv (fget (cddr root) "SCHEMA-VERSION")))
      (unless (and sv *schema-version* (string= (sname sv) *schema-version*))
        (v! "L7" (format nil "ROOT.sexp binds :schema-version ~s but MODEL-SCHEMA.sexp declares ~s"
                         (and sv (sname sv)) *schema-version*) "ROOT.sexp")))
    (let ((p (fget (cddr root) "PARENT-ARCHITECTURE-COMMIT")))
      (unless (and p (hexp (sname p) 40))
        (v! "L7" ":parent-architecture-commit is not a 40-character lower-case hexadecimal commit id" "ROOT.sexp")))
    (dolist (entry comp)
      (let* ((name (car entry)) (pin (cdr entry)) (path (merge-pathnames name *dir*)))
        (push name declared)
        (unless (and (stringp pin) (hexp pin 64))
          (v! "L7" (format nil "module ~a has no well-formed :sha256 pin" name) name))
        (if (probe-file path)
            (let ((actual (aml-hash:sha256-hex-of-file path)))
              (push (format nil "~a:~a" name actual) rows)
              (unless (equal actual pin) (v! "L7" (format nil "module ~a SHA drift (~a != pinned)" name (subseq actual 0 12)) name)))
            (progn (push (format nil "~a:MISSING" name) rows)
                   (v! "L7" (format nil "declared module ~a missing on disk" name) name)))))
    (dolist (f (directory (merge-pathnames "*.sexp" *dir*)))
      (let ((bn (file-namestring f)))
        (unless (or (string= bn "ROOT.sexp") (member bn declared :test #'string=))
          (v! "L7" (format nil "undeclared extra module on disk: ~a" bn) bn))))
    (let ((recomputed (aml-hash:sha256-hex-of-string (format nil "~{~a~^~%~}" (nreverse rows))))
          (stated (fget (cddr root) "CANONICAL-MODEL-ROOT-DIGEST"))
          (cnt (fget (cddr root) "MODULE-COUNT")))
      (unless (and (integerp cnt) (= cnt (length comp)))
        (v! "L7" (format nil "declared :module-count ~a != ~a pinned modules" cnt (length comp)) "ROOT.sexp"))
      (unless (equal recomputed (sname stated))
        (v! "L7" (format nil "canonical-model-root-digest mismatch: recomputed ~a != declared ~a"
                         (subseq recomputed 0 16) (subseq (sname stated) 0 (min 16 (length (sname stated))))) "ROOT.sexp")))))

;;; ─────────────────────────────────────────────────────────────────────── toolchain + commitment + main
(defun digest-tool ()
  "The DIGEST_PROVIDER tool fact — already schema-validated, so the provider is authorized from the model itself."
  (let ((found nil))
    (each-fact "TOOL" (lambda (id pl) (declare (ignore id))
      (when (string-equal (sname (fget pl "ROLE")) "DIGEST_PROVIDER") (setf found pl))))
    (unless found
      (format t "~&TOOLCHAIN-FAILURE: no tool fact declares :role DIGEST_PROVIDER~%")
      (format t "SHA-256 PROVIDER: UNAVAILABLE — no model hash was computed and no verdict is issued.~%")
      (finish-output) (sb-ext:exit :code 4))
    found))
(defun commitment-lines ()
  (let ((mods (make-hash-table :test 'equal)) (fams (make-hash-table :test 'equal)) (all '()) (out '()))
    (dolist (r *renders*)
      (push (third r) all) (push (third r) (gethash (first r) mods)) (push (third r) (gethash (second r) fams)))
    (flet ((dig (l) (aml-hash:sha256-hex-of-string (format nil "~{~a~^~%~}" (sort (copy-list l) #'string<)))))
      (push (format nil "COMMITMENT total-facts ~a" (length all)) out)
      (push (format nil "COMMITMENT total-digest ~a" (dig all)) out)
      (dolist (m (sort (loop for k being the hash-keys of mods collect k) #'string<))
        (push (format nil "COMMITMENT module ~a ~a ~a" m (length (gethash m mods)) (dig (gethash m mods))) out))
      (dolist (f (sort (loop for k being the hash-keys of fams collect k) #'string<))
        (push (format nil "COMMITMENT family ~a ~a ~a" (string-downcase f) (length (gethash f fams)) (dig (gethash f fams))) out)))
    (nreverse out)))
(defun main ()
  (setf *dir* (merge-pathnames "../" *load-pathname*))
  (let ((rootarg (second sb-ext:*posix-argv*))) (when rootarg (setf *dir* (make-pathname :directory (pathname-directory (truename rootarg))))))
  (load-schema) (load-facts)
  (let ((d (digest-tool)))
    (aml-hash:ensure-provider (sname (fget d "PATH")) (sname (fget d "SHA256")) (sname (fget d "SEMANTIC-VERSION"))))
  (law2-unique) (law3-closed-refs) (law4-acyclic) (law5-isolation) (law6-reqmap) (law7-hash-universe)
  (setf *viol* (nreverse *viol*))
  (let ((lines (commitment-lines))
        (out (second (member "--commitment" sb-ext:*posix-argv* :test #'string=))))
    (with-open-file (s (if out (pathname out) (merge-pathnames "KERNEL-COMMITMENT.txt" *dir*))
                       :direction :output :if-exists :supersede :if-does-not-exist :create :external-format :utf-8)
      (dolist (l lines) (write-line l s)))
    (dolist (l lines) (format t "~a~%" l)))
  (format t "~&; ARCHITECTURE-LAW KERNEL — facts=~a fact-types=~a enums=~a schema=~a hash-provider=~a~%"
          (hash-table-count *facts*) (hash-table-count *ftypes*) (hash-table-count *enums*)
          *schema-version* (aml-hash:provider-id))
  (if *viol*
      (progn (dolist (v *viol*) (format t "VIOLATION ~a: ~a  [~a]~%" (first v) (second v) (third v)))
             (format t "ARCHITECTURE MODEL LAWS: FAIL~%; (structural model-law check only — NOT semantic/legal/security/behavioral/operational/qualification proof)~%")
             (sb-ext:exit :code 3))
      (progn (format t "ARCHITECTURE MODEL LAWS: PASS~%; (structural model-law check only — NOT semantic/legal/security/behavioral/operational/qualification proof)~%")
             (sb-ext:exit :code 0))))
(main)
