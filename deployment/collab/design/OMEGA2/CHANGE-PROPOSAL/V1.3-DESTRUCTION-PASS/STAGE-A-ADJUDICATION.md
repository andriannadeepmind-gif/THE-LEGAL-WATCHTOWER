# STAGE A — ΑΠΟΦΑΣΗ ΤΕΚΜΗΡΙΩΝ (ADJUDICATION RECORD) ΓΙΑ ΤΑ ΔΙΑΤΗΡΗΜΕΝΑ ΕΥΡΗΜΑΤΑ A1–A4

**Αυτόματα αποδιδόμενο** από `STAGE-A-RERUN.py` (τεκμήρια) + `STAGE-A-ADJUDICATION.json` (κρίση). Μη επεξεργάσιμο χειροκίνητα — κάθε digest προέρχεται από επανεκτέλεση σε απομονωμένο αντίγραφο.

- **Στόχος:** commit `9dabc2bb0cb0c3d04fcda5071578bd0f0084f63b` (`git archive` σε προσωρινό κατάλογο, διαγράφεται μετά).
- **Μέθοδος:** Ανάγνωση ΜΟΝΟ των COMPLETED-A1..A4.json, του MECHANICAL-COUNTEREXAMPLES-INDEX.md και των ακριβών τμημάτων προδιαγραφής που παραθέτουν· χωρίς subagents/workflows· κάθε μηχανική εντολή επανεκτελέστηκε ΑΠΟ ΤΟΝ ΣΥΝΤΑΚΤΗ σε `git archive HEAD` μέσα σε προσωρινό κατάλογο (ποτέ στο working tree)· σύγκριση actual/claimed με κανονικοποίηση whitespace και διαδρομών· SHA-256 του πραγματικού output· αποσύνθεση των 46 ευρημάτων σε διακριτές ρίζες· κάθε εύρημα λαμβάνει ΑΚΡΙΒΩΣ ΜΙΑ κατάσταση από {CONFIRMED, REFUTED_FALSE_POSITIVE, UNREPRODUCIBLE, DUPLICATE_OF:<id>}. Κριτήριο CONFIRMED: το αντιπαράδειγμα αναπαράγεται ΚΑΙ κανένα κείμενο των target/foundation specs (όπως διαβάστηκαν πλήρως: MLTP 1-492, v1.3, Q-tests, KW, crosswalk, register, PCL §4-6, trust-bootstrap, key-lifecycle §1-3, USC §1.2/§1.4/§2.1β/§2.2/§5.1/§12, CPEI §2) το κλείνει όπως είναι γραμμένο.
- **Εύρος:** Μόνο τα διατηρημένα ευρήματα του διακοπέντος destruction pass (A1–A4, άξονας α). Οι A5–A8 (άξονας β, KW-5…KW-8, KW-13…KW-16) δεν εκτελέστηκαν ποτέ — καμία κρίση γι' αυτούς. Καμία επιδιόρθωση, καμία νέα σχεδίαση εδώ (Stage B).
- **Τι ΔΕΝ έγινε:** Καμία επιδιόρθωση προδιαγραφής· καμία εκτέλεση destruction programme· καμία αξίωση SURVIVES/FALSIFIED για το πλήρες target· καμία αξίωση qualification· κανένα commit/push.

## 0. Digests των αρχείων-στόχων στο commit

| αρχείο | sha256 |
|---|---|
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md` | `26f71d6d23b3cd65b5179b4093e70151334b304e48727dda1f76e0718e5f4cee` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md` | `4ebd20f627b268fd30d8413db5dd72e84ecfd3d8ef4edb49971035b159bd7dc0` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md` | `82a20caf1de7b52b3c8096a75cd77c82d35026c0205fa79d719f7afab785a6e7` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md` | `1f9b8fcecc89ae135bbaf67d3be37ac2f235e77fc73971d8e7e76e1140514607` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-SEMANTIC-CROSSWALK.md` | `692931fef3b3c2a9676512524797e2ff7a418acb1d614fd4582cb085192ad787` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/SUPERSEDED-REGISTER.md` | `7bf1cfcf415be9f677697267892152165ce51bd14a433e1ca604770d3b6096f3` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/AS-IS-EVIDENCE-MANIFEST.md` | `ab83bfdc683d83ba3a5a3a89ea269461d2d3c8c5b4f8629133cfeb7cba683c42` |
| `deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-CONSISTENCY-AUDIT.sh` | `2f9ead3d3f4612f7d7716d48be257192e701fe2980eb6bf107f82c05adecab5a` |
| `deployment/PROOF-CARRYING-LAW.md` | `aed9f075bbb67f166664adedb3127a5e762d32cbdd7847ee99364b4d29098dfa` |
| `deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md` | `96f255d404e093f66402cf2272ade8f9beaae62d5c52a2d461d636fdab432995` |
| `deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md` | `13861f036505a73311646821a9e477f81c86b20e813403e37da6321a5c33efe0` |
| `deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md` | `868467cda19ca69abe4ae3abc8fd324824c9173269ca1bb1f1d805f583371ea3` |
| `deployment/LAWMAX-PROOF-OBJECT-SPEC.md` | `e1cfc6adeeba69b4109b78bbf24c319c58a222af0c3bac4baf411feb6f2033c7` |
| `deployment/LAWMAX-CPEI-TARGET-SPEC.md` | `88d3f19cd8b5e7e1d4fe893cd22dacbcfc9a1f26fd48e592ae90b80495a6f192` |
| `deployment/verify/canonical-serialization-spec.md` | `c12d8b752b10705adfa8d0184fe648f64e38b635bad550247fc46af802b01a68` |
| `source/authority-evidence-replay.lisp` | `f6d955d08422af2d3695adbc6cf976ce6006ce97ef000362b4555ca878bead8a` |

## 1. Σύνοψη

- Ευρήματα: **46** · CONFIRMED **31** · DUPLICATE_OF **15** · REFUTED_FALSE_POSITIVE **0** · UNREPRODUCIBLE **0**.
- Διακριτές ρίζες (root causes): **31** — P0 **9** · P1 **15** · P2 **7**.
- Μηχανικές εντολές αντιπάλων: **42** επανεκτελέστηκαν· **39** ταυτόσημο output· **3** με απόκλιση μορφής μόνο (A1-F4, A1-F5, A1-F6) — βλ. §4.
- ARGUMENT-ONLY ευρήματα με συγγραφέντα έλεγχο προκείμενης στο Stage A: **4** (A1-F11, A1-F12, A2-13, A2-14).
- Υποχρεωτικά KW που επιτέθηκαν οι A1–A4 και επιβεβαιώθηκαν ως μη-παραδοτέα από το κείμενο: KW-1 (A1-F1), KW-2 (A2-01/A2-02), KW-3 (A3-F4), KW-4 (A4-1), KW-9 (A1-F4), KW-10 (A2-03/A2-04), KW-11 (A3-F1/A3-F3), KW-12 (A4-4). KW-5…KW-8, KW-13…KW-16: ΜΗ ΕΛΕΓΧΘΕΝΤΑ (A5–A8 δεν ολοκληρώθηκαν).

## 2. Πίνακας κατάστασης ανά εύρημα (ακριβώς ΜΙΑ κατάσταση)

| id | sev (filed) | KW | class (filed) | status | root cause | exit | sha256(actual output) |
|---|---|---|---|---|---|---|---|
| `A1-F1` | P1 | KW-1 | MECHANICAL | **CONFIRMED** | RC-14 | 0 | `cc96d066a5d7ae08` |
| `A1-F2` | P0 | NEW | MECHANICAL | **CONFIRMED** | RC-01 | 0 | `9b39450cabe6bb15` |
| `A1-F3` | P0 | NEW | MECHANICAL | **CONFIRMED** | RC-03 | 0 | `4fabd5bb784c88e5` |
| `A1-F4` | P1 | KW-9 | MECHANICAL | **CONFIRMED** | RC-15 | 1 | `a7eaaeaa2cf937d7` |
| `A1-F5` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-02 | 0 | `337384a5ed216808` |
| `A1-F6` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A2-05** | RC-04 | 1 | `b58194222e5f70db` |
| `A1-F7` | P0 | NEW | MECHANICAL | **DUPLICATE_OF:A4-4** | RC-06 | 0 | `0780ee5fbf1be831` |
| `A1-F8` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-20 | 1 | `7a7f2e9b390db1aa` |
| `A1-F9` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-21 | 1 | `e032f1ae6d7216ad` |
| `A1-F10` | P2 | NEW | MECHANICAL | **CONFIRMED** | RC-12 | 0 | `b1480d5f66e0b55d` |
| `A1-F11` | P2 | NEW | ARGUMENT-ONLY | **CONFIRMED** | RC-23 | 0 | `49acd434cfaa8f5c` |
| `A1-F12` | P2 | NEW | ARGUMENT-ONLY | **DUPLICATE_OF:A2-13** | RC-24 | 0 | `b9c58b81355516b7` |
| `A1-F13` | P2 | NEW | MECHANICAL | **CONFIRMED** | RC-25 | 1 | `627a903e6d8c6d97` |
| `A2-01` | P0 | KW-2 | MECHANICAL | **CONFIRMED** | RC-16 | 0 | `56afd7b3cb3352c7` |
| `A2-02` | P0 | KW-2 | MECHANICAL | **CONFIRMED** | RC-17 | 0 | `62768472516d22fb` |
| `A2-03` | P0 | KW-10 | MECHANICAL | **CONFIRMED** | RC-18 | 1 | `7631cd0238d34a62` |
| `A2-04` | P1 | KW-10 | MECHANICAL | **CONFIRMED** | RC-05 | 1 | `4c7d1c4dfc190b0a` |
| `A2-05` | P0 | NEW | MECHANICAL | **CONFIRMED** | RC-04 | 0 | `b6ee15813f5a6a15` |
| `A2-06` | P0 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F3** | RC-03 | 0 | `bc9ad50645e57e46` |
| `A2-07` | P0 | NEW | MECHANICAL | **CONFIRMED** | RC-09 | 1 | `c817ab03556cd856` |
| `A2-08` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A4-4** | RC-06 | 0 | `279221a879aa9a7e` |
| `A2-09` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A4-8** | RC-19 | 0 | `5ea4a9f0843323d7` |
| `A2-10` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F4** | RC-15 | 0 | `ef39ba4034c68287` |
| `A2-11` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F4** | RC-15 | 1 | `0df4dc1252027694` |
| `A2-12` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-27 | 0 | `21ce79e592cc9c2e` |
| `A2-13` | P2 | NEW | ARGUMENT-ONLY | **CONFIRMED** | RC-24 | 0 | `3b20e9413bbbdfea` |
| `A2-14` | P2 | NEW | ARGUMENT-ONLY | **CONFIRMED** | RC-26 | 0 | `b532f5c8112718e8` |
| `A3-F1` | P0 | KW-11 | MECHANICAL | **CONFIRMED** | RC-07 | 0 | `1e307be5c730ec1c` |
| `A3-F2` | P0 | NEW | MECHANICAL | **DUPLICATE_OF:A4-4** | RC-06 | 0 | `59357d294570e2f8` |
| `A3-F3` | P1 | KW-11 | MECHANICAL | **CONFIRMED** | RC-08 | 0 | `7b748473d269e0b3` |
| `A3-F4` | P1 | KW-3 | MECHANICAL | **CONFIRMED** | RC-28 | 0 | `b1ec67f8fc50349c` |
| `A3-F5` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-29 | 0 | `ec2a96cde7044045` |
| `A3-F6` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F2** | RC-01 | 0 | `ab66651f9230ae27` |
| `A3-F7` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-13 | 0 | `e5906e8f87163851` |
| `A3-F8` | P2 | NEW | MECHANICAL | **CONFIRMED** | RC-22 | 0 | `cb7f9d286208d2e9` |
| `A3-F9` | P2 | NEW | MECHANICAL | **DUPLICATE_OF:A4-2** | RC-11 | 0 | `e658cfa88fa407e3` |
| `A4-1` | P1 | KW-4 | MECHANICAL | **CONFIRMED** | RC-10 | 0 | `41ea4d0921662f1f` |
| `A4-2` | P0 | NEW | MECHANICAL | **CONFIRMED** | RC-11 | 0 | `9f676b57e00e5af9` |
| `A4-3` | P0 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F3** | RC-03 | 0 | `ac48e3c596223d97` |
| `A4-4` | P0 | KW-12 | MECHANICAL | **CONFIRMED** | RC-06 | 0 | `af3bb9d9b6b6cb62` |
| `A4-5` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-30 | 0 | `f4f9688ba12a83e5` |
| `A4-6` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A3-F3** | RC-08 | 0 | `9b6be6d530536552` |
| `A4-7` | P1 | NEW | MECHANICAL | **DUPLICATE_OF:A2-05** | RC-04 | 0 | `c9279aa2ec8c0ac4` |
| `A4-8` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-19 | 0 | `cc68409de4cc72c4` |
| `A4-9` | P2 | NEW | MECHANICAL | **DUPLICATE_OF:A1-F9** | RC-21 | 0 | `ba2f658b44249a59` |
| `A4-10` | P1 | NEW | MECHANICAL | **CONFIRMED** | RC-31 | 0 | `175883b1b062cb1f` |

## 3. Ρίζες (root causes) — ΜΙΑ εγγραφή ανά ρίζα, με το CONFIRMED αντιπροσωπευτικό εύρημα

Για κάθε ρίζα: invariant (τι ισχυρίζεται η σχεδίαση) · ακριβής θέση στην προδιαγραφή · εντολή · exit code · αναμενόμενο vs πραγματικό · SHA-256 του τεκμηρίου. Το «πραγματικό» είναι ανάγνωση κειμένου, όχι κρίση επιδιόρθωσης.

### RC-01 — Αόριστο signing input για IssuedClaim (κανένα context string / target)

- **Αντιπροσωπευτικό:** `A1-F2` · **μέλη:** `A1-F2`, `A3-F6` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Η υπογραφή του IssuedClaim δεσμεύει τα πεδία που καταναλώνει ο verifier (claim_type, profile, payload, proof_material, issued_at, qualification_state_ref, issuer, kid)· ο verifier «ξαναχτίζει το ίδιο payload» (MLTP §4:240-242)· δύο verifiers δίνουν ταυτόσημο result (Q21 δ).
- **Θέση spec:** MLTP §1.0:35,41 · §4:232-235,240-242 · §8.3:395
- **Αναμενόμενο (κατά το spec/witness):** Ρητό context string (π.χ. `mltp2:issued-claim`) και ρητός target (envelope χωρίς `signature.sig`, με `description` ρητά εκτός) ώστε το signing input να είναι μονοσήμαντο.
- **Πραγματικό (κείμενο ως έχει):** Τέσσερα context strings μόνο (release-root, delegation, witness-checkpoint, qual-state)· §1.0:35 δηλώνει το payload ως «ΤΟ ΜΟΝΟ input της επαλήθευσης»· καμία πρόταση ορίζει ποια bytes του envelope υπογράφονται· §1.0:41 παραπέμπει σε «§4 signature payload» που δεν ονομάζει IssuedClaim.
- **Σημείωση Stage A:** Υπόλειμμα από A3-F6 που διατηρείται εδώ: ο στόχος του RFC-3161 messageImprint (τι χρονοσφραγίζεται — payload ή υπογραφή) είναι επίσης αόριστος (imprint|messageImprint = 0 στο MLTP)· καταναλώνεται από τη RC-03.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'mltp2:' $M; sed -n '35p;41p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `9b39450cabe6bb158fa00ed33f9d4b90463e9f53a44604adfc1b60389d454e8e` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
233:ανά τύπο signature payload (π.χ. `"mltp2:release-root"`, `"mltp2:delegation"`,
234:`"mltp2:witness-checkpoint"`, `"mltp2:qual-state"`) ώστε υπογραφή ενός τύπου να μη
  "payload": <TYPED, κλειστό ανά profile — §2· ΤΟ ΜΟΝΟ input της επαλήθευσης>,
                 "sig": <base64url — §4 signature payload> },
```

