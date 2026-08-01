# [0124] — CAPTURE-BOUNDARY-CLOSURE-3 · ΔΥΟ P0 ΠΑΡΑΚΑΜΨΕΙΣ ΚΑΙ ΔΥΟ ΨΕΥΔΟ-ΠΡΑΣΙΝΕΣ ΕΓΓΥΗΣΕΙΣ
**Claude · 2026-08-01 · branch `claude/lawmax-level7-vcct-rsm` · πάνω στο `7b36c98b`**

Ο δημιουργός έτρεξε ξανά τον κώδικα και βρήκε **δύο κρίσιμες παρακάμψεις και δύο
ψευδο-πράσινες εγγυήσεις**. Κάθε μία ήταν σωστή. Δ4–Δ9 δεν αγγίχτηκαν.

---

## P0-①  `RESOLVE_NO_XDEV` από το «/» — η άγκυρα απέρριπτε κάθε νόμιμο mountpoint

> «/tmp και /workspace απορρίφθηκαν με EXDEV, και η adversarial suite έδωσε
> 8 passed / 16 failed. Αυτό θα χτυπήσει ακριβώς Docker volumes/bind mounts.»

**Το σφάλμα ήταν εννοιολογικό, όχι τυπογραφικό.** Το `NO_XDEV` απαντά στην
ερώτηση «μένει η διάσχιση στο ίδιο filesystem;» — **σωστή** ερώτηση μέσα στο
candidate δέντρο, **λάθος** για τη διαδρομή προς την άγκυρα, αφού κάθε άγκυρα σε
container **είναι** mountpoint. Στο δικό μου περιβάλλον το `/tmp` τυχαίνει να
είναι στο ίδιο mount με τη ρίζα — γι' αυτό δεν φάνηκε. Αυτό δεν είναι
δικαιολογία· είναι η απόδειξη ότι το test δεν άσκησε ποτέ την ιδιότητα.

**Η δομή τώρα:**
- **Έμπιστος launcher** (`open_anchor`): ανοίγει **μία φορά** τις δύο άγκυρες,
  διασχίζοντας συνιστώσα-προς-συνιστώσα με `BENEATH|NO_SYMLINKS` — **χωρίς**
  `NO_XDEV` — και **επαληθεύει mount-id** (από `/proc/self/fdinfo`), **owner**
  και **mode**: το vault πρέπει να ανήκει στην τρέχουσα ταυτότητα και να μην
  είναι group/world-writable· το inbox δεν επιτρέπεται world-writable χωρίς sticky.
- **Η `capture()` δεν βλέπει ποτέ pathname**: παίρνει τα `Anchor` και από εκεί
  και κάτω **μόνο** relative `openat2` με `BENEATH|NO_SYMLINKS|NO_XDEV|O_CLOEXEC`.

**Μάρτυρες σε πραγματικά mounts** (`capture-mountpoint-test.sh`, δημιουργεί
όντως tmpfs + bind mount):

```
  ok  capture ΠΕΤΥΧΕ πάνω σε πραγματικά mountpoints (inbox mnt=45, vault mnt=46)
  ok  τα δύο anchors σε ΔΙΑΦΟΡΕΤΙΚΑ mounts — ο έλεγχος ΔΕΝ είναι τετριμμένος
  ok  το inbox ΔΕΝ είναι στο mount της ρίζας (root mnt=37)
  ok  nested mount ΜΕΣΑ στο candidate ⇒ ΑΡΝΗΣΗ (το NO_XDEV ΚΑΤΩ από την άγκυρα ΠΑΡΑΜΕΝΕΙ)
  ok  symlink στην άγκυρα ⇒ symlink-in-anchor (η άμυνα ΔΕΝ χαλάρωσε)
  ok  η ΠΑΛΙΑ λογική ΑΠΟΡΡΙΠΤΕΙ το νόμιμο mountpoint (REJECTED tmpfs errno=18(EXDEV))
```

Το τελευταίο αναπαράγει **ακριβώς** το EXDEV που είδε ο δημιουργός.

## P0-②  Η ασφαλής τοπολογία υπήρχε αλλά δεν ήταν η μοναδική

> «Το κανονικό orchestrator και το ingestion εξακολουθούν να έχουν ολόκληρο το
> `/app/output:rw`. Το topology test εξετάζει μόνο το `services.producer`.»

Το χειρότερο είδος ψευδο-πράσινου: ο ελεγκτής κοίταζε ακριβώς εκεί όπου ήξερε ότι
θα βρει το σωστό. **Τώρα κάθε service** του `docker-compose.yml` έχει την ίδια
τοπολογία και **ο verifier τα απογράφει όλα**:

```
  ok  services με το runtime image: corpus-service, ingestion, orchestrator, producer
  ok  corpus-service: user=11003 · output ro · κανένα releases/keys/authority rw
  ok  ingestion:      user=11002 · output ro · μόνο candidates rw
  ok  orchestrator:   user=11002 · output ro · κλειδιά ro
  ok  producer:       user=11002 · output ro · μόνο candidates rw
```

