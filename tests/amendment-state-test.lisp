;;;; tests/amendment-state-test.lisp
;;;; The discovery loop's production glue: it MERGES newly-found amending laws into
;;;; AMENDMENT_LAWS_JSON (idempotent — a re-seen ΦΕΚ is never duplicated) and PERSISTS
;;;; the last-seen ΦΕΚ number so a cron run only ever processes genuinely-new gazettes.
;;;; These pure helpers carry the autonomy state; the network edge is thin.

(in-package :orchestrator.cli)

(require :sb-posix)
(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun law (id) (list (cons "id" id) (cons "date" "") (cons "fek" id)
                      (cons "text" (format nil "Κείμενο του ~A." id))))
(defun ids (laws) (mapcar (lambda (l) (cdr (assoc "id" l :test #'string=))) laws))

(format t "~%== merge: idempotent dedup by id ==~%")
(check "new laws appended after existing, in order"
       (equal '("A" "B" "C" "D")
              (ids (%merge-laws (list (law "A") (law "B")) (list (law "C") (law "D"))))))
(check "a re-discovered ΦΕΚ is NOT duplicated"
       (equal '("A" "B" "C")
              (ids (%merge-laws (list (law "A") (law "B")) (list (law "B") (law "C"))))))
(check "merging the same set twice is a no-op (idempotent)"
       (let ((once (%merge-laws (list (law "A")) (list (law "B")))))
         (equal (ids once) (ids (%merge-laws once (list (law "A") (law "B")))))))
(check "empty new → existing unchanged" (equal '("A") (ids (%merge-laws (list (law "A")) '()))))

(format t "~%== AMENDMENT_LAWS_JSON round-trip ==~%")
(let ((path (format nil "/tmp/amend-laws-~D.json" (get-universal-time))))
  (with-open-file (o path :direction :output :if-exists :supersede :external-format :utf-8)
    (write-string (%laws->json (list (law "ΦΕΚ Α' 246/2025") (law "ΦΕΚ Α' 250/2025"))) o))
  (let ((back (%read-laws-json path)))
    (check "two laws read back" (= 2 (length back)))
    (check "ids survive the round-trip"
           (equal '("ΦΕΚ Α' 246/2025" "ΦΕΚ Α' 250/2025") (ids back)))
    (check "Greek text survives" (search "Κείμενο" (cdr (assoc "text" (first back) :test #'string=)))))
  (check "absent file → NIL" (null (%read-laws-json "/tmp/does-not-exist-xyz.json")))
  (ignore-errors (delete-file path)))

(format t "~%== last-seen cursor persistence ==~%")
(let ((statef (format nil "/tmp/fek-last-~D.txt" (get-universal-time))))
  (sb-posix:setenv "FEK_STATE_FILE" statef 1)
  (check "fresh state → NIL (first run starts at 1)" (null (%read-last-seen)))
  (%write-last-seen 245)
  (check "after write, reads back 245" (eql 245 (%read-last-seen)))
  (check "advancing the cursor persists" (progn (%write-last-seen 251) (eql 251 (%read-last-seen))))
  (ignore-errors (delete-file statef))
  (sb-posix:unsetenv "FEK_STATE_FILE"))

(format t "~%========================================~%")
(format t "Amendment state (autonomy glue) tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
