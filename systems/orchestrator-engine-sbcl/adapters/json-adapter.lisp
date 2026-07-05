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
         ;; Extract label from "Άρθρο N - Title" format (e.g. "5", "5Α", "9Α")
         (title-parts (cl-ppcre:split "\\s+" title))
         (label (when (>= (length title-parts) 2) (second title-parts)))
         ;; Numeric base: parse-integer stops at the first non-digit (e.g. "5Α" → 5)
         (base-number (when label (parse-integer label :junk-allowed t)))
         ;; For articles with a letter suffix (e.g. "5Α"), encode as base*1000 + letter-index
         ;; so that "5" → 5 and "5Α" → 5001, avoiding integer collision while staying positive.
         ;; letter-index: 0 for pure-numeric, 1 for 'Α', 2 for 'Β', etc.
         (letter-suffix (when (and label (> (length label) (length (format nil "~D" base-number))))
                          (subseq label (length (format nil "~D" base-number)))))
         (letter-index (if letter-suffix
                           (let ((ch (char label (length (format nil "~D" base-number)))))
                             ;; Position of the Greek capital letter relative to 'Α' (U+0391)
                             (1+ (- (char-code ch) (char-code #\U+0391))))
                           0))
         (number (when base-number
                   (if (zerop letter-index)
                       base-number
                       (+ (* base-number 1000) letter-index)))))

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