# SSP — SUPREME-SEARCH PROTOCOL
### Πρωτόκολλο εύρεσης του ανωτάτου δυνατού σχεδίου (E★★) για το THE LEGAL WATCHTOWER
**Κατάσταση: ΣΧΕΔΙΟ ΠΡΟΣ ΕΓΚΡΙΣΗ — καμία εκτέλεση, καμία εγγραφή στο repo.**

---

## 0. Τι ισχυρισμό παράγει (και τι ΔΕΝ ισχυρίζεται)

**Στόχος:** E★★ = το **μοναδικό undominated** σχέδιο πάνω σε έναν **κλειστό, ανεξάρτητα παραγόμενο** χώρο εφικτών αρχιτεκτονικών F_T, στο **χρονολογημένο σύνορο του σήμερα**, με **πιστοποιητικό κλεισίματος χώρου** — ώστε το θεώρημα greatest-element (∀x∈F_T: E★★ ≥_T x) να είναι **μη-κενό** και μηχανικά ελέγξιμο όταν ξεμπλοκάρει το toolchain.

**Τίμιο τελικό token αυτού του προγράμματος:** `SUPREME_CANDIDATE_OVER_CLOSED_DOMAIN` — ΟΧΙ `VERIFIED`. Το VERIFIED απαιτεί το machine-checked discharge (F★/Lean) + ανεξάρτητη αναπαραγωγή, που έπονται. Κάθε άλλο κλείσιμο = ψευδο-πράσινο και απαγορεύεται.

**Γιατί αυτό είναι το «βρήκαμε το ανώτατο»:** χωρίς κλειστό χώρο και tournament, το «ανώτατο» είναι αναπόδεικτη δήλωση. Με αυτά, γίνεται: *κανένα σχέδιο καμίας κανονικής κλάσης του σημερινού εφικτού χώρου δεν κυριαρχεί του E★★ σε κανέναν από τους 22 άξονες — και ο χώρος καλύπτει αποδεδειγμένα και τις κλάσεις των CoCounsel/Protégé/Harvey.*

---

## ΣΤΑΔΙΟ 0 — Πάγωμα οργάνων (πριν από ΚΑΘΕ υποψήφιο)

Παγώνονται και κατακερματίζονται (SHA-256, καταγραφή στο chat) **πριν** γεννηθεί οποιοσδήποτε νέος υποψήφιος:

1. **Η 22-αξονική τάξη ≥_T** — per-axis typed evidence lattices + δ_a (τα ήδη συνταγμένα LATTICES-AND-DELTAS οριστικοποιούνται εδώ).
2. **Μητρώο σκληρών invariants** (νόμοι δημιουργού ως τυπικοί περιορισμοί του χώρου): no-LLM-in-trusted-path, honest ignorance (typed UNKNOWN, ποτέ μαντεψιά), fail-closed παντού, μία έδρα ανά έννοια, single-writer αλήθεια, all-rights-reserved συμβατότητα.
3. **Διαδικασία ετυμηγορίας κυριαρχίας** για σχέδια (design-stage): σύγκριση σε **βαθμίδες εγγύησης** (guarantee-class ranks) ανά άξονα — όχι runtime νούμερα. Στους καθαρά ποσοτικούς άξονες (AX-17/18) η κυριαρχία στο στάδιο σχεδίου κρίνεται **μόνο σε επίπεδο κλάσης μηχανισμού** (π.χ. deterministic-core vs sampling-core)· αλλιώς **UNKNOWN → μπλοκάρει** (δεν περνά ποτέ ως ισότητα).
4. **Κανόνας τερματισμού** (FOC-16): το tournament τελειώνει ΜΟΝΟ όταν ένας πλήρης γύρος challengers δώσει μηδέν επιζώντες ΚΑΙ ο completeness critic βρει μηδέν ανεξερεύνητη κλάση, σε **2 συνεχόμενους** στεγνούς γύρους. **Κανένα όριο γύρων/χρόνου/agents δεν εξουσιοδοτεί επιτυχία** — αν εξαντληθεί ο προϋπολογισμός πριν στεγνώσει, το τίμιο αποτέλεσμα είναι `TOURNAMENT_INCOMPLETE`, όχι νικητής.

**Anti-gaming:** τα όργανα παγώνουν από τον συντονιστή ΠΡΙΝ τους υποψηφίους (ο κριτής δεν συντάσσει το κριτήριο που θα κρίνει — κλείσιμο του ευρήματος C1 του roadmap review)· ανεξάρτητος αντίπαλος ελέγχει ότι κανένα όργανο δεν είναι «κομμένο-ραμμένο» στο E★ (self-serving instrument check).

