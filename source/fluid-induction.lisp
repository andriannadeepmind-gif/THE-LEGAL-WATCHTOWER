;;;; source/fluid-induction.lisp
;;;; ============================================================================
;;;; Σ12-ΡΕΥΣΤΟ — ΕΠΑΓΩΓΗ ΠΡΟΓΡΑΜΜΑΤΩΝ ΑΠΟ ΠΑΡΑΔΕΙΓΜΑΤΑ (η οικογένεια που
;;;; κερδίζει στο ARC: DSL + αναζήτηση + ΑΚΡΙΒΗΣ επαλήθευση — όχι μάντεμα)
;;;; ============================================================================
;;;;
;;;; Έργο: δοσμένων ζευγών (είσοδος→έξοδος) σε πλέγματα, ΒΡΕΣ το πρόγραμμα
;;;; που τα εξηγεί ΟΛΑ ακριβώς, και εφάρμοσέ το στη δοκιμή. Υπόθεση =
;;;; σύνθεση πρωτογενών μετασχηματισμών (DSL)· δεκτή ΜΟΝΟ αν αναπαράγει
;;;; ΚΑΘΕ ζεύγος εκπαίδευσης κύτταρο-κύτταρο· επιλογή MDL (το συντομότερο,
;;;; μετά λεξικογραφικά) — πλήρως ντετερμινιστικό. Αν κανένα πρόγραμμα του
;;;; DSL δεν εξηγεί τα παραδείγματα: ΤΙΜΙΟ nil με λόγο — ποτέ εικασία.
;;;; Το DSL ΜΕΓΑΛΩΝΕΙ κύμα-κύμα (και μέσω ονειρευτή αργότερα) — η πληρότητα
;;;; πάνω στο εκάστοτε DSL φυλάσσεται από πύλη με κρυφά προγράμματα-κριτές.

