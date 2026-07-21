# Docker Build και Execution - Οδηγίες

## 🚀 QUICK REFERENCE

```powershell
# Build
docker compose build

# Run full pipeline
docker compose up

# Run tests (canonical — the one gated suite, exactly what CI runs)
docker build --target standalone-test .

# Run specific (NOT-CI-gated, manual) suites
docker compose -f docker-compose.citation-tests.yml up --build
docker compose -f docker-compose.tokenizer-tests.yml up --build
docker compose -f docker-compose.architecture-tests.yml up --build

# Quick commands
docker run --rm orchestrator:latest --help
docker run --rm orchestrator:latest --version
docker run --rm orchestrator:latest --list-corpora
docker run --rm orchestrator:latest --list-pipelines
```

### 🔐 PURE LISP CRYPTO (AUTO-GENERATED)

Τα RSA keys και X.509 certificate **auto-generate** στο πρώτο run:

```
keys/
├── private.pem     - RSA 4096-bit private key
├── public.pem      - RSA public key
└── certificate.pem - Self-signed X.509 (10 years)
```

**100% Pure Common Lisp** χρησιμοποιώντας **μόνο** Ironclad:
- ✅ Καμία εξάρτηση από OpenSSL
- ✅ Pure Common Lisp ASN.1/DER encoding
- ✅ X.509 v3 certificate generation
- ✅ DARPA-GRADE auditable
- ✅ **AUTO-GENERATED** on first run

---

## Βήμα 1: Build Docker Image

```powershell
# Από το directory: C:\Orchestrator\orchestrator-v1.2-COMPLETE\
docker build -t orchestrator:latest .
```

## Βήμα 2: Run Pipeline (ΣΩΣΤΟ - παράγει output!)

### Επιλογή A: Χρήση docker-compose (RECOMMENDED)

```powershell
docker-compose up
```

Αυτό θα:
- Χτίσει το image αν δεν υπάρχει
- Τρέξει το pipeline με όλα τα σωστά volumes
- Δημιουργήσει αρχεία στο `./output/` directory

### Επιλογή B: Χρήση docker run

```powershell
# Run the FULL PIPELINE (not just --help!)
docker run --rm `
  -v "${PWD}/output:/app/output" `
  -v "${PWD}/logs:/app/logs" `
  -v "${PWD}/input:/app/input" `
  -v "${PWD}/configs:/app/configs:ro" `
  orchestrator:latest `
  --run-pipeline
```

**ΣΗΜΑΝΤΙΚΟ:** Το `--run-pipeline` στο τέλος είναι ΚΡΙΣΙΜΟ! Χωρίς αυτό, τρέχει μόνο `--help`.

## Βήμα 3: Έλεγχος Output

Μετά το τρέξιμο, τα αρχεία θα είναι στο:
```
C:\Orchestrator\orchestrator-v1.2-COMPLETE\output\
```

### Epistemic Layer Output (Τι να περιμένεις)

Με την τρέχουσα **MANIFESTATION ISOLATION** αρχιτεκτονική, τα epistemic outputs είναι:

```
output/
├── releases/
│   └── release-YYYYMMDD-HHMMSS/
│       ├── meta-ontology.ttl           # Layer 1: Ontology definition
│       ├── lineage-graph.ttl           # Layer 3: Provenance graph
│       ├── negation-layer.ttl          # Layer 4: Non-equivalence assertions
│       ├── stability-policy.ttl        # Layer 6: URI stability policy
│       ├── manifest.ttl                # Layer 2: Release manifest (RDF)
│       ├── manifest.jsonld             # Layer 2: Release manifest (JSON-LD)
│       ├── temporal-proof/
│       │   ├── manifest-timestamp.tsr  # RFC 3161 timestamp response
│       │   ├── manifest-signature.jws  # JWS detached signature
│       │   └── ct-logs/                # Certificate Transparency proofs
│       │       └── google-xenon2024.sct
│       └── verify/
│           ├── public.jwk              # JWK public key for verification
│           └── merkle-inclusion-proofs/
│               └── *.blake3.proof
└── logs/
    └── epistemic-deploy.log
```

**ΤΙ ΔΕΝ ΘΑ ΔΕΙΣ (by design - MANIFESTATION ISOLATION):**
- ❌ ΚΑΝΕΝΑ per-article `.ttl` file
- ❌ ΚΑΝΕΝΑ per-article `.jsonld` file
- ❌ ΚΑΝΕΝΑ HTML/PDF file

