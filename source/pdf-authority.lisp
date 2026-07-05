;;;; source/pdf-authority.lisp
;;;; ============================================================================
;;;; PDF AUTHORITY - Pure Common Lisp PDF Text Extraction via libpoppler CFFI
;;;; ============================================================================
;;;;
;;;; Replaces Python subprocess (pdfminer.six / pdf2txt.py) with direct
;;;; CFFI bindings to libpoppler-glib.
;;;;
;;;; ARCHITECTURE (UPGRADED FOR LAYOUT GRAPH):
;;;;
;;;;   PDF File ──▶ libpoppler-glib ──▶ Layout Graph (Layer 1)
;;;;                     ↑                    │
;;;;               CFFI bindings              ▼
;;;;                (Pure Lisp)         layout-document
;;;;                                         │
;;;;                                    layout-page[]
;;;;                                         │
;;;;                                    layout-block[]
;;;;                                         │
;;;;                                    layout-line[]
;;;;                                         │
;;;;                                    layout-span[]
;;;;
;;;; Requirements:
;;;;   - libpoppler-glib-dev (Debian: apt install libpoppler-glib-dev)
;;;;   - CFFI (Common Lisp Foreign Function Interface)
;;;;
;;;; DARPA-GRADE: No Python, no subprocess, direct C library access.
;;;; NSA-GRADE: Full traceability with trace-core integration.
;;;; ============================================================================
;;;;
;;;; COMMON LISP FEATURES UTILIZED
;;;; ============================================================================
;;;;
;;;; ┌─────────────────────────────────────────────────────────────────────────┐
;;;; │ FEATURE                  │ USAGE                                        │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CFFI                     │ Direct libpoppler-glib bindings              │
;;;; │                          │ • defcfun, defcstruct, defctype              │
;;;; │                          │ • foreign-alloc, mem-ref, with-foreign-*     │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ CONDITIONS               │ PDF error hierarchy with restarts            │
;;;; │                          │ • pdf-error, pdf-not-found, pdf-open-error   │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ UNWIND-PROTECT           │ Guaranteed resource cleanup                  │
;;;; │                          │ • Document/page/memory deallocation          │
;;;; ├─────────────────────────────────────────────────────────────────────────┤
;;;; │ MULTIPLE VALUES          │ Rich returns from layout extraction          │
;;;; │                          │ • (values layout-page text-content)          │
;;;; └─────────────────────────────────────────────────────────────────────────┘
;;;;
;;;; ============================================================================

