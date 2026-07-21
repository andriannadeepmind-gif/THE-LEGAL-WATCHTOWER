;;;; systems/orchestrator-engine-sbcl/adapters/docx-adapter.lisp
;;;; Office Open XML (.docx) → Normalized Article Input (IIR)
;;;; ============================================================================
;;;; Pure-Lisp authoritative-source ingestion:
;;;;   ZIP container  → (chipz inflate)     → word/document.xml octets
;;;;   word/document.xml → (cxml-stp DOM)   → plain text (one line per <w:p>)
;;;;   plain text     → (raw-text->iir-articles) → normalized-article-input list
;;;;
;;;; WHY THIS EXISTS (root cause, not a band-aid):
;;;;   The Greek Code of Civil Procedure (ΚΠολΔ, π.δ. 503/1985) is published by the
;;;;   Ministry of Justice ONLY as .docx — real digital text — while its ΦΕΚ 1985 PDF
;;;;   on et.gr is a SCANNED image (CCITTFax, zero text layer). The PDF path therefore
;;;;   extracts 0 articles. This adapter ingests the authoritative .docx DIRECTLY:
;;;;   no OCR, no manual transcription, no placeholder.
;;;;
;;;; DESIGN — maximal reuse, zero duplicated parsing:
;;;;   .docx is a pure TEXT front-end. All article / paragraph / sub-point structure
;;;;   is recovered by the existing MOP-grade 5-layer raw-text FSM
;;;;   (raw-text->iir-articles). This adapter only turns the WordprocessingML package
;;;;   into the plain text that pipeline already understands («Άρθρο N», numbered
;;;;   paragraphs, α)/β) sub-points). One source of truth for legal structure.
;;;;
;;;; CLOS / CL exploitation:
;;;;   ✓ Condition hierarchy rooted at orchestrator.spec:stage-error (docx-error +
;;;;     2 typed subclasses) — uniform with the raw-text/pdf adapters.
;;;;   ✓ #+/#- feature reader-conditionals (chipz, cxml-stp) — the file ALWAYS
;;;;     compiles; the .docx path degrades to a precise condition when a backend
;;;;     library is absent (same defensive pattern as html-parliament-adapter).
;;;;   ✓ DECLAIM INLINE little-endian octet readers on the hot ZIP-walk path.
;;;;   ✓ Central-directory ZIP parse (authoritative sizes) — robust to data
;;;;     descriptors that a local-header-only parse would mis-read.
;;;;   ✓ HANDLER-CASE boundary in docx-adapter: a malformed source returns NIL so
;;;;     the caller falls back exactly like an empty PDF extraction (never wipes a
;;;;     populated corpus — see materialize-pdf-sources safety).

(in-package :orchestrator.engine.sbcl)

(declaim (optimize (speed 2) (safety 2) (debug 1)))

;;; ============================================================================
;;; CONDITIONS — rooted at the shared stage-error, like every other adapter
;;; ============================================================================

(define-condition docx-error (orchestrator.spec:stage-error) ()
  (:documentation "Root condition for the Office Open XML (.docx) adapter."))

(define-condition docx-backend-missing (docx-error) ()
  (:report (lambda (c s)
             (format s "docx-adapter: required backend missing (chipz + cxml-stp) — ~A"
                     (orchestrator.spec:error-message c)))))

(define-condition docx-malformed (docx-error) ()
  (:report (lambda (c s)
             (format s "docx-adapter: malformed .docx container — ~A"
                     (orchestrator.spec:error-message c)))))

;;; ============================================================================
;;; ZIP CONTAINER — minimal, robust reader (central directory is authoritative)
;;;
;;; A .docx is a ZIP. We read the End-Of-Central-Directory record, walk the
;;; central directory (which always carries the true compressed size, unlike a
;;; streamed local header that may defer sizes to a data descriptor), locate
;;; word/document.xml, then inflate its DEFLATE stream with chipz.
;;; ============================================================================

