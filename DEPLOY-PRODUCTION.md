# PRODUCTION DEPLOYMENT - ΕΓΓΥΗΜΕΝΗ ΔΟΥΛΕΙΑ

## ✅ Τι Έχει Φτιαχτεί (3 Critical Fixes)

### 1. **ARITY MISMATCH FIX**
```
deploy-epistemic.lisp:149
❌ WAS: generate-stability-policy-ttl :timestamp timestamp  (2 args)
✅ NOW: generate-stability-policy-ttl                       (0 args)
```

### 2. **DOCKER-COMPOSE CMD OVERRIDE**
```yaml
# Προσθήκη:
command: ["--run-pipeline"]  # ← Τρέχει pipeline, όχι --help
```

### 3. **RESTART POLICY FIX**
```yaml
❌ WAS: restart: unless-stopped  # ← Έκανε infinite loop στο --help
✅ NOW: restart: "no"            # ← Τρέχει μια φορά και σταματάει
```

### 4. **DEPLOYMENT VOLUME MOUNT**
```yaml
# Προσθήκη:
- ./deployment:/app/deployment:ro  # ← Greek Constitution corpus data
```

---

## 🚀 ΕΝΤΟΛΕΣ ΠΑΡΑΓΩΓΗΣ (Copy-Paste)

### PowerShell (Windows):

```powershell
# 1. Pull όλες τις αλλαγές
git pull origin claude/fix-docker-dependency-5axFE

# 2. Clean rebuild (χωρίς cache)
docker-compose build --no-cache

# 3. Run pipeline (μια εντολή, τέλειο output)
docker-compose up

# 4. Έλεγχος output
Get-ChildItem -Recurse output/releases/
```

### Bash (Linux/macOS):

```bash
# 1. Pull όλες τις αλλαγές
git pull origin claude/fix-docker-dependency-5axFE

# 2. Clean rebuild
docker-compose build --no-cache

# 3. Run pipeline
docker-compose up

# 4. Έλεγχος output
find output/releases/ -type f
```

---

## 📂 Τι Θα Δείτε στο Output

```
output/
└── releases/
    └── 2025-12-21T21:XX:XX/
        ├── meta-ontology.ttl           # Layer 1: Epistemic system definition
        ├── lineage-graph.ttl           # Layer 3: PROV-O provenance
        ├── negation.ttl                # Layer 4: Defensive moat
        ├── stability-policy.ttl        # Layer 6: URI stability (ODRL)
        ├── stability-policy.md         # Layer 6: Human-readable
        ├── manifest.ttl                # Layer 2: DCAT release manifest
        ├── manifest.jsonld             # Layer 2: JSON-LD variant
        ├── shapes/
        │   ├── article-shape.ttl       # SHACL validation
        │   ├── manifest-shape.ttl
        │   └── lineage-shape.ttl
        ├── temporal-proof/
        │   ├── merkle-tree.json        # Blake3 Merkle root
        │   ├── timestamp.tsr           # RFC 3161 timestamp
        │   ├── signature.jws           # JWS detached signature
        │   └── inclusion-proofs/
        │       └── *.json
        └── verify/
            ├── public.jwk              # Public key for JWS verification
            ├── tsa-ca.pem              # TSA CA certificate
            ├── verify.sh               # Bash verification script
            ├── verify.ps1              # PowerShell verification
            ├── verify.lisp             # Lisp verification (deterministic)
            └── README-VERIFY.md        # Verification instructions
```

**ΣΗΜΑΝΤΙΚΟ (MANIFESTATION ISOLATION):**
- ❌ ΚΑΝΕΝΑ per-article `.ttl` ή `.jsonld` file
- ❌ ΚΑΝΕΝΑ HTML/PDF (μελλοντικό `orchestrator-manifestation` system)
- ✅ ΜΟΝΟ dataset-level epistemic metadata

---

## 🔍 Διαγνωστικά (αν κάτι πάει στραβά)

### Έλεγχος Docker logs σε real-time:
```powershell
docker-compose up --abort-on-container-exit
```

