# LAWMAX — PUBLIC-SOURCE-TYPE-AUTHORITY-REGISTRY (canonical)
# ΤΟ ΔΗΜΟΣΙΟ ΝΟΜΙΚΟ ΣΥΜΠΑΝ ΩΣ ΑΠΑΡΙΘΜΗΣΙΜΟ ΜΗΤΡΩΟ — ΜΙΑ ΕΔΡΑ

**ΚΑΤΑΣΤΑΣΗ: `DESIGN-ONLY · ACTIVE SHARED TRUST FOUNDATION`.** Καμία γραμμή κώδικα, κανένα
freeze. Η **κανονική έδρα** (μία ανά έννοια) του απαριθμήσιμου δημόσιου νομικού σύμπαντος,
απαιτούμενη από `CHANGE-PROPOSAL-v1.4.md §4.1` (National Legal Census) — δίνει, ανά τύπο
πηγής, την **πλήρη authority-metadata** που το §4.1 census καταναλώνει ως ολική συνάρτηση.
**ΔΕΝ** είναι δεύτερη αρχιτεκτονική· είναι το λείπον ορφανό registry (POST-C2 closure,
§3.A/§4.7 της εντολής).

## 0. Αρχή — απαρίθμηση ΠΡΙΝ από το περιεχόμενο

Το σύμπαν δηλώνεται ως **census space** ανά τύπο (I-4.1a: κάθε θέση ακριβώς μία κατάσταση
`INGESTED | EXPLICITLY-ABSENT | QUARANTINED | UNKNOWN`). Καμία σιωπηλή απώλεια είναι
**δομικά αδύνατη**: μη-δηλωμένος τύπος επιφαίνεται ως `UNKNOWN`. Οι έννοιες
**«ειδικός/γενικός»** είναι **τεκμηριωμένες σχέσεις ανά νομικό ζήτημα** (`rel1:` USC §6.3,
scoped από adopted `ConflictPolicyBundle` — MLTP semantic-contract §4), **ΟΧΙ** μόνιμες
αυθαίρετες ετικέτες.

## 1. ΜΗΤΡΩΟ ΤΥΠΩΝ ΠΗΓΗΣ (`ST-nn`) — στήλες: εκδότης · αρμοδιότητα · εξουσιοδοτική βάση · επίσημη πηγή · δεσμευτικότητα · πεδίο (εδαφικό/προσωπικό/θεματικό) · έναρξη/λήξη ισχύος · collector/profile/compiler · coverage test