Απαγορευμένα για **κάθε** service: εγγράψιμο `/app/output`, οποιοδήποτε
`releases/` rw, εγγράψιμα ιδιωτικά κλειδιά, οποιοδήποτε mount του authority
store. Το `authority-v2-proofs` δηλώνεται **ρητά** ως εξαίρεση (προνομιούχος
εκτελεστής αποδείξεων) **με έλεγχο** ότι δεν τρέχει το runtime image — αλλιώς η
εξαίρεση θα ήταν κερκόπορτα. 7 μεταλλαγμένες τοπολογίες απορρίπτονται.

## P1-③  Το «υποχρεωτικό profile» παρακαμπτόταν από το ίδιο το API

> «`capture(..., canonical_profile=<οποιοδήποτε dict>)` … χωρίς επικύρωση.»

Ο φρουρός ήταν στην πόρτα, όχι στον **τύπο**. Τώρα υπάρχει `CanonicalProfile`,
αδιαφανής, που παράγεται **μόνο** από `load_canonical_profile()`. Τα production
APIs απορρίπτουν οτιδήποτε άλλο με `canonical-profile-not-validated`, και η
`capture`/`measure` δέχονται **μόνο** επαληθευμένο `Anchor` (`anchor-required`).

## P1-④  Η «πλήρης απογραφή» ήταν glob-based

> «Έβαλα τεχνητή αποτυχημένη απόδειξη στο `authority-v2/other/forgotten-proof.py`:
> ο runner την αγνόησε και επέστρεψε exit 0.»

**Ένας κατάλογος εισόδων.** Όλες οι αποδείξεις μετακινήθηκαν στο
`authority-v2/proofs/` (επίπεδος κατάλογος — υποκατάλογος ⇒ σφάλμα). Ο runner
σαρώνει **αναδρομικά κάθε regular file** κάτω από το `authority-v2/` και
απαιτεί: ό,τι είναι μέσα στο `proofs/` να απογράφεται· **κανένα εκτελέσιμο
απόδειξης εκτός** — εκτός αν δηλώνεται ρητά ως `tool-*` με λόγο.

Μόλις έγινε αναδρομικός, **έπιασε αμέσως δύο αδήλωτα εκτελέσιμα** (`ceremony.sh`,
και τον ίδιο τον runner) που τώρα δηλώνονται ως εργαλεία. Και το mutant του
δημιουργού κοκκινίζει:

```
  ok  ΞΕΧΑΣΜΕΝΗ απόδειξη ΕΚΤΟΣ του καταλόγου εισόδων (authority-v2/other/) ⇒ exit 1
  ok  ΑΔΕΣΠΟΤΟ εκτελέσιμο σε ΤΥΧΑΙΟ βάθος (authority-v2/a/b/c/) ⇒ exit 1
```

## Και τα δύο υπόλοιπα

- **`measure()` επιβάλλει τώρα τα ίδια συνολικά όρια** με τη φάση αντιγραφής
  (`max_files`, `max_file_bytes`, `max_total_bytes`).
- **Ο καθαρισμός έπαψε να καταπίνει σφάλματα**: το `_purge` επιστρέφει τις
  αποτυχίες και η capture τις κάνει ορατές ως **`cleanup-incomplete`**.

---

## ΑΡΙΘΜΟΙ — ΟΛΑ ΕΚΤΕΛΕΣΜΕΝΑ

| απόδειξη | exit | αποτέλεσμα |
|---|---|---|
| `bash authority-v2/run-proofs.sh` | 0 | **14 passed / 0 failed / 0 blocked** (64 αρχεία σαρώθηκαν αναδρομικά) |
| capture-mountpoint (tmpfs + bind) | 0 | **6/0** |
| capture-adversarial + fixed point | 0 | **27/0** (26 σενάρια) |
| capture-mutation-witness | 0 | **15/0** — 14/14 φονεύσιμες σκοτωμένες |
| proof-census-adversarial | 0 | **14/0** (με το mutant του δημιουργού) |
| producer-topology (ΟΛΑ τα services) | 0 | **13/0** |
| seat-differential · OS boundary · capability closure | 0 | **8/0 · 11/0 · 5/0** |
| ceremony · witness-quorum · gate-negative-fixtures | 0 | **8/0 · 8/0 · 12/0** |
| level7-disarm · release-authority · transparency-log | 0 | **20/0 · 14/0 · 21/0** |

## ΤΙ ΔΕΝ ΔΗΛΩΝΕΤΑΙ

- **Docker: BLOCKED — NOT EXECUTED.** `compose config` επικυρώθηκε και η
  **δηλωμένη** τοπολογία όλων των services ελέγχεται εκτελεστικά, αλλά **δεν
  υπάρχει docker daemon** εδώ.
- **CI: ΣΥΡΜΑΤΩΜΕΝΟ, ΟΧΙ ΠΡΑΣΙΝΟ.** `workflow_dispatch` ⇒ **403**, 0 runs,
  0 status contexts.
- Η Merkle αλλαγή παραμένει **ισχυρή ανίχνευση παλινδρόμησης, όχι φέρουσα
  απόδειξη** — όπως ακριβώς το διατύπωσε ο δημιουργός.
- **Δ2/Δ3 = IMPLEMENTED-NOT-PROVED. Ούτε CLOSED ούτε PROVED. Δ4–Δ9 δεν αγγίχτηκαν.**
