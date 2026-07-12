# [0064] P4: ΠΛΗΡΗΣ κρυπτογραφική επαλήθευση TSR — RSA + ECDSA + αγκύρωση

**Ποιος/πότε:** Claude (Χειρουργός Πυρήνα) — 2026-07-11/12. Εντολή δημιουργού:
«προχωρα σε ολα εκτος απο το ceremony» ⇒ P4 (task #32).

## Τι χτίστηκε (η ΜΙΑ έδρα: verify-tsr-cryptographically)

Πλήρες RFC-3161/CMS(RFC-5652) verify πάνω στην αυστηρή DER έδρα orchestrator.asn1:
1. PKIStatus ∈ {granted, grantedWithMods}.
2. TSTInfo.messageImprint ≡ digest(message) — ΘΕΣΙΑΚΑ, exact-length (όχι containment).
3. signedAttrs: messageDigest ≡ digest(TSTInfo) + contentType ≡ TSTInfo +
   **SigningCertificate(V2)/ESSCertID ΥΠΟΧΡΕΩΤΙΚΟ** και certHash ≡ hash(signer cert).
4. Υπογραφή SignerInfo πάνω στο DER(SET signedAttrs, A0→31): **RSA PKCS#1
   (sha256/384/512, μέσω της έδρας verify-rsa-pkcs1) ΚΑΙ ECDSA
   secp256r1/384r1/521r1 (ironclad, DER{r,s}→raw, r,s range-checked στην έδρα)**.
5. Signer cert: επιλέγεται από την υπογραφή, δένεται από το ESSCertID, απαιτεί
   **EKU id-kp-timeStamping** και **genTime εντός [notBefore, notAfter]**.
6. Άγκυρα: με pinned CA ⇒ :pinned ΜΟΝΟ αν signer ≡ pinned cert Ή υπογράφεται
   από pinned cert με **basicConstraints CA:TRUE**. Χωρίς CA ⇒ :unpinned με
   ΡΗΤΗ δήλωση στο docstring ότι το tier αυτό ΔΕΝ αυθεντικοποιεί υπογράφοντα.
7. Αυστηρά όρια: κανένα trailing byte μετά TimeStampResp/TSTInfo.

Θάνατοι: η παλιά verify-timestamp/extract-hash-from-tsr (byte-scan, SHA-256-μόνο,
καμία υπογραφή) ΔΙΑΓΡΑΦΗΚΕ — δεύτερη ασθενέστερη έδρα ίδιας έννοιας, 0 callers.

## Αντιπαλική επιθεώρηση (2 ανεξάρτητοι κριτές, προ-proof, κατά το συμβόλαιο)

Κριτής ασφάλειας: C1 (unpinned forgeable/ασαφής δήλωση) → ΚΛΕΙΣΤΟ (ρητό docstring
+ ESS/EKU/validity παντού)· C2 (pinned χωρίς EKU/validity/basicConstraints) →
ΚΛΕΙΣΤΟ (όλα επιβάλλονται)· C3 (ESSCertID απόν) → ΚΛΕΙΣΤΟ (υποχρεωτικό + match)·
M1 (ECDSA r,s) → ΚΛΕΙΣΤΟ (range-check στην έδρα· ironclad επιβάλλει r,s<n)·
M2 (P-521/SHA-512) → ΑΝΑΣΚΕΥΑΣΤΗΚΕ (512<521 bits ⇒ e=όλο το hash, FIPS 186-4
§6.4, ironclad συμβατό)· M3 (trailing bytes) → ΚΛΕΙΣΤΟ· L1 (identity pinning
στο docstring) → ΥΛΟΠΟΙΗΘΗΚΕ.
Κριτής μετριότητας: F1 (διπλή έδρα TSR verify) → ΚΛΕΙΣΤΟ (θάνατος παλιάς)·
F2 (τεστ-ταυτολογία «⇒ επαληθεύεται t») → ΚΛΕΙΣΤΟ (βεβαιώνεται το tier)·
F3 (catch-all handler) → ΚΛΕΙΣΤΟ (στενός: asn1-error/invalid-response/
ironclad-error μόνο· εσωτερικά ελαττώματα διαδίδονται)·
F5 (διπλός TBS-walk) → ΜΕΡΙΚΩΣ: %cert-tbs-fields = η μία έδρα TBS εντός αρχείου.

**Δηλωμένα υπολείμματα (φάση θανάτου: L7-B ή επόμενη συντήρηση, απόφαση δημιουργού):**
- F4: το τερματικό βήμα RSA-SPKI→ironclad-key υπάρχει και στο jws-authority
  (parse-rsa-public-key)· ενοποίηση σε μία spki-span έδρα (RSA+EC, bytes/start/end).
- F5β: cert-triple decompose και στο x509-authority (validator)· decode-έδρα εκεί.
- F6: OID registry μία έδρα (numeric-list + byte-vector σήμερα σε 2 μορφές).
- L4: επιλογή SET με (find … reverse) — ορθό υπό αυστηρό DER, όχι δομικά αδύνατο λάθος.

## Proof (μηχάνημα session, SBCL 2.2.9)

- orchestrator-infrastructure: φορτώνει καθαρά (0 σφάλματα).
- **tests/tsr-crypto-verify-test.lisp: 19/19** σε ΓΝΗΣΙΑ fixtures (committed
  receipts [0058]/kpolitikis aaf60c01, tests/fixtures/tsr/): Sectigo RSA/SHA-384
  PASS· FreeTSA ECDSA P-384/SHA-512 PASS· :pinned και για τους ΔΥΟ με τον γνήσιο
  embedded issuer (intermediate/Root αντίστοιχα)· αρνητικά: λάθος μήνυμα,
  flipped signature bytes, μισό/άδειο/padded TSR, λάθος pinned CA — ΟΛΑ FAIL.
- Dockerfile: το τεστ μπήκε στο standalone-test gate (θα τρέξει στο owner proof).

## Εκκρεμεί

Owner docker proof (build --target standalone-test) + έγκριση φάσης. Μετά: #33
L7-B transparency log, #34 ΑΚ/ΚΠολΔ (θέλει αυθεντικό ΦΕΚ από δημιουργό), ceremony ΤΕΛΕΥΤΑΙΟ.
