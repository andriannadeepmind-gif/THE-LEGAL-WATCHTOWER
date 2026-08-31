---------------------------- MODULE PublicRoot ----------------------------
(* ΔΗΜΟΣΙΑ ΡΙΖΑ ΙΣΧΥΡΙΣΜΟΥ/ΤΕΚΜΗΡΙΟΥ. Διόρθωση δημιουργού 2: το σύστημα
   στοχεύει στην ισχυρότερη canonical, ΑΝΕΞΑΡΤΗΤΑ ΕΠΑΛΗΘΕΥΣΙΜΗ αναφορά.
   ΔΕΝ αποκτά juridical authority επειδή έχει Merkle root ή επειδή το
   γραφείο το δημοσιεύει. Η νομική αυθεντία προέρχεται από τις ΕΠΙΣΗΜΕΣ
   πηγές και τις θεσμικές πράξεις.                                        *)
EXTENDS FiniteSets
CONSTANTS Claims, UNSAFE
VARIABLES official, conflicting, published, rootSigned, assertedJuridical
vars == <<official, conflicting, published, rootSigned, assertedJuridical>>

TypeOK == /\ official \in [Claims -> BOOLEAN]      \* υπάρχει επίσημη πηγή/θεσμική πράξη
          /\ conflicting \in [Claims -> BOOLEAN]   \* αντιφατικές αυθεντίες
          /\ published \in [Claims -> BOOLEAN]
          /\ rootSigned \in [Claims -> BOOLEAN]    \* η ρίζα το υπέγραψε
          /\ assertedJuridical \in [Claims -> BOOLEAN]

Init == /\ official \in [Claims -> BOOLEAN]
        /\ conflicting \in [Claims -> BOOLEAN]
        /\ published = [c \in Claims |-> FALSE]
        /\ rootSigned = [c \in Claims |-> FALSE]
        /\ assertedJuridical = [c \in Claims |-> FALSE]

Sign(c) == /\ rootSigned' = [rootSigned EXCEPT ![c] = TRUE]
           /\ UNCHANGED <<official, conflicting, published, assertedJuridical>>

\* Δημοσίευση: αντιφατικές αυθεντίες ⇒ ΠΟΤΕ δημοσίευση ως ισχύον (I-15).
Publish(c) == /\ ~conflicting[c]
              /\ published' = [published EXCEPT ![c] = TRUE]
              /\ UNCHANGED <<official, conflicting, rootSigned, assertedJuridical>>

\* ΤΟ ΚΡΙΣΙΜΟ. SAFE: ο juridical χαρακτήρας είναι συνάρτηση ΜΟΝΟ της επίσημης
\* πηγής. UNSAFE: η υπογραφή της ρίζας αρκεί — ακριβώς ο σημερινός ισχυρισμός
\* «QES_VERIFIED» / «PRIMARY_SEMANTIC_AUTHORITY» στο authority.ttl.
AssertJuridical(c) ==
  /\ IF UNSAFE THEN rootSigned[c] ELSE official[c]
  /\ assertedJuridical' = [assertedJuridical EXCEPT ![c] = TRUE]
  /\ UNCHANGED <<official, conflicting, published, rootSigned>>

Next == \E c \in Claims : Sign(c) \/ Publish(c) \/ AssertJuridical(c)
Spec == Init /\ [][Next]_vars

\* ΟΥΣΙΑΣΤΙΚΗ (ΡΙΖΑ ≠ ΑΛΗΘΕΙΑ): κανένας juridical ισχυρισμός χωρίς επίσημη πηγή.
INV_RootIsNotSource == \A c \in Claims : assertedJuridical[c] => official[c]
\* Τίμια άγνοια: αντιφατικές αυθεντίες δεν δημοσιεύονται ποτέ ως ισχύον.
INV_ConflictNeverPublished == \A c \in Claims : published[c] => ~conflicting[c]
=============================================================================