### RC-02 — Απουσία φορέα/δέσμευσης δημόσιου delegated κλειδιού (fingerprint χωρίς κλειδί, kid↔fingerprint join αόριστο)

- **Αντιπροσωπευτικό:** `A1-F5` · **μέλη:** `A1-F5` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Το κλειδί που επαληθεύει ένα claim είναι ακριβώς το κλειδί που εξουσιοδότησε ο root (MLTP §8.2:370· §4:259-262 «κάθε υπογραφή με το αντίστοιχο δημόσιο κλειδί»).
- **Θέση spec:** TB §3:38-41 · MLTP §8.1:355 · §8.3:390,393,395 · PCL §4:97 (kid ελεύθερο) · KL §2.3:45
- **Αναμενόμενο (κατά το spec/witness):** Θετικός έλεγχος `thumbprint(embedded_delegated_pub) == d.delegate`· ρητό slot δημόσιου κλειδιού (bundle) ή carrier στο LocalTrustState· ρητό join kid↔fingerprint· το pinned_owner_root ως πλήρες κλειδί ή fingerprint + επαληθεύσιμος carrier.
- **Πραγματικό (κείμενο ως έχει):** Η delegation φέρει μόνο `<release-key fingerprint>`· jwk|public_key|pubkey = 0 στο MLTP· `sig_verify(d, lts.pinned_owner_root)` και `sig_verify(c.signature, d.delegated_key)` καλούνται πάνω σε fingerprints· `delegation_for(c.signature.kid, …)` χωρίς ορισμένο join· οι μόνες εμφανίσεις «thumbprint» στο MLTP είναι αρνητικοί κανόνες (373-375, 395).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '38,39p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; sed -n '355p;390p;393p;395p' $M; grep -n 'thumbprint' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `337384a5ed2168083dbb219c69aa793edbf10456d45517d2d9074147745a5cbc` · **ταυτόσημο με claimed:** False
- **Πραγματικό output:**
```
- **Release signing key delegation**: το root υπογράφει statement
  `{delegate: <release-key fingerprint>, scope: release-signing,
  pinned_owner_root:      <fingerprint του owner-root.pub, out-of-band, ≥2 κανάλια>,
     require sig_verify(d, lts.pinned_owner_root)                 # ΜΟΝΟ ο root υπογράφει delegations
     d = delegation_for(c.signature.kid, bundle.delegation_chain) else untrusted-key
     require sig_verify(c.signature, d.delegated_key)              # ΟΧΙ thumbprint == root
373:  release key έχει **ΔΙΑΦΟΡΕΤΙΚΟ** thumbprint — **ποτέ** δεν συγκρίνεται ως «ίσο με
374:  το root». Verifier που κάνει `thumbprint(delegated) == pinned_root` είναι **λάθος**
395:     require sig_verify(c.signature, d.delegated_key)              # ΟΧΙ thumbprint == root
```

### RC-03 — Το «trusted signature time» είναι issuer-written: anchor = hash pointer, καμία TSR/TSA έδρα στον verifier

- **Αντιπροσωπευτικό:** `A1-F3` · **μέλη:** `A1-F3`, `A2-06`, `A4-3` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** `issued_at` = trusted signature-time anchor, ΟΧΙ self-declared (MLTP §1.0:50-53)· η ανάκληση κρίνεται έναντι αυτού (§9:455-459)· μόνο υπογραφές με ανεξάρτητο RFC-3161 χρόνο πριν το `invalid_from` επιβιώνουν (§9:446).
- **Θέση spec:** MLTP §1.0:42-43,50-53 · §2.1:87 · §3:184 · §6:293-308 · §8.1:354-364 · §8.3:409 · §9:446,455-459 · KL §2.5:57-58 · PROOF-OBJECT §4:102-104
- **Αναμενόμενο (κατά το spec/witness):** Ο verifier λαμβάνει TSR bytes (ή witnessed checkpoint με χρόνο) ΜΕΣΑ στο bundle, TSA trust anchors στο LocalTrustState, επαληθεύει TSA υπογραφή + messageImprint πάνω στην υπογραφή του claim, και ΠΑΡΑΓΕΙ `t_sig` από το genTime — ποτέ δεν το διαβάζει από το claim.
- **Πραγματικό (κείμενο ως έχει):** `anchor: <tsr_sha256 | tlog_leaf_index>` = digest/δείκτης, όχι token· TrustBundle χωρίς TSR/timestamp field (0 στις 293-308)· LocalTrustState χωρίς TSA trust store (μόνο `trusted_time.evidence` για το δικό του now)· §8.3 G: `t_sig = c.issued_at.trusted_time (anchored)` — το «(anchored)» είναι σχόλιο, όχι βήμα· `tlog_leaf_index` δίνει σειρά, όχι χρόνο.
- **Σημείωση Stage A:** Προτεραιότητα δημιουργού (authenticated issued_at). Επηρεάζει RC-04 (παράθυρο delegation), RC-09 (freshness) και το KW-6/KW-14 κλείσιμο του §9.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'tsr' $M; sed -n '383,423p' $M | grep -cE 'tsr|TSR|TSA'; sed -n '293,308p' $M | grep -ciE 'tsr|timestamp'; sed -n '409p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `4fabd5bb784c88e56e7ed0560631df9a69eb3be995e98bc7492a1d7983fefa9f` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
43:                 "anchor": <tsr_sha256 (RFC-3161) | tlog_leaf_index> },   # ΑΞΙΟΠΙΣΤΟΣ χρόνος υπογραφής — §9
87:            "time_anchor": {"tsr_sha256","tlog_leaf_index"} | null,  # RFC-3161 = ΜΟΝΟ χρόνος
0
0
     t_sig = c.issued_at.trusted_time  (anchored)                     else UNKNOWN
```

### RC-04 — Το παράθυρο ισχύος της delegation ελέγχεται έναντι αόριστου `d.signed_time`, ποτέ έναντι του χρόνου υπογραφής του claim — `delegation-expired` απρόσιτο

- **Αντιπροσωπευτικό:** `A2-05` · **μέλη:** `A2-05`, `A1-F6`, `A4-7` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Claim υπογεγραμμένο εκτός [not_before, not_after] της delegation ⇒ `delegation-expired` (TB §3:38-44 ≤1 έτος· Q23:283 «valid στο genTime του TSR»· v1.3 §4.1:187-188).
- **Θέση spec:** MLTP §8.3:391,409 · §4:246 · TB §3:38-44 · Q23:283
- **Αναμενόμενο (κατά το spec/witness):** `require d.not_before <= t_sig(c) <= d.not_after` ανά claim, με `t_sig` αυθεντικοποιημένο (RC-03).
- **Πραγματικό (κείμενο ως έχει):** §8.3:391 `require d.not_before <= d.signed_time <= d.not_after` — το `signed_time` δεν υπάρχει σε καμία προδιαγραφή (μοναδική εμφάνιση σε όλο το deployment/: MLTP:391) και, ως χρόνος υπογραφής της ίδιας της delegation, είναι ταυτολογικά εντός· `t_sig` υπολογίζεται μόνο στο G (409) και δεν συγκρίνεται με κανένα παράθυρο· delegation-expired = 0 στο 383-423.
- **Σημείωση Stage A:** Προτεραιότητα δημιουργού (delegation validity at authenticated claim-signature time).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'signed_time\|not_after' $M; grep -n 'genTime' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md
```
- **Exit code:** `0` · **SHA-256(actual output):** `b6ee15813f5a6a1542dbbe428c855cfa0b1e8b16800b19d43e0efa5ebb9087f4` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
391:     require d.not_before <= d.signed_time <= d.not_after
283:**Κριτήριο:** delegation chain valid στο `genTime` του TSR· tlog inclusion +
```

### RC-05 — Επιλογή delegation/seq-supersession αόριστη· ανάκληση κατά delegation_seq δεν ταιριάζεται ποτέ

- **Αντιπροσωπευτικό:** `A2-04` · **μέλη:** `A2-04` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Το scope σε ισχύ είναι της νεότερης delegation (TB §3:41 «νεότερο statement με μεγαλύτερο seq»)· revoked_subject ∈ {kid | delegation_seq} εφαρμόζεται (MLTP §2.8:161).
- **Θέση spec:** MLTP §1.0:40 · §2.8:161 · §8.3:393,411 · TB §3:41
- **Αναμενόμενο (κατά το spec/witness):** `delegation_for` επιλέγει τη delegation με το μέγιστο seq για το kid (ή απορρίπτει αν το claim δηλώνει παλαιότερο seq)· `revoked()` ελέγχει kid ΚΑΙ delegation_seq.
- **Πραγματικό (κείμενο ως έχει):** `delegation_for(kid, chain)` χωρίς κανόνα seq (max/highest/νεότερο seq = 0 στο MLTP)· `c.signature.delegation_seq` επιλέγεται από τον υπογράφοντα· `revoked(c.signature.kid, r)` κατά kid μόνο.
- **Σημείωση Stage A:** Στην A1-F6 (DUPLICATE_OF A2-05) το δεύτερο σκέλος ανήκει εδώ.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'delegation_for\|revoked(c' $M; grep -n 'μεγαλύτερο seq' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; grep -c 'max(seq)\|highest seq\|μέγιστο seq\|νεότερο seq\|μεγαλύτερο seq' $M
```
- **Exit code:** `1` · **SHA-256(actual output):** `4c7d1c4dfc190b0ac89eed176d57cc0e6cbb22d70200b4be824e1c9669f9d56a` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
393:     d = delegation_for(c.signature.kid, bundle.delegation_chain) else untrusted-key
411:     if revoked(c.signature.kid, r) AND t_sig >= r.invalid_from:  return retroactively-revoked  # fail-closed
41:  από το delegated κλειδί. Ανάκληση = νεότερο statement με μεγαλύτερο seq.
0
```

### RC-06 — QualificationStateRecord: υπογραφή ποτέ δεν επαληθεύεται, role αυτοδηλούμενο, signer μη δεσμευμένος σε auditor_registry, «release-authority kid» αόριστο, receipts nullable, quorum μη αναπαραστάσιμο

- **Αντιπροσωπευτικό:** `A4-4` · **μέλη:** `A4-4`, `A1-F7`, `A2-08`, `A3-F2` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Μόνο independent-auditor / auditor-quorum / provider-registry εκδίδουν QSR· ο release issuer ποτέ για τον εαυτό του (MLTP §3:190-206)· «ο verifier ελέγχει ΚΑΘΕ υπογραφή» (§4:259-262)· QSR υπογεγραμμένο με context `mltp2:qual-state` (§4:220,234)· KW-12 want = unauthorized-qualification-issuer.
- **Θέση spec:** MLTP §3:186-187,200-206 · §4:220,234,259-262 · §7:338 · §8.1:358 · §8.3:390,395,400,412-418 · KL §1:18-21 · TB §2.3:28-29, §3:38-41
- **Αναμενόμενο (κατά το spec/witness):** `sig_verify(q.signer.sig, key(q.signer.kid))` με context qual-state· `q.signer.kid ∈ lts.auditor_registry` (allowlist) με role προερχόμενο από το registry, όχι από το record· `local_signature` ΜΗ nullable για receipts που μετρούν ως evidence· quorum = ≥2 διακριτά registered kids (signer schema με πολλαπλές υπογραφές)· ορισμοί `evidence_resolves`/`allowed_for`/`quorum_for`.
- **Πραγματικό (κείμενο ως έχει):** `sig_verify` μόνο στις 390/395· H:415-416 ελέγχει self-declared `q.signer.role` string και denylist ενός αόριστου «release-authority kid» (ο κυρίαρχος κατέχει root/release-authority/proof-root/delegated κλειδιά — KL §1)· `auditor_registry` χρησιμοποιείται μόνο για embedded `auditor_keys` (400)· `local_signature … | null` (338)· `evidence_resolves`/`quorum_for`/`allowed_for` = 0 ορισμοί· signer = ένα {kid,sig}.
- **Σημείωση Stage A:** Προτεραιότητα δημιουργού (QSR signature verification). Υπόλειμμα από A1-F7 (subject binding) → RC-08.
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '414,417p' $M; printf 'sig_verify in 8.3 (abs lines): %s\n' "$(sed -n '382,424p' $M | grep -n sig_verify | cut -d: -f1 | awk '{print $1+381}' | tr '\n' ' ')"; grep -n 'local_signature' $M; printf 'definitions of evidence_resolves/quorum_for: %s\n' "$(grep -c 'evidence_resolves\s*(\S*)\s*:=\|def evidence_resolves\|quorum_for\s*:=' $M)"
```
- **Exit code:** `0` · **SHA-256(actual output):** `af3bb9d9b6b6cb6251dd9621e34bf62362bb9449cd009c9f4cd226ef7dd0cd40` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
     q = resolve(c.qualification_state_ref, bundle.qualification_records)  else dangling-qualification-ref → level none
     require q.signer.role allowed_for(q.level)                     else unauthorized-qualification-issuer
     require q.signer.kid NOT release-authority kid                 else unauthorized-qualification-issuer
     require evidence_resolves(q.evidence_refs, q.auditor_receipts, auditors, quorum_for(q.level))
sig_verify in 8.3 (abs lines): 390 395
338:  "local_signature": {"alg","kid","sig"} | null }        # ΤΟΥ VERIFIER, ποτέ του issuer
definitions of evidence_resolves/quorum_for: 0
```

### RC-07 — Dangling qualification_state_ref ⇒ τοπικό «level none» και μετά VERIFIED· το receipt δεν έχει πεδίο level· §8:431 αντιφάσκει με §8.3:423

- **Αντιπροσωπευτικό:** `A3-F1` · **μέλη:** `A3-F1` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Dangling ref ⇒ `dangling-qualification-ref` ⇒ level none — ποτέ σιωπηλή αποδοχή (KW-11· MLTP §3:207-209)· «αποτυχία οποιουδήποτε βήματος ⇒ UNVERIFIED/UNKNOWN» (§8:431-432).
- **Θέση spec:** MLTP §7:330-339 · §8.3:414,422-423 · §8:431-432 · §3:205-209 · v1.3 §4.2:210 · §8:315
- **Αναμενόμενο (κατά το spec/witness):** Το level εκφράζεται στο VerificationReceipt (πεδίο ανά claim) και ένα dangling ref μεταβάλλει το consumer-visible αποτέλεσμα (reason ονομαστικό, result ≠ VERIFIED ή level none ορατό).
- **Πραγματικό (κείμενο ως έχει):** H:414 αναθέτει τοπική μεταβλητή «level none» χωρίς return· J:423 `return VERIFIED`· §7 receipt χωρίς πεδίο level (0 στις 330-339)· §8:431 και §8.3:423 δίνουν αντίθετη ετυμηγορία στην ίδια είσοδο.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && sed -n '414p;422,423p' $F && echo "level-fields-in-VerificationReceipt(§7 330-339): $(sed -n '330,339p' $F | grep -c level)" && sed -n '431,432p' $F
```
- **Exit code:** `0` · **SHA-256(actual output):** `1e307be5c730ec1c315963c3df7378cfc37e078e6395f9fe8dfa45ebe3521168` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
     q = resolve(c.qualification_state_ref, bundle.qualification_records)  else dangling-qualification-ref → level none
  if freshness_verdict == UNKNOWN_FRESHNESS: return UNKNOWN_FRESHNESS   # ποτέ VERIFIED χωρίς trusted now
  return VERIFIED
level-fields-in-VerificationReceipt(§7 330-339): 0
**Provider-side κανόνας:** αποτυχία οποιουδήποτε βήματος ⇒
`UNVERIFIED_FOR_MACHINE_RELIANCE`/`UNKNOWN` — ποτέ σιωπηλή παρουσίαση ως αυθεντικού
```

### RC-08 — Το QSR δεν έχει ταυτότητα (id), το subject και το bundle_digest των receipts δεν δεσμεύονται στο claim/release· η tlog-inclusion διαδρομή επίλυσης (§6) δεν υπάρχει στο §8.3

- **Αντιπροσωπευτικό:** `A3-F3` · **μέλη:** `A3-F3`, `A4-6` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Ένα `qualification_state_ref` επιλύεται offline σε record με ταυτότητα, δεσμευμένο στο subject (claim/release) που το φέρει (MLTP §1.0:44 «id ενός QSR»· §3:178 subject· §6:301,314-315).
- **Θέση spec:** MLTP §1.0:44 · §3:174-187 (0 πεδία id) · §6:314-315 · §7:332 · §8.3:414
- **Αναμενόμενο (κατά το spec/witness):** `record_id = canonical-hash(record χωρίς sig)`· `require q.subject == subject(c)` (ή release_root)· `require receipt.bundle_digest == digest(bundle υπό επαλήθευση)`· μία διαδρομή επίλυσης (στο bundle) — η tlog εναλλακτική είτε ορίζεται ως βήμα είτε αφαιρείται.
- **Πραγματικό (κείμενο ως έχει):** §3 record χωρίς id/record_id (0)· `subject` εμφανίζεται μόνο στις 151/161/178 — ποτέ στο §8.3· `bundle_digest` = 0 στο §8.3· §6:315 επιτρέπει επίλυση «με inclusion proof στο tlog» που το §8.3:414 δεν υλοποιεί και που από hash δεν αποδίδει περιεχόμενο record.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "subject" $F && echo "id-fields-in-§3-record(174-210): $(sed -n '174,210p' $F | grep -c '\"id\"\|record_id')" && sed -n '314,315p;414p' $F
```
- **Exit code:** `0` · **SHA-256(actual output):** `7b748473d269e0b3cbfb34159a4d8f3b0c1aa537f56563a8c5d0c69c41c59126` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
151:payload = { "subject": <work_id | expression_id>,
161:payload = { "revoked_subject": <kid | delegation_seq>,
178:  "subject": <τι αφορά>,
id-fields-in-§3-record(174-210): 0
- Κάθε `qualification_state_ref` **πρέπει** να επιλύεται σε `qualification_records`
  του ίδιου bundle (ή με inclusion proof στο tlog) — αλλιώς `dangling-qualification-ref`.
     q = resolve(c.qualification_state_ref, bundle.qualification_records)  else dangling-qualification-ref → level none
```

### RC-09 — Με αξιόπιστο now, η φρεσκάδα δεν υπολογίζεται ποτέ· `expired` δεν εκπέμπεται· η υποβάθμιση level χάνεται

- **Αντιπροσωπευτικό:** `A2-07` · **μέλη:** `A2-07` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** «Θετική απόδειξη φρεσκάδας» (v1.3 §4.2:210-216)· ληγμένη βαθμίδα ⇒ αυτόματη υποβάθμιση (Q28:330-337)· «Λήξη expiry ⇒ none» (MLTP §3:209)· `expired` στην ταξινομία (§4:247).
- **Θέση spec:** MLTP §2.4:110-116 · §3:205-209 · §4:247 · §7:331-338 · §8.3:404-406,418,421-423 · v1.3 §4.2:210-216 · Q28:330-337
- **Αναμενόμενο (κατά το spec/witness):** F: όταν now παρόν ⇒ freshness_verdict ∈ {FRESH, STALE} από `coverage-and-freshness.freshness{as_of,max_staleness}` και now· H: `now > q.expiry` ⇒ `expired` (typed) και level none ΣΤΟ receipt· J: STALE ⇒ ποτέ VERIFIED.
- **Πραγματικό (κείμενο ως έχει):** `freshness_verdict` ανατίθεται μόνο σε UNKNOWN_FRESHNESS (406)· coverage-and-freshness|max_staleness|as_of = 0 στο 383-423· 418 υποβαθμίζει τοπική μεταβλητή· 423 `return VERIFIED`· receipt χωρίς level (0).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'freshness_verdict\|max_staleness' $M; sed -n '383,423p' $M | grep -c 'coverage-and-freshness\|max_staleness\|as_of'; sed -n '421,423p' $M; sed -n '331,338p' $M | grep -c '"level"'
```
- **Exit code:** `1` · **SHA-256(actual output):** `c817ab03556cd8566dab05f12e8b46e7b2a9404caa27ed2324b0a8a62d62a9ee` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
114:            "freshness": {"as_of","max_staleness"},
406:     freshness_verdict = UNKNOWN_FRESHNESS                            # ιστορική υπογραφή ΜΠΟΡΕΙ να επαληθευτεί
418:     if freshness_verdict == UNKNOWN_FRESHNESS OR now > q.expiry: q.level = none
422:  if freshness_verdict == UNKNOWN_FRESHNESS: return UNKNOWN_FRESHNESS   # ποτέ VERIFIED χωρίς trusted now
0
  # J. result
  if freshness_verdict == UNKNOWN_FRESHNESS: return UNKNOWN_FRESHNESS   # ποτέ VERIFIED χωρίς trusted now
  return VERIFIED
0
```

### RC-10 — Κανένα βήμα provenance στο §8.3· `insufficient-provenance` δηλώνεται αλλά δεν εκπέμπεται· §2.1 «χωρίς A ΚΑΙ B» αμφίσημο έναντι v1.3 §2.2

- **Αντιπροσωπευτικό:** `A4-1` · **μέλη:** `A4-1` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** source-authenticity χωρίς authority_proof_ref + institutional_register_id ⇒ `insufficient-provenance`/UNKNOWN από τον local verifier (MLTP §2.1:90-91· KW-4· Q03 β:85-87)· RELEASED απαιτεί authority-proof-bundle ΚΑΙ ireg ΚΑΙ acquisition receipt (v1.3 §2.2:124-127).
- **Θέση spec:** MLTP §2.1:90-91 · §4:249 · §8.3:382-424 · v1.3 §2.2:124-127 · Q03:78-87 · KW-4:21
- **Αναμενόμενο (κατά το spec/witness):** Βήμα provenance στο §8.3: για κάθε claim που αφορά RELEASED αντικείμενο απαιτείται source-authenticity claim με authority_id ΚΑΙ institutional_register_id ΚΑΙ authority_proof_ref ΚΑΙ acquisition_receipt_id (σύζευξη)· έλλειψη οποιουδήποτε ⇒ `insufficient-provenance`.
- **Πραγματικό (κείμενο ως έχει):** insufficient-provenance/authority_proof_ref/institutional_register_id/source-authenticity = 0/0/0/0 στο §8.3· η §2.1:90-91 διατύπωση «χωρίς A ΚΑΙ B» επιδέχεται και τις δύο αναγνώσεις (και τα δύο απόντα / οποιοδήποτε απόν) ενώ η v1.3 §2.2 είναι συζευκτική.
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; for t in insufficient-provenance authority_proof_ref institutional_register_id source-authenticity; do printf '%-28s %s\n' "$t" "$(sed -n '382,424p' $M | grep -cE "$t")"; done; sed -n '90,91p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `41ea4d0921662f1f0ddb7ed48936960da4b5fa0bdda24aec4d789e66742ffde2` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
insufficient-provenance      0
authority_proof_ref          0
institutional_register_id    0
source-authenticity          0
**Κανόνας:** RFC-3161 μόνο ⇒ ΑΝΕΠΑΡΚΕΣ· χωρίς `authority_proof_ref` ΚΑΙ
`institutional_register_id` ο local verifier παράγει `UNKNOWN` (§4 error `insufficient-provenance`).
```

### RC-11 — Τα αναγνωριστικά προέλευσης είναι issuer-authored content-addresses χωρίς consumer-side άγκυρα· η έδρα authority-proof-bundle/1 αποδεικνύει εξουσία του Watchtower επί του γράφου του, όχι κρατική έκδοση

- **Αντιπροσωπευτικό:** `A4-2` · **μέλη:** `A4-2`, `A3-F9` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Ο verifier διακρίνει bytes επίσημης αρχής από issuer-labelled bytes (v1.3 §1:64 row B· §2.2:113-127)· authority-proof-bundle αποδεικνύει «ότι η αρχή είχε την εξουσία τη στιγμή έκδοσης» (v1.3:119)· «ΠΛΗΡΩΣ OFFLINE-RESOLVABLE» (MLTP §6:301).
- **Θέση spec:** v1.3 §1:64, §2.2:116-127, §3:153 · MLTP §2.1:81-91 · §6:313-321 · §8.1:353-365 · §10:476 · USC §2.1β:315-324, §2.2:350-354, §5.1:459-468, :546-549 · source/authority-evidence-replay.lisp:47-52 · TB §1:14
- **Αναμενόμενο (κατά το spec/witness):** Consumer-side άγκυρα για auth1:/ireg1: (registry snapshot root στο LocalTrustState ή root-signed registry checkpoint)· authority_proof_ref και acquisition receipt ΜΕΣΑ στο bundle ή με inclusion proof (στη λίστα §6)· έδρα που αποδεικνύει έκδοση από ΚΡΑΤΙΚΗ αρχή (η authority-proof-bundle/1 αποδεικνύει owner→delegate release authority)· ορισμός `provisional_id`.
- **Πραγματικό (κείμενο ως έχει):** auth1:/ireg1: = canonical-hash issuer-authored πεδίων (USC:315-324, 350-354)· authority_proof_ref/institutional_register_id/acquisition_receipt_id = 0 στη λίστα offline-resolvability (293-321)· authority/institutional registry = 0 στο LocalTrustState· `+bundle-required-keys+` της authority-proof-bundle/1 = {delegation-scope, authority-statement-jws, tra, census, release-manifest, …}· USC:546-549 «authority/institutional-register/checkpoint gates = ΔΗΛΩΜΕΝΑ παραδοτέα»· `provisional_id` (MLTP:120, Q07:116) χωρίς ορισμό.
- **Σημείωση Stage A:** Υπόλειμμα από A3-F9 (provisional_id αόριστο· authority_proof_ref = presence-only) διατηρείται εδώ.
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; for t in authority_proof_ref institutional_register_id acquisition_receipt_id; do printf '%-28s %s\n' "$t" "$(sed -n '293,321p' $M | grep -cE "$t")"; done; printf 'LTS authority/register registry: %s\n' "$(sed -n '353,365p' $M | grep -ciE 'authority_registry|institutional')"; sed -n '46,52p' source/authority-evidence-replay.lisp
```
- **Exit code:** `0` · **SHA-256(actual output):** `9f676b57e00e5af991d4c388fc678232574c56f2931db82f9e07997966842f6e` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
authority_proof_ref          0
institutional_register_id    0
acquisition_receipt_id       0
LTS authority/register registry: 0

(defparameter +bundle-required-keys+
  '(:protocol :bundle-id :corpus-id :body-id :release-id :release-generation
    :delegation-scope :registry-digest :envelope :source-artifact
    :extraction-receipt :normalization-receipt :receipt :receipt-membership
    :journal-bytes :census :release-manifest :verifier-binaries :tra
    :authority-statement-jws)
```

### RC-12 — Το §8.3 δεν καλύπτει την κλειστή ταξινομία (11 ονόματα χωρίς βήμα εκπομπής) και επιστρέφει τιμές εκτός του κλειστού result sum

- **Αντιπροσωπευτικό:** `A1-F10` · **μέλη:** `A1-F10` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** Το §8.3 είναι το «ΣΥΜΒΟΛΑΙΟ»: κάθε ονομαστικό error της §4 έχει βήμα εκπομπής, το result ∈ {VERIFIED, UNVERIFIED_FOR_MACHINE_RELIANCE, UNKNOWN} (§7:334), δύο υλοποιήσεις δίνουν ταυτόσημο receipt (Q21 δ).
- **Θέση spec:** MLTP §4:244-250 · §7:334 · §8.3:383-423 (397, 411, 422) · §5:283 · §2.1:90-91 · Q21:265-266 · KW:21
- **Αναμενόμενο (κατά το spec/witness):** Κάθε ονομαστικό error με ρητό βήμα (ή ρητή αναφορά στη συνάρτηση που το εκπέμπει)· return ⊆ κλειστό sum με `reason` = ονομαστικό error· 397 με `else root-mismatch`.
- **Πραγματικό (κείμενο ως έχει):** Ονόματα χωρίς βήμα εκπομπής στο §8.3 ή στην PCL §5 `inclusion()` που καλεί: root-mismatch, unknown-alg, sig-invalid, delegation-invalid, delegation-expired, consistency-failed, expired, insufficient-provenance, unknown-claim-type, unadopted-analysis, UNKNOWN(reason) = 11· 397 χωρίς else· 411 επιστρέφει `retroactively-revoked` και 422 `UNKNOWN_FRESHNESS` ως result, εκτός του sum §7:334.
- **Σημείωση Stage A:** Μερική διόρθωση του αντιπάλου: μέτρησε 14 συμπεριλαμβάνοντας text-hash-mismatch/inclusion-failed/path-too-long, τα οποία εκπέμπει η PCL §5:116-123 `inclusion()` που το §8.3 A καλεί κατ' αναφορά (348, 385-387). Το αδιαμφισβήτητο πλήθος είναι 11.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; TAX=$(sed -n '245,250p' $M | tr -d '`' | tr '·' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$'); echo "$TAX" | wc -l; for n in $TAX; do echo "$n => $(sed -n '383,423p' $M | grep -cF -- "$n")"; done; sed -n '334p;411p;422p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `b1480d5f66e0b55d91393755e8712d6381b7dec5f1c0368723f5e494ae09c0fd` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
23
text-hash-mismatch => 0
inclusion-failed => 0
path-too-long => 0
root-mismatch => 0
untrusted-key => 1
unknown-alg => 0
sig-invalid => 0
delegation-invalid => 0
delegation-expired => 0
delegation-scope-violation => 1
consistency-failed => 0
split-view => 2
expired => 0
revoked => 1
retroactively-revoked => 1
untrusted-registry => 2
dangling-qualification-ref => 1
unauthorized-qualification-issuer => 2
insufficient-provenance => 0
unknown-claim-type => 0
unadopted-analysis => 0
UNKNOWN_FRESHNESS => 3
UNKNOWN(reason). => 0
  "result": <"VERIFIED" | "UNVERIFIED_FOR_MACHINE_RELIANCE" | "UNKNOWN">,
     if revoked(c.signature.kid, r) AND t_sig >= r.invalid_from:  return retroactively-revoked  # fail-closed
  if freshness_verdict == UNKNOWN_FRESHNESS: return UNKNOWN_FRESHNESS   # ποτέ VERIFIED χωρίς trusted now
