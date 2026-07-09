;;;; tests/turtle-nil-omit-test.lisp
;;;; ============================================================================
;;;; FF3 [0030] REGRESSION: honest-ignorance στη γένεση Turtle
;;;; ============================================================================
;;;; Απόφαση δημιουργού [0030] (εύρημα Codex PR#2 #3): nil τίτλος/περιεχόμενο σε
;;;; άρθρο σημαίνει ΝΟΜΙΜΗ ΑΠΟΥΣΙΑ γνωστής τιμής. Το render-turtle ΔΕΝ εκπέμπει
;;;; το αντίστοιχο triple (eli:title / eli:description) και ΠΟΤΕ δεν κατασκευάζει
;;;; ψεύτικο "NIL" / """NIL""" RDF literal. Το escape-turtle-string διατηρεί
;;;; nil→nil· η ευθύνη παράλειψης είναι στο call site (conditional emission).
;;;;
;;;; Τρέχει κάτω από docker/run-standalone-test.lisp (self-exit 0/1) — gated.

(in-package :orchestrator.engine.sbcl)

(let ((pass 0) (fail 0))
  (flet ((chk (name ok)
           (if ok
               (progn (incf pass) (format t "  ok   ~A~%" name))
               (progn (incf fail) (format t "  FAIL ~A~%" name))))
         (mk-article (title content)
           ;; Ξεκινά έγκυρο, μετά επιβάλλει nil ΑΚΡΙΒΩΣ στα title/content (χωρίς να
           ;; αγγίζει το model invariant :type string — εντολή δημιουργού [0030]).
           (let ((a (orchestrator.model:make-article :number 7 :title "x" :content "y")))
             (setf (slot-value a 'orchestrator.model::eli-uri) "https://e/art/7")
             (setf (slot-value a 'orchestrator.model::title) title)
             (setf (slot-value a 'orchestrator.model::content) content)
             a))
         (mk-corpus ()
           (orchestrator.model:make-corpus
            :name "x" :short-name "x" :eli-prefix "https://e/"
            :publication-date "2026-01-01" :language "el"
            :webid "https://stavropouloslaw.com/#me")))
    (let* ((cor (mk-corpus))
           (nil-ttl (render-turtle (mk-article nil nil) cor))
           (full-ttl (render-turtle (mk-article "Τίτλος" "Περιεχόμενο") cor)))
      (format t "~&── FF3 regression: honest-ignorance στη γένεση Turtle ──~%")
      ;; honest-ignorance: nil ⇒ ΚΑΝΕΝΑ ψεύτικο literal
      (chk "nil title/content ⇒ ΚΑΝΕΝΑ \"NIL\" literal"
           (not (search "\"NIL\"" nil-ttl)))
      (chk "nil title/content ⇒ ΚΑΝΕΝΑ \"\"\"NIL\"\"\" literal"
           (not (search "\"\"\"NIL\"\"\"" nil-ttl)))
      ;; απουσία ⇒ παράλειψη triple (όχι κενή/ψεύτικη τιμή)
      (chk "nil title ⇒ eli:title ΠΑΡΑΛΕΙΠΕΤΑΙ"
           (not (search "eli:title" nil-ttl)))
      (chk "nil content ⇒ eli:description ΠΑΡΑΛΕΙΠΕΤΑΙ"
           (not (search "eli:description" nil-ttl)))
      ;; παρών τίτλος/περιεχόμενο ⇒ κανονικά triples (δεν καταπίνει έγκυρα δεδομένα)
      (chk "παρών τίτλος ⇒ eli:title εκπέμπεται"
           (and (search "eli:title" full-ttl) t))
      (chk "παρόν περιεχόμενο ⇒ eli:description εκπέμπεται"
           (and (search "eli:description" full-ttl) t))
      (chk "παρών τίτλος ⇒ η ΠΡΑΓΜΑΤΙΚΗ τιμή, όχι NIL"
           (and (search "Τίτλος" full-ttl) t))))
  (format t "~%turtle-nil-omit: ~D pass, ~D fail~%" pass fail)
  (sb-ext:exit :code (if (zerop fail) 0 1)))