| ST | τύπος πράξης | εκδότης | εξουσιοδοτική βάση | επίσημη πηγή | δεσμευτικότητα | πεδίο | έναρξη / λήξη | collector · profile · compiler | coverage test |
|---|---|---|---|---|---|---|---|---|---|
| ST-01 | Σύνταγμα + αναθεωρήσεις | Αναθεωρητική Βουλή | άρ. 110 Σ | ΦΕΚ Α΄ | **primary, ύψιστη** | εθνικό / erga omnes / όλα | δημοσίευση→έναρξη ρητή· λήξη μόνο με αναθεώρηση | `legislation-ingestion` · `syntagma-profile` · Lisp compiler | ΦΕΚ Α΄ census × άρθρο |
| ST-02 | Τυπικός νόμος / κώδικας | Βουλή | άρ. 73–77 Σ | ΦΕΚ Α΄ | **primary** | εθνικό / κατά περιεχόμενο | `effective_from` (ή ρητή)· κατάργηση/λήξη/sunset | `legislation-ingestion` · `law-profile` · Lisp compiler | ΦΕΚ Α΄ × έτος × αριθμός |
| ST-03 | Πράξη Νομοθετικού Περιεχομένου (ΠΝΠ) | Πρόεδρος Δημ. + Υπ. Συμβ. | άρ. 44§1 Σ | ΦΕΚ Α΄ | **primary, υπό κύρωση** | εθνικό | έναρξη άμεση· **λήγει αν δεν κυρωθεί σε 40 ημέρες** (typed `ratification_deadline`) | `legislation-ingestion` · `pnp-profile` · Lisp compiler | ΦΕΚ Α΄ + κυρωτικός νόμος link |
| ST-04 | Κυρωτικός νόμος (συνθήκης/ΠΝΠ) | Βουλή | άρ. 28, 36§2, 44§1 Σ | ΦΕΚ Α΄ | **primary** | κατά το κυρούμενο | ως ST-02· δένει ST-10 | `legislation-ingestion` · `ratification-profile` · Lisp compiler | link κυρωτικός↔κυρούμενο |
| ST-05 | Προεδρικό διάταγμα | Πρόεδρος Δημ. | νομοθετική εξουσιοδότηση (άρ. 43 Σ) | ΦΕΚ Α΄ | **secondary (κανονιστικό)** | κατά εξουσιοδότηση | `effective_from`· λήξη με ανάκληση/κατάργηση | `legislation-ingestion` · `pd-profile` · Lisp compiler | ΦΕΚ Α΄ + εξουσιοδοτική βάση link |
| ST-06 | Υπουργική / Κοινή Υπουργική Απόφαση (ΥΑ/ΚΥΑ) | Υπουργός/-οί | ρητή νομοθετική εξουσιοδότηση | ΦΕΚ Β΄ | **secondary** | κατά εξουσιοδότηση | `effective_from`· ανάκληση | `government-source` · `mad-profile` · Lisp compiler | ΦΕΚ Β΄ + εξουσιοδότηση link (ΟΧΙ βάση ⇒ `insufficient-authorization`) |
| ST-07 | Κανονιστική πράξη ανεξάρτητης αρχής | ΑΑΔΕ/ΕΕΤΤ/ΑΠΔΠΧ/ΡΑΕ/Ε.Κ. κ.λπ. | ιδρυτικός νόμος αρχής | ΦΕΚ Β΄ (+ κανάλι αρχής) | **secondary** | θεματικό (αρμοδιότητα αρχής) | `effective_from`· ανάκληση | `government-source` · `iauth-profile` · Lisp compiler | census ανά αρχή × έτος |
| ST-08 | Περιφερειακή / δημοτική κανονιστική πράξη | Περιφέρεια / Δήμος | Κώδικας Δήμων/Περιφερειών | ΦΕΚ Β΄/τοπικό + Διαύγεια | **secondary, τοπικό** | **εδαφικό (ΟΤΑ)** | ανά πράξη | `government-source` · `ota-profile` · Lisp compiler | census ΟΤΑ × έτος (U-7 εύρος) |
| ST-09 | Εγκύκλιος / οδηγία / ερμηνευτική πράξη | διοίκηση | ιεραρχική/οργανωτική εξουσία | Διαύγεια / κανάλι φορέα | **`binding: interpretive-non-binding`** (typed· ΟΧΙ δίκαιο) | θεματικό | ανά πράξη | `government-source` · `circular-profile` · parser | χωριστός census space `binding:false` |
| ST-10 | Διεθνής συνθήκη / πρωτόκολλο / επιφύλαξη / κύρωση | Κράτος (κύρωση Βουλή) | άρ. 28 Σ | ΦΕΚ Α΄ (κυρωτικός) + depositary | **primary (υπερνομοθετική, άρ.28§1)** | κατά τη συνθήκη | θέση σε ισχύ διεθνώς + εσωτερικά· καταγγελία | `treaty-collector` · `treaty-profile` · Lisp compiler | census συνθηκών × depositary link |
| ST-11 | Πρωτογενές ενωσιακό δίκαιο (Συνθήκες ΕΕ, Χάρτης) | ΕΕ | Συνθήκες ΕΕ | EUR-Lex/Cellar | **primary, υπεροχή** | ΕΕ / εθνικό (interaction) | κατά τη Συνθήκη | `eu-collector` · `eu-primary-profile` · Lisp compiler | Cellar CELEX census |
| ST-12 | Κανονισμός ΕΕ | ΕΕ | άρ. 288 ΣΛΕΕ | EUR-Lex/Cellar (ΕΕ Επίσημη Εφημερίδα) | **primary, άμεσης ισχύος** | ΕΕ / **άμεσα εφαρμοστέο** | `date_of_effect`· κατάργηση | `eu-collector` · `eu-regulation-profile` · Lisp compiler | CELEX × έτος |
| ST-13 | Οδηγία ΕΕ + εθνική μεταφορά | ΕΕ + Κράτος | άρ. 288 ΣΛΕΕ | Cellar + εθνικό ΦΕΚ (μεταφορά) | **primary (ΕΕ) → μεταφορά (εθνικό)** | ΕΕ→εθνικό | προθεσμία μεταφοράς· `EU-TRANSPOSITION` event | `eu-collector` · `eu-directive-profile` · Lisp compiler | οδηγία↔μεταφορά link (§4.5) |
| ST-14 | Απόφαση ΕΕ / delegated / implementing act | ΕΕ (Επιτροπή/Συμβ.) | άρ. 288–291 ΣΛΕΕ | Cellar | **secondary/primary κατά τύπο** | κατά αποδέκτη | `date_of_effect` | `eu-collector` · `eu-act-profile` · Lisp compiler | CELEX census |
| ST-15 | Ενωσιακό / διεθνές soft law | ΕΕ/διεθνείς οργανισμοί | — | επίσημο κανάλι οργανισμού | **`binding: soft-law-non-binding`** (typed) | καθοδηγητικό | ανά πράξη | `soft-law-collector` · `softlaw-profile` · parser | census space `authoritative:false` |
| ST-16 | Κανονιστική Συλλογική Σύμβαση Εργασίας / Διαιτητική Απόφαση | κοινωνικοί εταίροι / ΟΜΕΔ | ν.1876/1990 κ.λπ. | ΦΕΚ Β΄ / μητρώο ΣΣΕ | **secondary, όπου παράγει έννομα αποτελέσματα** | κλαδικό/επαγγελματικό/επιχειρησιακό | κήρυξη υποχρεωτικότητας· λήξη/καταγγελία | `government-source` · `cla-profile` · Lisp compiler | census ΣΣΕ × κλάδος |
| ST-17 | Ελληνική νομολογία | ΑΠ/ΣτΕ/Ελ.Συν./δικαστήρια ουσίας | δικαιοδοσία δικαστηρίου | επίσημη δημοσίευση/ECLI | **jurisprudential (§4.9 τάξεις)** | κατά αντικείμενο | χρόνος έκδοσης· later treatment | `legal-decisions` · `judgment-profile` · Lisp compiler | census δικαστήριο × έτος (U-7) |
| ST-18 | ΔΕΕ / ΕΔΔΑ νομολογία (επηρεάζει ελληνικό δίκαιο) | ΔΕΕ/ΕΔΔΑ | Συνθήκες/ΕΣΔΑ | Curia/HUDOC/ECLI | **jurisprudential, ερμηνευτικά δεσμευτική** | ΕΕ/ΕΣΔΑ→εθνικό | χρόνος έκδοσης | `legal-decisions` · `intl-judgment-profile` · Lisp compiler | Curia/HUDOC census |
| ST-19 | Γνωμοδότηση ΝΣΚ | ΝΣΚ | ν. περί ΝΣΚ | κανάλι ΝΣΚ | **`binding: advisory` (δεσμευτική μόνο επί αποδοχής)** | θεματικό | αποδοχή από όργανο | `government-source` · `nsk-profile` · parser | census ΝΣΚ × έτος |
| ST-20 | Αιτιολογική έκθεση / προπαρασκευαστικές εργασίες | Βουλή | — | Βουλή (πρακτικά) | **`binding: preparatory-non-binding`** (τελεολογία §4.3 μόνο ως πηγή) | ερμηνευτικό | ανά νομοσχέδιο | `legislation-ingestion` · `travaux-profile` · parser | link νόμος↔αιτιολογική |
| ST-21 | Δευτερογενής θεωρία (doctrine) | συγγραφείς | — | εκδότες (αδειοδότηση U-3) | **`authoritative: false`** | ερμηνευτικό | — | `doctrine-collector` · `doctrine-profile` · parser | census space `authoritative:false` (μόνο όπου νόμιμο) |

