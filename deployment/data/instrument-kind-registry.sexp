;;;; deployment/data/instrument-kind-registry.sexp
;;;; [0088 Φ7 Π1 + Φ6γ-Δ³] Το ΚΛΕΙΣΤΟ TYPED μητρώο ειδών θεσμικών γεγονότων
;;;; για effectivity conditions (:instrument-event KIND REF).
;;;; Schema /2: κάθε kind φέρει ΥΠΟΧΡΕΩΤΙΚΑ authority-class + evidence schema
;;;; (ποια τεκμήρια νομιμοποιούν :satisfied/:refuted event) — το γενικό
;;;; :event ΔΕΝ είναι «οτιδήποτε»: απαιτεί ρητή πράξη-πηγή με digest.
;;;; Νέο είδος = νέα εγγραφή εδώ (με έγκριση), ποτέ ad-hoc κόμβος γραμματικής.
;;;; Reader: *read-eval* ρητά NIL (source/version-graph.lisp).
(:schema :instrument-kind-registry/2
 :entries
 ((:kind :ya                 :authority-class :ministerial
   :evidence (:fek-ref :source-digest)
   :doc "Υπουργική Απόφαση — ΦΕΚ ή πράξη με digest")
  (:kind :pd                 :authority-class :presidential
   :evidence (:fek-ref :source-digest)
   :doc "Προεδρικό Διάταγμα")
  (:kind :kya                :authority-class :ministerial
   :evidence (:fek-ref :source-digest)
   :doc "Κοινή Υπουργική Απόφαση")
  (:kind :decision           :authority-class :administrative
   :evidence (:act-ref :source-digest)
   :doc "Διοικητική απόφαση/πράξη οργάνου")
  (:kind :eu-approval        :authority-class :eu
   :evidence (:act-ref :source-digest)
   :doc "Έγκριση οργάνου ΕΕ (π.χ. Επιτροπή)")
  (:kind :ratification       :authority-class :parliamentary
   :evidence (:fek-ref :source-digest)
   :doc "Κύρωση από Βουλή (π.χ. ΠΝΠ κατ' άρθ. 44§1 Σ)")
  (:kind :system-operational :authority-class :administrative
   :evidence (:act-ref :source-digest)
   :doc "Διαπιστωτική πράξη θέσης συστήματος σε λειτουργία")
  (:kind :event              :authority-class :declared
   :evidence (:act-ref :source-digest)
   :doc "Ρητά δηλωμένο θεσμικό γεγονός — ΜΟΝΟ με πράξη-πηγή + digest, ποτέ ελεύθερο κείμενο")))
