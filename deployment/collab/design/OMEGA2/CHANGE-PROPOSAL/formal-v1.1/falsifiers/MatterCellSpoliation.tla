---------------------- MODULE MatterCellSpoliation ----------------------
(* KT3 falsifier. Παραλλαγή του MatterCell με ΙΣΤΟΡΙΚΟ everHeld: υλικό που *)
(* ΚΑΠΟΤΕ τέθηκε υπό νόμιμη διακράτηση. Το ClearHold είναι ΧΩΡΙΣ           *)
(* εξουσιοδότηση (όπως στο σημερινό μοντέλο). Δείχνει ότι υλικό υπό        *)
(* διακράτηση φτάνει σε "erased" ενώ το INV_HoldExcludesErasure (τρέχον    *)
(* hold) μένει πράσινο — σπολίαση αποδεικτικού υλικού.                     *)
EXTENDS Naturals, FiniteSets
CONSTANTS Matters
Places == {"primary","replica","backup","index"}
VARIABLES keyState, loc, hold, everHeld, status
vars == <<keyState, loc, hold, everHeld, status>>
TypeOK == /\ keyState \in [Matters -> {"live","destroyed"}]
          /\ loc \in [Matters -> SUBSET Places]
          /\ hold \in [Matters -> BOOLEAN]
          /\ everHeld \in [Matters -> BOOLEAN]
          /\ status \in [Matters -> {"active","cryptoerased","erased"}]
Init == /\ keyState=[m \in Matters|->"live"] /\ loc=[m \in Matters|->Places]
        /\ hold=[m \in Matters|->FALSE] /\ everHeld=[m \in Matters|->FALSE]
        /\ status=[m \in Matters|->"active"]
SetHold(m)  == /\ ~hold[m] /\ status[m]#"erased"
               /\ hold'=[hold EXCEPT ![m]=TRUE] /\ everHeld'=[everHeld EXCEPT ![m]=TRUE]
               /\ UNCHANGED <<keyState,loc,status>>
ClearHold(m)== /\ hold[m] /\ hold'=[hold EXCEPT ![m]=FALSE]   \* ΧΩΡΙΣ εξουσιοδότηση
               /\ UNCHANGED <<keyState,loc,everHeld,status>>
CryptoErase(m)== /\ status[m]="active" /\ keyState'=[keyState EXCEPT ![m]="destroyed"]
               /\ status'=[status EXCEPT ![m]="cryptoerased"] /\ UNCHANGED <<loc,hold,everHeld>>
Purge(m,p)  == /\ ~hold[m] /\ p \in loc[m] /\ loc'=[loc EXCEPT ![m]=loc[m]\{p}]
               /\ UNCHANGED <<keyState,hold,everHeld,status>>
DeclareErased(m)== /\ keyState[m]="destroyed" /\ loc[m]={} /\ ~hold[m]
               /\ status'=[status EXCEPT ![m]="erased"] /\ UNCHANGED <<keyState,loc,hold,everHeld>>
Next == \E m \in Matters : SetHold(m)\/ClearHold(m)\/CryptoErase(m)\/DeclareErased(m)
                            \/ \E p \in Places : Purge(m,p)
Spec == Init /\ [][Next]_vars
INV_HoldExcludesErasure == \A m \in Matters : ~(hold[m] /\ status[m]="erased")
\* ΟΥΣΙΑΣΤΙΚΗ: ό,τι ΚΑΠΟΤΕ τέθηκε υπό διακράτηση δεν καταστρέφεται χωρίς
\* καταγεγραμμένη εξουσιοδότηση εκκαθάρισης (που το μοντέλο ΔΕΝ έχει ⇒ σπάει).
INV_NoSpoliation == \A m \in Matters : everHeld[m] => status[m]#"erased"
=========================================================================
