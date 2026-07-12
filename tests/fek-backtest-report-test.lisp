;;;; tests/fek-backtest-report-test.lisp
;;;; [FEK-COMPILER β'] Bounded ντετερμινιστική ανακάλυψη + structured backtest
;;;; report ΑΠΟ ΤΗΝ ΕΔΡΑ measure-extraction (ΟΧΙ log-grep — καμία δεύτερη έδρα
;;;; μέτρησης). Καθαρές helpers, gated ΧΩΡΙΣ δίκτυο (το fetch μένει owner-edge).

(in-package :orchestrator.cli)

(defvar *p* 0) (defvar *f* 0)
(defmacro ck (name form)
  `(handler-case (if ,form (progn (incf *p*) (format t "  ok   ~A~%" ,name))
                     (progn (incf *f*) (format t "  FAIL ~A~%" ,name)))
     (error (e) (incf *f*) (format t "  FAIL ~A (error: ~A)~%" ,name e))))

(format t "~%== [1] %fek-discover-only: bounded ντετερμινιστικό σύνολο ==~%")
(sb-posix:setenv "FEK_DISCOVER_ONLY" "103,105,239" 1)
(ck "«103,105,239» → (103 105 239)" (equal '(103 105 239) (%fek-discover-only)))
(sb-posix:setenv "FEK_DISCOVER_ONLY" "239, 103  105 , 103" 1)
(ck "διπλότυπα/κενά/σειρά → ταξινομημένο μοναδικό (103 105 239)"
    (equal '(103 105 239) (%fek-discover-only)))
(sb-posix:setenv "FEK_DISCOVER_ONLY" "abc xyz" 1)
(ck "σκουπίδια → NIL (τίμιο, όχι crash)" (null (%fek-discover-only)))
(sb-posix:unsetenv "FEK_DISCOVER_ONLY")
(ck "χωρίς env → NIL (walk mode)" (null (%fek-discover-only)))

(format t "~%== [2] %backtest-entry: metrics ΑΠΟ measure-extraction (ρητοί→float) ==~%")
(let ((e (%backtest-entry "Α' 81/2026"
                          (list :extracted 30 :routed 22 :unrouted 8 :self-reference 0
                                :identity-contradicted 1 :census-consistency 21/22
                                :ops-per-structural-verb 30/25)
                          (list "astikos" "kpolitikis"))))
  (ck "fek/extracted/routed περνούν αυτούσια"
      (and (equal "Α' 81/2026" (getf e :fek)) (= 30 (getf e :extracted))
           (= 22 (getf e :routed))))
  (ck "routed-buckets = μήκος buckets" (= 2 (getf e :routed-buckets)))
  (ck "census-consistency ρητός → double" (and (floatp (getf e :census-consistency))
                                               (< 0.954 (getf e :census-consistency) 0.955)))
  (ck "ops-per-structural-verb ρητός → double (μπορεί >1)"
      (and (floatp (getf e :ops-per-structural-verb)) (< 1.19 (getf e :ops-per-structural-verb) 1.21))))

(format t "~%== [3] %backtest-report->json: ντετερμινιστικό, δομικά σωστό ==~%")
(let* ((e1 (%backtest-entry "Α' 103/2026"
                            (list :extracted 4 :routed 1 :unrouted 3 :self-reference 2
                                  :identity-contradicted 1 :census-consistency 0
                                  :ops-per-structural-verb 1)
                            '()))
       (e2 (%backtest-entry "Α' 81/2026"
                            (list :extracted 30 :routed 22 :unrouted 8 :self-reference 0
                                  :identity-contradicted 1 :census-consistency 21/22
                                  :ops-per-structural-verb 30/25)
                            (list "astikos" "kpolitikis")))
       (j1 (%backtest-report->json (list e1 e2)))
       (j2 (%backtest-report->json (list e1 e2))))
  (ck "ντετερμινιστικό (ίδια είσοδος → ίδιο JSON)" (string= j1 j2))
  (ck "περιέχει και τα δύο ΦΕΚ" (and (search "103/2026" j1) (search "81/2026" j1)))
  (ck "structured πεδία παρόντα (routed, census_consistency, routed_buckets)"
      (and (search "\"routed\":22" j1) (search "\"census_consistency\":" j1)
           (search "\"routed_buckets\":2" j1)))
  (ck "buckets array (astikos, kpolitikis)" (and (search "\"astikos\"" j1) (search "\"kpolitikis\"" j1)))
  (ck "άδειο buckets ⇒ []" (search "\"buckets\":[]" j1))
  (ck "regression baseline του Α'103: routed=1 ΚΑΤΑΓΡΑΦΕΤΑΙ (όχι κρυμμένο)"
      (search "\"fek\":\"Α' 103/2026\",\"extracted\":4,\"routed\":1" j1)))

(format t "~%========================================~%")
(format t "FEK backtest report (bounded, one-seat): ~D passed, ~D failed~%" *p* *f*)
(format t "========================================~%")
(sb-ext:exit :code (if (zerop *f*) 0 1))