(defpackage :orchestrator.fluid
  (:use :cl)
  (:export #:solve-task #:all-solutions #:apply-program #:*primitives* #:grid-equal))

(in-package :orchestrator.fluid)

;;; Πλέγμα = λίστα γραμμών από ακέραιους 0-9.
(defun grid-equal (a b) (equal a b))
(defun %rows (g) (length g))
(defun %cols (g) (length (first g)))
(defun %cell (g r c) (nth c (nth r g)))

(defun %transpose (g)
  (when g (apply #'mapcar #'list g)))
(defun %flip-h (g) (mapcar #'reverse g))
(defun %flip-v (g) (reverse g))
(defun %rot90 (g) (%flip-h (%transpose g)))
(defun %rot180 (g) (%flip-v (%flip-h g)))
(defun %rot270 (g) (%flip-v (%transpose g)))
(defun %guard-cells (r c)
  "Όριο πεδίου ARC: πλέγματα ≤30×30 — ενδιάμεσα ≤10000 κύτταρα, αλλιώς σφάλμα
   (το πιάνει το apply-program ως αποτυχία του προγράμματος, όχι του λύτη)."
  (unless (and (plusp r) (plusp c) (<= (* r c) 10000))
    (error "εκτός ορίου μεγέθους πλέγματος")))

(defun %scale (g k)
  (%guard-cells (* k (%rows g)) (* k (%cols g)))
  (loop for row in g
        append (loop repeat k
                     collect (loop for x in row append (make-list k :initial-element x)))))
(defun %tile-h (g) (%guard-cells (%rows g) (* 2 (%cols g)))
  (mapcar (lambda (r) (append r r)) g))
(defun %tile-v (g) (%guard-cells (* 2 (%rows g)) (%cols g))
  (append g g))
(defun %crop-bbox (g)
  "Περικοπή στο ελάχιστο ορθογώνιο των μη-μηδενικών· αμετάβλητο αν όλο μηδέν."
  (let ((rmin nil) (rmax nil) (cmin nil) (cmax nil))
    (loop for r from 0 below (%rows g)
          do (loop for c from 0 below (%cols g)
                   unless (zerop (%cell g r c))
                     do (setf rmin (if rmin (min rmin r) r)
                              rmax (if rmax (max rmax r) r)
                              cmin (if cmin (min cmin c) c)
                              cmax (if cmax (max cmax c) c))))
    (if (null rmin) g
        (loop for r from rmin to rmax
              collect (loop for c from cmin to cmax collect (%cell g r c))))))

;;; ── β΄ κύμα: συμμετρία, συμπίεση, φράκταλ, βαρύτητα, λογική ημίσεων ──

(defun %mirror-h (g)
  (%guard-cells (%rows g) (* 2 (%cols g)))
  (mapcar (lambda (r) (append r (reverse r))) g))
(defun %mirror-v (g)
  (%guard-cells (* 2 (%rows g)) (%cols g))
  (append g (reverse g)))

(defun %dedup-rows (g)
  "Κατάρρευση διαδοχικών ίσων γραμμών σε μία (αντίστροφο της κλιμάκωσης καθ' ύψος)."
  (let ((acc '()))
    (dolist (r g (nreverse acc))
      (unless (and acc (equal r (first acc))) (push r acc)))))
(defun %dedup-cols (g) (%transpose (%dedup-rows (%transpose g))))

(defun %fractal (g)
  "Κάθε μη-μηδενικό κύτταρο → αντίγραφο ΟΛΟΥ του πλέγματος· μηδενικό → μηδενικά
   (η οικογένεια αυτο-πλακόστρωσης του ARC, π.χ. 007bbfb7)."
  (let ((r (%rows g)) (c (%cols g)))
    (%guard-cells (* r r) (* c c))
    (loop for row in g
          append (loop for i from 0 below r
                       collect (loop for x in row
                                     append (if (zerop x)
                                                (make-list c :initial-element 0)
                                                (nth i g)))))))

(defun %gravity (g)
  "Τα μη-μηδενικά πέφτουν στον πάτο κάθε στήλης, με τη σειρά τους."
  (%transpose
   (mapcar (lambda (col)
             (let ((nz (remove 0 col)))
               (append (make-list (- (length col) (length nz)) :initial-element 0) nz)))
           (%transpose g))))

(defun %strip-border (g)
  (unless (and (>= (%rows g) 3) (>= (%cols g) 3))
    (error "πολύ μικρό για αφαίρεση πλαισίου"))
  (mapcar (lambda (r) (butlast (rest r))) (butlast (rest g))))

(defun %majority (g)
  "1×1 πλέγμα με το συχνότερο χρώμα (ισοπαλία → το μικρότερο) — ντετερμινιστικό."
  (let ((counts '()))
    (dolist (row g)
      (dolist (x row)
        (let ((c (assoc x counts)))
          (if c (incf (cdr c)) (push (cons x 1) counts)))))
    (let ((best (first (sort counts (lambda (a b)
                                      (or (> (cdr a) (cdr b))
                                          (and (= (cdr a) (cdr b)) (< (car a) (car b)))))))))
      (list (list (car best))))))

(defun %split-cols (g)
  "(values αριστερό δεξί): άρτιο πλάτος = στη μέση· περιττό = απαιτεί ΟΜΟΙΟΜΟΡΦΗ
   διαχωριστική στήλη στη μέση (το κοινό μοτίβο δύο πινάκων του ARC)."
  (let ((w (%cols g)))
    (cond ((and (evenp w) (>= w 2))
           (values (mapcar (lambda (r) (subseq r 0 (/ w 2))) g)
                   (mapcar (lambda (r) (subseq r (/ w 2))) g)))
          ((and (oddp w) (>= w 3))
           (let* ((m (floor w 2))
                  (mid (mapcar (lambda (r) (nth m r)) g)))
             (unless (every (lambda (x) (eql x (first mid))) mid)
               (error "μη ομοιόμορφη διαχωριστική στήλη"))
             (values (mapcar (lambda (r) (subseq r 0 m)) g)
                     (mapcar (lambda (r) (subseq r (1+ m))) g))))
          (t (error "αδιαίρετο πλάτος")))))

(defun %split-rows (g)
  (let ((h (%rows g)))
    (cond ((and (evenp h) (>= h 2))
           (values (subseq g 0 (/ h 2)) (subseq g (/ h 2))))
          ((and (oddp h) (>= h 3))
           (let* ((m (floor h 2)) (mid (nth m g)))
             (unless (every (lambda (x) (eql x (first mid))) mid)
               (error "μη ομοιόμορφη διαχωριστική γραμμή"))
             (values (subseq g 0 m) (subseq g (1+ m)))))
          (t (error "αδιαίρετο ύψος")))))

(defun %binary (g axis fn)
  "Κυτταρική λογική στα δύο μισά (1 όπου ισχύει, 0 αλλού) — το μαθημένο recolor
   στο τέλος χρωματίζει το 1 όπως ζητά το εκάστοτε έργο."
  (multiple-value-bind (a b)
      (if (eq axis :h) (%split-cols g) (%split-rows g))
    (mapcar (lambda (ra rb)
              (mapcar (lambda (x y) (if (funcall fn (plusp x) (plusp y)) 1 0)) ra rb))
            a b)))

(defparameter *primitives*
  `((:id . ,#'identity)
    (:flip-h . ,#'%flip-h) (:flip-v . ,#'%flip-v) (:transpose . ,#'%transpose)
    (:rot90 . ,#'%rot90) (:rot180 . ,#'%rot180) (:rot270 . ,#'%rot270)
    (:scale2 . ,(lambda (g) (%scale g 2))) (:scale3 . ,(lambda (g) (%scale g 3)))
    (:tile-h . ,#'%tile-h) (:tile-v . ,#'%tile-v)
    (:crop . ,#'%crop-bbox)
    ;; β΄ κύμα (05-07-2026): μετρημένο στο επίσημο ARC πριν/μετά
    (:mirror-h . ,#'%mirror-h) (:mirror-v . ,#'%mirror-v)
    (:dedup-rows . ,#'%dedup-rows) (:dedup-cols . ,#'%dedup-cols)
    (:fractal . ,#'%fractal) (:gravity . ,#'%gravity)
    (:strip-border . ,#'%strip-border) (:majority . ,#'%majority)
    (:and-h . ,(lambda (g) (%binary g :h (lambda (a b) (and a b)))))
    (:or-h  . ,(lambda (g) (%binary g :h (lambda (a b) (or a b)))))
    (:xor-h . ,(lambda (g) (%binary g :h (lambda (a b) (if a (not b) b)))))
    (:and-v . ,(lambda (g) (%binary g :v (lambda (a b) (and a b)))))
    (:or-v  . ,(lambda (g) (%binary g :v (lambda (a b) (or a b)))))
    (:xor-v . ,(lambda (g) (%binary g :v (lambda (a b) (if a (not b) b))))))
  "Το DSL: α΄ κύμα γεωμετρία/κλίμακα/πλακόστρωση/περικοπή· β΄ κύμα συμμετρία/
   συμπίεση/φράκταλ/βαρύτητα/πλαίσιο/πλειοψηφία/λογική ημίσεων.
   Νέα ικανότητα = νέο στοιχείο ΕΔΩ — καμία αλλαγή στην αναζήτηση.")

(defun apply-program (prog g)
  "Εφάρμοσε ακολουθία πρωτογενών (+ προαιρετικό (:recolor alist) στο τέλος)."
  (handler-case
      (let ((out g))
        (dolist (step prog out)
          (setf out
                (if (and (consp step) (eq (first step) :recolor))
                    (mapcar (lambda (row)
                              (mapcar (lambda (x)
                                        (let ((m (assoc x (second step)))) (if m (cdr m) x)))
                                      row))
                            out)
                    (funcall (cdr (assoc step *primitives*)) out)))))
    (error () nil)))

(defun %learn-recolor (prog pairs)
  "Μάθε ΜΙΑ συνεπή αντιστοίχιση χρωμάτων που ισχύει σε ΟΛΑ τα ζεύγη
   (prog(είσοδος_i) → έξοδος_i, κύτταρο-κύτταρο), ή nil αν δεν υπάρχει.
   Από ΟΛΑ τα ζεύγη — όχι μόνο το πρώτο: χρώμα που πρωτοεμφανίζεται στο
   δεύτερο ζεύγος μπαίνει κι αυτό στην αντιστοίχιση."
  (let ((map '()))
    (dolist (pair pairs (sort map #'< :key #'car))
      (let* ((mid (apply-program prog (first pair)))
             (out (second pair)))
        (unless (and mid (= (%rows mid) (%rows out)) (= (%cols mid) (%cols out)))
          (return-from %learn-recolor nil))
        (loop for ra in mid for rb in out
              do (loop for x in ra for y in rb
                       do (let ((m (assoc x map)))
                            (cond ((null m) (push (cons x y) map))
                                  ((/= (cdr m) y) (return-from %learn-recolor nil))))))))))

(defun %explains-all-p (prog pairs)
  (loop for (in out) in pairs
        always (grid-equal (apply-program prog in) out)))

(defun %map-programs (fn names max-depth)
  "Κάλεσε FN σε κάθε ακολουθία ≤ MAX-DEPTH πρωτογενών, κατά μήκος (MDL)
   και μετά λεξικογραφικά. Η σειρά της αναζήτησης ορίζεται ΕΔΩ, μία φορά —
   λύτης και κριτής πύλης μοιράζονται τον ΙΔΙΟ χώρο υποθέσεων."
  (dolist (a names) (funcall fn (list a)))
  (when (>= max-depth 2)
    (dolist (a names)
      (dolist (b names)
        (funcall fn (list a b)))))
  (when (>= max-depth 3)
    (dolist (a names)
      (dolist (b names)
        (dolist (c names)
          (funcall fn (list a b c)))))))

(defun %consistent-variant (prog pairs)
  "Το πρόγραμμα που εξηγεί ΟΛΑ τα ζεύγη ακριβώς — ωμό, αλλιώς +recolor
   μαθημένο απ' όλα τα ζεύγη — ή nil."
  (if (%explains-all-p prog pairs)
      prog
      (let ((map (%learn-recolor prog pairs)))
        (when map
          (let ((p2 (append prog (list (list :recolor map)))))
            (when (%explains-all-p p2 pairs) p2))))))

(defun solve-task (pairs test-input &key (max-depth 2))
  "(values πρόβλεψη πρόγραμμα λόγος): αναζήτηση κατά μήκος (MDL) σε συνθέσεις
   ≤ MAX-DEPTH πρωτογενών, με προαιρετικό recolor μαθημένο απ' ΟΛΑ τα ζεύγη
   στο τέλος. Δεκτό ΜΟΝΟ πρόγραμμα που εξηγεί ΟΛΑ τα ζεύγη ακριβώς.
   Τίποτα; ⇒ (nil nil λόγος) — δηλωμένο όριο, ποτέ εικασία."
  (let ((names (mapcar #'car *primitives*)))
    (%map-programs
     (lambda (prog)
       (let ((v (%consistent-variant prog pairs)))
         (when v
           (return-from solve-task (values (apply-program v test-input) v nil)))))
     names max-depth)
    (values nil nil
            (format nil "κανένα πρόγραμμα του DSL (βάθος ≤~D, ~D πρωτογενή) δεν εξηγεί και τα ~D ζεύγη — δηλωμένο όριο, όχι εικασία"
                    max-depth (length names) (length pairs)))))

(defun all-solutions (pairs test-input &key (max-depth 2))
  "ΟΛΑ τα συνεπή προγράμματα με τις εξόδους τους στη δοκιμή, με τη σειρά της
   αναζήτησης. Ο κριτής της πύλης το χρησιμοποιεί για ΚΑΛΩΣ-ΤΕΘΕΙΜΕΝΑ έργα:
   έργο με >1 διακριτές εξόδους δεν καθορίζεται από τα παραδείγματά του —
   όπως οι επιμελητές του ARC εγγυώνται μονοσήμαντη απάντηση με το χέρι."
  (let ((names (mapcar #'car *primitives*))
        (acc '()))
    (%map-programs
     (lambda (prog)
       (let ((v (%consistent-variant prog pairs)))
         (when v (push (cons v (apply-program v test-input)) acc))))
     names max-depth)
    (nreverse acc)))
