---------------------------- MODULE Migration ----------------------------
(* Η9 — Η ΑΠΟΔΕΙΞΗ ΕΠΙΒΙΩΝΕΙ ΤΗ ΜΕΤΑΝΑΣΤΕΥΣΗ ΣΧΗΜΑΤΟΣ.
   Το ήδη παρατηρημένο «FAIL inclusion: text-hash-mismatch» είναι αυτή η
   κλάση. Η απόδειξη πρέπει να ΦΕΡΕΙ ΜΕΣΑ ΤΗΣ το αναγνωριστικό
   κανονικοποιητή, και ο επαληθευτής να ΔΙΑΤΗΡΕΙ τους παλαιούς.            *)
EXTENDS Naturals, FiniteSets
CONSTANTS MaxV, UNSAFE
VARIABLES schemaV, proofs, retained
vars == <<schemaV, proofs, retained>>

\* proof == [cv |-> κανονικοποιητής που χρησιμοποιήθηκε, tagged |-> φέρει tag;]
Proofs == [cv : 1..MaxV, tagged : BOOLEAN]

TypeOK == /\ schemaV \in 1..MaxV
          /\ proofs \subseteq Proofs
          /\ retained \subseteq 1..MaxV

Init == /\ schemaV = 1 /\ proofs = {} /\ retained = {1}

IssueProof ==
  /\ proofs' = proofs \cup {[cv |-> schemaV, tagged |-> ~UNSAFE]}
  /\ UNCHANGED <<schemaV, retained>>

Migrate ==
  /\ schemaV < MaxV
  /\ schemaV' = schemaV + 1
  /\ retained' = retained \cup {schemaV + 1}
  /\ UNCHANGED proofs

\* Επαλήθευση: με tag ⇒ επιλέγει τον κανονικοποιητή της απόδειξης (αν
\* διατηρείται). Χωρίς tag ⇒ αναγκαστικά ο ΤΡΕΧΩΝ ⇒ αστοχία μετά τη μετανάστευση.
Verifies(p) == IF p.tagged THEN p.cv \in retained ELSE p.cv = schemaV

Next == IssueProof \/ Migrate
Spec == Init /\ [][Next]_vars

INV_OldProofsStillVerify == \A p \in proofs : Verifies(p)
=============================================================================
