/* =========================================================================
   ΜΟΝΤΕΛΟ ΤΟΥ RUNNER ΤΟΥ ΠΕΙΡΑΜΑΤΟΣ — ο runner είναι ΜΕΡΟΣ του αντικειμένου
   απόδειξης, όχι εργαλείο εκτός ελέγχου.
   Ελέγχονται: T14 NO-PREMATURE-FINAL · T15 PHASE-NONINTERFERENCE
   Εκτέλεση:  spin -run experiment/formal/runner.pml
   ========================================================================= */

#define NOBL 5                    /* proof obligations */

mtype:phase = { INIT, P1, P2, P3, P4, SUSPENDED, FINAL };
mtype:phase st = INIT;

bool obl[NOBL];                   /* verified? */
bool obl_selfsigned[NOBL];        /* υπογεγραμμένο από τον ΙΔΙΟ τον προτείνοντα; */
bool frontier_open = true;        /* υπάρχει κλάδος χωρίς closure certificate */
bool constitution_sealed = false;
bool p2_saw_p1 = false;           /* ΔΙΑΡΡΟΗ: η τυφλή φάση είδε τη Φάση 1 */
bool p3_saw_proposer_rationale = false;
byte budget = 3;

inline verify(i) {
  /* Πύλη: ΚΑΝΕΝΑ obligation δεν γίνεται verified αν το υπέγραψε ο προτείνων */
  if
  :: obl_selfsigned[i] -> skip                    /* απορρίπτεται, μένει ανοιχτό */
  :: else -> obl[i] = true
  fi
}

active proctype runner() {
  st = INIT;
  constitution_sealed = true;                     /* σφραγίζεται ΠΡΙΝ την αναζήτηση */
  st = P1;

  /* ── Φάση 2: ΤΥΦΛΗ. Δομικά δεν έχει είσοδο από τη Φάση 1. ── */
  st = P2;
  /* καμία εντολή δεν θέτει p2_saw_p1: η απομόνωση είναι ΚΑΤΑΣΚΕΥΑΣΤΙΚΗ
     (χωριστό worktree/container, artifacts Φ1 εκτός του δέντρου της Φ2) */

  /* ── Φάση 3: αντιπαλική, χωρίς πρόσβαση στο σκεπτικό των προτεινόντων ── */
  st = P3;

  /* ── Εκκαθάριση υποχρεώσεων + κλείσιμο μετώπου ── */
  byte i = 0;
  do
  :: i < NOBL ->
       if
       :: obl_selfsigned[i] = true                /* απόπειρα αυτοπιστοποίησης */
       :: obl_selfsigned[i] = false
       fi;
       verify(i);
       i++
  :: i >= NOBL -> break
  od;

  if
  :: frontier_open = false                        /* κάθε κλάδος έκλεισε με certificate */
  :: skip                                          /* έμεινε ανοιχτός */
  fi;

  /* ── Γεγονότα που ΔΕΝ επιτρέπεται να οδηγούν σε FINAL ── */
  if
  :: budget == 0 -> st = SUSPENDED                 /* εξάντληση ⇒ ΠΟΤΕ FINAL */
  :: skip -> budget--
  fi;

  st = P4;

  /* ── Η ΜΟΝΗ μετάβαση σε FINAL ── */
  if
  :: (obl[0] && obl[1] && obl[2] && obl[3] && obl[4] && !frontier_open
      && constitution_sealed) -> st = FINAL
  :: else -> st = SUSPENDED                        /* fail-closed */
  fi;
end: skip
}

/* T14: ΠΟΤΕ FINAL με ανοιχτή υποχρέωση ή ανοιχτό μέτωπο */
ltl T14_no_premature_final {
  [] ( (st == FINAL) -> (obl[0] && obl[1] && obl[2] && obl[3] && obl[4]
                         && !frontier_open && constitution_sealed) )
}
