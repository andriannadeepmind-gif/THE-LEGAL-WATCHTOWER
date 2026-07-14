;;;; JSON Adapter - OMEGA GRADE
;;;; Creates Normalized Input (IIR) - NOT direct Article instances

(in-package :orchestrator.engine.sbcl)

(defun json-adapter (json-path &key (encoding :utf-8))
  "Load JSON and create normalized-article-input (IIR) instances"
  (handler-case
      (progn
        (log:info () "JSON Adapter: loading ~A" json-path)
        (unless (probe-file json-path)
          (error 'orchestrator.spec:config-error
                 :message (format nil "JSON file not found: ~A" json-path)
                 :config-key :json-path))
        (let* ((json-string (uiop:read-file-string json-path :external-format encoding))
               (json-data (yason:parse json-string)))
          (mapcar (lambda (item) (json-item->normalized-input item json-path))
                  json-data)))
    (error (e)
      (error 'orchestrator.spec:stage-error
             :message (format nil "JSON adapter failed: ~A" e)
             :stage-name :json-adapter))))

(defun json-item->normalized-input (json-item source-path)
  "Convert JSON item to normalized-article-input (IIR) - NOT Article instance

   This is the critical IIR transformation:
     JSON → Normalized Input → FRBR Stack

   Parser changes NEVER affect FRBR generation."
  (let* ((title (gethash "title" json-item))
         (content-list (gethash "content" json-item))
         (date (gethash "date" json-item))
         ;; P1b [0052]#Α1: ΑΥΣΤΗΡΗ γραμματική «Άρθρο <ψηφία><επίθημα;> [- τίτλος]»
         ;; — ίδια συμπεριφορά με το CLI (%parse-article-title): το επίθημα
         ;; κολλάει ΑΜΕΣΑ στα ψηφία. Το παλιό split-σε-κενά ΠΕΤΟΥΣΕ σιωπηλά
         ;; επίθημα χωρισμένο με κενό («Άρθρο 5 Α» ⇒ ταυτότητα 5!) ενώ το CLI
         ;; το δεχόταν — ο ίδιος τίτλος έπαιρνε ΔΙΑΦΟΡΕΤΙΚΗ ταυτότητα ανά
         ;; μονοπάτι. Τίτλος που ξεκινά «Άρθρο <ψηφία>» αλλά δεν είναι
         ;; κανονικός ⇒ ΣΦΑΛΜΑ (ποτέ σιωπηλή επανερμηνεία ταυτότητας).
         (label (multiple-value-bind (m g)
                    (cl-ppcre:scan-to-strings
                     "^\\s*[Άά]ρθρο\\s+(\\d+[Α-ΩA-Zα-ω]*)\\s*(?:[-–—].*)?$" title)
                  (cond
                    (m (aref g 0))
                    ((cl-ppcre:scan "^\\s*[Άά]ρθρο\\s+\\d+" (or title ""))
                     (error 'orchestrator.spec:stage-error
                            :stage-name :json-adapter
                            :message (format nil "Μη-κανονικός τίτλος άρθρου ~S — αναγνωρίσιμος αριθμός με άκυρη μορφή (π.χ. κενό πριν το επίθημα)" title)))
                    (t nil))))
         ;; Numeric base: parse-integer stops at the first non-digit (e.g. "5Α" → 5)
         (base-number (when label (parse-integer label :junk-allowed t)))
         ;; For articles with a letter suffix (e.g. "5Α"), encode as base*1000 + ordinal
         ;; so that "5" → 5 and "5Α" → 5001 — internal disambiguation only (the
         ;; synthetic never escapes into identities/artifacts).
         ;; P1b [0052]: ordinal ΑΠΟ ΤΗ ΜΙΑ ΕΔΡΑ article-suffix-ordinal — το παλιό
         ;; «πρώτο γράμμα − Α» κατέρρεε τα δίγραφα (ΙΑ↔Ι ίδιο index, ΣΤ ως 19)
         ;; και δεχόταν σιωπηλά λατινικά ομόγλυφα/πεζά ως αρνητικά/λάθος indexes.
         ;; Άκυρο επίθημα ⇒ ΣΦΑΛΜΑ εδώ, στο κατώφλι της εισόδου.
         (letter-suffix (when (and label base-number
                                   (> (length label) (length (format nil "~D" base-number))))
                          (subseq label (length (format nil "~D" base-number)))))
         (letter-index (if letter-suffix
                           (orchestrator.model:article-suffix-ordinal letter-suffix)
                           0))
         ;; [Δ³-κριτής A] το συνθετικό σχήμα από τη ΜΙΑ έδρα — όχι inline
         (number (when base-number
                   (if (zerop letter-index)
                       base-number
                       (orchestrator.model:synthetic-article-number
                        base-number letter-index)))))

    ;; Validate extracted number
    (unless (and (integerp number) (plusp number))
      (error 'orchestrator.spec:stage-error
             :stage-name :json-adapter
             :message (format nil "Failed to extract article number from title: ~A" title)))

    ;; Convert content list to string; newlines preserved as paragraph separators
    (let ((content-str (if (listp content-list)
                           (format nil "~{~A~^~%~}" content-list)
                           (or content-list ""))))

      ;; Create NORMALIZED INPUT (IIR)
      (orchestrator.model:make-normalized-article-input
        :article-number number
        :article-label label
        :article-title title
        :article-content content-str
        :source-type :json
        :source-path source-path
        :extraction-confidence 1.0
        :source-metadata (list :date date :source "syntagma_clean.json")))))