### Έλεγχος logs αφού τρέξει:
```powershell
Get-Content logs/epistemic-deploy.log -Tail 100
```

### Debug: Interactive shell μέσα στο container:
```powershell
docker run -it --rm `
  -v "${PWD}/output:/app/output" `
  -v "${PWD}/logs:/app/logs" `
  -v "${PWD}/configs:/app/configs:ro" `
  -v "${PWD}/deployment:/app/deployment:ro" `
  orchestrator:latest `
  /bin/bash

# Μέσα στο container:
/app/orchestrator.core --run-pipeline
```

---

## ✅ Definition of Success

Το pipeline ολοκληρώνεται με επιτυχία όταν δείτε:

```
=== EPISTEMIC DEPLOYMENT COMPLETE ===

Release directory: /app/output/releases/2025-12-21T21:XX:XX/
Merkle root: blake3:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
System commit hash: blake3:YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
Manifest path: /app/output/releases/2025-12-21T21:XX:XX/manifest.ttl
Latest symlink: /app/output/releases/latest → 2025-12-21T21:XX:XX
```

Και το container βγαίνει με **exit code 0**.

---

## 🎯 Proof Gates (όλα REQUIRED)

1. ✅ **Merkle Tree** - Blake3 commitment σε όλα τα artifacts
2. ✅ **RFC 3161 Timestamp** - Temporal priority από FreeTSA
3. ⚠️ **Certificate Transparency** - CONDITIONAL (αν έχετε `RELEASE_CERT_PATH`)
4. ✅ **JWS Signature** - Digital signature με RSA-2048
5. ✅ **SHACL Validation** - Structural compliance

**Αν κάποιο proof gate FAIL:**
- Pipeline θα κάνει HARD FAIL με `orchestrator.spec:validation-error`
- ❌ ΔΕΝ θα δημιουργηθεί release directory
- ❌ ΔΕΝ θα κάνει atomic publish

---

## 📊 Αναμενόμενο Output Size

- **Meta-ontology**: ~10-15 KB (OWL 2 DL definitions)
- **Lineage graph**: ~50-100 KB (120 άρθρα × provenance triples)
- **Negation layer**: ~5-10 KB (disjointness assertions)
- **Stability policy**: ~3-5 KB (TTL + MD)
- **Manifest**: ~30-50 KB (DCAT + VoID + temporal proofs)
- **SHACL shapes**: ~15-20 KB (3 files)
- **Temporal proofs**: ~5-10 KB (Merkle + RFC 3161 + JWS)
- **Verification kit**: ~15-20 KB (scripts + CA certs)

**Συνολικό Release Size**: ~150-250 KB (dataset-level metadata μόνο)

---

## 🔐 Production Crypto (AUTO-GENERATED)

Τα RSA keys και X.509 certificate **auto-generate** στο πρώτο run:

```powershell
# Just run - keys auto-generated by Pure Lisp (Ironclad)
docker compose up
```

Αυτόματα δημιουργούνται στο `keys/`:
- `private.pem` - RSA 4096-bit private key
- `public.pem` - RSA public key
- `certificate.pem` - Self-signed X.509 (10 years)

**100% Pure Common Lisp** - No OpenSSL required!

---

## 📞 Support

**Αν το pipeline fails:**
1. Ελέγξτε logs: `Get-Content logs/epistemic-deploy.log`
2. Ελέγξτε Docker logs: `docker logs orchestrator-main`
3. Ελέγξτε exit code: `docker inspect orchestrator-main --format='{{.State.ExitCode}}'`

**Exit Codes:**
- `0` - Success
- `1` - Validation error (SHACL/proof gate failed)
- `2` - Fatal error (missing dependencies, IO error)
- `125-127` - Container/artifact errors

---

**System Version**: 1.2.0
**Branch**: `claude/fix-docker-dependency-5axFE`
**Author**: Spyridon Stavropoulos
**ORCID**: 0009-0005-2832-2153
**License**: MIT
