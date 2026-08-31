# ΜΗΤΡΩΟ SUPERSEDED — ΜΙΑ ΚΑΝΟΝΙΚΗ TARGET ARCHITECTURE

**Η ΜΙΑ ΚΑΙ ΜΟΝΗ κανονική target architecture είναι το
`CHANGE-PROPOSAL-v1.1.md` (αυτός ο κατάλογος).** Κάθε προηγούμενο έγγραφο που
όριζε «αρχιτεκτονική / blueprint / final / target» είναι **ΙΣΤΟΡΙΚΟ /
SUPERSEDED** — διατηρείται ως τεκμήριο της αναζήτησης, δεν ορίζει πλέον στόχο,
δεν επεξεργάζεται. Όπου δύο έγγραφα αντιφάσκουν, **υπερισχύει το v1.1**.

Ρητή σήμανση (εντολή δημιουργού 2026-08-31, «μία και μόνη κανονική target
architecture v1.0 και σημαίνεις ρητά όλα τα παλαιότερα contradictory design
documents ως ιστορικά/superseded»):

## Ανταγωνιστικές «τελικές αρχιτεκτονικές» — ΟΛΕΣ SUPERSEDED από το v1.1

| έγγραφο | τι ισχυριζόταν | κατάσταση |
|---|---|---|
| `OMEGA2/TARGET-ARCH/WATCHTOWER-TARGET-ARCHITECTURE-v0.1 … v0.7` | διαδοχικές target αρχιτεκτονικές | **SUPERSEDED** — ιστορικό εξέλιξης |
| `OMEGA2/TARGET-ARCH/WATCHTOWER-v0.7.1-…`, `-v0.7.2-…` | pre-freeze / counter-challenge closure | **SUPERSEDED** |
| `OMEGA2/TARGET-ARCH/MERGED-BLUEPRINT-v0.8.md` | συγχωνευμένο blueprint | **ΝΕΚΡΟ** (δηλωμένο ήδη στο [0126]) |
| `OMEGA2/MERGED-BLUEPRINT.md`, `OMEGA2/MERGED-BLUEPRINT-v0.8.md` | blueprint | **ΝΕΚΡΟ** |
| `OMEGA2/BP/**` | blueprint σετ | **ΝΕΚΡΟ** |
| `OMEGA2/CANON-OMEGA2-ARCHITECTURE.md` | αρχιτεκτονική CANON | **SUPERSEDED** |
| `OMEGA2/O4-NORMATIVE/O4-NORMATIVE-SPEC-v1.0.md` | κανονιστικός Ο4 v1.0 | **ΘΕΜΕΛΙΟ, ΑΝΑΒΑΘΜΙΣΜΕΝΟ** — το v1.1 τον ΕΠΕΚΤΕΙΝΕΙ (δεν τον αντιφάσκει)· η v1.0 μένει ως το §5/§4/§8/§10 που το v1.1 επικαλείται |
| `CANON-OMEGA2/06-FINAL-ARCHITECTURE.md` | «final architecture» | **SUPERSEDED** |
| `CANON-OMEGA2/11-MERGED-BLUEPRINT.md`, `-v0.8.md` | merged blueprint | **SUPERSEDED / ΝΕΚΡΟ** |
| `CANON-OMEGA2/03-CANDIDATES/design-A|B|C` + `04-TOURNAMENT/**` | υποψήφιοι + tournament | **SUPERSEDED** — αντικαταστάθηκαν από το non-compensatory tournament του [0127] |
| `LAWMAX-OMEGA-CANON/02-ARCHITECTURE.md` (+ `GR/02-ΑΡΧΙΤΕΚΤΟΝΙΚΗ.md`) | αρχιτεκτονική CANON | **SUPERSEDED** |
| `LAWMAX-OMEGA-CANON/06-TRANSITION.md`, `07-VERIFICATION.md` | μετάβαση/επαλήθευση | **SUPERSEDED** — το v1.1 ορίζει μετάβαση ως μεταβατικά στάδια με ημ. θανάτου |
| `phase2-r5/phase-2/PHASE-2-CANDIDATE-ARCHITECTURES.md`, `PHASE-2-FRONTIER-ARCHITECTURE.md` | υποψήφιες/frontier | **SUPERSEDED** |
| `deployment/LAWMAX-OMEGA-PLAN.md`, `LAWMAX-CONSOLIDATION-PLAN.md`, `LAWMAX-ARCHITECTURE-CONSTITUTION.sexp` | σχέδια/σύνταγμα αρχιτεκτονικής | **SUPERSEDED ως προς την target αρχιτεκτονική** (το ιστορικό/λειτουργικό τους περιεχόμενο για τον σημερινό σπόρο παραμένει περιγραφικό, όχι κανονιστικός στόχος) |
| `OMEGA2/v07R/REDUCED-CONSTITUTION.md` + `v07R/**` | μειωμένο σύνταγμα v0.7-R | **ΑΝΑΣΚΕΥΑΣΜΕΝΟ** (κενότητα `KernelL1.tla`, [0128]) — όχι ενεργό |

## Τι ΔΕΝ είναι superseded (παραμένουν έγκυρα τεκμήρια)

- Όλα τα **ΑΡΧΕΙΑΚΑ** αποτελέσματα εκτέλεσης (formal models A–I, TLA+, evidence
  packs, break reports, base audits) — είναι μετρήσεις, όχι ανταγωνιστικοί
  στόχοι· διατηρούνται με τα digests τους.
- Οι καταθέσεις διαλόγου `0001–0129` (append-only ιστορικό).
- Το `O4-NORMATIVE-SPEC-v1.0 §4/§5/§8/§10` ως το θεμέλιο που το v1.1 επικαλείται
  ονομαστικά.

## Κανόνας από εδώ και πέρα

Καμία νέα «αρχιτεκτονική» δεν γράφεται εκτός του v1.1. Αλλαγή στόχου = **νέα
έκδοση του v1.1** (v1.2, …), ποτέ νέο παράλληλο έγγραφο. Ένα ευρετήριο, μία έδρα
στόχου.