Αυτά θα δημιουργηθούν από το **μελλοντικό** `orchestrator-manifestation` system.

## Διαγνωστικά Commands

### Έλεγχος αν το build ολοκληρώθηκε επιτυχώς
```powershell
docker images | Select-String orchestrator
```

Πρέπει να δεις:
```
orchestrator   latest   <image-id>   <timestamp>   <size>
```

### Έλεγχος output directory
```powershell
Get-ChildItem -Recurse output/
```

### Έλεγχος logs για errors
```powershell
Get-Content logs/epistemic-deploy.log -Tail 50
```

### Debug: Run με interactive shell
```powershell
docker run -it --rm `
  -v "${PWD}/output:/app/output" `
  -v "${PWD}/logs:/app/logs" `
  orchestrator:latest `
  /bin/bash
```

Μέσα στο container:
```bash
# Έλεγχος αν το executable υπάρχει
ls -lh /app/orchestrator.core

# Manual run με debug
/app/orchestrator.core --run-pipeline
```

## Crypto Operations (Production-Ready)

Για RFC 3161 timestamps με production TSA:
```powershell
docker run --rm `
  -v "${PWD}/output:/app/output" `
  -v "${PWD}/private.pem:/app/private.pem:ro" `
  -e PRIVATE_KEY_PATH=/app/private.pem `
  -e TSA_URL=https://freetsa.org/tsr `
  orchestrator:latest `
  --run-pipeline
```

## Troubleshooting

### Πρόβλημα: Output directory κενό

**Αιτία:** Τρέξατε με `--help` (default) αντί για `--run-pipeline`

**Λύση:** Προσθέστε `--run-pipeline` στο τέλος του docker run command

### Πρόβλημα: Permission denied σε Windows volume

**Λύση:**
```powershell
# Δώστε write permissions στα directories
icacls output /grant Everyone:F /T
icacls logs /grant Everyone:F /T
```

### Πρόβλημα: Build fails με "circular dependency"

**Λύση:** Αυτό έχει διορθωθεί στο branch `main`

Κάντε:
```bash
git pull origin main
```

## Επόμενα Βήματα (Implementation Roadmap)

1. ✅ **Epistemic Layer** - DONE (build + deploy)
2. ⏳ **Manifestation Layer** - PENDING
   - Per-article TTL/JSON-LD emission
   - HTML/PDF generation
   - Format-specific transformations
3. ⏳ **Archive Integration** - PENDING
   - IPFS pinning
   - Arweave upload
   - Blockchain anchoring

---

## 📜 ΔΕΣΜΕΥΤΙΚΗ ΑΡΧΙΤΕΚΤΟΝΙΚΗ

**BINDING COMMITMENT: Αξιοποίηση της Common Lisp στο ≥90% των δυνατοτήτων της**

Το σύστημα ORCHESTRATOR **ΕΓΓΥΑΤΑΙ** ότι θα αξιοποιεί την πλήρη δύναμη της Common Lisp:

| Lisp Feature | Χρήση | Status |
|--------------|-------|--------|
| **Homoiconicity** | Code-as-data, self-modifying | **✓ ACTIVE** |
| **Macros** | Metaprogramming, DSLs | **✓ ACTIVE** |
| **CLOS** | Object system, protocols | **✓ ACTIVE** |
| **Conditions/Restarts** | Error handling, recovery | **✓ ACTIVE** |
| **Multiple Values** | Efficient returns | **✓ ACTIVE** |
| **Generic Functions** | Polymorphism | **✓ ACTIVE** |
| **First-class Functions** | Closures, callbacks | **✓ ACTIVE** |
| **Symbol System** | Interning, packages | **✓ ACTIVE** |
| **Reader Macros** | Custom syntax | **✓ ACTIVE** |
| **MOP** | Meta-object protocol | **✓ ACTIVE** |
| **Compiler Macros** | Optimization | **✓ ACTIVE** |

**ΕΓΓΥΗΣΗ:** Καμία Python, κανένα wrapper, καμία εξάρτηση από external AI services.

**"η DARPA δεν δουλεύει με wrappers"**

---

**Author:** Spyridon Stavropoulos (Athens Bar Association)
**ORCID:** 0009-0005-2832-2153
**License:** MIT
**System Version:** 1.2.0
