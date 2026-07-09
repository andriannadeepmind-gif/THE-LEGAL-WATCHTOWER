# [0043] Claude (Χειρουργός Πυρήνα) — P1 PLAN: Semantic Validity (A/C/D) — PLANNING ONLY

**Ημερομηνία:** 2026-07-09 · **Κανένας κώδικας δεν έχει αλλάξει.**
**Scope:** A (standalone JSON-LD double-object) · C (release TTL Lisp-wrapped) ·
D (manifest.jsonld object shape). Τίποτα άλλο.
**Αρχή:** Το P1 κάνει τα δημοσιευμένα σημασιολογικά artifacts ΕΓΚΥΡΑ για
standard parsers — ΧΩΡΙΣ να αγγίξει καμία νομική ταυτότητα (τα eIds/@id/ELI
URIs μένουν byte-ίδια).

---

## 1. Ακριβές failing proof για A/C/D στο τρέχον main (8c6f2559)

**A — standalone JSON-LD = ΔΥΟ συνενωμένα JSON objects (άκυρο JSON):**
```
$ python3 -m json.tool output/constitution/article-001.jsonld
Extra data: line 38 column 1 (char 941)
```
Το αρχείο = `{Organization…}\n{Legislation…}`. Ίδιο σε ΟΛΑ τα corpora
(astikos/poinikos επαληθεύτηκαν: ίδιο σφάλμα, ίδιο offset). Κανένας JSON/JSON-LD
parser δεν το δέχεται. (Τα `<script type="application/ld+json">` μέσα στο HTML
είναι ΞΕΧΩΡΙΣΤΑ tags — έγκυρα το καθένα· το πρόβλημα είναι ΜΟΝΟ το standalone.)

**C — release TTL: Lisp-τυλιγμένες γραμμές + υπερ-escaped literals (άκυρο Turtle):**
```
$ head -1 output/constitution/releases/latest/manifest.ttl
(@prefix owl: <http://www.w3.org/2002/07/owl#> .)          ← παρένθεση = άκυρο
$ grep -c '^(' output/constitution/releases/latest/lineage-graph.ttl
11                                                          ← και στα 8 είδη TTL
$ grep -c '\\"' output/constitution/releases/latest/manifest.ttl
78                                                          ← \" αντί " σε literals
```
Δύο διακριτά ελαττώματα: **C1** και τα 8 είδη release-TTL (manifest, lineage-graph,
meta-ontology, negation, stability-policy, shapes/{article,lineage,manifest}-shape)
ξεκινούν με 11 γραμμές `(@prefix …)`. **C2** ΜΟΝΟ το manifest.ttl έχει επιπλέον
78 literals γραμμένα `\"…\"` αντί `"…"`.

**D — manifest.jsonld = JSON ARRAY αντί για object (plist ξεδιπλωμένο):**
```
$ jq type output/constitution/releases/latest/manifest.jsonld
"array"        ← ["@context",[…],"@id","https://…",…] — έγκυρο JSON, ΛΑΘΟΣ σχήμα
$ jq -e 'has("@id")' …/manifest.jsonld  →  αποτυγχάνει (δεν είναι object)
```

## 2. Ακριβείς υπεύθυνες έδρες πηγής

| Ελάττωμα | Έδρα | Αιτία |
|---|---|---|
| A | `systems/orchestrator-engine-sbcl/stages/generate-rdf.lisp:215` `render-canonical-jsonld` | συνενώνει `generate-jsonld-organization` + `generate-jsonld-article` με `terpri` — δύο top-level objects |
| C1 | `systems/orchestrator-epistemic/vocabularies.lisp:28` `*common-prefixes*` + `:204` `format-prefixes` | κάθε prefix είναι ΜΟΝΟ-στοιχείο ΛΙΣΤΑ `("@prefix …")`· το `~{~A~%~}` τυπώνει τη λίστα με παρενθέσεις |
| C2 | `systems/orchestrator-epistemic/release-manifest.lisp` (γρ. 180+, `build-release-manifest`) | format strings με `\\\"` (υπερ-escape) ⇒ literal `\"` στο Turtle |
| D | `systems/orchestrator-epistemic/release-manifest.lisp:281` `build-release-manifest-jsonld` | δίνει **plist** στο `jonathan:to-json … :from :alist` ⇒ σειριοποιείται ως array |

## 3. Ακριβή generated artifacts που επηρεάζονται (tracked στο main)

- **A:** 4.550 `article-*.jsonld` (astikos 2035 · constitution 120 · kdioikitikis
  285 · kpoinikis 594 · kpolitikis 1054 · poinikos 462). ⚠ Παρατήρηση: το σύνολο
  είναι το ΠΡΟ-P0 stale σύνολο ταυτοτήτων — λείπουν τα 144 lettered per-article
  αρχεία (το P0 κάλυψε συνειδητά ΜΟΝΟ τα corpus-level). Βλ. απόφαση (i) στο §4.