```

### RC-13 — legal_state UNDEC: §2.2 λέει UNKNOWN, το §8.3 δεν διαβάζει ποτέ το legal_state και επιστρέφει VERIFIED

- **Αντιπροσωπευτικό:** `A3-F7` · **μέλη:** `A3-F7` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** UNDEC ⇒ local verifier UNKNOWN (MLTP §2.2:97· v1.3 §5:248 KT6· Q10:144-147).
- **Θέση spec:** MLTP §2.2:97 · §8.3:383-423
- **Αναμενόμενο (κατά το spec/witness):** Βήμα στο §8.3 που διαβάζει `payload.legal_state` και επιστρέφει UNKNOWN (ονομαστικό reason) για UNDEC.
- **Πραγματικό (κείμενο ως έχει):** UNDEC = 0 στο §8.3· η μόνη έδρα του κανόνα είναι σχόλιο στο schema (97).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && grep -n "UNDEC" $F && echo "UNDEC-in-§8.3(383-423): $(sed -n '383,423p' $F | grep -c UNDEC)" && sed -n '423p' $F
```
- **Exit code:** `0` · **SHA-256(actual output):** `e5906e8f871638516b36067f84b5ece9841c09d7a41a9c0344e54422b96753be` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
97:            "legal_state": <"IN" | "OUT" | "UNDEC">,        # UNDEC ⇒ local verifier: UNKNOWN
UNDEC-in-§8.3(383-423): 0
  return VERIFIED
