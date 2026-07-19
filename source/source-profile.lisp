;;;; source/source-profile.lisp
;;;; ============================================================================
;;;; SOURCE AUTHORITY  —  ranked acquisition channels + multi-source consensus
;;;; ============================================================================
;;;;
;;;; "Πώς ενημερώνεται αυτόματα το σύστημα;" — the answer is NOT "scrape better".
;;;; The answer is an acquisition layer that knows WHERE authoritative text comes
;;;; from, RANKS those channels by how authoritative each one is, and never trusts
;;;; a single fragile scrape when a higher channel can confirm it.
;;;;
;;;; Every way the corpus can learn of a new/amended provision is modelled as a
;;;; SOURCE PROFILE. Each profile belongs to a CHANNEL whose AUTHORITY is carried
;;;; on the metaclass (CLOS + MOP), so the ranking is declarative and discoverable:
;;;;
;;;;   :institutional-feed  100   official ΦΕΚ stream (National Printing House)   ← top
;;;;   :open-data-api        80   data.gov.gr / Διαύγεια opendata (contract API)
;;;;   :eu-cellar            70   EUR-Lex / CELLAR (native Akoma Ntoso / ELI)
;;;;   :web-scraper          40   HTML/headless scrape (fragile, non-redistributable)
;;;;   :manual-drop          20   a human-placed file (last resort)
;;;;
;;;; The acquisition is PLUGGABLE: each profile wraps an injected acquirer, so the
;;;; existing government/EU feeds become backends without change, and the day a
;;;; sanctioned ΦΕΚ feed is granted, only the :institutional-feed backend is
;;;; configured — nothing else in the pipeline moves.
;;;;
;;;;   select-source            the highest-authority AVAILABLE profile
;;;;   acquire                  a profile -> provenance-stamped acquired-records
;;;;   acquire-with-consensus   gather every channel, then per logical provision:
;;;;                              · one source / all agree   -> TRUSTED (provenance)
;;;;                              · an official source beats a lower one -> override
;;;;                              · genuine disagreement      -> CONFLICT -> review
;;;;
;;;; This is the "ανώτερο": automatic where the channels agree, human-in-the-loop
;;;; exactly where they do not. Pure Common Lisp, deterministic, no network at load
;;;; time, degrades gracefully when a channel is unreachable.
;;;; ============================================================================

