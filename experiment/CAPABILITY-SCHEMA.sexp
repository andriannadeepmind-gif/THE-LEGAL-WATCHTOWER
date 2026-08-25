;;;; experiment/CAPABILITY-SCHEMA.sexp — ΤΟ ΚΟΙΝΟ ΣΥΜΒΟΛΑΙΟ ΙΚΑΝΟΤΗΤΑΣ (§2)
;;;; Capability ΔΕΝ θεωρείται παρούσα επειδή εμφανίζεται σε κείμενο, feature
;;;; list ή ισχυρισμό πράκτορα. ΜΟΝΟ όταν ικανοποιεί ΑΥΤΟ, με αποδεκτό evidence.
(:lawmax-capability-schema/1
 :required-fields
 ((:domain           "Πάνω σε τι ισχύει· ποια είσοδος, ποια δικαιοδοσία, ποιο χρονικό εύρος.")
  (:assumptions      "Τι ΠΡΕΠΕΙ να ισχύει για να δουλέψει. ΑΣΘΕΝΕΣΤΕΡΕΣ = ΚΑΛΥΤΕΡΕΣ (§6).")
  (:guarantees       "Τι υπόσχεται όταν οι assumptions ισχύουν. ΙΣΧΥΡΟΤΕΡΕΣ = ΚΑΛΥΤΕΡΕΣ (§6).")
  (:failure-semantics "Τι συμβαίνει όταν ΔΕΝ ισχύουν: ανίχνευση, άρνηση, ανάκτηση. ΟΧΙ ασθενέστερα (§6).")
  (:operating-model  "Φόρτος, ταυτοχρονία, fault model, διάρκεια — ΚΟΙΝΟ για κάθε σύγκριση (AS5).")
  (:materiality      "Κατώφλι κάτω από το οποίο η διαφορά ΔΕΝ μετράει.")
  (:evidence         "Τι ακριβώς αποδεικνύει την παρουσία: citation path:Lx-Ly@sha256, εκτέλεση με exit code, ή θεώρημα με checker."))
 :evidence-floor
 (:citation-required t
  :execution-or-theorem-required t
  :agent-assertion-alone :ΑΠΑΡΑΔΕΚΤΟ)
 :presence-verdicts (:present :absent :spec-only :unknown)
 :rule "Ό,τι δεν συμπληρώνει και τα 7 πεδία με evidence ⇒ :unknown, ΠΟΤΕ :present.")