**Invariants:** (I-STR-a) κάθε ST έχει ≥1 collector, ≥1 profile, ≥1 compiler-plan, ≥1
coverage test — **καμία κατηγορία χωρίς αυτά** (audit source-registry completeness)·
(I-STR-b) `binding` είναι **typed κλειστό sum**, ποτέ ελεύθερο· (I-STR-c) πράξη χωρίς
εξουσιοδοτική βάση όπου απαιτείται ⇒ `insufficient-authorization` (ΟΧΙ σιωπηλή αποδοχή)·
(I-STR-d) εδαφικό/προσωπικό/θεματικό πεδίο υποχρεωτικό ανά αντικείμενο.

## 2. Source-specific encoding profiles / compilers (§3.B, §4.7 της εντολής)

Κάθε ST → **source-specific profile** (δομικοί κανόνες του τύπου) → **source-specific
compiler** (παράγει το κοινό Legal Object Model + Legal IR). Κανένα δημόσιο αντικείμενο
δεν δημοσιεύεται ως απλό PDF/αδόμητο κείμενο (invariant B της εντολής): κάθε πηγή περνά
τα 11 βήματα (authentic manifestation → provenance receipt → structural encoding →
source profile/compiler → Legal Object Model → **μη εκτελέσιμο** Legal IR → semantic
encoding κανόνων/προϋποθέσεων/εξαιρέσεων/αποτελεσμάτων → valid-time projection + audit/
known-time → σχέσεις στον υπεργράφο → verification/qualification → proof-carrying output).

**Έδρες (EXTEND, μία ανά profile):** `legislation-ingestion.lisp`, `government-source.lisp`,
`legal-decisions.lisp`, `corpus-eu-links.lisp`/`eu-interop-layer.lisp`,
`pdf-authority.lisp`, `legal-ast.lisp`, `consolidation-engine.lisp`. Οι profiles ST-01..21
είναι **νέες capabilities πάνω σε αυτές τις έδρες** (crosswalk CAP), **ΟΧΙ** νέα stores.
Το semantic encoding περνά **υποχρεωτικά** από το `SECURE-SEMANTIC-INGRESS-CONTRACT`
(external bytes ≠ Lisp forms).

## 3. Τι ΔΕΝ κάνει

Καμία υλοποίηση των profiles/collectors (Implementation Book work packages). Δεν ορίζει
ουσιαστικές σχέσεις ειδικός/γενικός (adopted `ConflictPolicyBundle`). Δεν επινοεί
δεσμευτικότητα — αντλείται από την εξουσιοδοτική βάση. Το εύρος census (ποια δικαστήρια/
ΟΤΑ δημοσιεύουν νομίμως) = U-7 (external). Αδειοδότηση doctrine/full-text = U-3 (external).