```

### RC-14 — Το issuer self-verdict πεδίο αγνοείται, δεν απορρίπτεται: κανένα βήμα envelope-schema, κανένα ονομαστικό error

- **Αντιπροσωπευτικό:** `A1-F1` · **μέλη:** `A1-F1` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** IssuedClaim με `verification_result` ⇒ απορρίπτεται (KW-1:18· Q21 α:263-264)· κάθε witness ονομάζει typed error (KW:9-10).
- **Θέση spec:** MLTP §1.0:49,56-57 · §4:244-250 · §7:340-342 · §8.3:383-423 · Q21:263-264
- **Αναμενόμενο (κατά το spec/witness):** Βήμα envelope-schema validation στο §8.3 (κλειστό σύνολο πεδίων· άγνωστο/απαγορευμένο πεδίο ⇒ typed error) και όνομα στην ταξινομία.
- **Πραγματικό (κείμενο ως έχει):** §8.3 χωρίς schema/envelope βήμα (0)· ταξινομία χωρίς όνομα για self-verdict/forbidden-field (0)· §1.0:56-57 «ο verifier δρα μόνο στο typed payload» ⇒ το πεδίο αγνοείται· §7:340-342 = δήλωση πρόθεσης, όχι κανόνας verifier.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; Q=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md; sed -n '56,57p' $M; sed -n '383,423p' $M | grep -cE 'verification_result|schema|validate'; sed -n '244,250p' $M | grep -ciE 'self|schema|forbidden|envelope|malformed'; sed -n '263,264p' $Q; sed -n '340,342p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `cc96d066a5d7ae08b82721852f5dbc51ce55e679463ed748db5efb13b4e34b79` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
- **Το `description` (ελεύθερο κείμενο) ΔΕΝ διαβάζεται ποτέ από τον verifier.** Ο
  verifier δρα **μόνο** στο typed `payload`.
0
0
**Αρνητικός μάρτυρας:** (α) `IssuedClaim` που φέρει δικό του `verification_result:
VERIFIED` ⇒ **απορρίπτεται** (issuer self-verdict, §7)· (β) inline `assurance_level`
**Το αποτέλεσμα το παράγει ο καταναλωτής, όχι ο εκδότης.** Ο εκδότης δεν μπορεί να
προ-δηλώσει «VERIFIED». Αν ο verifier υπογράψει, υπογράφει **ως verifier** (δικό του
receipt), ποτέ ως αυτο-ετυμηγορία του εκδότη.
```

### RC-15 — Το «pinned key υπογράφει claims/root» μοντέλο επιβιώνει σε ACTIVE κείμενο (PCL §5, v1.3 §4.1 item 2, Q22 α)· ο audit δεν σαρώνει PCL/TB

