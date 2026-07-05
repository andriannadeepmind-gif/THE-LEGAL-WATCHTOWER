;;;; tests/article-identity-test.lisp
;;;; THE lettered-article guarantee, locked: a lettered article (100Α) must NEVER
;;;; collapse onto its base number (100) in ANY identifier the system builds —
;;;; padded file/eId, URI/ELI path, or the FRBR Work it threads everywhere.
;;;; All identity now flows from the single source of truth in orchestrator.model
;;;; (pad-article-id / article-uri-id); this test fails if any of them diverge.

(in-package :orchestrator.model)

(defvar *pass* 0) (defvar *fail* 0)
(defmacro check (name form)
  `(handler-case
       (if ,form (progn (incf *pass*) (format t "  ok   ~A~%" ,name))
           (progn (incf *fail*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *fail*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== pad-article-id: padded id, suffix preserved ==~%")
(check "plain number zero-padded to 3"        (string= "070" (pad-article-id 70)))
(check "bare suffix preserved"                (string= "070Α" (pad-article-id 70 "Α")))
(check "full label accepted as suffix source" (string= "070Α" (pad-article-id 70 "70Α")))
(check "three-digit number unchanged"         (string= "100" (pad-article-id 100)))
(check "nil suffix == no suffix"              (string= "100" (pad-article-id 100 nil)))
(check "100 and 100Α PAD to DISTINCT ids"     (not (string= (pad-article-id 100)
                                                            (pad-article-id 100 "Α"))))

(format t "~%== article-uri-id: unpadded URI-path id, suffix preserved ==~%")
(check "plain number, no padding"             (string= "70" (article-uri-id 70)))
(check "suffix preserved, no padding"         (string= "70Α" (article-uri-id 70 "Α")))
(check "full label accepted"                  (string= "100Α" (article-uri-id 100 "100Α")))
(check "100 and 100Α give DISTINCT uri ids"   (not (string= (article-uri-id 100)
                                                            (article-uri-id 100 "Α"))))

(format t "~%== article-file-id (on real article objects) ==~%")
(let ((base (make-instance 'article))
      (lettered (make-instance 'article)))
  (setf (article-number base) 100 (article-label base) "100")
  (setf (article-number lettered) 100 (article-label lettered) "100Α")
  (check "base 100 file-id"          (string= "100" (article-file-id base)))
  (check "lettered 100Α file-id"     (string= "100Α" (article-file-id lettered)))
  (check "file-ids are DISTINCT"     (not (string= (article-file-id base)
                                                   (article-file-id lettered)))))

(format t "~%== build-eli-article-uri: suffix-safe (was numeric-only) ==~%")
(let ((prefix "https://stavropouloslaw.com/eli/gr/const/1975"))
  (check "base article URI"
         (string= (concatenate 'string prefix "/art/100")
                  (build-eli-article-uri prefix 100)))
  (check "lettered article URI keeps the suffix"
         (string= (concatenate 'string prefix "/art/100Α")
                  (build-eli-article-uri prefix 100 "Α")))
  (check "full label also accepted"
         (string= (concatenate 'string prefix "/art/100Α")
                  (build-eli-article-uri prefix 100 "100Α")))
  (check "base and lettered ELI URIs are DISTINCT"
         (not (string= (build-eli-article-uri prefix 100)
                       (build-eli-article-uri prefix 100 "Α")))))

(format t "~%== FRBR Work stores the suffix (threads it everywhere downstream) ==~%")
;; NOTE: do not pass :article-root-uri — let the Work derive it from the prefix
;; (in production it comes suffix-safe from the Article Root), so the URI actually
;; exercises the suffix threading.
(let ((base (make-frbr-work :article-number 100 :article-suffix ""
                            :eli-prefix "https://stavropouloslaw.com/eli/gr/const/1975"
                            :document-type "const" :law-year "1975"
                            :issued-date "1975-06-11"))
      (lettered (make-frbr-work :article-number 100 :article-suffix "Α"
                                :eli-prefix "https://stavropouloslaw.com/eli/gr/const/1975"
                                :document-type "const" :law-year "1975"
                                :issued-date "1975-06-11")))
  (check "work stores the letter suffix"
         (string= "Α" (article-letter-suffix lettered)))
  (check "base work has empty suffix"
         (string= "" (article-letter-suffix base)))
  (check "base and lettered Work URIs are DISTINCT"
         (not (string= (resource-uri base) (resource-uri lettered))))
  (check "base and lettered Work eIds are DISTINCT"
         (not (string= (eli-identifier base) (eli-identifier lettered))))
  (check "the lettered Work URI actually contains the suffix"
         (search "100Α" (resource-uri lettered)))
  ;; the wikidata owl:sameAs refs the generators emit are built from exactly this
  (check "wikidata-style id from the work is suffix-safe"
         (not (string= (article-uri-id (article-number base)
                                       (article-letter-suffix base))
                       (article-uri-id (article-number lettered)
                                       (article-letter-suffix lettered))))))

(format t "~%========================================~%")
(format t "Article identity tests: ~D passed, ~D failed~%" *pass* *fail*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *fail*) 0 1))