**Παραδοτέο:** `SSP-FREEZE.json` + hash.

---

## ΣΤΑΔΙΟ 1 — Κλείσιμο διαστάσεων: ο χώρος F_T (FOC-04)

**1α. Γραμματική διαστάσεων.** Από τους 22 άξονες + το B0 + το σύνορο έρευνας παράγεται το πλήρες σύνολο **σχεδιαστικών διαστάσεων μηχανισμού**, καθεμία με απαριθμήσιμες οικογένειες. Ενδεικτικός σκελετός (το στάδιο τον οριστικοποιεί):

| Διάσταση | Οικογένειες (ενδεικτικά) |
|---|---|
| D1 Υπόστρωμα συλλογιστικής | LLM-only · symbolic defeasible (JTMS/ASPIC+/Carneades/deontic) · neurosymbolic (LLM-propose + symbolic-verify) · proof-search με heuristic καθοδήγηση |
| D2 Θεμελίωση/grounding | top-k RAG · closed-corpus canonical identity + inclusion proofs · KG-mediated · υβρίδια |
| D3 Κατάσταση/χρόνος | mutable store · event-sourced · **bitemporal** event-sourced + transparency log |
| D4 Συντονισμός/εγγραφή | multi-writer · leader-based · single-writer + capability closure · BFT quorum · CRDT |
| D5 Διασφάλιση | tests-only · runtime gates/contracts · machine-checked kernel + refinement · PCC artifacts · fully-verified stack |
| D6 Μνήμη | vector store · append-only hash chain · signed reflective consolidation |
| D7 Provenance | logs · PROV-O · Merkle + recompute-and-compare · witnessed cosigning |
| D8 Ενορχήστρωση | ad-hoc agents · typed DAG plans + admission · transactional workflows |
| D9 Άγνοια/αβεβαιότητα | best-effort · calibrated confidence · typed honest-total UNKNOWN |
| D10 Εξέλιξη | redeploy · gated ratchet · proof-carrying continual evolution |

**1β. Κλάδεμα με απόδειξη, όχι με γούστο.** Κάθε οικογένεια που αποκλείεται παίρνει **elimination lemma**: είτε «παραβιάζει hard invariant H_k» (π.χ. LLM-only στη trusted διαδρομή) είτε «κυριαρχείται αυστηρά σε άξονα a από την f′ ανεξαρτήτως των άλλων επιλογών» (per-dimension dominance argument). Καμία σιωπηλή απόρριψη.

**1γ. Κανονικές κλάσεις D_T.** Το γινόμενο των επιζωσών οικογενειών κβαντίζεται σε **κανονικές κλάσεις** (quotient κατά material equivalence). **Κρίσιμο για FOC-04 μη-κενότητα:** στο D_T περιλαμβάνονται ρητά και οι **εμπορικές κλάσεις** (η κλάση των CoCounsel/Protégé/Harvey: LLM-in-path + RAG + citation-validation + agent teams) και η κλάση του **B0** — άρα U_T ανεξάρτητο, μη-κενό, D_T ≠ {winner}, τίποτα post-hoc. Απαγορευμένα σχήματα (D_T={winner}, winner-only U_T) ελέγχονται από negative controls NC-14/NC-24.

**Ορισμός εφικτότητας (δύο, ρητά διακριτοί):** F_T = σχέδια **κατασκευάσιμα σήμερα** με την υπάρχουσα τεχνολογία (ο χώρος του θεωρήματος)· η υλοποιησιμότητα **ως διάδοχος του B0 με πεπερασμένο delta** είναι η ξεχωριστή υποχρέωση FOC-19/T7 και δηλώνεται χωριστά — δεν συγχέονται.

**Agents:** ~8 dimension-derivation + 2 αντίπαλοι (κυνήγι χαμένης διάστασης · κυνήγι αδικαιολόγητου κλαδέματος).
**Παραδοτέα:** `DIMENSIONS.md`, ενημέρωση `DomainModel.lean` (η δομή Arch = το F_T), `ELIMINATION-LEMMAS.md`.

---

## ΣΤΑΔΙΟ 2 — Frontier sweep (χρονολογημένο σύνορο, πραγματική έρευνα)

Web-research agents σαρώνουν το πραγματικό σύνορο του 2026 ανά περιοχή — με URL + ημερομηνία πρόσβασης σε κάθε ισχυρισμό, UNKNOWN όπου οι πηγές συγκρούονται:

- Formal legal reasoning: ASPIC+, Carneades, defeasible deontic logics, LogiKEy, formal case-based reasoning.
- Neurosymbolic verification & verified extraction· proof-carrying answers/code.
- Verified stacks: F★/EverParse, Lean 4, Coq, CompCert, Perennial — τρέχουσα ωριμότητα.
- Integrity/transparency: RFC 6962/9162, C2SP witnessing, sigstore, TUF.
- Κατανεμημένη ακεραιότητα: BFT, quorum systems, CRDTs.
- Agentic orchestration research (τρέχουσες αρχιτεκτονικές πολλαπλών πρακτόρων).
- **Επανέλεγχος των 3 εμπορικών baselines** στο cutoff (δηλωμένοι μηχανισμοί — μήπως άλλαξαν· αν ναι, νέο comparator epoch κατά FOC-17).

**Σκοπός:** (α) καμία οικογένεια μηχανισμού να μη λείπει από το F_T· (β) η κορυφαία οικογένεια κάθε διάστασης να επιβεβαιωθεί έναντι του state of the art· (γ) `FRONTIER-CERTIFICATE.md` με ημερομηνία — το open-world άγκιστρο του FOC-17 (νέα κλάση μετά το cutoff ⇒ επανάνοιγμα εποχής).

**Agents:** ~8–10 research + 1 completeness critic.
**Πύλη δημιουργού #1:** μετά τα Στάδια 1–2 σου παρουσιάζω **τον κατάλογο κανονικών κλάσεων + τα elimination lemmas + το frontier certificate** για ρητή έγκριση πριν το tournament.

---

## ΣΤΑΔΙΟ 3 — Challenger tournament (FOC-16, universal escalation)

**3α. Steelman ανά κλάση.** Για ΚΑΘΕ κανονική κλάση C_i (αναμένονται ~10–16): ένας **ανεξάρτητος architect agent με φρέσκο πλαίσιο** χτίζει το **ισχυρότερο δυνατό** σχέδιο εντός της κλάσης. Ο architect λαμβάνει: ορισμό κλάσης + 22 άξονες + hard invariants + frontier — **ΟΧΙ το σχέδιο του incumbent** (αποτροπή αγκύρωσης· πραγματικοί, όχι αχυρένιοι, αντίπαλοι).

**3β. Κρίση.** Incumbent αφετηρίας: το E★ (seed). Για κάθε challenger, panel 3 κριτών ανά αμφισβητούμενο άξονα, με τα παγωμένα lattices, **αυστηρά μη-αντισταθμιστικά** — το verdict schema έχει ΜΟΝΟ per-axis πεδία· πεδίο συνολικού σκορ **δεν υπάρχει** ώστε η αντιστάθμιση να είναι δομικά αδύνατη, όχι απαγορευμένη.

**3γ. Εκβάσεις ανά challenger:**
- `DOMINATED` — χάνει σε ≥1 άξονα, δεν κερδίζει πουθενά: καταγράφεται με το proof του.
- `WINS-ON-AXIS-a` — κερδίζει κάπου: ο μηχανισμός του **απορροφάται** στη σύνθεση ή ο incumbent αντικαθίσταται.
- `INCOMPARABLE` — **δεν αγνοείται ποτέ** (FOC-16): γεννά υποχρέωση σύνθεσης που να κυριαρχεί και των δύο, αλλιώς το πρόγραμμα μπλοκάρει με ρητή αναφορά.

**3δ. Βρόχος μέχρι στεγνώματος.** Μετά από κάθε απορρόφηση: επανακρίνονται οι επηρεαζόμενοι challengers· νέοι challengers από τον completeness critic («ποια κλάση/υβρίδιο δεν δοκιμάστηκε;»). Τερματισμός μόνο με τον παγωμένο κανόνα του Σταδίου 0.

**Agents:** ~12–16 architects + panels + synthesizer + critics· συνολικά **~40–80** στους γύρους.
**Παραδοτέα:** `challengers/CH-<class>.md` (πλήρη σχέδια), `tournament/ROUND-n-VERDICTS.json` (per-axis, με αιτιολογία), ledger απορροφήσεων.

---

## ΣΤΑΔΙΟ 4 — Σύνθεση E★★ + per-class άνω φράγματα