- **Αντιπροσωπευτικό:** `A1-F4` · **μέλη:** `A1-F4`, `A2-10`, `A2-11` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Κανένα ACTIVE έγγραφο δεν προδιαγράφει `thumbprint(delegated) == pinned root` ούτε claims/root υπογεγραμμένα από το pinned κλειδί (KW-9:26· MLTP §8.2:372-375· TB §2.3:28-29 «ΠΟΤΕ per-release»)· δύο ACTIVE specs δεν δίνουν αντίθετη ετυμηγορία (KW-16 αρχή).
- **Θέση spec:** PCL §4:104-109, §5:129-132 · v1.3 §4.1:184-186 · Q22 α:275-276 · MLTP §8:348, §8.1:355, §8.2:372-375, §9:461-467 · SUPERSEDED-REGISTER:101,109-111 · V1.3-CONSISTENCY-AUDIT.sh:16-17,80
- **Αναμενόμενο (κατά το spec/witness):** PCL §5 `authentic()` σε νέα έκδοση delegation-aware (ή ρητή versioned precedence MLTP §8.2 επί PCL §4-5)· v1.3 §4.1 item 2 αναδιατυπωμένο («delegated key, εξουσιοδοτημένο από pinned root»)· Q22 α thumbprint-match έναντι `d.delegate`· audit που σαρώνει PCL/TB.
- **Πραγματικό (κείμενο ως έχει):** PCL:129 `alg == "RS256"` hard-pin· PCL:131-132 `thumbprint(public_key) == thumbprint(PINNED_KEY)` + `RS256_verify(PINNED_KEY, …)`· v1.3:184-186 «root/claims υπογεγραμμένα από pinned κλειδί»· Q22 α «δεν κάνει thumbprint-match ⇒ untrusted-key» χωρίς αντικείμενο σύγκρισης· PROOF-CARRYING-LAW = 0 στον audit· versioned precedence μόνο για KL §2.5.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL; grep -n 'thumbprint' deployment/PROOF-CARRYING-LAW.md $D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md $D/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '185,186p' $D/CHANGE-PROPOSAL-v1.3.md; sed -n '28,29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; sed -n '80p' $D/V1.3-CONSISTENCY-AUDIT.sh; grep -c 'PROOF-CARRYING-LAW' $D/V1.3-CONSISTENCY-AUDIT.sh
```
- **Exit code:** `1` · **SHA-256(actual output):** `a7eaaeaa2cf937d7efd91b71f62d658d5ad349c1c14e01b6cd0f66827e84ea2b` · **ταυτόσημο με claimed:** False
- **Πραγματικό output:**
```
deployment/PROOF-CARRYING-LAW.md:108:> (or its RFC 7638 thumbprint). If a proof embeds a `public_key`, it must match
deployment/PROOF-CARRYING-LAW.md:109:> the pinned key by thumbprint; otherwise the result is `untrusted-key`.
deployment/PROOF-CARRYING-LAW.md:131:     require thumbprint(corpus_proof.public_key) == thumbprint(PINNED_KEY)   # else untrusted-key
deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md:276:thumbprint-match ⇒ `untrusted-key`· (β) verifier που «επαληθεύει» RS256/Ed25519
deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:373:  release key έχει **ΔΙΑΦΟΡΕΤΙΚΟ** thumbprint — **ποτέ** δεν συγκρίνεται ως «ίσο με
deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:374:  το root». Verifier που κάνει `thumbprint(delegated) == pinned_root` είναι **λάθος**
deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md:395:     require sig_verify(c.signature, d.delegated_key)              # ΟΧΙ thumbprint == root
   υπογεγραμμένα από **pinned** κλειδί που ο verifier παίρνει **out-of-band**, ΠΟΤΕ
   από το bundle (PCL §4 trust anchor).
3. Το root key υπογράφει ΜΟΝΟ: (α) delegation statements (§3),
   (β) revocations, (γ) το ceremony record. ΠΟΤΕ per-release/per-query.
ck C12c "$(c 'thumbprint(bundle release key) == thumbprint(PINNED_ROOT)' $M)" eq 0
0
```

### RC-16 — Στάσιμος περιγραφέας «SHA-256 μόνο» για τον επαναχρησιμοποιούμενο verifier (crosswalk:54, PCL §6:145-146)· ο audit ελέγχει μόνο την αγγλική φράση

- **Αντιπροσωπευτικό:** `A2-01` · **μέλη:** `A2-01` · **severity (filed / adjudicated):** P0 / P2
- **Invariant:** Καμία v1/v1.2 «SHA-256 μόνο» σημασιολογία σε ACTIVE τομή (KW-8:25)· ο ελεγκτής «δεν είναι hash-only» (v1.3 §4.1:177-178· MLTP §4:222).
- **Θέση spec:** V1.3-SEMANTIC-CROSSWALK.md:54 · PCL §6:145-146 · MLTP §8:348 · v1.3 §4.1:174-179 · V1.3-CONSISTENCY-AUDIT.sh:37-39 (C2c/C2d)
- **Αναμενόμενο (κατά το spec/witness):** Η γραμμή έδρας του verifier να περιγράφει τη σύνθεση «PCL §5 inclusion + authentic (RS256) → EXTEND προς delegation-aware/Ed25519», όχι «6 γραμμές, SHA-256 μόνο | REUSE»· audit που πιάνει και την ελληνική διατύπωση.
- **Πραγματικό (κείμενο ως έχει):** crosswalk:54 «minimal offline verifier (6 γραμμές, SHA-256 μόνο) | PROOF-CARRYING-LAW.md §5-6 | REUSE»· PCL:145-146 «only SHA-256» (για την inclusion)· C2c/C2d ελέγχουν μόνο 'verified only with sha-256'.
- **Σημείωση Stage A:** Μερική διόρθωση: ο τίτλος του αντιπάλου «hash-only seat still REUSED» (P0) υπερβάλλει — η PCL §5:132 περιέχει `RS256_verify`, άρα η έδρα δεν είναι hash-only· το στάσιμο είναι ο ΠΕΡΙΓΡΑΦΕΑΣ στο crosswalk (P2). Τα δύο P0 σκέλη της A2-01 (αόριστο signing message, απουσία key carrier) κρίνονται στις RC-01/RC-02 — η A2-01 παραμένει CONFIRMED για το μοναδικό της στοιχείο (RC-16). KW-2 καλύπτεται από RC-01+RC-02+RC-17.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -o 'mltp2:[a-z-]*' $M | sort -u; grep -c -i 'jwk\|public_key\|pubkey' $M; sed -n '39,40p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; grep -n 'SHA-256 μόνο' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-SEMANTIC-CROSSWALK.md
```
- **Exit code:** `0` · **SHA-256(actual output):** `56afd7b3cb3352c7fd1f7d72ab93493f127956c07a7b4d995059df163ad690b2` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
mltp2:delegation
mltp2:qual-state
mltp2:release-root
mltp2:witness-checkpoint
0
  `{delegate: <release-key fingerprint>, scope: release-signing,
  not-before, not-after (≤ 1 έτος), seq}` — το per-release JWS υπογράφεται
54:| minimal offline verifier (6 γραμμές, SHA-256 μόνο) | `PROOF-CARRYING-LAW.md §5-6` | **REUSE** |
```

### RC-17 — Τα per-claim inclusion proofs δεν δεσμεύονται ποτέ στο release_root και η υπογραφή του release_root δεν επαληθεύεται στο §8.3

- **Αντιπροσωπευτικό:** `A2-02` · **μέλη:** `A2-02` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** «Η ΜΟΝΗ ρίζα αυθεντίας … κάθε TrustBundle δείχνει σε αυτήν» (MLTP §5:273-283)· «inclusion alone … is not proof of authenticity» (PCL §5:136-139)· ίδιο artifact για κάθε καταναλωτή (Q20:246-248).
- **Θέση spec:** MLTP §5:273-283 · §8.3:385-387,396-397,401-403 · PCL §5:126-133,136-139 · v1.3 §3:165-166
- **Αναμενόμενο (κατά το spec/witness):** A: `require proof.merkle_root == bundle.release_anchor.release_root` (root-mismatch)· C: `sig_verify(release_root, delegated release key)` με context `mltp2:release-root`· E: tlog inclusion ΤΟΥ release_root.
- **Πραγματικό (κείμενο ως έχει):** Στο 383-423 η μόνη εμφάνιση release_root/merkle_root/root-mismatch = γραμμή 397 (`is THE authority root`, ταυτολογία χωρίς else)· καμία υπογραφή επί release_root· §8.3 A καλεί μόνο `pcl_inclusion` (έλεγχος έναντι της ρίζας του ίδιου του proof).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '383,423p' $M | grep -n 'root-mismatch\|merkle_root\|release_root\|release-root'
```
- **Exit code:** `0` · **SHA-256(actual output):** `62768472516d22fb49485ae56def2e1e4a21acad2acab240ea94543402eea6d3` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
15:  require bundle.release_anchor.release_root is THE authority root   # pcl_text_root = cross-check μόνο
```

### RC-18 — claim_type και profile: δύο πεδία για μία έννοια χωρίς κανόνα δέσμευσης — scope κατά claim_type, τύπος payload κατά profile

- **Αντιπροσωπευτικό:** `A2-03` · **μέλη:** `A2-03` · **severity (filed / adjudicated):** P0 / P0
- **Invariant:** Delegated key με scope εκτός του τύπου του claim ⇒ `delegation-scope-violation` (KW-10:27· MLTP §8.2:376-378)· «profile = το id του typed payload schema του claim_type» (§1.0:34).
- **Θέση spec:** MLTP §1.0:33-35 · §4:252-253 · §8.2:376-378 · §8.3:394,420 · §2.6:143-147
- **Αναμενόμενο (κατά το spec/witness):** `require profile == schema_of(claim_type)` (ή αφαίρεση του profile ως ανεξάρτητου πεδίου) και payload validation κατά schema(claim_type) πριν το scope check.
- **Πραγματικό (κείμενο ως έχει):** Δύο πεδία (33-34)· scope κατά claim_type (394)· payload «κλειστό ανά profile» (35)· κανόνας mismatch/error = 0.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '33,35p' $M; grep -c 'profile-mismatch\|claim-type-mismatch\|profile ≠ claim_type\|profile != claim_type' $M
```
- **Exit code:** `1` · **SHA-256(actual output):** `7631cd0238d34a623e19212517de68c551c7b54c99288c13e66ea46bcb60e1d6` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
  "claim_type": <ΚΛΕΙΣΤΟ sum — §1.1· ΠΟΤΕ ελεύθερο string>,
  "profile": <το id του typed payload schema του claim_type>,
  "payload": <TYPED, κλειστό ανά profile — §2· ΤΟ ΜΟΝΟ input της επαλήθευσης>,