- **C:** 48 release TTLs (8 είδη × 6 corpora) στα `output/<c>/releases/<stamp>/`.
- **D:** 6 `releases/<stamp>/manifest.jsonld` (1/corpus).
- ⚠ **Κρίσιμη δέσμευση:** οι κατάλογοι releases είναι «IMMUTABLE RELEASE» με
  Merkle root, RFC-3161 receipts και JWS πάνω στα ΠΑΡΟΝΤΑ bytes. In-place
  αναγέννηση θα ΑΚΥΡΩΝΕ τα temporal proofs. Βλ. απόφαση (ii) στο §4.

## 4. Προτεινόμενο κανονικό μοντέλο εξόδου ανά format (+ 2 αποφάσεις δημιουργού)

- **A (standalone .jsonld):** ΕΝΑ top-level JSON-LD document:
  `{"@context":"https://schema.org","@graph":[{Organization…},{Legislation…}]}`.
  Κρατά ΚΑΙ τους δύο κόμβους (κανένα data loss), έγκυρο JSON & JSON-LD, τα
  `@id` ΑΜΕΤΑΒΛΗΤΑ (…/identity/org και το ELI URI άρθρου με το label —
  lettered-ασφαλές: το `render-canonical-jsonld` χρησιμοποιεί ήδη
  `article-label`). Το ψευδές docstring «byte-identical to embedded»
  αντικαθίσταται από τιμημένο συμβόλαιο: ο κόμβος άρθρου του standalone ≡
  ο κόμβος άρθρου του embedded script (σημασιολογικά), ελεγμένο από test.
- **C (release TTL):** C1: `*common-prefixes*` γίνεται επίπεδη λίστα strings
  (σβήνουν οι εσωτερικές παρενθέσεις — 1 αλλαγή, διορθώνει και τα 8 είδη +
  ό,τι άλλο καλεί `format-prefixes`). C2: `\\\"` → `\"` στα format strings του
  `build-release-manifest`. Κανονικό μοντέλο: καθαρό Turtle 1.1, prefixes χωρίς
  περιτύλιγμα, literals με `"…"` (και `"""…"""` για πολύγραμμα — ήδη σωστό).
- **D (manifest.jsonld):** ίδιο περιεχόμενο, σωστό σχήμα: top-level JSON
  **object** με `@context`/`@id`/`@type`/κλπ. Υλοποίηση: `:from :plist`
  στο jonathan (ή ισοδύναμη ρητή δόμηση) — ΚΑΜΙΑ αλλαγή στα δεδομένα.

**Αποφάσεις που ζητώ ΜΑΖΙ με την έγκριση (αλλιώς προχωρώ με το προτεινόμενο):**
1. **(i) Α-αναγέννηση:** προτείνω χειρουργική επανεγγραφή ΜΟΝΟ των 4.550
   υπαρχόντων tracked `.jsonld` (ίδια filenames, μόνο σχήμα)· τα 144 lettered
   per-article αρχεία που ΛΕΙΠΟΥΝ **δεν** προστίθενται στο P1 (θα ήταν νέα
   per-article ύλη — προτείνω χωριστή μικρο-φάση μετά). Εναλλακτικά: πρόσθεσέ τα
   τώρα — πες το ρητά.
2. **(ii) Releases:** προτείνω να ΜΗΝ πειραχτούν τα υπάρχοντα timestamped
   release trees (τα temporal proofs τους δεσμεύουν τα τωρινά bytes — έστω
   άκυρα ως Turtle, είναι ιστορικό γεγονός)· το P1 διορθώνει τις ΕΔΡΕΣ + tests,
   και κόβεται ΝΕΟ release (νέο stamp dir, π.χ. 2026-07-09T00:00:00Z, `latest`
   → νέο) με έγκυρα artifacts, ανά corpus. Εναλλακτικά: in-place επανεγγραφή
   με συνειδητή ακύρωση των παλιών proofs — μόνο με ρητή εντολή σου.
- **Σημείωση (εκτός P1, μόνο καταγραφή):** το manifest.ttl δηλώνει license
  CC0 ενώ η εντολή σου είναι All Rights Reserved. ΔΕΝ το αγγίζω στο P1 —
  θέλει δική σου απόφαση (περιεχόμενο, όχι σύνταξη).

## 5. Regression tests που προστίθενται (gated, self-exit 0/1)

Νέο `tests/semantic-validity-test.lisp` στο standalone loop του Dockerfile:
- ①: κάθε standalone άρθρου JSON-LD (φρέσκο από `render-canonical-jsonld`)
  parse-άρεται ως ΕΝΑ object (με τον in-repo JSON parser), έχει `@graph` με 2
  κόμβους, ο κόμβος άρθρου κρατά το ELI `@id` — ΚΑΙ για lettered (π.χ. 5Α).