1. **E★★**: σύνθεση του τελικού undominated σχεδίου από το absorption set (E★ + ό,τι κέρδισε), σε ένα συνεκτικό, κατασκευάσιμο-σήμερα αρχιτεκτονικό κείμενο, γειωμένο στο B0 (ποιες έδρες κρατά, τι προσθέτει).
2. **Upper-bound lemmas**: για ΚΑΘΕ κλάση C_i, σκίτσο λήμματος «κάθε μέλος της C_i ≤_T E★★, διότι <επιχείρημα μηχανισμού>» — αυτά γίνονται ο σκελετός case-analysis της Lean απόδειξης του greatest-element (το βήμα που κάνει το θεώρημα αποδείξιμο και όχι ευχή).
3. **Αντίπαλος διαφυγής:** προσπαθεί να κατασκευάσει μέλος κάποιας κλάσης που ξεφεύγει από το λήμμα της· κάθε επιτυχία του ⇒ επιστροφή στο Στάδιο 3.

**Πύλη δημιουργού #2:** έγκριση του E★★ + των upper bounds.

---

## ΣΤΑΔΙΟ 5 — Πιστοποιητικό κλεισίματος + τίμια κατάσταση

`DOMAIN-CLOSURE-CERTIFICATE.md`: το πλήρες επιχείρημα ότι το D_T καλύπτει το F_T στο χρονολογημένο σύνορο· checklist FOC-04 (U_T μη-κενό/ανεξάρτητο, D_T≠{winner}, τίποτα post-hoc)· ρητά τα ΑΝΟΙΧΤΑ (open-world: νέα κλάση μετά το cutoff επανανοίγει την εποχή — FOC-17)· και το χαρτογράφημα προς το machine-checking (ποιο λήμμα → ποιο Lean/F★ obligation).

**Τελικό status:** `SUPREME_CANDIDATE_OVER_CLOSED_DOMAIN` + ό,τι μπλοκάρει το VERIFIED, κατονομασμένο. Το συνολικό study status παραμένει `FINAL_OPTIMALITY_BLOCKED` μέχρι το πλήρες discharge — fail-closed, όπως ορίζει ο νόμος σου.

---

## Εγκάρσιοι κανόνες τιμιότητας (ισχύουν παντού)

- Όργανα παγωμένα + hashed **πριν** τους υποψηφίους· αντίπαλος ελέγχει candidate-independence.
- Challengers από agents **χωρίς πρόσβαση στο σχέδιο του incumbent**.
- Μη-αντιστάθμιση **δομικά** (δεν υπάρχει πεδίο aggregate στο schema).
- UNKNOWN ποτέ ισότητα/πέρασμα· INCOMPARABLE ποτέ δεν πετιέται.
- Κανένα cap δεν εξουσιοδοτεί επιτυχία· εξάντληση ⇒ `TOURNAMENT_INCOMPLETE`.
- Κάθε στάδιο: εκτέλεση → ανεξάρτητη αντιπαλική επιθεώρηση → κλείσιμο ευρημάτων → αναφορά σε σένα.
- Καμία εγγραφή στο repo· όλα τα παραδοτέα εκτός repo, με hashes.

## Κλίμακα & πύλες

| Στάδιο | Agents (εκτίμηση) | Πύλη δημιουργού |
|---|---|---|
| 0 Freeze | 2–3 | hash στο chat |
| 1 Closure | ~10 | — |
| 2 Frontier | ~10 | **Έγκριση #1: κλάσεις + lemmas + frontier** |
| 3 Tournament | ~40–80 (γύροι) | — |
| 4 Synthesis | ~8 | **Έγκριση #2: E★★ + upper bounds** |
| 5 Certificate | ~4 | **Έγκριση #3: closure certificate** |

Σύνολο: **~80–120 agents**, πολλές ώρες, σε διαδοχικά workflows (μένω στον βρόχο ανάμεσά τους).

## Σχέση με ό,τι ήδη υπάρχει

- Το **E★** dossier = ο **seed incumbent** του tournament (όχι το τελικό «ανώτατο»).
- Το **B0 map** = οι περιορισμοί κατασκευασιμότητας + οι έδρες που κληρονομούνται.
- Τα **LATTICES-AND-DELTAS** (αν έχουν συνταχθεί) = πρώτη ύλη του Σταδίου 0.
- Ο **πλήρης χάρτης μετάβασης** (census/crosswalk/DAG) και το **formal scaffold** ξανατρέχουν ΜΕΤΑ το E★★ — πάνω στο σωστό, τελικό σχέδιο, όχι στο seed. (Γι' αυτό ήταν σωστό που τα σταμάτησες: σειρά προτεραιότητας.)