0
```

### RC-19 — Αντίφαση εξουσίας ανάκλησης (root vs delegated IssuedClaim vs μη-επαληθευμένα bundle records)· καμία προτεραιότητα συγκρουόμενων records

- **Αντιπροσωπευτικό:** `A4-8` · **μέλη:** `A4-8`, `A2-09` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Ανακλήσεις υπογράφονται από root (TB §2.3:28-29· KL §2.5:55-56)· revocation records στο bundle «resolved, checkpointed» (MLTP §8.3:410)· μία ετυμηγορία ανά υπογραφή (§9:461-467).
- **Θέση spec:** MLTP §2.8:159-167 · §6:304-305,316-317 · §8.3:392-393,407-411 · §9:448-453 · TB §2.3:28-29, §3:41 · KL §2.5:55-56
- **Αναμενόμενο (κατά το spec/witness):** Revocation ως root-signed statement με δικό του context (`mltp2:revocation`), όχι delegated IssuedClaim (ή ρητή delegation με scope-by-subject)· G: `sig_verify` κάθε revocation record· κανόνας προτεραιότητας (αυστηρότερο invalid_from / μέγιστο seq) για πολλαπλά records ανά kid· `revoked_subject` ⊆ subjects υπό την εξουσία του υπογράφοντος.
- **Πραγματικό (κείμενο ως έχει):** §2.8 revocation = IssuedClaim ⇒ §8.3 B απαιτεί delegation κατά kid — ο root δεν έχει delegation προς εαυτόν ⇒ untrusted-key· `bundle.revocation.records` εκτός `issued_claims` και το G τα καταναλώνει «(resolved, checkpointed)» χωρίς sig_verify· `revoked_subject` χωρίς δέσμευση· προτεραιότητα συγκρουόμενων records = 0.
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '304p' $M; sed -n '392p' $M; sed -n '410p' $M; sed -n '28,29p' deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md
```
- **Exit code:** `0` · **SHA-256(actual output):** `cc68409de4cc72c4f21dab50c9ad116ba5aa87ba0859902818f209877251d4fe` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
  "revocation": { "records": [ <trust-key-or-delegation-revocation IssuedClaims> ],
  for c in bundle.issued_claims:
     r = lts.revocation_state ∪ bundle.revocation.records  (resolved, checkpointed)
3. Το root key υπογράφει ΜΟΝΟ: (α) delegation statements (§3),
   (β) revocations, (γ) το ceremony record. ΠΟΤΕ per-release/per-query.
```

### RC-20 — reviewer_adoption_act αυτο-υπογράψιμο: κανένα reviewer registry, `unadopted()` αόριστο, `unadopted-analysis` δεν εκπέμπεται

- **Αντιπροσωπευτικό:** `A1-F8` · **μέλη:** `A1-F8` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Interpretive ratio θεσμικά πιστοποιημένο ΜΟΝΟ με reviewer adoption· raw AI inference ποτέ ως θεσμικό ratio (MLTP §2.6:143-147· v1.3 §5:248-252· KW-7:24).
- **Θέση spec:** MLTP §2.6:138-147 · §4:250 · §8.1:354-364 · §8.3:420
- **Αναμενόμενο (κατά το spec/witness):** reviewer registry στο LocalTrustState (ή root-signed reviewer roster)· `sig_verify(reviewer_adoption_act, registered reviewer kid ≠ issuer kid)`· ορισμός `unadopted()` και εκπομπή `unadopted-analysis`.
- **Πραγματικό (κείμενο ως έχει):** reviewer = 0 στο LocalTrustState (354-364)· `unadopted()` αόριστο· unadopted-analysis = 0 στο §8.3· καμία απαγόρευση self-attribution/self-adoption.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '354,364p' $M | grep -ci 'reviewer'; sed -n '420p' $M; sed -n '383,423p' $M | grep -c 'unadopted-analysis'
```
- **Exit code:** `1` · **SHA-256(actual output):** `7a7f2e9b390db1aaceea9eb342531d20e51cdb4281453e5dd06ba85d4794fe8d` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
0
  if unadopted(analysis_claims): return UNVERIFIED_FOR_MACHINE_RELIANCE
0
```

### RC-21 — Το envelope `issuer` δεν δεσμεύεται στο κλειδί υπογραφής και μοιράζεται το de jure `auth1:` namespace

- **Αντιπροσωπευτικό:** `A1-F9` · **μέλη:** `A1-F9`, `A4-9` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Ο εκδότης ενός claim είναι ο κάτοχος του delegated key· κανένα claim δεν παρουσιάζεται ως εκδοθέν από de jure αρχή (v1.3 §7:299-302· §10:345· Q-tests:378-381).
- **Θέση spec:** MLTP §1.0:38 · §2.1:83 · §2.7:153 · §8.2:367-378 · §8.3:383-423 (issuer = 0) · USC §2.2:350-355 · AS-IS EV-11
- **Αναμενόμενο (κατά το spec/witness):** `issuer` δεσμευμένο στο kid/delegation (issuer_id = fingerprint ή subject της delegation)· τύπος διακριτός από `auth1:` (ή αφαίρεση του πεδίου)· `verifier_id` μόνο σε Layer C.
- **Πραγματικό (κείμενο ως έχει):** `issuer: {authority_id | verifier_id}` ελεύθερο· c.issuer/issuer. = 0 στο §8.3· `authority_id` = ο ίδιος τύπος με το USC §2.2 `auth1:` (§2.1:83 «# USC §2.2»).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '38p' $M; sed -n '383,423p' $M | grep -cE 'c\.issuer|issuer\.'
```
- **Exit code:** `1` · **SHA-256(actual output):** `e032f1ae6d7216ad08595702936f822dea9e5de144571e1a0c105a891433f10c` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
  "issuer": { "authority_id" | "verifier_id" },
0
```

### RC-22 — Ελεύθερο κείμενο `description` (και `ratio[].claim`) σε κάθε δημόσιο IssuedClaim — η αξίωση «κανένα πεδίο να γραφτεί» είναι ψευδής όπως είναι γραμμένη

- **Αντιπροσωπευτικό:** `A3-F8` · **μέλη:** `A3-F8` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** «Το δημόσιο σχήμα δεν έχει τύπο Matter/Case/Client — καμία διαρροή να φρουρηθεί, γιατί κανένα πεδίο να γραφτεί» (v1.3 §0:46-48)· δομική αδυναμία, όχι φρουρός (Q20:249-251).
- **Θέση spec:** MLTP §1.0:45,56-57 · §2.6:132 · §2.7:157 · v1.3 §0:46-48 · Q20:246-251
- **Αναμενόμενο (κατά το spec/witness):** Είτε αφαίρεση του `description` από υπογεγραμμένα δημόσια αντικείμενα, είτε επαναδιατύπωση της αξίωσης (κανένας ΤΥΠΟΣ Matter/Case/Client) με ρητή δήλωση ότι τα free-text πεδία είναι εκδοτικό περιεχόμενο υπό policy — όχι «κανένα πεδίο».
- **Πραγματικό (κείμενο ως έχει):** `description: <ΠΡΟΑΙΡΕΤΙΚΟ ανθρώπινο κείμενο>` σε κάθε IssuedClaim· η προστασία = «ΔΕΝ διαβάζεται από τον verifier» (φρουρός)· `ratio[].claim` ελεύθερο κείμενο· tlog χωρίς διαγραφή.
- **Σημείωση Stage A:** Η A1 εξερεύνησε τον ίδιο άξονα και δεν κατέθεσε εύρημα (issuer-controlled public content). Το Stage A επιβεβαιώνει ΜΟΝΟ ότι η λέξη-προς-λέξη αξίωση «κανένα πεδίο να γραφτεί» δεν ισχύει· η ουσία (τύπος vs κείμενο) κρίνεται στο Stage B.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL && sed -n '45p' $D/MACHINE-LEGAL-TRUST-PROTOCOL.md && sed -n '46,48p' $D/CHANGE-PROPOSAL-v1.3.md
```
- **Exit code:** `0` · **SHA-256(actual output):** `cb7f9d286208d2e93037ea05313c7e0cb50b5e9fe0d1bfe78521e8f6175dbac6` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
  "description": <ΠΡΟΑΙΡΕΤΙΚΟ ανθρώπινο κείμενο — ΠΟΤΕ input επαλήθευσης> }
  υποθέσεις, χρήση, πελάτες ή προνομιακό υλικό. Το δημόσιο σχήμα **δεν έχει τύπο**
  `Matter`/`Case`/`Client` — καμία διαρροή να φρουρηθεί, γιατί κανένα πεδίο να
  γραφτεί.
```

### RC-23 — Το cockpit intent εδράζεται στο InstitutionalAct/%ask-envelope του οποίου τα αδελφά πεδία (claim, counterproof, weakest_link) είναι matter-solving χωρίς δημόσιο περιορισμό τύπου

- **Αντιπροσωπευτικό:** `A1-F11` · **μέλη:** `A1-F11` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** Το δημόσιο cockpit intent δεν μπορεί να μεταφέρει matter-solving περιεχόμενο (v1.3 §0:36-48· Q20)· μία έδρα envelope (v1.3 §6:270-271· CPEI §2:151).
- **Θέση spec:** v1.3 §6:256-275 · CPEI §2:147-175 (151, 160, 163) · V1.3-SEMANTIC-CROSSWALK.md:84-85 · SUPERSEDED-REGISTER.md:69,84-86
- **Αναμενόμενο (κατά το spec/witness):** PUBLIC OBSERVATORY PROFILE του InstitutionalAct με κλειστό, δημόσιο σύνολο πεδίων (τα matter-solving πεδία δομικά απόντα από το δημόσιο profile ή τυποποιημένα ως δημόσιοι τύποι).
- **Πραγματικό (κείμενο ως έχει):** v1.3 §6 εδράζει το intent στο %ask-envelope/InstitutionalAct (CPEI §2), που ορίζει `claim` = «σώμα απάντησης + θέσεις υπαγωγής» και `counterproof` = «ενστάσεις αντιδικίας»· Matter|Case|Client = 0 στις v1.3:256-275 (κανένας περιορισμός τύπου στη δημόσια χρήση του envelope).
- **Σημείωση Stage A:** ARGUMENT-ONLY όπως κατατέθηκε· η προκείμενη ελέγχθηκε μηχανικά στο Stage A. Συμφιλίωση με την εντολή δημιουργού 2026-09-01: η διατύπωση «PRIVATE target's envelope» βασιζόταν στην ταξινόμηση του CPEI ως ιδιωτικού, η οποία ΑΝΑΚΛΗΘΗΚΕ (CPEI = κοινή συνταγματική αρχιτεκτονική, τρία profiles). Η ρίζα επιβιώνει με νέα διατύπωση: το PUBLIC OBSERVATORY PROFILE πρέπει να ορίσει το δημόσιο υποσύνολο πεδίων του InstitutionalAct — Stage B.
- **Εντολή (stage-A-authored-premise-check):**
```
V=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; C=deployment/LAWMAX-CPEI-TARGET-SPEC.md; sed -n '270,271p' $V; sed -n '151p;160p;163p' $C; printf 'public-type restriction on envelope fields in v1.3 s6 (Matter|Case|Client, lines 256-275): %s\n' "$(sed -n '256,275p' $V | grep -c 'Matter\|Case\|Client')"
```
- **Exit code:** `0` · **SHA-256(actual output):** `49acd434cfaa8f5c854ee7adeca0af976b1dcc66024d4771bb0cc4ec2a565484` · **ταυτόσημο με claimed:** n/a (authored)
- **Πραγματικό output:**
```
- Έδρα: `%ask-envelope` / InstitutionalAct (CPEI §2) — μία έδρα envelope, το
  cockpit intent είναι πεδίο της, όχι δεύτερο κανάλι.
**Απαγορεύεται δεύτερο παράλληλο envelope — μία έδρα: `%ask-envelope`.**
| `claim` | το σώμα απάντησης + θέσεις υπαγωγής | ◐ όχι δομημένο Claim αντικείμενο ανά πράξη |
| `counterproof` | ενστάσεις αντιδικίας (μόνο subsume/draft) | ◐ |
public-type restriction on envelope fields in v1.3 s6 (Matter|Case|Client, lines 256-275): 0
```

### RC-24 — Καμία μονοτονία tree_size / ηλικία revocation checkpoint: παλαιότερο συνεπές prefix (rollback) και παραλειφθείσα νεότερη ανάκληση περνούν το split-view

- **Αντιπροσωπευτικό:** `A2-13` · **μέλη:** `A2-13`, `A1-F12` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** Consistency/gossip καθιστά ανιχνεύσιμη την stale/rolled-back κατάσταση· «τρέχον revocation checkpoint» (MLTP §6:304-305)· consumers βλέπουν ανακλήσεις μέσω consistency/gossip (§9:451-453).
- **Θέση spec:** MLTP §6:300,304-305 · §8.1:359-360 · §8.3:402,410 · TB §4:59-62
- **Αναμενόμενο (κατά το spec/witness):** `require bundle.transparency.tree_size >= lts.last_accepted_tlog.tree_size`· `require revocation.checkpoint.tree_size >= lts.revocation_state.tree_size`· μέγιστη ηλικία revocation checkpoint έναντι trusted now — αλλιώς UNKNOWN.
- **Πραγματικό (κείμενο ως έχει):** tree_size = 0 στο §8.3· μονοτονία/rollback/ηλικία = 0 στο MLTP· TB §4:59-61 απορρίπτει μόνο «μη-συνεπές» log — παλαιότερο συνεπές prefix είναι εξ ορισμού συνεπές.
- **Σημείωση Stage A:** ARGUMENT-ONLY όπως κατατέθηκαν (A2-13, A1-F12)· προκείμενες ελεγμένες μηχανικά στο Stage A.
- **Εντολή (stage-A-authored-premise-check):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; T=deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; printf 'tree_size monotonicity rule in s8.3 (383-423): %s\n' "$(sed -n '383,423p' $M | grep -c 'tree_size')"; printf 'monotone/rollback wording in MLTP: %s\n' "$(grep -ci 'monoton\|rollback\|older prefix' $M)"; sed -n '402p' $M; sed -n '59,61p' $T
```
- **Exit code:** `0` · **SHA-256(actual output):** `3b20e9413bbbdfea7b0ada574cd4eb00c70e5fdf59a83a1cb7817d76b7c30c79` · **ταυτόσημο με claimed:** n/a (authored)
- **Πραγματικό output:**
```
tree_size monotonicity rule in s8.3 (383-423): 0
monotone/rollback wording in MLTP: 0
  require tlog_inclusion(bundle) AND consistency(bundle.transparency, lts.last_accepted_tlog)  else split-view
- **Gossip κανόνας καταναλωτή**: αποθηκεύει το τελευταίο (tree_size,
  log_root) που είδε· νεότερη απάντηση με μη-συνεπές log ⇒ απόρριψη
  (split-view detection). Το `tlog-verify` ήδη παρέχει consistency proofs
```

### RC-25 — Δύο ασύμβατοι μηχανισμοί rotation: continuity statement από το ΠΑΛΙΟ κλειδί (KL §2.4, v1.3 §4.1) vs «ΜΟΝΟ ο root υπογράφει delegations» (MLTP §8.3-B)· key_lineage χωρίς καταναλωτή