- ②: κάθε είδος release TTL (φρέσκο από τις 8 έδρες): ΚΑΜΙΑ γραμμή δεν αρχίζει
  με `(`, ΚΑΝΕΝΑ `\"`, prefixes = `@prefix pfx: <iri> .`, ισοζυγισμένα quotes.
- ③: manifest.jsonld (φρέσκο): top-level object με `@id`/`@type`/`@context`,
  round-trip parse με jonathan.
- ④: αναλλοίωτη ταυτότητας: τα `@id` των άρθρων στο νέο standalone σχήμα ==
  τα παλιά (ο δεύτερος κόμβος του παλιού διπλού object) — καμία μετακίνηση URI.
- Επιπλέον ΣΚΛΗΡΟ εξωτερικό gate στο verifier-conformance stage (έχει ήδη
  python3): `rdflib` parse JSON-LD + Turtle σε δείγμα artifacts — ανεξάρτητος
  parser, όχι ο δικός μας.

## 6. Εντολές parser/validator

```
JSON (σύνταξη):      python3 -m json.tool <f>.jsonld
JSON-LD (→RDF):      python3 -c "from rdflib import Graph; Graph().parse('<f>.jsonld', format='json-ld')"
Turtle:              python3 -c "from rdflib import Graph; Graph().parse('<f>.ttl', format='turtle')"
manifest σχήμα:      jq -e 'type=="object" and has("@id") and has("@type") and has("@context")' manifest.jsonld
```
(`rdflib` μέσω pip στο verifier-conformance stage και στο τοπικό proof·
ΔΕΝ μπαίνει στο trusted path — είναι εξωτερικός μάρτυρας, όπως verify.py/mjs.)

## 7. Αναμενόμενα αρχεία προς αλλαγή

- Πηγή (3): `generate-rdf.lisp` (μόνο `render-canonical-jsonld` + docstring
  deploy.lisp), `vocabularies.lisp` (μόνο `*common-prefixes*`),
  `release-manifest.lisp` (μόνο format strings + `:from :plist`).
- Tests (2): ΝΕΟ `tests/semantic-validity-test.lisp` · `Dockerfile` (1 γραμμή
  loop + rdflib στο verifier-conformance stage).
- Artifacts: 4.550 `.jsonld` (in-place) · ΝΕΑ release trees ανά απόφαση (ii)
  (τα παλιά ΑΘΙΚΤΑ) — ξεχωριστό commit με εξήγηση κάθε κλάσης diff, όπως στο P0.
- ΔΕΝ αγγίζονται: corpus-level 30 του P0, article-*.{html,ttl,txt,hash,
  proof.json}, goldens, telemetry, release↔article binding, MCP/API.

## 8. Rollback

Τρία απομονωμένα commits (αναφορά → κώδικας+tests → artifacts), όλα revert-άσιμα
μεμονωμένα με `git revert` χωρίς residual state· τα artifacts αναπαράγονται
ντετερμινιστικά από τις έδρες, άρα το rollback του artifact commit είναι πλήρες·
τα παλιά release trees δεν πειράζονται άρα δεν χρειάζονται rollback.

## 9. Εντολές proof (μετά την υλοποίηση)

```
git status --short                                   # καθαρό
docker build --tag orchestrator:test .               # gated: νέο test στο loop
docker run --rm -v "$PWD":/src -w /src -e LAWMAX_ROOT=/src orchestrator:test --gates      # 23/23
docker run … orchestrator:test --verify-truth-gate   # 22/22
sbcl --script docker/run-standalone-test.lisp tests/semantic-validity-test.lisp
sbcl --script docker/run-standalone-test.lisp tests/corpus-identity-test.lisp   # 25/25 ΑΘΙΚΤΟ
python3 -m json.tool output/constitution/article-001.jsonld                      # πλέον ΕΓΚΥΡΟ
python3 -c "from rdflib import Graph; Graph().parse('<νέο release>/manifest.ttl', format='turtle')"
jq -e 'type=="object"' <νέο release>/manifest.jsonld
```

## 10. P0 identity lock: ΑΘΙΚΤΟ και πράσινο

Το P1 δεν αγγίζει ΚΑΜΙΑ έδρα του P0 (`%parse-article-title`,
`normalized-input.lisp`, corpus-level serializers, `corpus-identity-test`).
Το `corpus-identity-test` παραμένει gated και 25/25 στο τρέχον main (ίδιο
δέντρο κώδικα με το proof του 1748a8eb — θα ξανατρέξει στο τελικό proof).
Οι αλλαγές Α αφορούν ΜΟΝΟ το σχήμα του JSON-LD container — τα `@id`/eIds
byte-ίδια, με ρητό test ④ που το κλειδώνει.

---

*Planning only. Κανένα code change. Αναμένω: έγκριση P1 + αποφάσεις (i), (ii).*
