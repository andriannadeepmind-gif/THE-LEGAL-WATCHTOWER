;;;; tests/mcp-live-resolver-test.lisp
;;;; TIER 2-H: the MCP get_article tool, bound to LIVE consolidation, must return
;;;; the authentic provision text + citation + ELI + a freshly built PCL-1 proof
;;;; that the server's own verify_provision confirms. The trust loop closes
;;;; inside the server: retrieve → verify. A tampered text fails; an unknown
;;;; article resolves to NIL. Pure, offline, deterministic.

(in-package :orchestrator.cli)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(defun verify-json (text proof)
  (funcall (find-symbol "VERIFY-PROOF-JSON" :orchestrator.proof-carrying) text proof))

;; Seed the live-consolidation cache with a deterministic mini-corpus (same shape
;; build-consolidated-for produces), exercising the real proof-building path.
(let* ((pc :orchestrator.proof-carrying)
       (leaf (find-symbol "HASH-LEAF-STRING" pc))
       (root (find-symbol "MERKLE-TREE-HASH" pc))
       (texts (list "Καμία ποινή χωρίς νόμο." "Αναστολή υπό επιτήρηση." "Ανθρωποκτονία με πρόθεση."))
       (ids   (list "1" "100Α" "299"))               ; lettered id stays distinct from base
       (leaves (mapcar (lambda (tx) (funcall leaf tx)) texts)))
  (setf (gethash "demo" *mcp-corpus-cache*)
        (list :ids ids :texts texts :leaves leaves :root (funcall root leaves)
              :eli "https://stavropouloslaw.com/eli/gr/demo" :abbrev "ΠΚ"))

  (format t "~%== get_article resolves from live consolidation ==~%")
  (let ((r (%mcp-resolve-article "demo" "299")))
    (check "returns the authentic text" (string= "Ανθρωποκτονία με πρόθεση." (getf r :text)))
    (check "returns the canonical citation" (string= "Άρθρο 299 ΠΚ" (getf r :cite)))
    (check "returns the ELI to the article" (search "/art/299" (getf r :eli)))
    (check "carries a PCL-1 proof JSON" (and (getf r :proof) (search "merkle_root" (getf r :proof))))

    (format t "~%== the trust loop closes: retrieve → verify_provision ==~%")
    (multiple-value-bind (ok reason) (verify-json (getf r :text) (getf r :proof))
      (check "the returned proof verifies against the returned text" ok)
      (check "reason :ok" (eq :ok reason)))
    (check "a tampered text is rejected by the returned proof"
           (not (verify-json "ΑΛΛΟΙΩΜΕΝΟ" (getf r :proof)))))

  (format t "~%== lettered vs base id, and unknown ==~%")
  (let ((r100a (%mcp-resolve-article "demo" "100Α")))
    (check "lettered article 100Α resolves to its OWN text"
           (string= "Αναστολή υπό επιτήρηση." (getf r100a :text)))
    (check "100Α proof verifies" (verify-json (getf r100a :text) (getf r100a :proof))))
  (check "an unknown article resolves to NIL" (null (%mcp-resolve-article "demo" "9999")))
  (check "an unknown corpus resolves to NIL"
         (progn (setf (gethash "nope" *mcp-corpus-cache*) :error)
                (null (%mcp-resolve-article "nope" "1")))))

(format t "~%== audit_corpus: the AI-reviewer report ==~%")
(let ((r (%mcp-audit-corpus "demo")))
  (check "reports the article count" (eql 3 (getf r :count)))
  (check "reports the numbering range" (and (eql 1 (getf r :min)) (eql 299 (getf r :max))))
  (check "counts lettered families" (eql 1 (getf r :lettered)))      ; 100Α
  (check "surfaces numbering gaps for the AI to judge"
         (let ((g (getf r :gaps))) (and (member "1→100" g :test #'string=)
                                        (member "100→299" g :test #'string=))))
  (check "an unknown corpus yields no audit" (null (%mcp-audit-corpus "nope"))))

(format t "~%========================================~%")
(format t "MCP live-resolver tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
