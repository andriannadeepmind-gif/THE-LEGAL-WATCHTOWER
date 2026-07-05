;;;; SEMANTIC-VERSIONING-SYSTEM.LISP
;;;; Advanced Versioning with PROV-O, ELI, and Semantic Diffs
;;;; World-class implementation for legal corpus versioning

(defpackage :orchestrator.semantic-versioning
  (:use :cl :local-time :ironclad)
  (:export #:corpus-version
           #:compute-text-diff
           #:create-version
           #:compute-semantic-diff
           #:generate-version-graph
           #:generate-delta-graph
           #:track-article-evolution
           #:version-manager
           #:semantic-anchor
           #:diff-triple
           #:version-lineage))

(in-package :orchestrator.semantic-versioning)

;;; Article accessors live in the canonical model, which is not a compile-time
;;; dependency of this layer; resolve them at runtime (the model is always
;;; loaded in the full system). Article objects flow in from there.
(defun article-title (a)
  (funcall (find-symbol "ARTICLE-TITLE" :orchestrator.model) a))
(defun article-content (a)
  (funcall (find-symbol "ARTICLE-CONTENT" :orchestrator.model) a))
(defun article-metadata (a)
  (funcall (find-symbol "ARTICLE-METADATA" :orchestrator.model) a))

;;; ============================================================================
;;; VERSION ONTOLOGY DEFINITIONS
;;; ============================================================================

(defparameter *versioning-prefixes*
  `(("prov" . "http://www.w3.org/ns/prov#")
    ("eli" . "http://data.europa.eu/eli/ontology#")
    ("dct" . "http://purl.org/dc/terms/")
    ("sem" . "http://semanticweb.cs.vu.nl/2009/11/sem/")
    ("sioc" . "http://rdfs.org/sioc/ns#")
    ("owl" . "http://www.w3.org/2002/07/owl#")
    ("xsd" . "http://www.w3.org/2001/XMLSchema#")
    ("delta" . ,(format nil "~A/ontology/delta#" (or (ignore-errors (orchestrator.uris:get-base-uri)) "https://stavropouloslaw.com"))))
  "Prefixes for versioning RDF")

(defparameter *version-properties*
  '(:prov-was-revision-of "prov:wasRevisionOf"
    :prov-was-derived-from "prov:wasDerivedFrom"
    :prov-generated-at-time "prov:generatedAtTime"
    :prov-invalidated-at-time "prov:invalidatedAtTime"
    :prov-was-attributed-to "prov:wasAttributedTo"
    :prov-was-generated-by "prov:wasGeneratedBy"
    :eli-version "eli:version"
    :eli-version-date "eli:version_date"
    :eli-is-realized-by "eli:is_realized_by"
    :eli-amended-by "eli:amended_by"
    :eli-amends "eli:amends"
    :eli-repealed-by "eli:repealed_by"
    :eli-repeals "eli:repeals"
    :dct-has-version "dct:hasVersion"
    :dct-is-version-of "dct:isVersionOf"
    :dct-replaces "dct:replaces"
    :dct-is-replaced-by "dct:isReplacedBy"
    :dct-valid "dct:valid"
    :dct-date-accepted "dct:dateAccepted"
    :delta-added "delta:added"
    :delta-removed "delta:removed"
    :delta-modified "delta:modified")
  "Version control properties mapping")

;;; ============================================================================
;;; CORE VERSION CLASSES
;;; ============================================================================

(defclass corpus-version ()
  ((version-id :initarg :version-id 
               :accessor version-id
               :type string
               :documentation "Semantic version identifier (e.g., '1.0.0')")
   
   (corpus-uri :initarg :corpus-uri 
               :accessor corpus-uri
               :type string
               :documentation "Base URI of the corpus")
   
   (version-uri :accessor version-uri
                :type string
                :documentation "Full URI for this version")
   
   (previous-version :initarg :previous-version 
                     :accessor previous-version
                     :initform nil
                     :type (or null corpus-version)
                     :documentation "Previous version object")
   
   (timestamp :initarg :timestamp 
              :accessor version-timestamp
              :initform (orchestrator.time:get-current-timestamp)
              :documentation "Version creation timestamp")
   
   (valid-from :initarg :valid-from 
               :accessor valid-from
               :type local-time:timestamp
               :documentation "When this version becomes valid")
   
   (valid-until :initarg :valid-until 
                :accessor valid-until
                :initform nil
                :type (or null local-time:timestamp)
                :documentation "When this version is superseded")
   
   (author :initarg :author 
           :accessor version-author
           :type string
           :documentation "WebID of version author")
   
   (change-note :initarg :change-note 
                :accessor change-note
                :type string
                :documentation "Description of changes")
   
   (activity-uri :accessor activity-uri
                 :type string
                 :documentation "PROV activity that generated this version")
   
   (articles :initarg :articles 
            :accessor version-articles
            :initform (make-hash-table :test 'equal)
            :documentation "Articles in this version")
   
   (metadata :initarg :metadata 
             :accessor version-metadata
             :initform (make-hash-table :test 'equal)
             :documentation "Additional version metadata")
   
   (semantic-anchors :accessor semantic-anchors
                     :initform nil
                     :documentation "List of semantic anchor points")))

(defmethod initialize-instance :after ((version corpus-version) &key)
  "Initialize version URI and activity"
  (setf (version-uri version)
        (format nil "~A/version/~A" 
                (corpus-uri version)
                (version-id version)))
  
  (setf (activity-uri version)
        (format nil "~A/activity/~A-~A"
                (corpus-uri version)
                (version-id version)
                (orchestrator.time:now :source :system))))

(defclass semantic-anchor ()
  ((anchor-id :initarg :anchor-id 
              :accessor anchor-id
              :type string
              :documentation "Unique anchor identifier")
   
   (anchor-type :initarg :anchor-type 
                :accessor anchor-type
                :type keyword
                :documentation "Type: :legislative :judicial :amendment")
   
   (source-uri :initarg :source-uri 
               :accessor source-uri
               :type string
               :documentation "URI of source document")
   
   (target-article :initarg :target-article 
                   :accessor target-article
                   :type integer
                   :documentation "Article number affected")
   
   (change-type :initarg :change-type 
                :accessor change-type
                :type keyword
                :documentation ":addition :modification :deletion :replacement")
   
   (legal-basis :initarg :legal-basis 
                :accessor legal-basis
                :type string
                :documentation "Legal basis for change")
   
   (timestamp :initarg :timestamp 
              :accessor anchor-timestamp
              :initform (orchestrator.time:get-current-timestamp)
              :documentation "When anchor was created")
   
   (hash :accessor anchor-hash
         :type string
         :documentation "Cryptographic hash of anchor")))

(defmethod initialize-instance :after ((anchor semantic-anchor) &key)
  "Compute anchor hash"
  (setf (anchor-hash anchor)
        (compute-anchor-hash anchor)))

(defclass diff-triple ()
  ((subject :initarg :subject 
            :accessor triple-subject
            :type string)
   
   (predicate :initarg :predicate 
              :accessor triple-predicate
              :type string)
   
   (object :initarg :object 
           :accessor triple-object)
   
   (operation :initarg :operation 
              :accessor triple-operation
              :type keyword
              :documentation ":added :removed :modified")
   
   (old-value :initarg :old-value 
              :accessor old-value
              :initform nil
              :documentation "Previous value if modified")
   
   (context :initarg :context 
            :accessor triple-context
            :initform nil
            :documentation "Named graph context")))

(defclass version-lineage ()
  ((root-version :initarg :root-version 
                 :accessor root-version
                 :type corpus-version
                 :documentation "Initial version")
   
   (versions :accessor all-versions
             :initform (make-hash-table :test 'equal)
             :documentation "All versions by ID")
   
   (branches :accessor version-branches
             :initform nil
             :documentation "Branch points in history")
   
   (merges :accessor version-merges
           :initform nil
           :documentation "Merge points in history")
   
   (current-version :accessor current-version
                    :type corpus-version
                    :documentation "Currently active version")))

;;; ============================================================================
;;; VERSION MANAGER
;;; ============================================================================

(defclass version-manager ()
  ((corpus-uri :initarg :corpus-uri 
               :accessor corpus-uri
               :type string)
   
   (lineage :accessor version-lineage
            :type version-lineage)
   
   (diff-cache :accessor diff-cache
               :initform (make-hash-table :test 'equal)
               :documentation "Cached diffs between versions")
   
   (anchor-registry :accessor anchor-registry
                    :initform (make-hash-table :test 'equal)
                    :documentation "All semantic anchors")
   
   (validation-rules :accessor validation-rules
                     :initform nil
                     :documentation "Version validation rules")))

(defmethod create-version ((manager version-manager) 
                          version-id 
                          &key author change-note valid-from articles)
  "Create a new corpus version"
  (log:info () "Creating version ~A" version-id)
  
  (let* ((previous (when (version-lineage manager)
                    (current-version (version-lineage manager))))
         
         (new-version 
          (make-instance 'corpus-version
                        :version-id version-id
                        :corpus-uri (corpus-uri manager)
                        :previous-version previous
                        :author author
                        :change-note change-note
                        :valid-from (or valid-from (orchestrator.time:get-current-timestamp))
                        :articles articles)))
    
    ;; Set previous version's valid-until
    (when previous
      (setf (valid-until previous) (valid-from new-version)))
    
    ;; Add to lineage
    (add-to-lineage manager new-version)
    
    ;; Compute and cache diff
    (when previous
      (let ((diff (compute-semantic-diff previous new-version)))
        (cache-diff manager (version-id previous) version-id diff)))
    
    ;; Generate version graph
    (generate-version-graph new-version)
    
    new-version))

(defmethod add-to-lineage ((manager version-manager) (version corpus-version))
  "Add version to lineage tree"
  (unless (version-lineage manager)
    (setf (version-lineage manager)
          (make-instance 'version-lineage
                        :root-version version)))
  
  (let ((lineage (version-lineage manager)))
    (setf (gethash (version-id version) (all-versions lineage)) version)
    (setf (current-version lineage) version)))

;;; ============================================================================
;;; SEMANTIC DIFF COMPUTATION
;;; ============================================================================

(defgeneric compute-semantic-diff (old-version new-version)
  (:documentation "Compute semantic differences between versions"))

(defmethod compute-semantic-diff ((old corpus-version) (new corpus-version))
  "Compute complete semantic diff between versions"
  (log:info () "Computing semantic diff: ~A -> ~A" 
           (version-id old) (version-id new))
  
  (let* ((diff-triples nil)
         (old-articles (version-articles old))
         (new-articles (version-articles new))
         (all-article-numbers (union (hash-table-keys old-articles)
                                     (hash-table-keys new-articles))))
    
    ;; Process each article
    (dolist (article-num all-article-numbers)
      (let ((old-article (gethash article-num old-articles))
            (new-article (gethash article-num new-articles)))
        
        (cond
          ;; Article added
          ((and (null old-article) new-article)
           (push (make-instance 'diff-triple
                               :subject (article-uri new article-num)
                               :predicate "rdf:type"
                               :object "eli:LegalResource"
                               :operation :added)
                 diff-triples)
           (append-article-triples new-article :added diff-triples))
          
          ;; Article removed
          ((and old-article (null new-article))
           (push (make-instance 'diff-triple
                               :subject (article-uri old article-num)
                               :predicate "eli:repealed"
                               :object "true"
                               :operation :removed)
                 diff-triples)
           (append-article-triples old-article :removed diff-triples))
          
          ;; Article modified
          ((and old-article new-article)
           (let ((article-diff (compute-article-diff old-article new-article)))
             (when article-diff
               (setf diff-triples (append diff-triples article-diff))))))))
    
    diff-triples))

(defun compute-article-diff (old-article new-article)
  "Compute diff for a single article"
  (let ((diffs nil))
    
    ;; Compare title
    (unless (string= (article-title old-article) 
                     (article-title new-article))
      (push (make-instance 'diff-triple
                          :subject (article-uri-string old-article)
                          :predicate "dct:title"
                          :object (article-title new-article)
                          :operation :modified
                          :old-value (article-title old-article))
            diffs))
    
    ;; Compare content
    (unless (string= (article-content old-article)
                     (article-content new-article))
      (let ((content-diff (compute-text-diff 
                          (article-content old-article)
                          (article-content new-article))))
        (push (make-instance 'diff-triple
                            :subject (article-uri-string old-article)
                            :predicate "eli:description"
                            :object (article-content new-article)
                            :operation :modified
                            :old-value (article-content old-article)
                            :context content-diff)
              diffs)))
    
    ;; Compare metadata
    (let ((metadata-diff (compute-metadata-diff 
                         (article-metadata old-article)
                         (article-metadata new-article))))
      (setf diffs (append diffs metadata-diff)))
    
    diffs))

(defun %diff-words (text)
  "Split TEXT into words for word-level diffing (newlines -> spaces)."
  (remove "" (split-sequence:split-sequence
              #\Space (substitute #\Space #\Newline (or text "")))
          :test #'string=))

(defun compute-text-diff (old-text new-text)
  "Proper word-level diff via Longest-Common-Subsequence (no simplification).
   Returns (:segments ((:op :equal|:add|:remove :text W) ...) :additions (...)
   :deletions (...) :modification-count N)."
  (let* ((a (coerce (%diff-words old-text) 'vector))
         (b (coerce (%diff-words new-text) 'vector))
         (m (length a)) (n (length b))
         (dp (make-array (list (1+ m) (1+ n)) :initial-element 0)))
    ;; LCS length table
    (loop for i from (1- m) downto 0 do
      (loop for j from (1- n) downto 0 do
        (setf (aref dp i j)
              (if (string= (aref a i) (aref b j))
                  (1+ (aref dp (1+ i) (1+ j)))
                  (max (aref dp (1+ i) j) (aref dp i (1+ j)))))))
    ;; Backtrack into an ordered segment list
    (let ((segs '()) (adds '()) (dels '()) (i 0) (j 0))
      (loop while (or (< i m) (< j n)) do
        (cond
          ((and (< i m) (< j n) (string= (aref a i) (aref b j)))
           (push (list :op :equal :text (aref b j)) segs) (incf i) (incf j))
          ((and (< j n) (or (>= i m) (>= (aref dp i (1+ j)) (aref dp (1+ i) j))))
           (push (list :op :add :text (aref b j)) segs) (push (aref b j) adds) (incf j))
          (t
           (push (list :op :remove :text (aref a i)) segs) (push (aref a i) dels) (incf i))))
      (list :segments (nreverse segs)
            :additions (nreverse adds)
            :deletions (nreverse dels)
            :modification-count (+ (length adds) (length dels))))))

;;; ============================================================================
;;; GRAPH GENERATION
;;; ============================================================================

(defmethod generate-version-graph ((version corpus-version))
  "Generate complete version graph in RDF/Turtle"
  (with-output-to-string (stream)
    ;; Prefixes
    (write-prefixes stream)
    
    ;; Version resource
    (format stream "~%~%# Version: ~A~%" (version-id version))
    (format stream "<~A> a prov:Entity, eli:LegalResource ;~%" 
            (version-uri version))
    
    ;; Version metadata
    (format stream "    eli:version \"~A\" ;~%" (version-id version))
    (format stream "    eli:version_date \"~A\"^^xsd:dateTime ;~%" 
            (format-timestamp (version-timestamp version)))
    (format stream "    dct:created \"~A\"^^xsd:dateTime ;~%" 
            (format-timestamp (version-timestamp version)))
    (format stream "    dct:valid \"~A/~A\" ;~%" 
            (format-timestamp (valid-from version))
            (if (valid-until version)
                (format-timestamp (valid-until version))
                ""))
    
    ;; Previous version linkage
    (when (previous-version version)
      (format stream "    prov:wasRevisionOf <~A> ;~%" 
              (version-uri (previous-version version)))
      (format stream "    dct:replaces <~A> ;~%" 
              (version-uri (previous-version version))))
    
    ;; Attribution
    (format stream "    prov:wasAttributedTo <~A> ;~%" (version-author version))
    (format stream "    prov:wasGeneratedBy <~A> ;~%" (activity-uri version))
    
    ;; Change note
    (format stream "    dct:description \"~A\"@en ;~%" (change-note version))
    
    ;; Articles in this version
    (format stream "    dct:hasPart ~%")
    (let ((article-nums (hash-table-keys (version-articles version))))
      (loop for num in article-nums
            for i from 0
            do (format stream "        <~A/article-~3,'0D>~A~%" 
                      (version-uri version)
                      num
                      (if (< i (1- (length article-nums)))
                          ","
                          " ."))))
    
    ;; Activity
    (format stream "~%<~A> a prov:Activity ;~%" (activity-uri version))
    (format stream "    prov:startedAtTime \"~A\"^^xsd:dateTime ;~%" 
            (format-timestamp (version-timestamp version)))
    (format stream "    prov:endedAtTime \"~A\"^^xsd:dateTime ;~%" 
            (format-timestamp (orchestrator.time:get-current-timestamp)))
    (format stream "    prov:wasAssociatedWith <~A> ;~%" (version-author version))
    (format stream "    prov:generated <~A> .~%" (version-uri version))
    
    ;; Semantic anchors
    (when (semantic-anchors version)
      (format stream "~%# Semantic Anchors~%")
      (dolist (anchor (semantic-anchors version))
        (write-semantic-anchor anchor stream)))))

(defun write-semantic-anchor (anchor stream)
  "Write semantic anchor to RDF"
  (format stream "~%<~A> a delta:SemanticAnchor ;~%"
          (orchestrator.uris:build-anchor-uri (anchor-id anchor)))
  (format stream "    delta:anchorType \"~A\" ;~%" (anchor-type anchor))
  (format stream "    delta:source <~A> ;~%" (source-uri anchor))
  (format stream "    delta:targetArticle ~D ;~%" (target-article anchor))
  (format stream "    delta:changeType \"~A\" ;~%" (change-type anchor))
  (format stream "    delta:legalBasis \"~A\" ;~%" (legal-basis anchor))
  (format stream "    delta:timestamp \"~A\"^^xsd:dateTime ;~%" 
          (format-timestamp (anchor-timestamp anchor)))
  (format stream "    delta:hash \"~A\" .~%" (anchor-hash anchor)))

;;; ============================================================================
;;; DELTA GRAPH GENERATION
;;; ============================================================================

(defmethod generate-delta-graph ((manager version-manager) old-version-id new-version-id)
  "Generate graph-delta.ttl showing differences"
  (let ((diff (get-cached-diff manager old-version-id new-version-id)))
    (unless diff
      (let ((old (gethash old-version-id (all-versions (version-lineage manager))))
            (new (gethash new-version-id (all-versions (version-lineage manager)))))
        (setf diff (compute-semantic-diff old new))
        (cache-diff manager old-version-id new-version-id diff)))
    
    (with-output-to-string (stream)
      ;; Prefixes
      (write-prefixes stream)
      
      ;; Delta metadata
      (format stream "~%~%# Delta Graph: ~A -> ~A~%" old-version-id new-version-id)
      (format stream "# Generated: ~A~%~%" (orchestrator.time:get-current-timestamp))
      
      (let ((delta-uri (format nil "~A/delta/~A-to-~A" 
                              (corpus-uri manager)
                              old-version-id
                              new-version-id)))
        
        (format stream "<~A> a delta:VersionDelta ;~%" delta-uri)
        (format stream "    delta:fromVersion <~A/version/~A> ;~%" 
                (corpus-uri manager) old-version-id)
        (format stream "    delta:toVersion <~A/version/~A> ;~%" 
                (corpus-uri manager) new-version-id)
        (format stream "    delta:tripleCount ~D ;~%" (length diff))
        (format stream "    delta:generatedAt \"~A\"^^xsd:dateTime .~%"
                (format-timestamp (orchestrator.time:get-current-timestamp))))
      
      ;; Added triples
      (let ((added (remove-if-not (lambda (d) (eq (triple-operation d) :added)) diff)))
        (when added
          (format stream "~%# Added Triples (~D)~%" (length added))
          (dolist (triple added)
            (write-diff-triple triple stream :added))))
      
      ;; Removed triples
      (let ((removed (remove-if-not (lambda (d) (eq (triple-operation d) :removed)) diff)))
        (when removed
          (format stream "~%# Removed Triples (~D)~%" (length removed))
          (dolist (triple removed)
            (write-diff-triple triple stream :removed))))
      
      ;; Modified triples
      (let ((modified (remove-if-not (lambda (d) (eq (triple-operation d) :modified)) diff)))
        (when modified
          (format stream "~%# Modified Triples (~D)~%" (length modified))
          (dolist (triple modified)
            (write-diff-triple triple stream :modified)))))))

(defun write-diff-triple (triple stream operation)
  "Write a diff triple with operation annotation"
  (format stream "~%[] a delta:~A ;~%"
          (case operation
            (:added "Addition")
            (:removed "Removal")
            (:modified "Modification")))
  
  (format stream "    delta:subject <~A> ;~%" (triple-subject triple))
  (format stream "    delta:predicate ~A ;~%" (triple-predicate triple))
  (format stream "    delta:object ")
  
  ;; Handle literal vs URI object
  (if (stringp (triple-object triple))
      (if (or (starts-with-p (triple-object triple) "http://")
              (starts-with-p (triple-object triple) "https://"))
          (format stream "<~A>" (triple-object triple))
          (format stream "\"~A\"" (triple-object triple)))
      (format stream "~A" (triple-object triple)))
  
  ;; Add old value for modifications
  (when (and (eq operation :modified) (old-value triple))
    (format stream " ;~%    delta:oldValue \"~A\"" (old-value triple)))
  
  (format stream " .~%"))

;;; ============================================================================
;;; ARTICLE EVOLUTION TRACKING
;;; ============================================================================

(defmethod track-article-evolution ((manager version-manager) article-number)
  "Track the evolution of a specific article across all versions"
  (let ((evolution nil)
        (versions (sort (hash-table-values (all-versions (version-lineage manager)))
                       #'string< :key #'version-id)))
    
    (dolist (version versions)
      (let ((article (gethash article-number (version-articles version))))
        (when article
          (push (list :version (version-id version)
                     :timestamp (version-timestamp version)
                     :title (article-title article)
                     :content-hash (hash-content (article-content article))
                     :author (version-author version))
                evolution))))
    
    (nreverse evolution)))

(defun generate-article-evolution-graph (evolution article-number)
  "Generate RDF graph for article evolution"
  (with-output-to-string (stream)
    (write-prefixes stream)
    
    (format stream "~%# Evolution of Article ~D~%" article-number)
    
    (loop for evo in evolution
          for i from 0
          do (let ((version-uri (orchestrator.uris:build-article-uri
                                  article-number
                                  (getf evo :version))))
               
               (format stream "~%<~A> a eli:LegalResource ;~%" version-uri)
               (format stream "    eli:number ~D ;~%" article-number)
               (format stream "    eli:version \"~A\" ;~%" (getf evo :version))
               (format stream "    dct:title \"~A\" ;~%" (getf evo :title))
               (format stream "    prov:generatedAtTime \"~A\"^^xsd:dateTime ;~%" 
                       (format-timestamp (getf evo :timestamp)))
               (format stream "    prov:wasAttributedTo <~A>" (getf evo :author))
               
               ;; Link to previous version
               (when (> i 0)
                 (let ((prev-version (nth (1- i) evolution)))
                   (format stream " ;~%    prov:wasRevisionOf <~A>"
                           (orchestrator.uris:build-article-uri
                            article-number
                            (getf prev-version :version)))))
               
               (format stream " .~%")))))

;;; ============================================================================
;;; VERSION TEMPLATES
;;; ============================================================================

(defun generate-version-template (version-string &key major minor patch)
  "Generate version template for semantic versioning"
  (let ((template (make-hash-table :test 'equal)))
    
    (setf (gethash "version" template) version-string)
    (setf (gethash "major" template) (or major (parse-integer (subseq version-string 0 1))))
    (setf (gethash "minor" template) (or minor (parse-integer (subseq version-string 2 3))))
    (setf (gethash "patch" template) (or patch (if (> (length version-string) 3)
                                                  (parse-integer (subseq version-string 4))
                                                  0)))
    
    ;; Version type based on changes
    (cond
      ((and patch (> patch 0))
       (setf (gethash "type" template) "patch")
       (setf (gethash "description" template) "Bug fixes and minor updates"))
      
      ((and minor (> minor 0))
       (setf (gethash "type" template) "minor")
       (setf (gethash "description" template) "New features, backwards compatible"))
      
      (major
       (setf (gethash "type" template) "major")
       (setf (gethash "description" template) "Breaking changes")))
    
    ;; Generate URIs
    (setf (gethash "uri" template)
          (orchestrator.uris:build-corpus-version-uri version-string))
    
    ;; PROV template
    (setf (gethash "prov_template" template)
          (format nil "@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix eli: <http://data.europa.eu/eli/ontology#> .
@prefix dct: <http://purl.org/dc/terms/> .

<~A> a prov:Entity, eli:LegalResource ;
    eli:version \"~A\" ;
    eli:version_date \"~A\"^^xsd:date ;
    dct:hasVersion \"~A\" ;
    prov:wasRevisionOf <~A> ;
    prov:generatedAtTime \"~A\"^^xsd:dateTime ."
                  (gethash "uri" template)
                  version-string
                  (local-time:today)
                  version-string
                  (orchestrator.uris:build-corpus-version-uri
                   (previous-version-string version-string))
                  (orchestrator.time:get-current-timestamp)))
    
    template))

(defun previous-version-string (version)
  "Calculate previous version string"
  (let* ((parts (mapcar #'parse-integer (split-sequence:split-sequence #\. version)))
         (major (first parts))
         (minor (or (second parts) 0))
         (patch (or (third parts) 0)))
    
    (cond
      ((> patch 0)
       (format nil "~D.~D.~D" major minor (1- patch)))
      ((> minor 0)
       (format nil "~D.~D.0" major (1- minor)))
      ((> major 0)
       (format nil "~D.0.0" (1- major)))
      (t "0.0.0"))))

;;; ============================================================================
;;; UTILITY FUNCTIONS
;;; ============================================================================

(defun write-prefixes (stream)
  "Write RDF prefixes"
  (dolist (prefix *versioning-prefixes*)
    (format stream "@prefix ~A: <~A> .~%" (car prefix) (cdr prefix))))

(defun format-timestamp (timestamp)
  "Format timestamp for RDF"
  (local-time:format-timestring nil timestamp
                                :format '(:year "-" (:month 2) "-" (:day 2) 
                                         "T" (:hour 2) ":" (:min 2) ":" (:sec 2))))

(defun hash-content (content)
  "Compute hash of content"
  (orchestrator.hash-authority:compute-hash content :algorithm :sha256))

(defun compute-anchor-hash (anchor)
  "Compute hash for semantic anchor"
  (let ((anchor-string (format nil "~A|~A|~A|~A|~A|~A"
                               (anchor-id anchor)
                               (anchor-type anchor)
                               (source-uri anchor)
                               (target-article anchor)
                               (change-type anchor)
                               (legal-basis anchor))))
    (orchestrator.hash-authority:compute-hash anchor-string :algorithm :sha512)))

(defun article-uri (version article-num)
  "Generate article URI for version"
  (format nil "~A/article-~3,'0D" (version-uri version) article-num))

(defun article-uri-string (article)
  "Get URI string from article object (model accessor resolved at runtime so
   the infrastructure layer need not compile-depend on orchestrator-model)."
  (orchestrator.uris:build-article-uri
   (funcall (find-symbol "ARTICLE-NUMBER" :orchestrator.model) article)))

(defun hash-table-keys (hash-table)
  "Get all keys from hash table"
  (loop for key being the hash-keys of hash-table
        collect key))

(defun hash-table-values (hash-table)
  "Get all values from hash table"
  (loop for value being the hash-values of hash-table
        collect value))

(defun starts-with-p (string prefix)
  "Check if string starts with prefix"
  (and (>= (length string) (length prefix))
       (string= string prefix :end1 (length prefix))))

(defun get-cached-diff (manager old-id new-id)
  "Get cached diff between versions"
  (gethash (format nil "~A->~A" old-id new-id) (diff-cache manager)))

(defun cache-diff (manager old-id new-id diff)
  "Cache diff between versions"
  (setf (gethash (format nil "~A->~A" old-id new-id) (diff-cache manager))
        diff))

(defun append-article-triples (article operation triples)
  "Append all triples for an article with operation"
  ;; Implementation depends on article structure
  ;; This is simplified
  triples)

(defun compute-metadata-diff (old-meta new-meta)
  "Compute differences in metadata"
  ;; Simplified implementation
  nil)

;;; ============================================================================
;;; PUBLIC API
;;; ============================================================================

(defun create-version-manager (corpus-uri)
  "Create a new version manager for corpus"
  (make-instance 'version-manager :corpus-uri corpus-uri))

(defun make-semantic-anchor (&key type source target change-type legal-basis)
  "Create a semantic anchor"
  (make-instance 'semantic-anchor
                :anchor-id (format nil "anchor-~A" (orchestrator.time:now :source :system))
                :anchor-type type
                :source-uri source
                :target-article target
                :change-type change-type
                :legal-basis legal-basis))

;;; ============================================================================
;;; EXPORT FUNCTIONS
;;; ============================================================================

(defun save-version-graph (version filename &key authority)
  "Save version graph to file"
  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :provenance"))
  (orchestrator.write-authority:emit-graph
    (generate-version-graph version)
    filename
    :authority authority)
  (log:info () "Saved version graph to ~A" filename))

(defun save-delta-graph (manager old-id new-id filename &key authority)
  "Save delta graph to file"
  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :provenance"))
  (orchestrator.write-authority:emit-graph
    (generate-delta-graph manager old-id new-id)
    filename
    :authority authority)
  (log:info () "Saved delta graph to ~A" filename))

(defun save-lineage-graph (manager filename &key authority)
  "Save complete lineage graph"
  (unless authority
    (error "AUTHORITY parameter is required. Use :authority :provenance"))
  (let ((content (with-output-to-string (stream)
                   (write-prefixes stream)
                   (format stream "~%# Complete Version Lineage~%")
                   (format stream "# Generated: ~A~%~%" (orchestrator.time:get-current-timestamp))

                   (let ((versions (hash-table-values (all-versions (version-lineage manager)))))
                     (dolist (version (sort versions #'string< :key #'version-id))
                       (format stream "~%# Version ~A~%" (version-id version))
                       (write-string (generate-version-graph version) stream))))))
    (orchestrator.write-authority:emit-graph content filename :authority authority)
    (log:info () "Saved lineage graph to ~A" filename)))

;;; ============================================================================
;;; END OF SEMANTIC-VERSIONING-SYSTEM.LISP
;;; ============================================================================