- **Αντιπροσωπευτικό:** `A1-F13` · **μέλη:** `A1-F13` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** Ένας μηχανισμός rotation αποδεκτός από τον verifier· ανάκληση/διαδοχή = νεότερη root-signed delegation με μεγαλύτερο seq (TB §3:38-42)· δύο ACTIVE specs δεν διαφωνούν (KW-16 αρχή).
- **Θέση spec:** KL §2.4:49-52 · v1.3 §4.1:196-198 · MLTP §1.0:40, §8.3:390 (key_lineage = 0 στο §8.3) · TB §3:41
- **Αναμενόμενο (κατά το spec/witness):** Rotation = νέα root-signed delegation (TB §3)· η continuity statement του παλιού κλειδιού ΜΟΝΟ ως ιστορικό lineage (μη-authoritative) ή αφαιρείται· δηλωμένη versioned precedence MLTP §8.3-B επί KL §2.4.
- **Πραγματικό (κείμενο ως έχει):** KL:49-50 και v1.3:197-198 προδιαγράφουν «continuity statement υπογεγραμμένο από το παλιό κλειδί»· MLTP:390 «ΜΟΝΟ ο root υπογράφει delegations»· `key_lineage` δεν διαβάζεται στο §8.3· versioned precedence μόνο για KL §2.5.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && sed -n '49p' deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md; sed -n '197,198p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; sed -n '390p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '383,423p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md | grep -c 'key_lineage'
```
- **Exit code:** `1` · **SHA-256(actual output):** `627a903e6d8c6d97e9928c5e78943b342a9f04bccee49f809ea11ee5a6d469c8` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
- Νέο κλειδί υπογράφεται από το ΠΑΛΙΟ (continuity statement: «το kid-N+1
revocation**: append-only key registry, `kid`+`alg`+`key_lineage`, continuity
statement υπογεγραμμένο από το παλιό κλειδί· revocation out-of-band (key-lifecycle §2.4-2.5).
     require sig_verify(d, lts.pinned_owner_root)                 # ΜΟΝΟ ο root υπογράφει delegations
0
```

### RC-26 — Crypto profile χωρίς παραμέτρους: δύο ορισμοί fingerprint, κανένα RSA floor, καμία Ed25519 verification variant, καμία δέσμευση alg↔τύπος κλειδιού

- **Αντιπροσωπευτικό:** `A2-14` · **μέλη:** `A2-14` · **severity (filed / adjudicated):** P2 / P2
- **Invariant:** Το «ΠΡΑΓΜΑΤΙΚΟ» crypto profile (MLTP §4:213-242) είναι αρκετά πλήρες ώστε δύο ανεξάρτητοι kernels να δίνουν ταυτόσημο result (Q21 δ:261-262· Q22).
- **Θέση spec:** TB §2:21-25 · PCL §4:108 · KL §2.1:33 · MLTP §4:219-242 · PROOF-OBJECT §4:101-107
- **Αναμενόμενο (κατά το spec/witness):** ΜΙΑ fingerprint συνάρτηση (π.χ. RFC 7638 JWK thumbprint ή sha256 επί DER SPKI)· ένα RSA floor· μία Ed25519 verification variant (RFC 8032 strict ή ZIP215)· `alg` πρέπει να ταιριάζει με τον τύπο του delegated key.
- **Πραγματικό (κείμενο ως έχει):** TB:24-25 «fingerprint (sha256 του δημόσιου κλειδιού)» χωρίς encoding vs PCL:108 «RFC 7638 thumbprint»· TB:22 δέχεται RSA-3072, KL:33 «RSA-4096 σήμερα», MLTP floor = 0· Ed25519 variant = 0· alg↔key-type = 0.
- **Σημείωση Stage A:** ARGUMENT-ONLY όπως κατατέθηκε· προκείμενες ελεγμένες μηχανικά στο Stage A. Το μοτίβο του πρώτου δοκιμαστικού ελέγχου ('canonical S' με -i) έδωσε ψευδή αντιστοίχιση στο «canonical set» (MLTP:269)· το τελικό μοτίβο του STAGE-A-RERUN.py δίνει 0.
- **Εντολή (stage-A-authored-premise-check):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; T=deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; P=deployment/PROOF-CARRYING-LAW.md; K=deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md; sed -n '24,25p' $T; sed -n '108p' $P; sed -n '21,22p' $T; sed -n '33p' $K; printf 'RSA modulus floor in MLTP: %s\n' "$(grep -ci 'modulus\|RSA-[0-9]' $M)"; printf 'Ed25519 verification variant pin in MLTP (RFC 8032|ZIP215|cofactor|small-order): %s\n' "$(grep -c 'RFC 8032\|RFC8032\|ZIP215\|cofactor\|small-order' $M)"; printf 'fingerprint encoding rule in MLTP (DER|SPKI|RFC 7638|JWK thumbprint): %s\n' "$(grep -c 'DER\|SPKI\|RFC 7638\|JWK thumbprint' $M)"; printf 'alg<->key-type binding rule in MLTP: %s\n' "$(grep -c 'alg.*key type\|key type.*alg\|alg.*matches.*key\|delegated key.*alg' $M)"
```
- **Exit code:** `0` · **SHA-256(actual output):** `b532f5c8112718e8665baa068475ed9526e9cfc6164808c01b3e756b71db134d` · **ταυτόσημο με claimed:** n/a (authored)
- **Πραγματικό output:**
```
2. Πρακτικό τελετής (ceremony record): ημερομηνία, fingerprint
   (sha256 του δημόσιου κλειδιού), μάρτυρες (§4), αποθήκευση ιδιωτικού
> (or its RFC 7638 thumbprint). If a proof embeds a `public_key`, it must match
   serving host), γεννά το **Owner Root Key** (Ed25519 προτεινόμενο·
   RSA-3072 αποδεκτό για συμβατότητα με την υπάρχουσα RSA έδρα):
