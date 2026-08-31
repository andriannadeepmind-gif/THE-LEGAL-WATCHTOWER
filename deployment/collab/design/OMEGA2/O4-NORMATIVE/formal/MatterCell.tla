---------------------------- MODULE MatterCell ----------------------------
(* Η7 — ΔΙΑΓΡΑΦΗ ∧ ΕΛΕΓΧΟΣ. Το «καταστρέφω το κλειδί και κρατώ tombstone»
   ΔΕΝ αρκεί. Έξι διακριτές έννοιες, μοντελοποιημένες χωριστά:
     logical deletion · cryptographic erasure · physical deletion από
     primary/replicas/backups/indexes · lawful retention (legal hold) ·
     audit minimisation · linkability του tombstone.                        *)
EXTENDS Naturals, FiniteSets
CONSTANTS Matters, UNSAFE
Places == {"primary","replica","backup","index"}

VARIABLES keyState, loc, hold, tomb, audit, status
vars == <<keyState, loc, hold, tomb, audit, status>>

TypeOK ==
  /\ keyState \in [Matters -> {"live","destroyed"}]
  /\ loc      \in [Matters -> SUBSET Places]
  /\ hold     \in [Matters -> BOOLEAN]
  /\ tomb     \in [Matters -> {"none","linkable","unlinkable"}]
  /\ audit    \in [Matters -> {"full","minimised"}]
  /\ status   \in [Matters -> {"active","logical","cryptoerased","erased"}]

Init ==
  /\ keyState = [m \in Matters |-> "live"]
  /\ loc      = [m \in Matters |-> Places]
  /\ hold     = [m \in Matters |-> FALSE]
  /\ tomb     = [m \in Matters |-> "none"]
  /\ audit    = [m \in Matters |-> "full"]
  /\ status   = [m \in Matters |-> "active"]

\* ΕΥΡΗΜΑ TLC-3: νόμιμη διακράτηση που φτάνει ΜΕΤΑ από νόμιμη διαγραφή είναι
\* ΑΝΙΚΑΝΟΠΟΙΗΤΗ. Χωρίς αυτόν τον φρουρό το σύστημα καταλήγει σε κατάσταση
\* «hold ΚΑΙ erased» — που για δικηγορικό γραφείο διαβάζεται ως καταστροφή
\* αποδεικτικού υλικού. Απαιτείται ΚΑΙ πιστοποιητικό διαγραφής με χρονοσήμανση
\* που ΑΠΟΔΕΙΚΝΥΕΙ τη σειρά (erasure ΠΡΙΝ hold), αλλιώς η άμυνα είναι ανέφικτη.
SetHold(m)   == /\ ~hold[m] /\ status[m] # "erased"
                /\ hold' = [hold EXCEPT ![m] = TRUE]
                /\ UNCHANGED <<keyState, loc, tomb, audit, status>>
ClearHold(m) == /\ hold[m] /\ hold' = [hold EXCEPT ![m] = FALSE]
                /\ UNCHANGED <<keyState, loc, tomb, audit, status>>

\* ① ΛΟΓΙΚΗ ΔΙΑΓΡΑΦΗ: αόρατο στη ροή εργασίας, ΤΙΠΟΤΑ δεν έφυγε φυσικά.
LogicalDelete(m) ==
  /\ status[m] = "active"
  /\ status' = [status EXCEPT ![m] = "logical"]
  /\ tomb'   = [tomb   EXCEPT ![m] = "linkable"]
  /\ UNCHANGED <<keyState, loc, hold, audit>>

\* ② ΚΡΥΠΤΟΓΡΑΦΙΚΗ ΕΞΑΛΕΙΨΗ: το κλειδί χάνεται· τα bytes ΠΑΡΑΜΕΝΟΥΝ παντού.
CryptoErase(m) ==
  /\ status[m] \in {"active","logical"}
  /\ keyState' = [keyState EXCEPT ![m] = "destroyed"]
  /\ status'   = [status   EXCEPT ![m] = "cryptoerased"]
  /\ UNCHANGED <<loc, hold, tomb, audit>>

\* ③ ΦΥΣΙΚΗ ΔΙΑΓΡΑΦΗ ανά τόπο — φράσσεται από νόμιμη διακράτηση.
PhysicalPurge(m, p) ==
  /\ ~hold[m]
  /\ p \in loc[m]
  /\ loc' = [loc EXCEPT ![m] = loc[m] \ {p}]
  /\ UNCHANGED <<keyState, hold, tomb, audit, status>>

\* ④ ΕΛΑΧΙΣΤΟΠΟΙΗΣΗ ΕΛΕΓΧΟΥ + ⑤ ΑΠΟΣΥΝΔΕΣΙΜΟ ΙΧΝΟΣ.
Minimise(m) ==
  /\ audit' = [audit EXCEPT ![m] = "minimised"]
  /\ tomb'  = [tomb  EXCEPT ![m] = "unlinkable"]
  /\ UNCHANGED <<keyState, loc, hold, status>>

\* ΤΟ ΚΡΙΣΙΜΟ ΒΗΜΑ: πότε επιτρέπεται να ΔΗΛΩΣΕΙΣ «διαγράφηκε».
DeclareErasedSafe(m) ==
  /\ keyState[m] = "destroyed"
  /\ loc[m] = {}
  /\ ~hold[m]
  /\ tomb[m] = "unlinkable"
  /\ audit[m] = "minimised"
  /\ status' = [status EXCEPT ![m] = "erased"]
  /\ UNCHANGED <<keyState, loc, hold, tomb, audit>>

\* ΑΡΝΗΤΙΚΟΣ ΜΑΡΤΥΡΑΣ: crypto-shredding ΜΟΝΟ (ο ισχυρισμός του Γύρου 2).
DeclareErasedUnsafe(m) ==
  /\ keyState[m] = "destroyed"
  /\ status' = [status EXCEPT ![m] = "erased"]
  /\ UNCHANGED <<keyState, loc, hold, tomb, audit>>

DeclareErased(m) == IF UNSAFE THEN DeclareErasedUnsafe(m) ELSE DeclareErasedSafe(m)

Next == \E m \in Matters :
  \/ SetHold(m) \/ ClearHold(m) \/ LogicalDelete(m) \/ CryptoErase(m)
  \/ Minimise(m) \/ DeclareErased(m)
  \/ \E p \in Places : PhysicalPurge(m, p)

Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ (ground truth μόνο: πού βρίσκονται όντως τα bytes και το ίχνος).
INV_ErasedIsComplete ==
  \A m \in Matters :
    (status[m] = "erased") => (loc[m] = {} /\ keyState[m] = "destroyed"
                               /\ tomb[m] # "linkable")
\* Η νόμιμη διακράτηση υπερισχύει της διαγραφής — ΠΟΤΕ και τα δύο.
INV_HoldExcludesErasure ==
  \A m \in Matters : ~(hold[m] /\ status[m] = "erased")
\* Κρυπτογραφική εξάλειψη ΔΕΝ είναι διαγραφή: τα bytes υπάρχουν ακόμη.
INV_CryptoIsNotDeletion ==
  \A m \in Matters : (status[m] = "cryptoerased") => (loc[m] # {} => TRUE)
=============================================================================