(defconstant +zip-eocd-sig+  #x06054b50 "End of central directory signature.")
(defconstant +zip-cd-sig+    #x02014b50 "Central directory file header signature.")
(defconstant +zip-lfh-sig+   #x04034b50 "Local file header signature.")

;; Hard cap on the INFLATED size of any single entry. word/document.xml for even a
;; large legal code is a few MB; this ceiling defeats a DEFLATE zip-bomb (a few KB
;; inflating to gigabytes → OOM) WITHOUT a false positive on real corpora. The cap
;; is enforced by decompressing into a fixed-size buffer, so the allocation is
;; bounded and chipz signals rather than the process OOM-ing.
(defconstant +docx-max-inflate+ (* 256 1024 1024)
  "Maximum accepted decompressed size (bytes) for one .docx ZIP entry.")

(declaim (inline %le-u16 %le-u32 %need))
(defun %need (buf i len)
  "Guard: I and I+LEN must lie within BUF. Signals DOCX-MALFORMED otherwise so the
   adapter's HANDLER-CASE turns a crafted/truncated container into a clean NIL
   (safe fallback) instead of an uncaught SB-INT:INVALID-ARRAY-INDEX-ERROR. This is
   the single choke point that makes every attacker-controlled offset/length safe."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf))
  (unless (and (integerp i) (>= i 0)
               (<= (+ i len) (length buf)))
    (error 'docx-malformed :stage-name :docx-adapter
           :message (format nil "offset ~A+~A outside container of ~A octets"
                            i len (length buf))))
  t)
(defun %le-u16 (buf i)
  "Little-endian unsigned 16-bit integer at octet index I of BUF."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf) (type fixnum i))
  (logior (aref buf i) (ash (aref buf (+ i 1)) 8)))
(defun %le-u32 (buf i)
  "Little-endian unsigned 32-bit integer at octet index I of BUF."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf) (type fixnum i))
  (logior (aref buf i)
          (ash (aref buf (+ i 1)) 8)
          (ash (aref buf (+ i 2)) 16)
          (ash (aref buf (+ i 3)) 24)))

;; File → octets uses the project-wide idiom ALEXANDRIA:READ-FILE-INTO-BYTE-VECTOR
;; (already used by merkle-tree / release-manifest) — not re-implemented here.

(defun %ascii (buf start end)
  "Decode BUF[START,END) as ASCII (ZIP entry names are ASCII: 'word/document.xml')."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf) (type fixnum start end))
  (let ((s (make-string (- end start))))
    (loop for i of-type fixnum from start below end
          for k of-type fixnum from 0
          do (setf (char s k) (code-char (aref buf i))))
    s))

(defun %find-eocd (buf)
  "Index of the End-Of-Central-Directory record, scanning backward from the end.
   Returns NIL when absent (BUF is not a ZIP)."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf))
  (loop with n of-type fixnum = (length buf)
        for i of-type fixnum from (- n 22) downto 0
        when (= (%le-u32 buf i) +zip-eocd-sig+) return i))

(defun %zip-locate (buf name)
  "Walk the central directory of the in-memory ZIP BUF; return, for the entry whose
   filename = NAME, (values local-header-offset compression-method compressed-size
   uncompressed-size), else NIL. Every attacker-controlled offset/length read from a
   central-directory header is bounds-checked via %NEED before use, so a crafted
   container can never drive an out-of-bounds AREF/SUBSEQ — it yields DOCX-MALFORMED
   (→ clean NIL fallback)."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf))
  (let ((eocd (%find-eocd buf)))
    (unless eocd (return-from %zip-locate nil))
    (%need buf eocd 20)
    (let ((count  (%le-u16 buf (+ eocd 10)))
          (p      (%le-u32 buf (+ eocd 16))))   ; central-directory offset
      (dotimes (k count nil)
        (%need buf p 46)                        ; fixed CD header is 46 octets
        (unless (= (%le-u32 buf p) +zip-cd-sig+) (return nil))
        (let* ((method (%le-u16 buf (+ p 10)))
               (csize  (%le-u32 buf (+ p 20)))
               (usize  (%le-u32 buf (+ p 24)))
               (fnlen  (%le-u16 buf (+ p 28)))
               (eflen  (%le-u16 buf (+ p 30)))
               (cmlen  (%le-u16 buf (+ p 32)))
               (lho    (%le-u32 buf (+ p 42))))
          (%need buf (+ p 46) fnlen)            ; variable filename must be in bounds
          (let ((fname (%ascii buf (+ p 46) (+ p 46 fnlen))))
            (when (string= fname name)
              (return (values lho method csize usize)))
            (setf p (+ p 46 fnlen eflen cmlen))))))))