- Αλγόριθμος: RSA-4096 σήμερα· **Ed25519 στόχος** (P4 migration, με `kid`
RSA modulus floor in MLTP: 0
Ed25519 verification variant pin in MLTP (RFC 8032|ZIP215|cofactor|small-order): 0
fingerprint encoding rule in MLTP (DER|SPKI|RFC 7638|JWK thumbprint): 0
alg<->key-type binding rule in MLTP: 0
```

### RC-27 — «Κάθε IssuedClaim είναι proof-carrying» ισχύει για 3 από 8 profiles· το §8.3 A καλεί pcl_inclusion για όλα

- **Αντιπροσωπευτικό:** `A2-12` · **μέλη:** `A2-12` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Κάθε IssuedClaim περιέχει το αντικείμενο απόδειξης· υπογραφή = επιπλέον, ποτέ αντί (v1.3 §3:162-164· MLTP §1.0:36-37· §8.3:385-387).
- **Θέση spec:** v1.3 §3:162-164 · MLTP §1.0:36-37 · §2.1:79-91, §2.4:110-116, §2.6:129-147, §2.7:149-157, §2.8:159-170 · §8.3:385-387 · PROOF-OBJECT §0:9-14
- **Αναμενόμενο (κατά το spec/witness):** `proof_material` shape ανά profile και για τα 8 (ή ρητή δήλωση ποια profiles είναι signature-only, με ονομαστικό βήμα A που τα εξαιρεί)· bundle-carried referenced objects για source-authenticity.
- **Πραγματικό (κείμενο ως έχει):** `proof_material` ορίζεται μόνο στις 99 (legal-state), 106 (temporal-projection), 125 (judgment-identity-and-text)· 8 headings `### 2.x`· §8.3 A: `pcl_inclusion(c.payload, c.proof_material)` για ΟΛΑ τα claims.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER; M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; grep -n 'proof_material' $M; grep -c '^### 2\.' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `21ce79e592cc9c2e4fd6d6d70ff77bf0427bc601e4d2348c386d91b4cb54aee5` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
36:  "proof_material": <το αναπαραγώγιμο αντικείμενο απόδειξης — Merkle path,
99:proof_material = { "pcl_inclusion": <PCL path ≤64>, "uncertainty_roots": {...} }
106:proof_material = { "snapshot_manifest": <version-graph snapshot-at + per-step fold>,
125:proof_material = { "source_seal": <acquisition + PCL inclusion των bytes> }
387:     checks += pcl_inclusion(c.payload, c.proof_material)
8
```

### RC-28 — Two-channel ταυτότητα απόφασης: expression_id = content digest ⇒ anonymized/original = δύο ταυτότητες κατά Q13· ο witness του KW-3 δοκιμάζει άλλη μετάλλαξη

- **Αντιπροσωπευτικό:** `A3-F4` · **μέλη:** `A3-F4` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Ίδια απόφαση από δύο κανάλια ⇒ μία νομική ταυτότητα (Q07:119· Q13:176-177 γ· Q24:291-294· KW-3:20 want)· κάθε witness σκοτώνει τη δηλωμένη μετάλλαξη (KW:9-12).
- **Θέση spec:** USC §1.2:164-176 · USC §12:642 · v1.3 §2.1:98-102 · Q07:115-119 · Q13:169-177 · Q24:293-298 · KW-3:20 · canonical-serialization §2:34-36 · MLTP §2.5:123
- **Αναμενόμενο (κατά το spec/witness):** Ρητός ορισμός του επιπέδου ταυτότητας για τον two-channel invariant (work_id) και ρητή σχέση anonymized↔original (ίδιο work, διακριτές expressions με anonymization provenance)· witness για τη μετάλλαξη «δεύτερο κανάλι ⇒ δεύτερο work_id», όχι W-UNRELATED-CORPUS-IDENTITY-CHURN.
- **Πραγματικό (κείμενο ως έχει):** Judgments = single-document-expression = content digest (USC:164-166, 176)· §2 normalization = NFC/LF/whitespace μόνο ⇒ anonymized vs original = δύο expression_ids· Q13:169-170 μετρά expression_id ως ταυτότητα και (γ) απαιτεί μία· v1.3:100 «(αν ίδιο §2-normalized κείμενο)»· KW-3 παραπέμπει στο W-UNRELATED-CORPUS-IDENTITY-CHURN (USC:642) που δοκιμάζει άσχετη εισαγωγή (seq 100→101), όχι δεύτερο κανάλι.
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && D=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL && sed -n '20p' $D/V1.3-KILL-WITNESSES.md && sed -n '642p' deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md && sed -n '164,166p;176p' deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md && sed -n '100p' $D/CHANGE-PROPOSAL-v1.3.md && sed -n '169,170p;176,177p' $D/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md && sed -n '34,36p' deployment/verify/canonical-serialization-spec.md
```
- **Exit code:** `0` · **SHA-256(actual output):** `b1ec67f8fc50349c4636e0c9409fa04c67ae66ff5b9cd552d8d2243f8d7114f1` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
| **KW-3** | raw-byte identity churn | εισαγωγή δεύτερου manifestation/κανάλι της ίδιας απόφασης· σχεδίαση που παράγει **δεύτερο** `work_id`/`expression_id` από τα raw bytes | **W-UNRELATED-CORPUS-IDENTITY-CHURN** — μία νομική ταυτότητα, πολλά items· ταυτότητα ΟΧΙ από raw-byte digest | v1.3 §2.1, MLTP §2.5, Q13/Q24 |
| **W-UNRELATED-CORPUS-IDENTITY-CHURN** | εισαγωγή άσχετης απόφασης (corpus seq 100→101) → ΚΑΘΕ υπάρχον expression_id ΑΜΕΤΑΒΛΗΤΟ· μόνο νέες attestations δυνατές· expression schema με πεδίο cut/checkpoint → reject |
single-document-expression: {"work", "language",
                         "content_sha256": <sha256(UTF-8(§2-normalized
                           κείμενο — Η ΙΔΙΑ normalization των
- Rule-B works χωρίς body-kind: ΜΟΝΟ single-document [Κ-S8] — provision-
⇒ **ίδιο `work_id`** και (αν ίδιο §2-normalized κείμενο) **ίδιο `expression_id`**,
**Κριτήριο:** ταυτότητα = `work_id` (identity_domain + official_key) και
`expression_id` (κείμενο + valid_at) — **τα raw bytes ταυτοποιούν το ITEM μιας
(`W-UNRELATED-CORPUS-IDENTITY-CHURN`)· (γ) ίδια απόφαση από δύο κανάλια που παράγει
**δύο** ταυτότητες ⇒ αποτυγχάνει (πρέπει μία νομική ταυτότητα, πολλά items).
- **NFC** Unicode normalization.
- Γραμμές με **LF** (ποτέ CRLF).
- Χωρίς trailing whitespace ανά γραμμή· χωρίς BOM.
```

### RC-29 — Η δέσμευση bytes↔νομικό αντικείμενο είναι ανέκφραστη στα MLTP profiles (κανένα manifestation επίπεδο, κάθε profile φέρει ένα μόνο άκρο)

- **Αντιπροσωπευτικό:** `A3-F5` · **μέλη:** `A3-F5` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Offline verifier/auditor ελέγχει ότι το κείμενο ενός RELEASED αντικειμένου παράγεται από bytes με πιστοποιημένη επίσημη προέλευση (v1.3 §2.2:124-127· Q03:78-80)· τέσσερα επίπεδα υιοθετημένα αυτούσια (v1.3 §2.1:85-96)· «Η ΜΟΝΗ γέφυρα» raw→text = extraction-receipt/2 + manifestation_id (USC:52).
- **Θέση spec:** MLTP §2.1:81-88 · §2.2:95-99 · §2.5:120-125 · §8.3:386-387 · v1.3 §2.1:85-96 · USC:52 · PCL:4-5
- **Αναμενόμενο (κατά το spec/witness):** Typed γέφυρα στα profiles: source-authenticity φέρει manifestation_id/work_id· legal-state/judgment φέρουν acquisition_receipt_id + extraction-receipt/2 ref· manifestation επίπεδο (lsm1:) παρόν· judgment payload φέρει content digest/expression_id ώστε το pcl_inclusion να έχει typed leaf.
- **Πραγματικό (κείμενο ως έχει):** manifestation_id|lsm1 = 0 στο MLTP· work/expression = 0 στο §2.1· artifact/receipt = 0 στο §2.2· digest/expression = 0 στο §2.5 payload (μόνο untyped `source_seal` στο proof_material).
- **Εντολή (adversary):**
```
cd /home/user/THE-LEGAL-WATCHTOWER && F=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md && echo "manifestation_id|lsm1 in MLTP: $(grep -c 'lsm1\|manifestation_id' $F)" && echo "work/expression fields in §2.1 source-authenticity (81-88): $(sed -n '81,88p' $F | grep -c 'work_id\|expression_id\|lsw1\|lse1')" && echo "artifact/receipt fields in §2.2 legal-state (95-99): $(sed -n '95,99p' $F | grep -c 'raw_artifact\|acq1\|acquisition\|digest')" && echo "digest/expression fields in §2.5 judgment (120-125): $(sed -n '120,125p' $F | grep -c 'expression_id\|lse1\|digest\|acq1\|content_sha256')" && sed -n '386,387p' $F
```
- **Exit code:** `0` · **SHA-256(actual output):** `ec2a96cde70440457aa83bcf282248a4e74533e34853e30bcad912026622c1ec` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
manifestation_id|lsm1 in MLTP: 0
work/expression fields in §2.1 source-authenticity (81-88): 0
artifact/receipt fields in §2.2 legal-state (95-99): 0
digest/expression fields in §2.5 judgment (120-125): 0
  for c in bundle.issued_claims:
     checks += pcl_inclusion(c.payload, c.proof_material)
```

### RC-30 — provider-adoption-qualified αυτο-εκδόσιμο: κανένα provider registry στο LocalTrustState· provider_attestations δεν διαβάζονται

- **Αντιπροσωπευτικό:** `A4-5` · **μέλη:** `A4-5` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** provider-adoption-qualified ΜΟΝΟ από εξωτερικό provider-registry με attestations «όχι δικές μας» (MLTP §3:183,197· v1.3 §7:295-297· Q-tests:43).
- **Θέση spec:** MLTP §3:183,197 · §8.1:353-364 · §8.3:412-418 · v1.3 §7:295-297, §8:318
- **Αναμενόμενο (κατά το spec/witness):** `provider_registry` στο LocalTrustState· H: για level provider-adoption-qualified `require signer.kid ∈ lts.provider_registry` και provider_attestations υπογεγραμμένες από registered providers ≠ issuer.
- **Πραγματικό (κείμενο ως έχει):** provider = 0 στο LocalTrustState· provider_attestations = 0 στο §8.3.
- **Σημείωση Stage A:** Αδελφή της RC-06 (ίδια κλάση: registry-unbound signer) αλλά διακριτή έδρα (provider registry απουσιάζει εντελώς).
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; printf 'provider in LTS: %s\n' "$(sed -n '353,365p' $M | grep -ci provider)"; printf 'provider_attestations in 8.3: %s\n' "$(sed -n '382,424p' $M | grep -c provider_attestations)"; sed -n '197p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `f4f9688ba12a83e59f2ce095dd0a6d08ba0aba5a80d0a8b49b5813577d5646d5` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
provider in LTS: 0
provider_attestations in 8.3: 0
| `provider-adoption-qualified` | provider-registry (εξωτερικό) | provider attestations/μετρήσεις — **όχι** δικές μας |
```

### RC-31 — Οι witnesses πιστώνονται με μη-equivocation ενώ GitHub+TSA quorum ικανοποιείται από τον owner σε αμφότερα τα forks· first-time consumer απροστάτευτος

- **Αντιπροσωπευτικό:** `A4-10` · **μέλη:** `A4-10` · **severity (filed / adjudicated):** P1 / P1
- **Invariant:** Split-view ανιχνεύσιμο (MLTP §10:475· §8.3:401-403 quorum=2· v1.3 §4.1:189-193· Q23:283-288) ενώ «RFC-3161 = μόνο χρόνος» (v1.3:121· TB §1:14).
- **Θέση spec:** MLTP §10:475 · §8.3:401-403 · v1.3 §2.2:121, §4.1:189-193 · TB §1:14, §4:51-62 · KW-5:22, KW-14:31
- **Αναμενόμενο (κατά το spec/witness):** Ρητή δήλωση ότι `witness_quorum(GitHub+TSA)` αποδεικνύει δημοσίευση/χρόνο μόνο· non-equivocation ΜΟΝΟ από (α) consumer gossip έναντι δικού του checkpoint και (β) ανεξάρτητο cross-client witness που ΥΠΟΓΡΑΦΕΙ checkpoints (CT/OTS ή third-party witness)· first-time consumer ⇒ UNKNOWN για split-view μέχρι δεύτερο checkpoint.
- **Πραγματικό (κείμενο ως έχει):** §10:475 πιστώνει την τάξη witnesses (GitHub history, ≥2 TSAs, opt. CT) με «consistency/μη-equivocation»· οι TSAs χρονοσφραγίζουν οποιοδήποτε digest· ο «Μάρτυρας 1 — GitHub» = commit του owner (TB:51-53), χωρίς witness-key· ο μόνος cross-client μάρτυρας (TB:57-58) = «μελλοντικός, προαιρετικός»· §8.3 E ελέγχει μόνο συνέπεια με το ΔΙΚΟ του checkpoint.
- **Σημείωση Stage A:** Μερική διόρθωση: η φράση «TSAs are credited» είναι υπερβολική ανάγνωση της γραμμής 475 (το «(TSA)» προσδιορίζει τον χρόνο, όχι τη μη-equivocation). Η ρίζα (owner-satisfiable quorum, first-time consumer απροστάτευτος, ο μόνος cross-client witness προαιρετικός) επιβιώνει.
- **Εντολή (adversary):**
```
M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; sed -n '121p' deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; sed -n '475p' $M | cut -c1-140; sed -n '403p' $M
```
- **Exit code:** `0` · **SHA-256(actual output):** `175883b1b062cb1f01aad17d097fc863c058af44d49c1bfe2d3a03bae109651e` · **ταυτόσημο με claimed:** True
- **Πραγματικό output:**
```
| Χρόνος (μόνο) | RFC-3161 anchoring στο receipt | **μόνο** χρόνος bytes — ένα στοιχείο, όχι το όλον |
| **Transparency witnesses** | δημοσίευση checkpoint, χρόνο (TSA), consistency/μη-equivocation (split-view) | **ΟΧΙ** ο
  require witness_quorum(bundle.witness_checkpoints, witnesses, quorum=2)
```

## 4. Αποκλίσεις επανεκτέλεσης (μορφή μόνο — καμία ουσιαστική)

- `A1-F4`: Ο αντίπαλος συντόμευσε δύο διαδρομές αρχείων με «.../» στο claimed raw_output· το πλήρες output είναι κατά τα άλλα ταυτόσημο. Καμία ουσιαστική διαφορά.
- `A1-F5`: Το claimed raw_output δείχνει τις γραμμές 39-40 του LAWMAX-TRUST-BOOTSTRAP-SPEC.md ενώ η εντολή (`sed -n '38,39p'`) τυπώνει τις 38-39. Η προκείμενη (η delegation φέρει fingerprint, όχι κλειδί) ισχύει και στις δύο· οι υπόλοιπες γραμμές ταυτόσημες.
- `A1-F6`: Το claimed raw_output παρουσιάζει τις γραμμές 391/411/161 με διαφορετική σειρά από αυτή που τυπώνει το `sed -n '391p;411p;161p'` (σειρά αρχείου: 161, 391, 411). Ίδιο περιεχόμενο.

## 5. DUPLICATE_OF — υπόλειμμα που διατηρείται στη ρίζα

- `A1-F6` → **DUPLICATE_OF:A2-05** (RC-04): Σκέλος (1) = RC-04 (παράθυρο vs d.signed_time)· σκέλος (2) (seq supersession, revocation κατά delegation_seq) = RC-05 (A2-04). Ίδιο περιεχόμενο output με διαφορετική σειρά γραμμών.
- `A1-F7` → **DUPLICATE_OF:A4-4** (RC-06): Πλήρως καλυπτόμενο από RC-06· το σκέλος «q.subject ποτέ δεν δεσμεύεται στο claim» = RC-08 (A3-F3).
- `A1-F12` → **DUPLICATE_OF:A2-13** (RC-24): Ίδια ρίζα (καμία μονοτονία/ηλικία revocation checkpoint)· το ιδιαίτερο σκέλος «max-staleness revocation_state έναντι trusted now» διατηρείται στο expected της RC-24.
- `A2-06` → **DUPLICATE_OF:A1-F3** (RC-03): Ίδια ρίζα· προσθέτει ότι ο «Witness 1 — GitHub» δεν έχει signer key στο witness_key_registry (διατηρείται στη RC-31).
- `A2-08` → **DUPLICATE_OF:A4-4** (RC-06): Ίδια ρίζα (QSR χωρίς sig_verify, role αυτοδηλούμενο, denylist ενός kid, receipts nullable, αόριστα predicates).
- `A2-09` → **DUPLICATE_OF:A4-8** (RC-19): Σκέλη (α) root-signed revocation ⇒ untrusted-key και (β) revoked_subject χωρίς δέσμευση — αμφότερα στη RC-19.
- `A2-10` → **DUPLICATE_OF:A1-F4** (RC-15): Υποσύνολο της RC-15 (v1.3 §4.1 item 2).
- `A2-11` → **DUPLICATE_OF:A1-F4** (RC-15): Υποσύνολο της RC-15 (PCL §5 RS256/thumbprint pin· audit εκτός PCL/TB).
- `A3-F2` → **DUPLICATE_OF:A4-4** (RC-06): Ίδια ρίζα· το σκέλος «quorum μη αναπαραστάσιμο με ένα {kid,sig}» και «sibling delegated key υπό τον ίδιο pinned root» διατηρούνται στο actual/expected της RC-06.
- `A3-F6` → **DUPLICATE_OF:A1-F2** (RC-01): Ίδια ρίζα (αόριστο signing input)· το σκέλος «στόχος RFC-3161 imprint αόριστος» διατηρείται στο note της RC-01 και καταναλώνεται από τη RC-03.
- `A3-F9` → **DUPLICATE_OF:A4-2** (RC-11): Ίδια ρίζα (καμία consumer-side άγκυρα για auth1:/ireg1:)· τα σκέλη «authority_proof_ref presence-only» και «provisional_id αόριστο» διατηρούνται στη RC-11.
- `A4-3` → **DUPLICATE_OF:A1-F3** (RC-03): Ίδια ρίζα· προσθέτει QSR.issued_at και source-authenticity.time_anchor ως ίδιας κλάσης — διατηρείται στη RC-03 (spec_location §2.1:87, §3:184).
- `A4-6` → **DUPLICATE_OF:A3-F3** (RC-08): Ίδια ρίζα (subject/bundle_digest χωρίς δέσμευση)· το σκέλος «transplant σε release N+37 μέχρι expiry» διατηρείται στο expected της RC-08.
- `A4-7` → **DUPLICATE_OF:A2-05** (RC-04): Ίδια ρίζα· προσθέτει ότι το `signed_time` δεν υπάρχει σε καμία spec (grep όλου του deployment/ = 1 εμφάνιση, MLTP:391) — διατηρείται στο actual της RC-04.
- `A4-9` → **DUPLICATE_OF:A1-F9** (RC-21): Ίδια ρίζα (issuer unbound, auth1: collision).

## 6. Τι ΔΕΝ αποδεικνύει αυτό το record

- Δεν αποδεικνύει ότι το v1.3 είναι FALSIFIED ως σύνολο ούτε ότι επιβιώνει· ο διακοπείς κύκλος δεν είχε adjudication ούτε A5–A8. Οι καταστάσεις εδώ είναι κρίση του συντάκτη με βάρος στο κείμενο (spec-literalist), όχι ανεξάρτητη adjudication.
- Οι έλεγχοι προκείμενης για τα 4 ARGUMENT-ONLY ευρήματα συγγράφηκαν στο Stage A· επιβεβαιώνουν την ΑΠΟΥΣΙΑ κανόνα στο κείμενο, όχι την εκμεταλλευσιμότητα.
- Το CONFIRMED σημαίνει «το κείμενο, όπως είναι γραμμένο, δεν παραδίδει τον invariant»· δεν σημαίνει ότι η επιδιόρθωση είναι μεγάλη ή μικρή — αυτό κρίνεται στο Stage B ανά έδρα.
- Η επανεκτέλεση είναι grep/sed πάνω σε κείμενο· δεν εκτελεί verifier. Kernel-diversity/υλοποίηση δεν υπάρχουν.