(defpackage :orchestrator.pdf-authority
  (:use :cl :cffi)
  (:import-from :orchestrator.layout-types
                #:make-bbox
                #:make-font-info
                #:make-layout-span
                #:make-layout-line
                #:make-layout-block
                #:make-layout-page
                #:make-layout-document
                #:layout-span
                #:layout-line
                #:layout-block
                #:layout-page
                #:layout-document
                #:bbox-union
                #:compute-reading-order
                #:reset-layout-counters)
  (:export
   ;; ══════════════════════════════════════════════════════════════════
   ;; LEGACY TEXT EXTRACTION API (backwards compatible)
   ;; ══════════════════════════════════════════════════════════════════
   #:extract-text-from-pdf
   #:ocr-available-p
   #:extract-text-via-ocr
   #:extract-text-any
   #:extract-text-layout-from-pdf
   #:extract-text-columns-from-pdf
   #:reflow-page-text
   #:filter-text-by-region
   #:extract-pages-from-pdf
   #:extract-page-text
   #:get-pdf-metadata
   #:get-page-count

   ;; ══════════════════════════════════════════════════════════════════
   ;; LAYOUT GRAPH EXTRACTION API (NEW - Layer 1)
   ;; ══════════════════════════════════════════════════════════════════
   #:extract-layout-graph
   #:extract-page-layout
   #:extract-page-layout-with-text

   ;; ══════════════════════════════════════════════════════════════════
   ;; CONDITIONS
   ;; ══════════════════════════════════════════════════════════════════
   #:pdf-error
   #:pdf-not-found
   #:pdf-open-error
   #:pdf-extraction-error
   #:pdf-layout-error

   ;; ══════════════════════════════════════════════════════════════════
   ;; LIBRARY STATUS
   ;; ══════════════════════════════════════════════════════════════════
   #:poppler-available-p
   #:ensure-poppler-loaded
   #:*poppler-library-loaded*))

(in-package :orchestrator.pdf-authority)

;;; ============================================================================
;;; CFFI LIBRARY DEFINITION
;;; ============================================================================

(define-foreign-library libpoppler-glib
  (:unix (:or "libpoppler-glib.so.8" "libpoppler-glib.so"))
  (:darwin "libpoppler-glib.dylib")
  (t (:default "libpoppler-glib")))

(define-foreign-library libglib
  (:unix (:or "libglib-2.0.so.0" "libglib-2.0.so"))
  (:darwin "libglib-2.0.dylib")
  (t (:default "libglib-2.0")))

(define-foreign-library libgobject
  (:unix (:or "libgobject-2.0.so.0" "libgobject-2.0.so"))
  (:darwin "libgobject-2.0.dylib")
  (t (:default "libgobject-2.0")))

(defvar *poppler-library-loaded* nil
  "T if libpoppler-glib was successfully loaded")

(defvar *poppler-load-attempted* nil
  "T if we've already attempted to load poppler (prevents repeated attempts)")

(defun load-poppler-libraries ()
  "Load required libraries in correct order.

   IMPORTANT: This is called LAZILY at runtime, NOT at compile/save time.
   Loading at compile time causes memory faults when the saved core is loaded
   because CFFI library pointers become invalid."
  (when *poppler-load-attempted*
    (return-from load-poppler-libraries *poppler-library-loaded*))

  (setf *poppler-load-attempted* t)

  (handler-case
      (progn
        (unless (foreign-library-loaded-p 'libglib)
          (use-foreign-library libglib))
        (unless (foreign-library-loaded-p 'libgobject)
          (use-foreign-library libgobject))
        (unless (foreign-library-loaded-p 'libpoppler-glib)
          (use-foreign-library libpoppler-glib))
        (setf *poppler-library-loaded* t)
        (log:info () "libpoppler-glib loaded successfully"))
    (error (e)
      (log:warn () "Failed to load libpoppler-glib: ~A" e)
      (setf *poppler-library-loaded* nil)))

  *poppler-library-loaded*)

;; NOTE: Do NOT load library at compile/save time!
;; Loading is done lazily at runtime via ensure-poppler-loaded
;; This prevents memory faults when the saved core image is loaded.

(defun ensure-poppler-loaded ()
  "Ensure poppler library is loaded. Call this before any poppler operations."
  (unless *poppler-library-loaded*
    (load-poppler-libraries))
  *poppler-library-loaded*)

(defun poppler-available-p ()
  "Check if libpoppler-glib is available (loads if not yet attempted)"
  (ensure-poppler-loaded))

;;; ============================================================================
;;; CONDITIONS
;;; ============================================================================

(define-condition pdf-error (error)
  ((message :initarg :message :reader pdf-error-message)
   (path :initarg :path :reader pdf-error-path :initform nil))
  (:report (lambda (c s)
             (format s "PDF Error~@[ (~A)~]: ~A"
                     (pdf-error-path c)
                     (pdf-error-message c)))))

(define-condition pdf-not-found (pdf-error) ())
(define-condition pdf-open-error (pdf-error) ())
(define-condition pdf-extraction-error (pdf-error) ())
(define-condition pdf-layout-error (pdf-error)
  ((page-number :initarg :page-number :reader pdf-layout-error-page :initform nil))
  (:report (lambda (c s)
             (format s "PDF Layout Error~@[ (page ~D)~]~@[ (~A)~]: ~A"
                     (pdf-layout-error-page c)
                     (pdf-error-path c)
                     (pdf-error-message c)))))

;;; ============================================================================
;;; GLIB TYPE DEFINITIONS
;;; ============================================================================

(defctype gchar :char)
(defctype guint :unsigned-int)
(defctype gint :int)
(defctype gboolean :int)
(defctype gdouble :double)
(defctype gpointer :pointer)

;; GError structure
(defcstruct gerror
  (domain :uint32)
  (code :int)
  (message :pointer))

;;; ============================================================================
;;; GLIB MEMORY FUNCTIONS
;;; ============================================================================

(defcfun ("g_free" g-free) :void
  (mem :pointer))

(defcfun ("g_object_unref" g-object-unref) :void
  (object :pointer))

(defcfun ("g_error_free" g-error-free) :void
  (error :pointer))

;;; ============================================================================
;;; POPPLER DOCUMENT FUNCTIONS
;;; ============================================================================

;; PopplerDocument* poppler_document_new_from_file(const char *uri, const char *password, GError **error)
(defcfun ("poppler_document_new_from_file" poppler-document-new-from-file) :pointer
  (uri :string)
  (password :pointer)  ; can be null
  (error :pointer))    ; GError**

;; int poppler_document_get_n_pages(PopplerDocument *document)
(defcfun ("poppler_document_get_n_pages" poppler-document-get-n-pages) :int
  (document :pointer))

;; PopplerPage* poppler_document_get_page(PopplerDocument *document, int index)
(defcfun ("poppler_document_get_page" poppler-document-get-page) :pointer
  (document :pointer)
  (index :int))

;; char* poppler_document_get_title(PopplerDocument *document)
(defcfun ("poppler_document_get_title" poppler-document-get-title) :pointer
  (document :pointer))

;; char* poppler_document_get_author(PopplerDocument *document)
(defcfun ("poppler_document_get_author" poppler-document-get-author) :pointer
  (document :pointer))

;; char* poppler_document_get_subject(PopplerDocument *document)
(defcfun ("poppler_document_get_subject" poppler-document-get-subject) :pointer
  (document :pointer))

;; char* poppler_document_get_creator(PopplerDocument *document)
(defcfun ("poppler_document_get_creator" poppler-document-get-creator) :pointer
  (document :pointer))

;; char* poppler_document_get_producer(PopplerDocument *document)
(defcfun ("poppler_document_get_producer" poppler-document-get-producer) :pointer
  (document :pointer))

;;; ============================================================================
;;; POPPLER PAGE FUNCTIONS
;;; ============================================================================

;; char* poppler_page_get_text(PopplerPage *page)
(defcfun ("poppler_page_get_text" poppler-page-get-text) :pointer
  (page :pointer))

;; void poppler_page_get_size(PopplerPage *page, double *width, double *height)
(defcfun ("poppler_page_get_size" poppler-page-get-size) :void
  (page :pointer)
  (width :pointer)
  (height :pointer))

;; int poppler_page_get_index(PopplerPage *page)
(defcfun ("poppler_page_get_index" poppler-page-get-index) :int
  (page :pointer))

;;; ============================================================================
;;; POPPLER LAYOUT FUNCTIONS (NEW - For Layout Graph extraction)
;;; ============================================================================

;; PopplerRectangle structure (x1, y1 = bottom-left, x2, y2 = top-right)
(defcstruct poppler-rectangle
  (x1 :double)
  (y1 :double)
  (x2 :double)
  (y2 :double))

;; gboolean poppler_page_get_text_layout(PopplerPage *page, PopplerRectangle **rectangles, guint *n_rectangles)
;; Returns array of rectangles, one per character
(defcfun ("poppler_page_get_text_layout" poppler-page-get-text-layout) gboolean
  (page :pointer)
  (rectangles :pointer)  ; PopplerRectangle** (output)
  (n-rectangles :pointer)) ; guint* (output)

;; char* poppler_page_get_text_for_area(PopplerPage *page, PopplerRectangle *area)
(defcfun ("poppler_page_get_text_for_area" poppler-page-get-text-for-area) :pointer
  (page :pointer)
  (area :pointer))

;; GList* poppler_page_get_text_attributes(PopplerPage *page)
;; Returns list of PopplerTextAttributes
(defcfun ("poppler_page_get_text_attributes" poppler-page-get-text-attributes) :pointer
  (page :pointer))

;; void poppler_page_free_text_attributes(GList *list)
(defcfun ("poppler_page_free_text_attributes" poppler-page-free-text-attributes) :void
  (list :pointer))

;; PopplerTextAttributes structure (partial - key fields only)
;; Full struct has: font_name, font_size, is_underlined, color, start_index, end_index
(defcstruct poppler-text-attributes
  (font-name :pointer)
  (font-size :double)
  (is-underlined gboolean)
  (color-red :uint16)
  (color-green :uint16)
  (color-blue :uint16)
  (start-index :int)
  (end-index :int))

;; GList navigation
(defcfun ("g_list_length" g-list-length) :uint
  (list :pointer))

(defcfun ("g_list_nth_data" g-list-nth-data) :pointer
  (list :pointer)
  (n :uint))

(defcfun ("g_list_free" g-list-free) :void
  (list :pointer))

;;; ============================================================================
;;; HELPER FUNCTIONS
;;; ============================================================================

(defun path-to-uri (path)
  "Convert filesystem path to file:// URI"
  (let ((absolute-path (namestring (truename path))))
    ;; URL encode special characters
    (format nil "file://~A"
            (cl-ppcre:regex-replace-all
             " " absolute-path "%20"))))

(defun pointer-to-string-and-free (ptr)
  "Convert C string pointer to Lisp string and free the C memory"
  (if (null-pointer-p ptr)
      nil
      (unwind-protect
          (foreign-string-to-lisp ptr :encoding :utf-8)
        (g-free ptr))))

(defun extract-gerror-message (gerror-ptr)
  "Extract error message from GError pointer"
  (if (null-pointer-p gerror-ptr)
      "Unknown error"
      (let ((gerror (mem-ref gerror-ptr :pointer)))
        (if (null-pointer-p gerror)
            "Unknown error"
            (let ((msg-ptr (foreign-slot-value gerror '(:struct gerror) 'message)))
              (if (null-pointer-p msg-ptr)
                  "Unknown error"
                  (foreign-string-to-lisp msg-ptr :encoding :utf-8)))))))

;;; ============================================================================
;;; CORE API: EXTRACT TEXT
;;; ============================================================================

(defun extract-text-from-pdf (pdf-path &key (page-separator #\Newline))
  "Extract all text from PDF file

   Uses libpoppler-glib for reliable PDF text extraction.
   This is the DARPA-grade replacement for pdf2txt.py subprocess.

   Args:
     pdf-path: Path to PDF file
     page-separator: Character/string to insert between pages (default: newline)

   Returns:
     String containing all extracted text

   Conditions:
     pdf-not-found: File does not exist
     pdf-open-error: Cannot open/parse PDF
     pdf-extraction-error: Text extraction failed"

  (unless (ensure-poppler-loaded)
    (error 'pdf-error
           :message "libpoppler-glib not available. Install: apt install libpoppler-glib-dev"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          ;; Open document
          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (let ((msg (extract-gerror-message gerror-ptr)))
              (unless (null-pointer-p (mem-ref gerror-ptr :pointer))
                (g-error-free (mem-ref gerror-ptr :pointer)))
              (error 'pdf-open-error
                     :message (format nil "Cannot open PDF: ~A" msg)
                     :path pdf-path)))

          ;; Extract text from all pages
          (let* ((n-pages (poppler-document-get-n-pages document))
                 (texts '()))

            (dotimes (i n-pages)
              (let ((page (poppler-document-get-page document i)))
                (unless (null-pointer-p page)
                  (unwind-protect
                      (let ((text-ptr (poppler-page-get-text page)))
                        (unless (null-pointer-p text-ptr)
                          (push (pointer-to-string-and-free text-ptr) texts)))
                    (g-object-unref page)))))

            ;; Join pages with separator
            (format nil (format nil "~~{~~A~~^~A~~}" page-separator)
                    (nreverse texts))))

      ;; Cleanup
      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

;;; ============================================================================
;;; LAYOUT-AWARE EXTRACTION  (root fix: drop page chrome by POSITION, not regex)
;;; ============================================================================
;;;
;;; poppler get_text reads a page in reading order, so a repeated header/footer
;;; (the DSAnet print URL, page number, date, 'ΟΘΟΝΗ ΕΚΤΥΠΩΣΗΣ') is interleaved
;;; into the body and has to be scrubbed downstream with brittle regexes. With
;;; the per-character rectangles from get_text_layout we instead keep only the
;;; characters that fall inside the page's BODY band and drop the top/bottom
;;; margins — removing the chrome at the source. The filtering itself is a pure,
;;; unit-tested function; only the rectangle read is foreign.

(defun %page-text-layout (page)
  "Return (values text rectangles) for PAGE, where RECTANGLES is a simple-vector
   of (x1 y1 x2 y2) aligned 1:1 with TEXT's characters, or NIL rectangles if the
   layout is unavailable / does not align."
  (let ((text-ptr (poppler-page-get-text page)))
    (if (null-pointer-p text-ptr)
        (values "" nil)
        (let ((text (pointer-to-string-and-free text-ptr)))
          (with-foreign-objects ((rects-ref :pointer) (n-ref :uint))
            (if (zerop (poppler-page-get-text-layout page rects-ref n-ref))
                (values text nil)
                (let* ((arr (mem-ref rects-ref :pointer))
                       (count (mem-ref n-ref :uint)))
                  (unwind-protect
                       (if (/= count (length text))
                           (values text nil)          ; alignment unsure → no filtering
                           (let ((v (make-array count)))
                             (dotimes (i count)
                               (let ((r (mem-aptr arr '(:struct poppler-rectangle) i)))
                                 (setf (aref v i)
                                       (list (foreign-slot-value r '(:struct poppler-rectangle) 'x1)
                                             (foreign-slot-value r '(:struct poppler-rectangle) 'y1)
                                             (foreign-slot-value r '(:struct poppler-rectangle) 'x2)
                                             (foreign-slot-value r '(:struct poppler-rectangle) 'y2)))))
                             (values text v)))
                    (unless (null-pointer-p arr) (g-free arr))))))))))

(defun %page-height (page)
  (with-foreign-objects ((w :double) (h :double))
    (poppler-page-get-size page w h)
    (mem-ref h :double)))

(defun filter-text-by-region (text rects height &key (header-frac 0.06) (footer-frac 0.06))
  "Pure: keep only characters whose vertical box lies in the body band of a page
   of HEIGHT, dropping the top HEADER-FRAC and bottom FOOTER-FRAC margins (where
   running headers/footers live). Whitespace is always kept; a dropped glyph
   becomes a space so words never merge. Falls back to TEXT unchanged when RECTS
   are absent or not aligned. (poppler space: y grows downward, y1=top y2=bottom.)"
  (if (or (null rects) (/= (length text) (length rects)) (<= height 0))
      text
      (let ((top (* header-frac height)) (bot (* (- 1.0 footer-frac) height)))
        (with-output-to-string (s)
          (loop for c across text for r across rects
                for y1 = (second r) for y2 = (fourth r) do
            (cond ((member c '(#\Newline #\Space #\Tab #\Return)) (write-char c s))
                  ((and (>= y2 top) (<= y1 bot)) (write-char c s))
                  (t (write-char #\Space s))))))))

(defun extract-text-layout-from-pdf (pdf-path &key (page-separator #\Newline)
                                                   (header-frac 0.06) (footer-frac 0.06))
  "Like EXTRACT-TEXT-FROM-PDF but drops each page's header/footer band by glyph
   position, so running page chrome never enters the text. Falls back per page to
   the plain text when layout rectangles are unavailable."
  (unless (ensure-poppler-loaded)
    (error 'pdf-error :message "libpoppler-glib not available" :path pdf-path))
  (unless (probe-file pdf-path)
    (error 'pdf-not-found :message "PDF file not found" :path pdf-path))
  (let ((uri (path-to-uri pdf-path)) (document nil))
    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))
          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))
          (when (null-pointer-p document)
            (error 'pdf-open-error :message "Cannot open PDF" :path pdf-path))
          (let ((texts '()) (n (poppler-document-get-n-pages document)))
            (dotimes (i n)
              (let ((page (poppler-document-get-page document i)))
                (unless (null-pointer-p page)
                  (unwind-protect
                      (multiple-value-bind (text rects) (%page-text-layout page)
                        (push (filter-text-by-region text rects (%page-height page)
                                                     :header-frac header-frac
                                                     :footer-frac footer-frac)
                              texts))
                    (g-object-unref page)))))
            (format nil (format nil "~~{~~A~~^~A~~}" page-separator) (nreverse texts))))
      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

;;; ============================================================================
;;; COLUMN-AWARE REFLOW  (root fix: rebuild reading order from glyph POSITIONS)
;;; ============================================================================
;;;
;;; poppler's get_text returns a page in a heuristic "reading order" that breaks
;;; on the two-column ΦΕΚ layout: physical rows that span both columns get read
;;; together, so text is interleaved and whole articles fall out at column/page
;;; boundaries (the ΚΠΔ lost ~8 articles this way; «εκπροσώ-» was cut mid-word).
;;;
;;; We don't trust poppler's order — we REBUILD it from the per-character boxes
;;; (already available via %page-text-layout) with a geometric XY-cut:
;;;   • a full-height vertical whitespace gap (the gutter) splits COLUMNS — done
;;;     FIRST so a column is never interleaved with its neighbour;
;;;   • a full-width horizontal gap splits BANDS (a full-width heading above the
;;;     two-column body) — done when no gutter exists (the heading blocks it);
;;;   • a leaf block is emitted line-by-line (group by y, order by x).
;;; The whole thing is a PURE function of (text, rects) → it is unit-tested with
;;; synthetic glyph boxes; only the rectangle read is foreign.

(defun %median (numbers)
  "Median of a non-empty list of reals."
  (let* ((v (sort (coerce numbers 'vector) #'<)) (n (length v)))
    (if (oddp n) (aref v (floor n 2))
        (/ (+ (aref v (1- (floor n 2))) (aref v (floor n 2))) 2.0))))

(defstruct (glyph (:constructor %glyph (char x1 y1 x2 y2)))
  char x1 y1 x2 y2)

(declaim (inline glyph-xc glyph-yc))
(defun glyph-xc (g) (/ (+ (glyph-x1 g) (glyph-x2 g)) 2.0))
(defun glyph-yc (g) (/ (+ (glyph-y1 g) (glyph-y2 g)) 2.0))

(defun %largest-gap (intervals lo hi min-gap)
  "INTERVALS: list of (a . b) occupied spans on one axis. Return (values mid width)
   of the widest INTERIOR uncovered sub-interval of [lo,hi] whose width ≥ MIN-GAP,
   else (values NIL 0). Leading/trailing margins are not gaps (cursor starts at the
   content edge LO)."
  (let ((sorted (sort (copy-list intervals) #'< :key #'car))
        (cursor lo) (best-mid nil) (best-w 0))
    (dolist (iv sorted)
      (when (> (car iv) cursor)
        (let ((w (- (car iv) cursor)))
          (when (and (>= w min-gap) (> w best-w))
            (setf best-w w best-mid (+ cursor (/ w 2.0))))))
      (when (> (cdr iv) cursor) (setf cursor (cdr iv))))
    (values best-mid best-w)))

(defun %emit-lines (glyphs mgh)
  "Leaf: order a single-column block. Group GLYPHS into lines by y-centre
   (tolerance 0.6·MGH), order lines top→bottom and glyphs left→right, one #\\Newline
   between lines."
  (let* ((sorted (sort (copy-list glyphs) #'< :key #'glyph-yc))
         (tol (* 0.6 mgh)) (lines '()) (cur '()) (anchor nil))
    (dolist (g sorted)
      (cond ((null anchor) (setf anchor (glyph-yc g) cur (list g)))
            ((<= (abs (- (glyph-yc g) anchor)) tol) (push g cur))
            (t (push (nreverse cur) lines) (setf anchor (glyph-yc g) cur (list g)))))
    (when cur (push (nreverse cur) lines))
    (setf lines (nreverse lines))
    (with-output-to-string (s)
      (loop for line in lines for first = t then nil do
        (unless first (write-char #\Newline s))
        (dolist (g (sort line #'< :key #'glyph-xc))
          (write-char (glyph-char g) s))))))

(defun %reflow (glyphs mgw mgh depth)
  "Recursive XY-cut over GLYPHS. Vertical (column) cut takes precedence over a
   horizontal (band) cut, so columns are separated before lines."
  (cond
    ((null glyphs) "")
    ((or (null (cdr glyphs)) (>= depth 80)) (%emit-lines glyphs mgh))
    (t
     (let ((x-lo (reduce #'min glyphs :key #'glyph-x1))
           (x-hi (reduce #'max glyphs :key #'glyph-x2))
           (y-lo (reduce #'min glyphs :key #'glyph-y1))
           (y-hi (reduce #'max glyphs :key #'glyph-y2)))
       (multiple-value-bind (xmid)
           (%largest-gap (mapcar (lambda (g) (cons (glyph-x1 g) (glyph-x2 g))) glyphs)
                         x-lo x-hi (* 1.8 mgw))
         (if xmid
             (concatenate 'string
                          (%reflow (remove-if-not (lambda (g) (< (glyph-xc g) xmid)) glyphs)
                                   mgw mgh (1+ depth))
                          (string #\Newline)
                          (%reflow (remove-if (lambda (g) (< (glyph-xc g) xmid)) glyphs)
                                   mgw mgh (1+ depth)))
             (multiple-value-bind (ymid)
                 (%largest-gap (mapcar (lambda (g) (cons (glyph-y1 g) (glyph-y2 g))) glyphs)
                               y-lo y-hi (* 1.0 mgh))
               (if ymid
                   (concatenate 'string
                                (%reflow (remove-if-not (lambda (g) (< (glyph-yc g) ymid)) glyphs)
                                         mgw mgh (1+ depth))
                                (string #\Newline)
                                (%reflow (remove-if (lambda (g) (< (glyph-yc g) ymid)) glyphs)
                                         mgw mgh (1+ depth)))
                   (%emit-lines glyphs mgh)))))))))

(defun reflow-page-text (text rects)
  "Reorder TEXT into correct reading order from per-character RECTS (a sequence of
   (x1 y1 x2 y2) aligned 1:1 with TEXT). Geometric XY-cut: columns before lines,
   so an interleaved two-column page is restored without losing text. RECTS NIL or
   length-mismatched → TEXT returned unchanged (safe fallback)."
  (if (or (null rects) (/= (length text) (length rects)))
      text
      (let ((glyphs '()))
        (loop for c across text for r across rects do
          (unless (member c '(#\Newline #\Return))
            (push (%glyph c (first r) (second r) (third r) (fourth r)) glyphs)))
        (setf glyphs (nreverse glyphs))
        (if (null glyphs) ""
            (let* ((ws (loop for g in glyphs for w = (- (glyph-x2 g) (glyph-x1 g))
                             when (> w 0) collect w))
                   (hs (loop for g in glyphs for h = (- (glyph-y2 g) (glyph-y1 g))
                             when (> h 0) collect h))
                   (mgw (if ws (%median ws) 1.0))
                   (mgh (if hs (%median hs) 1.0)))
              (%reflow glyphs mgw mgh 0))))))

(defun extract-text-columns-from-pdf (pdf-path &key (page-separator #\Newline))
  "Smart extraction for MULTI-COLUMN sources (the two-column ΦΕΚ): per page, rebuild
   the body into the correct reading order (geometric XY-cut — columns before lines),
   so text is never lost or interleaved at a column/page seam.

   The running header/footer (masthead, page numbers) is deliberately NOT clipped by
   position here: clipping a fixed top/bottom band also ate the first/last BODY line
   of a page, which is exactly where a hyphenated word breaks across a page boundary
   (δικαστη-/ρίου), losing text. Instead the masthead is removed downstream by
   clean-fek-text's content-based noise patterns — which is also what lets those
   hyphenated words be rejoined across the page seam. Falls back per page to poppler's
   native text when layout rectangles are unavailable."
  (unless (ensure-poppler-loaded)
    (error 'pdf-error :message "libpoppler-glib not available" :path pdf-path))
  (unless (probe-file pdf-path)
    (error 'pdf-not-found :message "PDF file not found" :path pdf-path))
  (let ((uri (path-to-uri pdf-path)) (document nil))
    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))
          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))
          (when (null-pointer-p document)
            (error 'pdf-open-error :message "Cannot open PDF" :path pdf-path))
          (let ((texts '()) (n (poppler-document-get-n-pages document)))
            (dotimes (i n)
              (let ((page (poppler-document-get-page document i)))
                (unless (null-pointer-p page)
                  (unwind-protect
                      (multiple-value-bind (text rects) (%page-text-layout page)
                        (let ((out
                               (if (and rects (= (length text) (length rects)))
                                   (reflow-page-text text rects)
                                   (let ((tp (poppler-page-get-text page)))
                                     (if (null-pointer-p tp) text
                                         (pointer-to-string-and-free tp))))))
                          (push out texts)))
                    (g-object-unref page)))))
            (format nil (format nil "~~{~~A~~^~A~~}" page-separator) (nreverse texts))))
      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

(defun extract-pages-from-pdf (pdf-path)
  "Extract text from PDF as list of page strings

   Args:
     pdf-path: Path to PDF file

   Returns:
     List of strings, one per page"

  (unless (ensure-poppler-loaded)
    (error 'pdf-error
           :message "libpoppler-glib not available"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (let ((msg (extract-gerror-message gerror-ptr)))
              (unless (null-pointer-p (mem-ref gerror-ptr :pointer))
                (g-error-free (mem-ref gerror-ptr :pointer)))
              (error 'pdf-open-error
                     :message (format nil "Cannot open PDF: ~A" msg)
                     :path pdf-path)))

          (let* ((n-pages (poppler-document-get-n-pages document))
                 (pages (make-array n-pages :initial-element nil)))

            (dotimes (i n-pages)
              (let ((page (poppler-document-get-page document i)))
                (unless (null-pointer-p page)
                  (unwind-protect
                      (let ((text-ptr (poppler-page-get-text page)))
                        (unless (null-pointer-p text-ptr)
                          (setf (aref pages i) (pointer-to-string-and-free text-ptr))))
                    (g-object-unref page)))))

            (coerce pages 'list)))

      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

(defun extract-page-text (pdf-path page-number)
  "Extract text from specific page (0-indexed)

   Args:
     pdf-path: Path to PDF file
     page-number: Page index (0-based)

   Returns:
     String containing page text, or NIL if page empty"

  (unless (ensure-poppler-loaded)
    (error 'pdf-error
           :message "libpoppler-glib not available"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (error 'pdf-open-error
                   :message "Cannot open PDF"
                   :path pdf-path))

          (let ((n-pages (poppler-document-get-n-pages document)))
            (unless (and (>= page-number 0) (< page-number n-pages))
              (error 'pdf-extraction-error
                     :message (format nil "Page ~D out of range (0-~D)"
                                      page-number (1- n-pages))
                     :path pdf-path))

            (let ((page (poppler-document-get-page document page-number)))
              (if (null-pointer-p page)
                  nil
                  (unwind-protect
                      (let ((text-ptr (poppler-page-get-text page)))
                        (unless (null-pointer-p text-ptr)
                          (pointer-to-string-and-free text-ptr)))
                    (g-object-unref page))))))

      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

;;; ============================================================================
;;; METADATA EXTRACTION
;;; ============================================================================

(defun get-pdf-metadata (pdf-path)
  "Extract PDF metadata

   Args:
     pdf-path: Path to PDF file

   Returns:
     Plist with metadata:
       :title - Document title
       :author - Document author
       :subject - Document subject
       :creator - Creating application
       :producer - PDF producer
       :page-count - Number of pages"

  (unless (ensure-poppler-loaded)
    (error 'pdf-error
           :message "libpoppler-glib not available"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (error 'pdf-open-error
                   :message "Cannot open PDF"
                   :path pdf-path))

          (list :title (pointer-to-string-and-free (poppler-document-get-title document))
                :author (pointer-to-string-and-free (poppler-document-get-author document))
                :subject (pointer-to-string-and-free (poppler-document-get-subject document))
                :creator (pointer-to-string-and-free (poppler-document-get-creator document))
                :producer (pointer-to-string-and-free (poppler-document-get-producer document))
                :page-count (poppler-document-get-n-pages document)))

      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

(defun get-page-count (pdf-path)
  "Get number of pages in PDF

   Args:
     pdf-path: Path to PDF file

   Returns:
     Integer page count"

  (unless (ensure-poppler-loaded)
    (error 'pdf-error
           :message "libpoppler-glib not available"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (error 'pdf-open-error
                   :message "Cannot open PDF"
                   :path pdf-path))

          (poppler-document-get-n-pages document))

      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

;;; ============================================================================
;;; FALLBACK: PURE LISP PDF PARSING (BASIC)
;;; ============================================================================
;;;;
;;;; If libpoppler is not available, provide a basic pure-Lisp fallback
;;;; that can extract text from simple, uncompressed PDFs.
;;;; This is not as robust as poppler but handles basic cases.

(defun extract-text-fallback (pdf-path)
  "Fallback text extraction for simple PDFs without libpoppler

   WARNING: This is a limited fallback. For production, install libpoppler.

   Handles:
   - Uncompressed text streams
   - Basic Latin/Greek text

   Does NOT handle:
   - Compressed streams (FlateDecode)
   - Complex fonts/encodings
   - Encrypted PDFs"

  (with-open-file (stream pdf-path
                          :direction :input
                          :element-type '(unsigned-byte 8))
    (let* ((size (file-length stream))
           (buffer (make-array size :element-type '(unsigned-byte 8))))
      (read-sequence buffer stream)

      (let ((content (babel:octets-to-string buffer :encoding :latin-1))
            (texts '()))

        ;; Find text streams (BT ... ET blocks)
        (cl-ppcre:do-register-groups (text)
            ("BT\\s*(.*?)\\s*ET" content)
          (when text
            ;; Extract text from Tj/TJ operators
            (cl-ppcre:do-register-groups (str)
                ("\\(([^)]*)\\)\\s*Tj" text)
              (when str
                (push str texts)))))

        (format nil "~{~A~^ ~}" (nreverse texts))))))

;;; ============================================================================
;;; UNIFIED INTERFACE
;;; ============================================================================

(defun extract-pdf-text (pdf-path &key (prefer-poppler t))
  "Extract text from PDF using best available method

   Tries in order:
   1. libpoppler-glib (if available and prefer-poppler is T)
   2. Pure Lisp fallback (limited functionality)

   Args:
     pdf-path: Path to PDF file
     prefer-poppler: If T, prefer libpoppler (default: T)

   Returns:
     Extracted text string"

  (cond
    ((and prefer-poppler *poppler-library-loaded*)
     (extract-text-from-pdf pdf-path))

    (t
     (warn "Using limited pure-Lisp PDF fallback. Install libpoppler-glib for full support.")
     (extract-text-fallback pdf-path))))

;;; ============================================================================
;;; LAYOUT GRAPH EXTRACTION (NEW - Layer 1)
;;; ============================================================================
;;;
;;; These functions extract the visual/geometric structure of PDF pages
;;; as a Layout Graph (hierarchy of spans, lines, blocks, pages).
;;;
;;; This is the FOUNDATION of the 5-layer PDF parser architecture:
;;;   Layer 1: PDF → Layout Graph (THIS)
;;;   Layer 2: Layout Graph → Logical Blocks
;;;   Layer 3: Logical Blocks → Canonical Text
;;;   Layer 4: Canonical Text → AST
;;;   Layer 5: Traceability (integrated throughout)

(defun extract-character-rects (page)
  "Extract character-level rectangles from a poppler page.

   Returns: List of (text x y width height) tuples"
  (with-foreign-objects ((rects-ptr :pointer)
                         (n-rects-ptr :uint))
    (let ((success (poppler-page-get-text-layout page rects-ptr n-rects-ptr)))
      (when (zerop success)
        (return-from extract-character-rects nil))

      (let* ((n-rects (mem-ref n-rects-ptr :uint))
             (rects (mem-ref rects-ptr :pointer))
             (text-ptr (poppler-page-get-text page))
             (full-text (if (null-pointer-p text-ptr)
                            ""
                            (foreign-string-to-lisp text-ptr :encoding :utf-8)))
             (result '()))

        (unwind-protect
            (progn
              ;; Extract each character with its bounding box
              (dotimes (i (min n-rects (length full-text)))
                (let* ((rect-ptr (mem-aptr rects '(:struct poppler-rectangle) i))
                       (x1 (foreign-slot-value rect-ptr '(:struct poppler-rectangle) 'x1))
                       (y1 (foreign-slot-value rect-ptr '(:struct poppler-rectangle) 'y1))
                       (x2 (foreign-slot-value rect-ptr '(:struct poppler-rectangle) 'x2))
                       (y2 (foreign-slot-value rect-ptr '(:struct poppler-rectangle) 'y2))
                       (char (if (< i (length full-text))
                                 (string (char full-text i))
                                 " ")))
                  ;; Only include visible characters (non-zero bbox)
                  (when (and (> (- x2 x1) 0.001) (> (- y2 y1) 0.001))
                    (push (list char
                                (coerce x1 'single-float)
                                (coerce y1 'single-float)
                                (coerce (- x2 x1) 'single-float)
                                (coerce (- y2 y1) 'single-float))
                          result))))
              (nreverse result))

          ;; Cleanup
          (unless (null-pointer-p text-ptr)
            (g-free text-ptr))
          (unless (null-pointer-p rects)
            (g-free rects)))))))

(defun cluster-chars-into-spans (char-rects &key (x-tolerance 2.0) (y-tolerance 3.0))
  "Cluster character rectangles into spans.

   A span is a horizontal sequence of characters with similar baseline.

   Args:
     char-rects: List of (text x y width height)
     x-tolerance: Max horizontal gap to merge (default 2.0)
     y-tolerance: Max vertical variance for same line (default 3.0)

   Returns: List of span data: ((text bbox) ...)"
  (when (null char-rects)
    (return-from cluster-chars-into-spans nil))

  (let ((spans '())
        (current-span-chars '())
        (current-span-x nil)
        (current-span-y nil)
        (current-span-x2 nil)
        (current-span-y2 nil))

    (flet ((flush-span ()
             (when current-span-chars
               (let ((text (format nil "~{~A~}" (nreverse current-span-chars))))
                 (push (list text
                             (make-bbox :x current-span-x
                                        :y current-span-y
                                        :width (- current-span-x2 current-span-x)
                                        :height (- current-span-y2 current-span-y)))
                       spans))
               (setf current-span-chars nil))))

      (dolist (char-rect char-rects)
        (destructuring-bind (char x y w h) char-rect
          (let ((x2 (+ x w))
                (y2 (+ y h)))
            (cond
              ;; First character in span
              ((null current-span-x)
               (push char current-span-chars)
               (setf current-span-x x
                     current-span-y y
                     current-span-x2 x2
                     current-span-y2 y2))

              ;; Continue span if close enough
              ((and (<= (- x current-span-x2) x-tolerance)
                    (<= (abs (- y current-span-y)) y-tolerance))
               (push char current-span-chars)
               (setf current-span-x2 (max current-span-x2 x2)
                     current-span-y (min current-span-y y)
                     current-span-y2 (max current-span-y2 y2)))

              ;; Start new span
              (t
               (flush-span)
               (push char current-span-chars)
               (setf current-span-x x
                     current-span-y y
                     current-span-x2 x2
                     current-span-y2 y2))))))

      (flush-span))
    (nreverse spans)))

(defun cluster-spans-into-lines (span-data &key (y-tolerance 5.0))
  "Cluster spans into lines based on vertical position.

   Args:
     span-data: List of (text bbox) from cluster-chars-into-spans
     y-tolerance: Max vertical distance to consider same line

   Returns: List of line data: ((spans-list line-bbox) ...)"
  (when (null span-data)
    (return-from cluster-spans-into-lines nil))

  ;; Sort spans by y coordinate (top to bottom in PDF coordinates)
  (let* ((sorted (sort (copy-list span-data) #'>
                       :key (lambda (s) (orchestrator.layout-types:bbox-y (second s)))))
         (lines '())
         (current-line-spans '())
         (current-line-y nil))

    (flet ((flush-line ()
             (when current-line-spans
               ;; Sort spans within line left to right
               (let* ((line-spans (sort (nreverse current-line-spans) #'<
                                        :key (lambda (s) (orchestrator.layout-types:bbox-x (second s)))))
                      (line-bbox (reduce #'bbox-union
                                         (mapcar #'second line-spans))))
                 (push (list line-spans line-bbox) lines))
               (setf current-line-spans nil))))

      (dolist (span sorted)
        (let ((span-y (orchestrator.layout-types:bbox-y (second span))))
          (cond
            ;; First span
            ((null current-line-y)
             (push span current-line-spans)
             (setf current-line-y span-y))

            ;; Same line
            ((<= (abs (- span-y current-line-y)) y-tolerance)
             (push span current-line-spans))

            ;; New line
            (t
             (flush-line)
             (push span current-line-spans)
             (setf current-line-y span-y)))))

      (flush-line))
    (nreverse lines)))

(defun cluster-lines-into-blocks (line-data &key (vertical-gap-threshold 20.0)
                                                  (horizontal-overlap-threshold 0.5))
  "Cluster lines into text blocks.

   A block is a group of vertically adjacent lines that form a paragraph
   or other logical unit.

   Args:
     line-data: List of (spans-list line-bbox) from cluster-spans-into-lines
     vertical-gap-threshold: Max gap between lines to be in same block
     horizontal-overlap-threshold: Min horizontal overlap ratio (0-1)

   Returns: List of block data: ((lines-list block-bbox) ...)"
  (when (null line-data)
    (return-from cluster-lines-into-blocks nil))

  (let ((blocks '())
        (current-block-lines '())
        (current-block-bbox nil))

    (flet ((flush-block ()
             (when current-block-lines
               (push (list (nreverse current-block-lines) current-block-bbox) blocks)
               (setf current-block-lines nil
                     current-block-bbox nil)))

           (lines-horizontally-overlap-p (bbox1 bbox2)
             (let* ((x1-start (orchestrator.layout-types:bbox-x bbox1))
                    (x1-end (+ x1-start (orchestrator.layout-types:bbox-width bbox1)))
                    (x2-start (orchestrator.layout-types:bbox-x bbox2))
                    (x2-end (+ x2-start (orchestrator.layout-types:bbox-width bbox2)))
                    (overlap-start (max x1-start x2-start))
                    (overlap-end (min x1-end x2-end))
                    (overlap (max 0 (- overlap-end overlap-start)))
                    (min-width (min (- x1-end x1-start) (- x2-end x2-start))))
               (if (zerop min-width)
                   nil
                   (>= (/ overlap min-width) horizontal-overlap-threshold)))))

      (dolist (line line-data)
        (let ((line-bbox (second line)))
          (cond
            ;; First line
            ((null current-block-bbox)
             (push line current-block-lines)
             (setf current-block-bbox line-bbox))

            ;; Check if should join block
            ((let* ((block-bottom (orchestrator.layout-types:bbox-y current-block-bbox))
                    (line-top (+ (orchestrator.layout-types:bbox-y line-bbox)
                                 (orchestrator.layout-types:bbox-height line-bbox)))
                    (gap (- block-bottom line-top)))
               (and (<= gap vertical-gap-threshold)
                    (lines-horizontally-overlap-p current-block-bbox line-bbox)))
             (push line current-block-lines)
             (setf current-block-bbox (bbox-union current-block-bbox line-bbox)))

            ;; Start new block
            (t
             (flush-block)
             (push line current-block-lines)
             (setf current-block-bbox line-bbox)))))

      (flush-block))
    (nreverse blocks)))

(defun extract-page-layout (pdf-path page-number)
  "Extract layout graph for a single page.

   This is the core Layer 1 function that transforms PDF content
   into a structured layout-page object with full traceability.

   Args:
     pdf-path: Path to PDF file
     page-number: Page index (0-based)

   Returns: layout-page object"

  (unless (ensure-poppler-loaded)
    (error 'pdf-layout-error
           :message "libpoppler-glib not available for layout extraction"
           :path pdf-path
           :page-number page-number))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  (let ((uri (path-to-uri pdf-path))
        (document nil)
        (source-file (namestring (truename pdf-path))))

    (unwind-protect
        (with-foreign-object (gerror-ptr :pointer)
          (setf (mem-ref gerror-ptr :pointer) (null-pointer))

          (setf document (poppler-document-new-from-file uri (null-pointer) gerror-ptr))

          (when (null-pointer-p document)
            (error 'pdf-open-error
                   :message "Cannot open PDF for layout extraction"
                   :path pdf-path))

          (let ((n-pages (poppler-document-get-n-pages document)))
            (unless (and (>= page-number 0) (< page-number n-pages))
              (error 'pdf-layout-error
                     :message (format nil "Page ~D out of range (0-~D)"
                                      page-number (1- n-pages))
                     :path pdf-path
                     :page-number page-number))

            (let ((page (poppler-document-get-page document page-number)))
              (if (null-pointer-p page)
                  (error 'pdf-layout-error
                         :message "Failed to get page"
                         :path pdf-path
                         :page-number page-number)

                  (unwind-protect
                      (with-foreign-objects ((width-ptr :double)
                                             (height-ptr :double))
                        (poppler-page-get-size page width-ptr height-ptr)
                        (let* ((page-width (coerce (mem-ref width-ptr :double) 'single-float))
                               (page-height (coerce (mem-ref height-ptr :double) 'single-float))
                               ;; Extract character rectangles
                               (char-rects (extract-character-rects page))
                               ;; Cluster into spans
                               (span-data (cluster-chars-into-spans char-rects))
                               ;; Cluster into lines
                               (line-data (cluster-spans-into-lines span-data))
                               ;; Cluster into blocks
                               (block-data (cluster-lines-into-blocks line-data))
                               ;; Build layout structures
                               (layout-blocks
                                 (loop for (lines-data block-bbox) in block-data
                                       for block-idx from 0
                                       collect
                                       (let ((layout-lines
                                               (loop for (spans-data line-bbox) in lines-data
                                                     for line-idx from 0
                                                     collect
                                                     (let ((layout-spans
                                                             (loop for (text bbox) in spans-data
                                                                   collect
                                                                   (make-layout-span
                                                                    :text text
                                                                    :bbox bbox
                                                                    :source-file source-file
                                                                    :page-number page-number))))
                                                       (make-layout-line
                                                        :spans layout-spans
                                                        :reading-order line-idx
                                                        :source-file source-file
                                                        :page-number page-number)))))
                                         (make-layout-block
                                          :lines layout-lines
                                          :reading-order block-idx
                                          :source-file source-file
                                          :page-number page-number)))))
                          ;; Compute reading order with column detection
                          (compute-reading-order layout-blocks
                                                 :page-height page-height
                                                 :page-width page-width)
                          ;; Build page
                          (make-layout-page
                           :page-number page-number
                           :blocks layout-blocks
                           :width page-width
                           :height page-height
                           :source-file source-file)))
                    (g-object-unref page))))))

      (when (and document (not (null-pointer-p document)))
        (g-object-unref document)))))

(defun extract-page-layout-with-text (pdf-path page-number)
  "Extract layout graph and full text for a page.

   Returns: (values layout-page full-text-string)"
  (let ((layout (extract-page-layout pdf-path page-number))
        (text (extract-page-text pdf-path page-number)))
    (values layout text)))

(defun extract-layout-graph (pdf-path)
  "Extract complete layout graph for entire PDF document.

   This is the main entry point for Layer 1 of the PDF parser pipeline.
   Returns a layout-document containing all pages as layout-page objects.

   Args:
     pdf-path: Path to PDF file

   Returns:
     layout-document with full hierarchy:
       document → pages → blocks → lines → spans

   Each element has:
     - Unique ID
     - Bounding box
     - Trace information (source file, page, coordinates)"

  (unless (ensure-poppler-loaded)
    (error 'pdf-layout-error
           :message "libpoppler-glib not available for layout extraction"
           :path pdf-path))

  (unless (probe-file pdf-path)
    (error 'pdf-not-found
           :message "PDF file not found"
           :path pdf-path))

  ;; Reset counters for fresh IDs
  (reset-layout-counters)

  (let ((n-pages (get-page-count pdf-path))
        (source-file (namestring (truename pdf-path)))
        (pages '()))

    ;; Extract each page
    (dotimes (i n-pages)
      (handler-case
          (push (extract-page-layout pdf-path i) pages)
        (pdf-layout-error (e)
          (warn "Failed to extract layout for page ~D: ~A" i e)
          ;; Create empty page placeholder
          (push (make-layout-page
                 :page-number i
                 :blocks '()
                 :source-file source-file)
                pages))))

    ;; Build document
    (make-layout-document
     :source-file source-file
     :pages (nreverse pages))))

;;; ============================================================================
;;; OCR FALLBACK — σαρωμένα PDF χωρίς text layer (tesseract + ελληνικά)
;;; ============================================================================
;;;
;;; Η poppler διαβάζει ΜΟΝΟ το text layer· οι υπογεγραμμένες/σαρωμένες
;;; αποφάσεις είναι εικόνες. Εδώ ζει η ΜΙΑ κλιμάκωση: σελίδες -> PNG
;;; (pdftoppm) -> tesseract -l ell. Εξωτερικά εργαλεία, δηλωμένα: αν λείπουν,
;;; ο καλών το μαθαίνει ρητά (ocr-available-p) — ποτέ σιωπηλή αποτυχία.

(defun ocr-available-p ()
  "Υπάρχουν τα εργαλεία OCR (pdftoppm + tesseract με ελληνικά);"
  (handler-case
      (and (zerop (nth-value 2 (uiop:run-program '("which" "pdftoppm")
                                                 :ignore-error-status t)))
           (zerop (nth-value 2 (uiop:run-program '("which" "tesseract")
                                                 :ignore-error-status t)))
           (search "ell" (uiop:run-program '("tesseract" "--list-langs")
                                           :output :string
                                           :error-output :output
                                           :ignore-error-status t)))
    (error () nil)))

(defun extract-text-via-ocr (pdf-path &key (lang "ell") (dpi 300))
  "Κείμενο σαρωμένου PDF μέσω OCR: κάθε σελίδα σε PNG (pdftoppm) και μετά
   tesseract. Επιστρέφει το συνενωμένο κείμενο ή NIL αν το OCR δεν είναι
   διαθέσιμο/αποτύχει — ο καλών αποφασίζει τίμια τι δηλώνει."
  (unless (ocr-available-p) (return-from extract-text-via-ocr nil))
  (let ((dir (format nil "/tmp/lawmax-ocr-~D/" (get-universal-time))))
    (unwind-protect
         (handler-case
             (progn
               (ensure-directories-exist dir)
               (uiop:run-program
                (list "pdftoppm" "-r" (princ-to-string dpi) "-png"
                      (namestring pdf-path) (concatenate 'string dir "page"))
                :ignore-error-status nil)
               (let ((pages (sort (uiop:directory-files dir "*.png") #'string<
                                  :key #'namestring)))
                 (when pages
                   (with-output-to-string (out)
                     (dolist (png pages)
                       (write-string
                        (uiop:run-program
                         (list "tesseract" (namestring png) "stdout" "-l" lang)
                         :output :string :error-output nil)
                        out)
                       (terpri out))))))
           (error () nil))
      (ignore-errors (uiop:delete-directory-tree (pathname dir) :validate t)))))

(defun extract-text-any (pdf-path &key (min-chars 600))
  "(values κείμενο πηγή): το κείμενο του PDF από το text layer, και αν αυτό
   είναι κοντύτερο από MIN-CHARS (σαρωμένο), από OCR. ΠΗΓΗ = :text-layer |
   :ocr | :none — ο καλών ξέρει ΠΑΝΤΑ από πού ήρθε το κείμενο. Η ΜΙΑ
   υλοποίηση ανάγνωσης PDF-εγγράφου του συστήματος."
  (let ((text (extract-text-from-pdf (namestring pdf-path))))
    (if (>= (length text) min-chars)
        (values text :text-layer)
        (let ((ocr (extract-text-via-ocr pdf-path)))
          (if (and ocr (>= (length ocr) min-chars))
              (values ocr :ocr)
              (values (if (and ocr (> (length ocr) (length text))) ocr text)
                      :none))))))

;;; ============================================================================
;;; END OF PDF-AUTHORITY.LISP
;;; ============================================================================