(defpackage :orchestrator.source-authority
  (:use :cl)
  (:export
   ;; metaclass + base + channel taxonomy (MOP)
   #:source-profile-class #:source-profile #:define-source-channel #:source-channels
   #:profile-channel #:profile-authority #:profile-redistributable-p
   ;; instance api
   #:make-source-profile #:profile-name #:profile-enabled-p #:profile-available-p
   #:acquire #:source-acquirer
   ;; provenance-stamped records
   #:acquired-record #:make-acquired-record #:acquired-record-p
   #:record-identity #:record-content #:record-payload #:record-source-name
   #:record-channel #:record-authority #:record-fetched-at #:record-content-hash
   #:record-provenance #:record-consensus #:record-corroboration #:record-overrode
   ;; registry + selection
   #:register-profile #:registered-profiles #:clear-registry #:select-source
   ;; consensus
   #:*auto-trust-authority* #:acquire-with-consensus
   #:consensus-conflict #:consensus-conflict-p
   #:conflict-identity #:conflict-candidates #:conflict-reason
   #:consensus-conflicts->review-items
   ;; concrete backends (adapters over the existing feeds)
   #:make-institutional-profile #:make-open-data-profile #:make-eu-cellar-profile
   #:make-scraper-profile #:make-manual-profile #:default-source-profiles
   ;; daemon integration
   #:make-consensus-source))

(in-package :orchestrator.source-authority)

;;; ----------------------------------------------------------------------------
;;; MOP: a metaclass carrying each channel's CHANNEL keyword, AUTHORITY rank and
;;; whether the channel is legally REDISTRIBUTABLE.
;;; ----------------------------------------------------------------------------

(defclass source-profile-class (standard-class)
  ((channel         :initform :generic :accessor class-channel)
   (authority       :initform 0        :accessor class-authority)
   (redistributable :initform t        :accessor class-redistributable))
  (:documentation "Metaclass for source profiles; carries the channel keyword, its
   authority rank and redistributability so selection/consensus are declarative."))

(defmethod closer-mop:validate-superclass
    ((class source-profile-class) (super standard-class)) t)
(defmethod closer-mop:validate-superclass
    ((class standard-class) (super source-profile-class)) t)

;;; ----------------------------------------------------------------------------
;;; deterministic timestamp (shared %now pattern; no hard time coupling)
;;; ----------------------------------------------------------------------------

(defun %now ()
  "Provenance timestamp via the single time authority (deterministic when enabled).
   Fail-closed: returns a genuine RFC3339 stamp or the call errors — never a
   fabricated epoch masquerading as the acquisition time."
  (orchestrator.time:get-rfc3339-timestamp))

;;; ----------------------------------------------------------------------------
;;; base profile
;;; ----------------------------------------------------------------------------

(defclass source-profile ()
  ((name         :initarg :name :accessor profile-name :initform "source")
   (acquirer     :initarg :acquirer :accessor source-acquirer :initform nil
                 :documentation "(function (since-iso-or-nil) -> list of acquired
                  things), each an acquired-record or a (:identity :content
                  :payload) plist that ACQUIRE stamps with provenance.")
   (enabled      :initarg :enabled :accessor profile-enabled-p :initform t)
   (available-fn :initarg :available-fn :accessor profile-available-fn :initform nil
                 :documentation "Optional (function () -> boolean) reachability
                  probe; NIL means 'available whenever enabled + acquirer set'."))
  (:metaclass source-profile-class)
  (:documentation "One configured way to acquire authoritative legal text."))

(defgeneric profile-channel (p)
  (:method ((p source-profile)) (class-channel (class-of p))))
(defgeneric profile-authority (p)
  (:method ((p source-profile)) (class-authority (class-of p))))
(defgeneric profile-redistributable-p (p)
  (:method ((p source-profile)) (class-redistributable (class-of p))))

(defgeneric profile-available-p (p)
  (:documentation "Whether P can acquire right now: enabled, has an acquirer, and
   its reachability probe (if any) passes. Never throws.")
  (:method ((p source-profile))
    (and (profile-enabled-p p)
         (source-acquirer p)
         (if (profile-available-fn p)
             (handler-case (and (funcall (profile-available-fn p)) t) (error () nil))
             t)
         t)))

;;; ----------------------------------------------------------------------------
;;; declarative channel taxonomy  (mirrors define-review-kind)
;;; ----------------------------------------------------------------------------

(defmacro define-source-channel (name (channel authority redistributable) &optional doc)
  "Define source-profile subclass NAME for CHANNEL with AUTHORITY rank and
   REDISTRIBUTABLE flag (all stored on the metaclass)."
  `(progn
     (defclass ,name (source-profile) () (:metaclass source-profile-class))
     (setf (class-channel (find-class ',name)) ,channel
           (class-authority (find-class ',name)) ,authority
           (class-redistributable (find-class ',name)) ,redistributable)
     ,@(when doc `((setf (documentation (find-class ',name) 'type) ,doc)))
     ',name))

(define-source-channel institutional-source (:institutional-feed 100 t)
  "Sanctioned bulk feed from the National Printing House (ΦΕΚ) — the authentic
   source. The highest channel; eliminates extraction patches at the root.")
(define-source-channel open-data-source (:open-data-api 80 t)
  "Government open-data API under a usage contract (data.gov.gr / Διαύγεια).")
(define-source-channel eu-cellar-source (:eu-cellar 70 t)
  "EUR-Lex / CELLAR — native Akoma Ntoso / ELI feed (no extraction).")
(define-source-channel web-scraper-source (:web-scraper 40 nil)
  "HTML / headless-browser scrape — fragile and legally grey; fallback only.")
(define-source-channel manual-source (:manual-drop 20 t)
  "A human-placed file in a watched directory — last-resort acquisition.")

(defun source-channels ()
  "All registered channel keywords, discovered via the MOP."
  (mapcar #'class-channel
          (closer-mop:class-direct-subclasses (find-class 'source-profile))))

(defun %channel->class (channel)
  (find-if (lambda (c) (eq (class-channel c) channel))
           (closer-mop:class-direct-subclasses (find-class 'source-profile))))

(defun make-source-profile (channel &key name acquirer (enabled t) available-fn)
  "Make a profile on CHANNEL (a channel keyword), wrapping ACQUIRER."
  (let ((class (or (%channel->class channel)
                   (error "Unknown source channel ~S (known: ~{~A~^ ~})"
                          channel (source-channels)))))
    (make-instance class :name (or name (string-downcase (symbol-name channel)))
                         :acquirer acquirer :enabled enabled :available-fn available-fn)))

;;; ----------------------------------------------------------------------------
;;; provenance-stamped acquired records
;;; ----------------------------------------------------------------------------

(defstruct (acquired-record (:conc-name record-))
  "A unit of acquired text with its full provenance and consensus disposition."
  (identity nil)            ; logical key of the provision (law/act/article id)
  (content nil)             ; the value compared for agreement across sources
  (payload nil)             ; the opaque thing to act on downstream
  (source-name nil)
  (channel nil)
  (authority 0)
  (fetched-at nil)
  (content-hash nil)
  (consensus nil)           ; :sole | :agreed | :authority-override (when trusted)
  (corroboration nil)       ; source names that independently agreed
  (overrode nil))           ; provenance of lower sources this one overrode

(defun record-provenance (r)
  "A serializable provenance summary of acquired-record R."
  (list :source (record-source-name r) :channel (record-channel r)
        :authority (record-authority r) :fetched-at (record-fetched-at r)
        :content-hash (record-content-hash r)))

;;; ----------------------------------------------------------------------------
;;; canonical content + content hash  (deterministic agreement comparison)
;;; ----------------------------------------------------------------------------

(defun %plist-like-p (x)
  (and (consp x) (evenp (length x))
       (loop for (k nil) on x by #'cddr always (keywordp k))))

(defun %alist-like-p (x)
  (and (consp x) (every #'consp x)
       (every (lambda (e) (or (stringp (car e)) (symbolp (car e)))) x)))

(defun %canonical (x)
  "A deterministic, order-stable string rendering of X for cross-source equality.
   plists/alists are sorted by key so two sources that report the same facts in a
   different field order still compare equal."
  (cond
    ((null x) "()")
    ((stringp x) (format nil "~S" x))
    ((keywordp x) (format nil ":~A" (symbol-name x)))
    ((symbolp x) (symbol-name x))
    ((numberp x) (princ-to-string x))
    ((%plist-like-p x)
     (let ((pairs (loop for (k v) on x by #'cddr
                        collect (cons (symbol-name k) (%canonical v)))))
       (format nil "{~{~A~^ ~}}"
               (loop for (k . v) in (sort pairs #'string< :key #'car)
                     collect (format nil "~A=~A" k v)))))
    ((%alist-like-p x)
     (let ((pairs (loop for e in x
                        collect (cons (princ-to-string (car e)) (%canonical (cdr e))))))
       (format nil "{~{~A~^ ~}}"
               (loop for (k . v) in (sort pairs #'string< :key #'car)
                     collect (format nil "~A=~A" k v)))))
    ((consp x) (format nil "(~{~A~^ ~})" (mapcar #'%canonical x)))
    (t (format nil "~S" x))))

(defun %content-hash (content)
  "SHA-256 (hex) of CONTENT's canonical form via the single hash authority.
   Fail-closed: a content-hash is ALWAYS a genuine digest or the call errors —
   never the raw canonical string masquerading as a hash. Both authorities load
   before this file in the same serial system, so they are guaranteed present."
  (orchestrator.hash-authority:compute-hash (%canonical content) :algorithm :sha256))

;;; ----------------------------------------------------------------------------
;;; acquire (one profile)
;;; ----------------------------------------------------------------------------

(defun %stamp (profile thing)
  "Turn THING (an acquired-record or a (:identity :content :payload) plist) into a
   provenance-stamped acquired-record for PROFILE."
  (if (acquired-record-p thing)
      thing
      (let* ((id (getf thing :identity))
             (content (getf thing :content (getf thing :payload)))
             (payload (getf thing :payload content)))
        (make-acquired-record
         :identity (and id (princ-to-string id))
         :content content
         :payload payload
         :source-name (profile-name profile)
         :channel (profile-channel profile)
         :authority (profile-authority profile)
         :fetched-at (%now)
         :content-hash (%content-hash content)))))

(defun acquire (profile &optional since)
  "Acquire from PROFILE every provision newer than SINCE, as provenance-stamped
   acquired-records. Returns NIL when the profile is unavailable or the fetch
   fails — never throws, so a daemon keeps running."
  (when (profile-available-p profile)
    (let ((raw (handler-case (funcall (source-acquirer profile) since)
                 (error () nil))))
      (loop for thing in raw collect (%stamp profile thing)))))

;;; ----------------------------------------------------------------------------
;;; registry + selection
;;; ----------------------------------------------------------------------------

(defvar *registry* '()
  "Ordered list of configured profiles (the acquisition stack).")

(defun clear-registry () (setf *registry* '()))

(defun register-profile (p)
  "Register profile P (replacing any same-named one), preserving order. Returns P."
  (setf *registry*
        (append (remove (profile-name p) *registry* :key #'profile-name :test #'equal)
                (list p)))
  p)

(defun registered-profiles () (copy-list *registry*))

(defun %by-authority (profiles)
  "PROFILES sorted by authority descending, name ascending (deterministic)."
  (stable-sort (copy-list profiles)
               (lambda (a b)
                 (cond ((> (profile-authority a) (profile-authority b)) t)
                       ((< (profile-authority a) (profile-authority b)) nil)
                       (t (string< (profile-name a) (profile-name b)))))))

(defun select-source (profiles)
  "The single highest-authority AVAILABLE profile in PROFILES (or NIL)."
  (first (%by-authority (remove-if-not #'profile-available-p profiles))))

;;; ----------------------------------------------------------------------------
;;; multi-source consensus
;;; ----------------------------------------------------------------------------

(defparameter *auto-trust-authority* 80
  "The authority at which a single source is trusted OVER a strictly lower
   disagreeing source without human review (open-data feed and above auto-win over
   web scrapers and manual drops). Below it, ANY disagreement goes to a lawyer.
   Default trusts official channels; never auto-trusts a scraper over another.")

(defstruct (consensus-conflict (:conc-name conflict-))
  "A provision where sources DISAGREE and no authoritative tie-break applies — it
   must be confirmed by a human, never silently resolved."
  (identity nil)
  (candidates nil)          ; the disagreeing acquired-records
  (reason :disagreement))

(defun %group-by-identity (records)
  "Group RECORDS by logical identity, preserving first-seen order."
  (let ((h (make-hash-table :test 'equal)) (order '()))
    (dolist (r records)
      (let ((k (or (record-identity r) "")))
        (unless (nth-value 1 (gethash k h)) (push k order) (setf (gethash k h) '()))
        (push r (gethash k h))))
    (loop for k in (nreverse order)
          collect (cons k (nreverse (gethash k h))))))

(defun %max-authority (records)
  "The highest-authority record (ties broken by source name, deterministic)."
  (first (%by-authority-records records)))

(defun %by-authority-records (records)
  (stable-sort (copy-list records)
               (lambda (a b)
                 (cond ((> (record-authority a) (record-authority b)) t)
                       ((< (record-authority a) (record-authority b)) nil)
                       (t (string< (or (record-source-name a) "")
                                   (or (record-source-name b) "")))))))

(defun %resolve-group (identity records auto-trust)
  "Decide one provision. Returns (values trusted-record-or-nil conflict-or-nil)."
  (let ((distinct (remove-duplicates (mapcar #'record-content-hash records)
                                     :test #'equal)))
    (cond
      ;; AGREEMENT (one source, or every source reports the same text)
      ((= 1 (length distinct))
       (let* ((best (%max-authority records))
              (others (remove best records)))
         (setf (record-consensus best) (if others :agreed :sole)
               (record-corroboration best)
               (sort (mapcar #'record-source-name others) #'string<))
         (values best nil)))
      ;; DISAGREEMENT — let an official source override strictly-lower ones
      (t
       (let* ((sorted (%by-authority-records records))
              (top (first sorted))
              (next (second sorted)))
         (if (and (>= (record-authority top) auto-trust)
                  next (> (record-authority top) (record-authority next)))
             (progn
               (setf (record-consensus top) :authority-override
                     (record-overrode top)
                     (mapcar #'record-provenance (remove top records)))
               (values top nil))
             (values nil (make-consensus-conflict
                          :identity identity :candidates records
                          :reason :disagreement))))))))

(defun acquire-with-consensus (profiles &key since (auto-trust *auto-trust-authority*))
  "Acquire from every available profile in PROFILES, then reconcile per provision.
   Returns (values TRUSTED CONFLICTS): TRUSTED are provenance-rich acquired-records
   safe to apply automatically (sole/agreed/authority-override); CONFLICTS are
   genuine disagreements for human review."
  (let ((records (loop for p in profiles append (acquire p since)))
        (trusted '()) (conflicts '()))
    (dolist (group (%group-by-identity records))
      (multiple-value-bind (tr cf) (%resolve-group (car group) (cdr group) auto-trust)
        (when tr (push tr trusted))
        (when cf (push cf conflicts))))
    (values (nreverse trusted) (nreverse conflicts))))

;;; ----------------------------------------------------------------------------
;;; integration: a disagreement becomes a review item (human confirms the text)
;;; ----------------------------------------------------------------------------

(defun %conflict-sources (conflict)
  (format nil "~{~A~^, ~}"
          (sort (remove nil (mapcar #'record-source-name (conflict-candidates conflict)))
                #'string<)))

(defun consensus-conflicts->review-items (conflicts &key source)
  "Turn each CONFLICT into a high-severity source-conflict review item (via the
   review queue's CLOS machinery, when loaded), so a lawyer confirms the
   authoritative text. Returns NIL when the review module is unavailable."
  (let ((class (and (find-package :orchestrator.review)
                    (let ((s (find-symbol "SOURCE-CONFLICT-REVIEW" :orchestrator.review)))
                      (and s (find-class s nil))))))
    (when class
      (loop for c in conflicts
            collect (make-instance
                     class
                     :source (or source (%conflict-sources c))
                     :target (conflict-identity c)
                     :confidence :low
                     :payload (list :reason (conflict-reason c)
                                    :candidates (mapcar #'record-provenance
                                                        (conflict-candidates c))))))))

;;; ----------------------------------------------------------------------------
;;; concrete backends — adapters over the EXISTING government / EU feeds
;;; (defensive find-symbol: this layer never hard-depends on a network module)
;;; ----------------------------------------------------------------------------

(defun %ii (item accessor)
  "Read ACCESSOR (a string symbol name) off an ingest-item, defensively."
  (let ((fn (find-symbol accessor :orchestrator.ingestion)))
    (and fn (fboundp fn) (funcall fn item))))

(defun %ingest-item->plist (item)
  "Adapt an orchestrator.ingestion:ingest-item into an acquire plist."
  (let ((payload (%ii item "INGEST-ITEM-PAYLOAD")))
    (list :identity (%ii item "INGEST-ITEM-ID")
          :content (or payload (%ii item "INGEST-ITEM-TITLE"))
          :payload payload)))

(defun %feed->records (feed-source since)
  "Pull from an orchestrator.ingestion source struct and adapt its items."
  (let ((fetch (find-symbol "FETCH-ITEMS" :orchestrator.ingestion)))
    (when (and fetch (fboundp fetch) feed-source)
      (loop for it in (funcall fetch feed-source since)
            collect (%ingest-item->plist it)))))

(defun %dir->records (dir)
  "One acquire plist per file dropped in DIR (identity/content = file name)."
  (loop for f in (sort (mapcar #'namestring
                               (ignore-errors (directory (merge-pathnames "*.*" dir))))
                       #'string<)
        for name = (file-namestring f)
        collect (list :identity name :content name :payload f)))

(defun make-institutional-profile (&key (name "official-fek-feed") feed-url feed-dir)
  "The TOP channel: a sanctioned ΦΕΚ feed. Configure FEED-DIR (a watched directory
   of official files) or FEED-URL (an official JSON/HTML feed). With neither set
   the profile is correctly UNAVAILABLE and the stack falls back to lower channels;
   granting the feed configures ONLY this backend, nothing else in the pipeline."
  (let* ((mk (and feed-url (find-package :orchestrator.gov-source)
                  (find-symbol "MAKE-FEED-SOURCE" :orchestrator.gov-source)))
         (src (and mk (fboundp mk)
                   (funcall mk :name name :url feed-url :format :json
                               :id-key "id" :date-key "date" :title-key "title"))))
    (make-source-profile
     :institutional-feed :name name
     :available-fn (lambda () (and (or feed-dir src) t))
     :acquirer (cond (feed-dir (lambda (since) (declare (ignore since))
                                 (%dir->records feed-dir)))
                     (src (lambda (since) (%feed->records src since)))
                     (t nil)))))

(defun make-open-data-profile (&key (name "diavgeia") types)
  "Government open-data channel (Διαύγεια opendata API)."
  (let* ((mk (and (find-package :orchestrator.gov-source)
                  (find-symbol "MAKE-DIAVGEIA-SOURCE" :orchestrator.gov-source)))
         (src (and mk (fboundp mk) (if types (funcall mk :types types) (funcall mk)))))
    (make-source-profile
     :open-data-api :name name
     :available-fn (lambda () (and src (find-package :drakma) t))
     :acquirer (when src (lambda (since) (%feed->records src since))))))

(defun make-eu-cellar-profile (&key (name "eu-cellar") eli)
  "EUR-Lex / CELLAR channel: the expressions of the work identified by ELI
   (native Akoma Ntoso / ELI — no PDF extraction)."
  (let ((search (and (find-package :orchestrator.eu-interop)
                     (find-symbol "SEARCH-CELLAR-BY-ELI" :orchestrator.eu-interop))))
    (make-source-profile
     :eu-cellar :name name
     :available-fn (lambda () (and search (fboundp search) eli (find-package :drakma) t))
     :acquirer (when (and search (fboundp search) eli)
                 (lambda (since) (declare (ignore since))
                   (let ((res (ignore-errors (funcall search eli))))
                     (when res (list (list :identity eli :content res :payload res)))))))))

(defun make-scraper-profile (&key (name "fek-scraper") url (enabled nil))
  "Web-scraper channel over the ΦΕΚ search page. DISABLED by default: it is the
   fragile, legally grey fallback, enabled explicitly only when no higher channel
   is available."
  (let* ((mk (and (find-package :orchestrator.gov-source)
                  (find-symbol "MAKE-FEK-SOURCE" :orchestrator.gov-source)))
         (src (and mk (fboundp mk) (if url (funcall mk :url url) (funcall mk)))))
    (make-source-profile
     :web-scraper :name name :enabled enabled
     :available-fn (lambda () (and src (find-package :drakma) t))
     :acquirer (when src (lambda (since) (%feed->records src since))))))

(defun make-manual-profile (&key (name "manual-drop") (dir #p"input/"))
  "Manual-drop channel: files a human places in DIR (last resort, lowest authority,
   used mainly to corroborate higher channels)."
  (make-source-profile
   :manual-drop :name name
   :available-fn (lambda () (and dir (ignore-errors (probe-file dir)) t))
   :acquirer (lambda (since) (declare (ignore since)) (%dir->records dir))))

(defun default-source-profiles
    (&key fek-feed-url fek-feed-dir eli (diavgeia t) (scrape nil)
          (manual t) (manual-dir #p"input/"))
  "The full acquisition stack, highest authority first. Unconfigured channels are
   simply UNAVAILABLE and skipped by selection/consensus. Set FEK-FEED-URL/DIR to
   add the sanctioned top channel without touching the rest of the pipeline."
  (remove nil
          (list (make-institutional-profile :feed-url fek-feed-url :feed-dir fek-feed-dir)
                (when diavgeia (make-open-data-profile))
                (when eli (make-eu-cellar-profile :eli eli))
                (when scrape (make-scraper-profile :enabled t))
                (when manual (make-manual-profile :dir manual-dir)))))

;;; ----------------------------------------------------------------------------
;;; daemon integration: the consensus stack AS a single ingestion source
;;; ----------------------------------------------------------------------------

(defun make-consensus-source (&key (name "consensus") profiles
                                   (auto-trust *auto-trust-authority*) on-conflict)
  "Wrap PROFILES (default: the full ranked stack) into a single
   orchestrator.ingestion SOURCE that the existing daemon already understands —
   no change to its contract. Each poll runs multi-source consensus: TRUSTED
   provisions become ingest-items (the daemon consolidates + re-emits them), and
   any genuine disagreement is handed to ON-CONFLICT (a (function (conflicts))
   that e.g. enqueues review items) instead of being published. Returns NIL when
   the ingestion package is unavailable."
  (let ((mk-src (and (find-package :orchestrator.ingestion)
                     (find-symbol "MAKE-INGESTION-SOURCE" :orchestrator.ingestion)))
        (mk-item (and (find-package :orchestrator.ingestion)
                      (find-symbol "MAKE-INGEST-ITEM" :orchestrator.ingestion)))
        (profs (or profiles (default-source-profiles))))
    (when (and mk-src mk-item (fboundp mk-src) (fboundp mk-item))
      (funcall
       mk-src
       :name name
       :fetcher
       (lambda (since)
         (multiple-value-bind (trusted conflicts)
             (acquire-with-consensus profs :since since :auto-trust auto-trust)
           (when (and on-conflict conflicts)
             (ignore-errors (funcall on-conflict conflicts)))
           (loop for r in trusted
                 collect (funcall mk-item
                                  :id (record-identity r)
                                  :title (record-identity r)
                                  :date (record-fetched-at r)
                                  :source-uri (record-source-name r)
                                  :kind "consensus"
                                  :payload (record-payload r)))))))))
