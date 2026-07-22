# LAWMAX — DATASET-PACKAGE PROJECTION CONTRACT · v1
**Spec-only. Καμία υλοποίηση χωρίς ρητό «εγκρίνω» δημιουργού.**
Καταγράφηκε στη φάση [0115] (απόσυρση legacy HuggingFace renderer).

## Τι είναι

Η ικανότητα «πακετάρισμα του corpus ως διανεμήσιμο dataset» (π.χ. HuggingFace)
ΔΕΝ πέθανε — αποσύρθηκε η ΛΑΝΘΑΣΜΕΝΗ legacy υλοποίησή της
(`export-corpus-dataset`/`huggingface-formatter`, source/ai-ingest-manifest.lisp),
η οποία παραβίαζε το Universal Source Contract και το proof-carrying release
model με hardcoded παραδοχές:

- default dataset «Greek Constitution» (corpus-specific σε multi-corpus σύστημα)
- hardcoded dataset description/citation
- hardcoded άδεια `cc-by-4.0` (αντίθετη με All Rights Reserved / Deferred License Policy)
- σταθερό embedding length 768 · σταθερό split 80/10/10
- ειδική HF class + dataset card εκτός canonical release

## Τι ΚΡΑΤΗΘΗΚΕ ζωντανό (η ουδέτερη ικανότητα)

| Ικανότητα | Ζωντανή έδρα |
|---|---|
| canonical article records | `orchestrator.ai-ingest:build-corpus-manifest` |
| dataset JSONL serialization | `orchestrator.ai-ingest:dataset-jsonl-string` |
| deterministic ordering | `manifest-articles-ordered` |
| release/provenance metadata | canonical release (deploy-epistemic) + provenance sidecars |

## Το μελλοντικό συμβόλαιο (όταν/αν εγκριθεί υλοποίηση)

```
dataset-package projection
├── canonical release checkpoint      ← είσοδος: ΜΟΝΟ υπογεγραμμένο release, ποτέ raw corpus
├── source/provenance roots           ← κάθε record δένεται στο pcl_text_root / census
├── corpus-specific licence           ← ΑΝΑ corpus, από config — ΠΟΤΕ hardcoded
├── configurable split policy         ← δηλωμένη πολιτική, όχι μαγικό 80/10/10
├── schema version                    ← versioned, μεταναστεύσιμο
└── optional HuggingFace renderer     ← ΠΡΟΒΟΛΗ (projection), ΠΟΤΕ orchestration path
```

Αρχές (δεσμευτικές):
1. **Projection, όχι orchestration** — καταναλώνει canonical release checkpoint·
   δεν τρέχει pipeline, δεν διαβάζει πηγές, δεν γράφει δεύτερη αλήθεια.
2. **Μία έδρα serialization** — πάνω στο `dataset-jsonl-string`· κανένας δεύτερος serializer.
3. **Άδεια ανά corpus από config** — συμβατή με All Rights Reserved μέχρι την
   Deferred License Policy Decision του δημιουργού.
4. Κάθε renderer (HF ή άλλος) είναι προαιρετικό τελικό στάδιο πάνω στο ίδιο
   projection — νέο target μορφής = νέος renderer, όχι νέα έδρα.
