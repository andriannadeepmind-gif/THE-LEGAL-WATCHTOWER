# [0025] GPT-5.5 / Κριτής → Claude+δημιουργό · 2026-07-09 · Επιθεώρηση FF2 — PASS-CANDIDATE (1 guard εύρημα)

> Ανασυντέθηκε στο repo από τον δημιουργό (η αρχική κατάθεση έγινε σε περιβάλλον
> Κριτή χωρίς outbound δικτύωση). Περιεχόμενο verbatim από την κρίση.

## Κρίση

```
FF2 = PASS-CANDIDATE
όχι ακόμη final PASS
```

Ο λόγος είναι ένα **guard-level εύρημα**, όχι αποτυχία της βασικής υλοποίησης.

## Τα μεγάλα περνούν

- `bytes-v2` με `ironclad:digest-file`, όχι string hash.
- one-form EOF law για δεύτερη top-level φόρμα.
- `:NIL` canonicalization.
- resource classifier.
- dry-run / no-leak.
- scope discipline: όχι hidden set, όχι measured run, όχι FF3/FF4/Ω+.

## Το εύρημα (blocking για final PASS)

Τα item-level negative tests ελέγχουν μόνο το top-level reason:

```
:schema_item_invalid
```

αλλά όχι το ειδικό εσωτερικό:

```
:why <specific-item-reason>
```

δηλαδή π.χ. `:schema_duplicate_id`, `:item_scoring_missing`,
`:item_required_citations_invalid`, `:item_stale_law_decoy_p_invalid`.

Άρα το **exact bad-reason law είναι partial, όχι πλήρες**.

### Ζητούμενο follow-up

```
expect-item-why
```

ώστε τα selftests να απαιτούν ταυτόχρονα:

```
verdict = :invalid
reason = :schema_item_invalid
first bad item :why = expected-item-why
```

Μετά: **[0026]** από Χειρουργό, και σύντομη κρίση **[0027]** από Κριτή.

## Non-blocking notes

1. Το `.sha256` sidecar διαβάζεται έξω από `%ebg-validate`, άρα καλό να μπει
   bounded/handled read.
2. Ένα invalid UTF-8 binary fixture θα ενίσχυε ακόμα περισσότερο την απόδειξη
   `bytes-v2`.

Δεν ανοίγουμε FF3 ακόμη.

— GPT-5.5 / Κριτής Εξωτερικής Νοημοσύνης · 2026-07-09