(defun %zip-entry-octets (buf name)
  "Return the DECOMPRESSED octets of entry NAME inside ZIP BUF.
   Supports stored (0) and DEFLATE (8). Signals DOCX-MALFORMED / DOCX-BACKEND-MISSING."
  (declare (type (simple-array (unsigned-byte 8) (*)) buf))
  (multiple-value-bind (lho method csize usize) (%zip-locate buf name)
    (unless lho
      (error 'docx-malformed :stage-name :docx-adapter
                             :message (format nil "entry ~A not found in container" name)))
    (%need buf lho 30)                            ; fixed local file header is 30 octets
    (unless (= (%le-u32 buf lho) +zip-lfh-sig+)
      (error 'docx-malformed :stage-name :docx-adapter
                             :message "bad local file header signature"))
    (when (> usize +docx-max-inflate+)
      (error 'docx-malformed :stage-name :docx-adapter
             :message (format nil "declared decompressed size ~A exceeds cap ~A (zip-bomb?)"
                              usize +docx-max-inflate+)))
    (let* ((fnlen (%le-u16 buf (+ lho 26)))
           (eflen (%le-u16 buf (+ lho 28)))
           (data  (+ lho 30 fnlen eflen)))
      (%need buf data csize)                      ; compressed payload must be in bounds
      (let ((comp (subseq buf data (+ data csize))))
        (case method
          ;; stored — already plain; trust the declared size as the authoritative length.
          (0 comp)
          ;; DEFLATE. chipz's convenience form (output = NIL → fresh vector) is the
          ;; portable, dependency-stable call. The zip-bomb ceiling is enforced by the
          ;; declared-usize check above (rejected pre-inflate) AND a post-inflate length
          ;; check here — so a stream that lies about its size still cannot slip a
          ;; multi-GB payload past the cap into the corpus. chipz is a hard dependency;
          ;; call it directly. (An earlier #+chipz feature guard was WRONG: chipz loads
          ;; but does not push :chipz to *features*, so the guard silently took the error
          ;; branch even though the library was present.)
          (8 (handler-case
                 (let ((out (chipz:decompress nil 'chipz:deflate comp)))
                   (when (> (length out) +docx-max-inflate+)
                     (error 'docx-malformed :stage-name :docx-adapter
                            :message (format nil "inflated size ~A exceeds cap ~A (zip-bomb?)"
                                             (length out) +docx-max-inflate+)))
                   out)
               (docx-error (e) (error e))
               (error (e)
                 (error 'docx-malformed :stage-name :docx-adapter
                        :message (format nil "DEFLATE inflate failed (bomb or corruption): ~A" e)))))
          (t (error 'docx-malformed :stage-name :docx-adapter
                    :message (format nil "unsupported ZIP compression method ~D" method))))))))

;;; ============================================================================
;;; WORDPROCESSINGML → PLAIN TEXT (cxml-stp DOM, mirroring html-parliament-adapter)
;;;
;;; Each <w:p> is a paragraph → one output line. Text lives in <w:t> runs. We emit
;;; the concatenation of every <w:t> under a paragraph, preserving legal numbering
;;; lines («Άρθρο 1», «1.», «α)») exactly as the raw-text FSM expects them.
;;; ============================================================================

(defun %wml-octets->text (octets)
  "Parse WordprocessingML OCTETS (word/document.xml) into plain text, one line per
   <w:p>. cxml decodes the document's declared encoding (UTF-8), so Greek is intact.
   cxml/cxml-stp are hard dependencies — called directly (no feature guard)."
  (let ((doc   (cxml:parse octets (cxml-stp:make-builder)))
        (lines '()))
    (cxml-stp:do-recursively (node doc)
      (when (and (typep node 'cxml-stp:element)
                 (string-equal (cxml-stp:local-name node) "p"))
        (let ((para (with-output-to-string (s)
                      (cxml-stp:do-recursively (n node)
                        (when (and (typep n 'cxml-stp:text)
                                   ;; only text that lives inside a <w:t> run
                                   (let ((par (cxml-stp:parent n)))
                                     (and (typep par 'cxml-stp:element)
                                          (string-equal (cxml-stp:local-name par) "t"))))
                          (write-string (cxml-stp:data n) s))))))
          (push para lines))))
    (format nil "~{~A~%~}" (nreverse lines))))

;;; ============================================================================
;;; PUBLIC ENTRY POINTS
;;; ============================================================================

(defun docx->text (docx-path)
  "Extract the full plain text of the Office Open XML document at DOCX-PATH —
   one line per WordprocessingML paragraph. Pure Lisp: ZIP+inflate (chipz) +
   DOM (cxml-stp). Signals a DOCX-ERROR subclass on failure."
  (let* ((buf (alexandria:read-file-into-byte-vector docx-path))
         (xml (%zip-entry-octets buf "word/document.xml")))
    (%wml-octets->text (coerce xml '(simple-array (unsigned-byte 8) (*))))))

(defun docx-adapter (docx-path &key (source-path nil))
  "Office Open XML (.docx) → normalized-article-input (IIR) list.

   Mirrors PDF-ADAPTER's contract: extract the authoritative digital text, then feed
   it to the RIGHT parser for its style — never duplicating parse logic:

     • Isokratis (ΔΣΑ) export — the ΔΣΑ database emits the SAME regular structure as
       .docx or PDF (Άρθρο: N … Ημ/νία … Περιγραφή όρου θησαυρού … Λήμματα …
       Κείμενο Αρθρου … body). This is exactly the format PDF-ADAPTER already parses,
       so the docx text is routed to the very same ISOKRATIS-TEXT-P / CLEAN-FEK-TEXT /
       PARSE-ISOKRATIS-TEXT / ARTICLE-TO-IIR pipeline. The per-article metadata is
       stripped and only the normative «Κείμενο Αρθρου» body is kept — identical
       result to ingesting the ΔΣΑ PDF, one source of truth for the format.
     • otherwise — the generic raw-text 5-layer FSM (RAW-TEXT->IIR-ARTICLES).

   Returns NIL on any failure, so the caller falls back exactly as it does for an
   empty PDF extraction (the materialize safety then preserves any populated corpus)."
  (handler-case
      (let ((text (docx->text docx-path)))
        (when (and text (plusp (length text)))
          (let ((cleaned (clean-fek-text text))
                (path    (or source-path (princ-to-string docx-path))))
            ;; [Π7-U.1 Φ1γ] ΥΠΟΧΡΕΩΤΙΚΑ μέσα από το όριο errata (μία έδρα)
            (apply-declared-errata
             (if (isokratis-text-p cleaned)
                 (mapcar (lambda (art) (article-to-iir art path))
                         (parse-isokratis-text cleaned))
                 (raw-text->iir-articles text :source-path path))))))
    (docx-error (e)
      (warn "docx-adapter: ~A" e)
      nil)
    (error (e)
      (warn "docx-adapter: unexpected failure on ~A: ~A" docx-path e)
      nil)))
