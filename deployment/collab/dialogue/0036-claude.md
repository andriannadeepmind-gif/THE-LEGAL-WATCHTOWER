# [0036] Claude → Κριτή+δημιουργό · 2026-07-09 · CI-unblockers ΚΛΕΙΣΤΑ + Constitution Output Audit (A–F)

Αποφάσεις δημιουργού: (i) ΝΑΙ fek-html-parser· (ii) **Δ1 αυστηρά test-scoped** +
invariant tests· scope = pre-existing CI-unblockers· + constitution.zip audit A–F
στο τρέχον HEAD. Commits: `e5179fe6` (unblockers). Πολιτική δημιουργού:
**telemetry μόνο ΕΚΤΟΣ canonical ELI/legal σελίδων — canonical = inert, static,
hashable authority artifacts.**

## Μέρος 1 — CI-unblockers: ΟΛΟ το standalone loop πλέον πράσινο τοπικά

| test | πριν | μετά | τι ήταν |
|---|---|---|---|
| corpus-fingerprint | 27/3 | **30/30** | stale padded eIds (art_001) vs canonical unpadded (art_1) — πηγή ΑΘΙΚΤΗ |
| fek-html-parser | 10/1 | **11/11** | stale flatten expectation vs documented paragraph-structure |
| document-fetch | 23/0 | **29/29** | +6 ΝΕΑ invariant tests Δ1 (ζητούμενο δημιουργού) |
| fek-ingestion | 0/10 | **10/10** | Δ1 scoped binding στο let του τοπικού server |
| ingestion-e2e | 0/10 | **10/10** | ομοίως |
| government-source | 4/3 | **7/7** | ομοίως |
| review-service | 14/6 | **20/20** | stale test vs hardened υπηρεσία (POST+CSRF token+data-action) — υπηρεσία ΑΘΙΚΤΗ |

**Δ1 όπως το όρισες:** `*allow-loopback-fetch*` default **NIL** (παραγωγική
πολιτική αμετάβλητη)· δένεται ΜΟΝΟ ως πρώτο binding στο `let` του τοπικού server
κάθε test (γνήσιο dynamic scope — unwind ⇒ ξανά κλειστό)· ΟΧΙ env flag. Με
binding: ΜΟΝΟ loopback ανοίγει· 10/8, 172.16/12, 192.168/16, 169.254/16 (incl.
metadata IP), 0/8, multicast **πάντα** μπλοκαρισμένα. Invariants:
```
✓ DEFAULT: 127.0.0.1 ⇒ NIL   ✓ DEFAULT: localhost ⇒ NIL
✓ ΜΕ binding: loopback ⇒ T   ✓ ΜΕ binding: private/metadata ⇒ NIL
✓ ΜΕΤΑ unwind: ξανά NIL      ✓ δημόσιο DNS: όπως πριν
```
Ολομέλεια 22/23 (advisor)· golden 8/8· verify-truth 22/22 — αμετάβλητα.

## Μέρος 2 — Constitution Output Audit: **το zip ΔΕΝ ήταν παλιό**

Έλεγξα ΚΑΙ το τοπικό `output/constitution` ΚΑΙ τους ΤΡΕΧΟΝΤΕΣ γεννήτορες.
**ΚΑΙ ΤΑ 6 ισχύουν στο τρέχον HEAD** — με ακριβείς έδρες:

```
A. standalone JSON-LD : 124/124 PARSE FAIL («Extra data») — ΔΥΟ top-level objects.
   ΕΔΡΑ: html-rdfa-generator.lisp:537 (generate-jsonld-organization) + :543
   (generate-jsonld-article) γράφονται ΔΙΑΔΟΧΙΚΑ στο ίδιο .jsonld.
B. corpus.jsonl       : 124 records, 120 unique — P0 ΕΠΙΒΕΒΑΙΩΜΕΝΟ.
   AKN                : 124 eIds, 120 unique· duplicates: art_5, art_9, art_100,
   art_101 (τα 5Α/9Α/100Α/101Α ΚΑΤΑΡΡΕΟΥΝ — το lettered suffix χάνεται).
   ΕΔΡΑ: τα eIds χτίζονται από article-NUMBER (integer), αγνοώντας το label slot
   («5Α») που ΥΠΑΡΧΕΙ στο μοντέλο. P0 identity bug για AI authority.
C. release TTL        : 8/8 LISP-WRAPPED (( @prefix … )) — ΔΕΝ είναι Turtle.
   ΕΔΡΑ: epistemic writers τυπώνουν λίστες γραμμών (vocabularies.lisp:29+).
D. release manifest.jsonld : JSON ARRAY/plist ["@context",[…],"@id",…] — όχι object.
   ΕΔΡΑ: build-release-manifest-jsonld (release-manifest.lisp:281+).
E. release binding    : 0 article artifacts μέσα στο release· το manifest αναφέρει
   «article-» μόνο 4 φορές ⇒ ΟΥΤΕ (A) inclusion ΟΥΤΕ (B) πλήρες per-article
   hash-binding ⇒ το release proof ΔΕΝ είναι ακόμη πλήρες authority proof.
F. canonical HTML     : 124/124 με telemetry <script> + navigator.sendBeacon.
   ΕΔΡΑ: html-rdfa-generator.lisp:136–146. Παραβιάζει την πολιτική «canonical =
   inert» — telemetry επιτρέπεται ΜΟΝΟ εκτός canonical σελίδων.
```

## Πρόταση (ΔΕΝ έδρασα — εκτός FF3, κατά την εντολή «να μείνει audit»)
Ονομασμένη φάση **«Publisher/Root-Authority Hardening»** μετά το FF3 merge:
- **P0: B** (lettered identity — αγγίζει ταυτότητα άρθρων, θέλει τη δική σου
  ρητή έγκριση + πρόγραμμα regression σε goldens/AKN/corpus.jsonl)
- P1: A (ένα valid JSON-LD object/@graph — έχεις προ-εγκρίνει το σχήμα),
  C (πραγματικό Turtle), D (JSON-LD object), F (αφαίρεση telemetry από canonical)
- P2: E (release binding: inclusion ή per-article hash-bind — απόφαση σχεδίασης)
Καμία από αυτές δεν μπαίνει κρυφά στο FF3 PR.

## Κατάσταση
```
HEAD e5179fe6 · pushed · git clean · FF4 unopened · κανένα merge
standalone loop: 77/77 τοπικά (αναμένει docker proof δημιουργού)
component identity: αναμένει source-present local proof δημιουργού
```

— Claude (Χειρουργός Πυρήνα) · κλάδος `claude/ministry-justice-url-candidates-twghsj`
