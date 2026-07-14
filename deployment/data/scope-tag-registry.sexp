;;;; deployment/data/scope-tag-registry.sexp
;;;; [0088 Φ7-HARDENING #2] Το ΚΛΕΙΣΤΟ TYPED μητρώο scope tags — 4 διαστάσεις
;;;; (spec v3 §5 Scope model): {:territorial :personal :material :procedural}.
;;;; Σημασιολογία: απούσα διάσταση σε scope-set = ΚΑΘΟΛΙΚΗ ισχύς· παρούσα =
;;;; περιορισμός στην ένωση των tags της. Tag εκτός μητρώου ⇒ typed σφάλμα.
;;;; Νέο tag = νέα εγγραφή εδώ (με έγκριση δημιουργού), ποτέ ελεύθερο κείμενο.
;;;; Η πλήρης άλγεβρα (ενώσεις/διαφορές/μερική κατάργηση) = Φ8 — δηλωμένο όριο.
;;;; Reader: *read-eval* ρητά NIL (source/version-graph.lisp).
(:schema :scope-tag-registry/1
 :dimensions
 ((:dimension :territorial
   :tags (:gr :attiki :thessaloniki :nisia-aigaiou :paramethories-periohes)
   :doc "Εδαφική εμβέλεια — επικράτεια/περιφέρειες/ειδικές ζώνες")
  (:dimension :personal
   :tags (:oloi :dikigoroi :dikastikoi-leitourgoi :dimosioi-ypalliloi
          :anilikoi :stratiotikoi)
   :doc "Προσωπική εμβέλεια — κατηγορίες προσώπων")
  (:dimension :material
   :tags (:geniko :poiniko :astiko :dioikitiko :forologiko :ergatiko)
   :doc "Καθ' ύλην εμβέλεια — κλάδοι δικαίου/αντικείμενα")
  (:dimension :procedural
   :tags (:oles-diadikasies :ekkremeis-diadikasies :nees-diadikasies
          :anakopes :endika-mesa)
   :doc "Διαδικαστική εμβέλεια — εκκρεμείς/νέες διαδικασίες, ένδικα μέσα")))
