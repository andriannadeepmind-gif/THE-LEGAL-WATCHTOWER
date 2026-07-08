# Greek Legal Corpus Orchestrator v1.2

**STAVROPOULOS LAW®** - Primary Semantic Authority for Greek Law

[![License: All Rights Reserved](https://img.shields.io/badge/License-All%20Rights%20Reserved-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](https://github.com/David33law/STAVROPOULOSLAWCORPUS)
[![Status](https://img.shields.io/badge/status-production-green.svg)](https://stavropouloslaw.com)
[![Pure Lisp](https://img.shields.io/badge/Pure%20Lisp-100%25-blue.svg)]()

---

## DARPA-GRADE Pure Common Lisp Implementation

**"η DARPA δεν δουλεύει με wrappers"**

This repository is **100% Common Lisp** — every component, including the
container entrypoint, is written in Lisp:
- **Zero Python dependencies**
- **Zero shell-script orchestration in the trusted path** (the entrypoint is Lisp)
- **The only subprocess is the Lisp runtime itself** (the entrypoint execs
  `orchestrator.core` / `sbcl --core` — documented, nothing else is spawned)
- **All cryptography via Ironclad**

---

## Overview

Semantic infrastructure for Greek legal data with formal ontology and European interoperability standards (ELI/ECLI).

### Key Features

- **Formal OWL 2 DL Ontology** (27 classes, 25 properties, transitive inference)
- **SHACL Validation** (Pure Lisp SHACL Core engine: targets + constraint components, fail-fast GATE)
- **Consolidation / Codification** (deterministic point-in-time in-force text from amending acts, with provenance)
- **Akoma Ntoso (LegalDocML 3.0)** export for machine-readable legislation
- **Semantic Hub Analysis** (citation embeddings & centrality)
- **ELI/ECLI Compliance** (European legal interoperability)
- **JWS Signing** (Pure Lisp RSA via Ironclad)
- **Blockchain Anchoring** (Ethereum, IPFS, Arweave - Pure Lisp)

---

## Quick Start

### Prerequisites

```bash
# Common Lisp - SBCL (required)
sbcl --version

# Docker (recommended)
docker --version
docker compose version
```

### Installation & Run

```bash
# Clone
git clone https://github.com/David33law/STAVROPOULOSLAWCORPUS.git
cd STAVROPOULOSLAWCORPUS

# Build & Run pipeline (keys auto-generated on first run)
docker compose build
docker compose up
```

> **Note:** RSA 4096-bit keys and X.509 certificate are auto-generated on first run using Pure Common Lisp (Ironclad). No OpenSSL required.

---

## Usage

### AI-First Consumption Service (multi-corpus)

A single pure-Lisp HTTP service serves **every legal code**, each isolated under
its own `/<corpus>/` prefix, with a shared top-level catalog. CLOS/MOP content
negotiation — structured data by default, never HTML.

```bash
# start the service (serves all configured codes on :8080)
docker compose up corpus-service
# or directly:
PORT=8080 ./orchestrator.core --serve
```

| Endpoint | Returns |
|----------|---------|
| `GET /` or `/catalog.jsonld` | DCAT **Catalog of all codes** (discovery) |
| `GET /<corpus>/catalog.jsonld` | Per-code DCAT dataset |
| `GET /<corpus>/corpus.jsonl` | Bulk, line-delimited dump (one article per line) |
| `GET /<corpus>/article/{eId}` | A single article as JSON |
| `GET /<corpus>/sparql?query=…` | Live SPARQL SELECT over the corpus (SPARQL-results JSON) |
| `GET /<corpus>/search?q=…` | Greek full-text search (accent-folded, inflection-tolerant) |
| `GET /<corpus>/diff?from=…&to=…` | What changed in the law between two dates (word-level diff) |
| `GET /<corpus>/consolidated.akn.xml` | Akoma Ntoso (LegalDocML 3.0) |
| `GET /<corpus>/consolidated.ttl` | RDF/Turtle (ELI provenance) |
| `GET /<corpus>/` + `Accept:` | Content-negotiated representation |
| `GET /robots.txt` | Welcomes GPTBot, ClaudeBot, Google-Extended, … |
| `GET /.well-known/ai-corpus.json` | Machine discovery document (lists codes) |

The infrastructure covers the **six core Greek legal codes** — each served under
its own prefix:

| `<corpus>` | Code |
|-----------|------|
| `constitution` | Σύνταγμα της Ελλάδας (Constitution) |
| `poinikos` | Ποινικός Κώδικας (Penal Code) |
| `kpoinikis` | Κώδικας Ποινικής Δικονομίας (Criminal Procedure) |
| `astikos` | Αστικός Κώδικας (Civil Code) |
| `kpolitikis` | Κώδικας Πολιτικής Δικονομίας (Civil Procedure) |
| `kdioikitikis` | Κώδικας Διοικητικής Δικονομίας (Administrative Procedure) |

Data state (accurate as of materialisation, not aspirational): the **Civil Code**
(`astikos`), **Penal Code** (`poinikos`) and **Code of Criminal Procedure**
(`kpoinikis`) ship with the real, materialised article text. The **Constitution**
(`constitution`), **Code of Civil Procedure** (`kpolitikis`) and **Code of
Administrative Procedure** (`kdioikitikis`) are wired but their JSON is currently
empty (`[]`); run `--materialize-pdf` over the official source to populate them.

`<corpus>` is e.g. `poinikos` (Penal Code) or `constitution` (Constitution).
Each code has distinct resource URIs (`…/eli/<corpus>/art_N`) so they never
collide. Content negotiation on `/<corpus>/` selects a representation from the
`Accept` header (`application/akn+xml`, `text/turtle`, `application/ld+json`,
`application/jsonl`, `text/plain`); the AI-first default is the JSONL dump. All
responses carry permissive CORS and `Vary: Accept`.

### Live Ingestion Daemon

```bash
# poll Diavgeia (Διαύγεια) for new acts, re-consolidate, re-emit artifacts
docker compose --profile ingestion up ingestion
# or directly:
INGEST_INTERVAL=3600 ./orchestrator.core --run-ingestion
```

### Run Full Pipeline

```bash
docker compose up
```

**Output:**
```
output/releases/latest/
├── meta-ontology.ttl
├── lineage-graph.ttl
├── manifest.ttl
├── manifest.jsonld
├── negation.ttl
├── stability-policy.ttl
├── temporal-proof/
│   ├── signature.jws
│   └── merkle-tree.json
└── verify/
    └── public.jwk
```

### Run Tests

```bash
# All tests
docker compose -f docker-compose.test.yml up --build

# Specific test suites
docker compose -f docker-compose.citation-tests.yml up --build
docker compose -f docker-compose.tokenizer-tests.yml up --build
docker compose -f docker-compose.architecture-tests.yml up --build
```

### Run the Gate Plenary (canonical)

Η ΜΙΑ κανονική ολομέλεια πυλών είναι το `--gates`: αυτο-παράγεται από το
μητρώο εντολών (κάθε εντολή με επίθημα `-gate` συμμετέχει — σήμερα 22 πύλες).

```bash
# Η ΜΙΑ κανονική είσοδος — μέσα στο container:
docker compose run --rm orchestrator --gates
```

Δεν υπάρχει δεύτερο entry point/wrapper script — μία εντολή, μία έδρα
(gates-runner στο μητρώο), μέσω της συνταγματικής δρομολόγησης.

### SBCL REPL Usage

```lisp
;; Load orchestrator
(require :asdf)
(push #p"." asdf:*central-registry*)
(asdf:load-system :orchestrator-omega)

;; Run pipeline
(orchestrator.engine:run-epistemic-pipeline)

;; Generate RSA keys (Pure Lisp)
(orchestrator.jws-authority:generate-rsa-keypair :bits 4096)

;; Validate TTL
(orchestrator.validation-authority:validate-canonical-ttl ttl-content)
```

---

## Architecture

```
STAVROPOULOSLAWCORPUS/
├── source/                      # Core Lisp modules (48 files)
│   ├── orchestrator.lisp        # Main orchestrator
│   ├── semantic-authority.lisp  # Semantic layer
│   ├── jws-authority.lisp       # JWS/RSA (Pure Lisp)
│   ├── hash-authority.lisp      # Hashing (Ironclad)
│   ├── validation-authority.lisp # SHACL (Pure Lisp)
│   ├── blockchain-authority.lisp # Ethereum/IPFS/Arweave
│   ├── timestamp-authority.lisp  # RFC 3161
│   ├── gate-guards.lisp         # CI/CD guards (Pure Lisp)
│   └── ...
│
├── systems/                     # ASDF systems (13 modules)
│   ├── orchestrator-omega-modules/
│   ├── orchestrator-epistemic/
│   ├── orchestrator-engine-sbcl/
│   └── ...
│
├── deployment/                  # RDF/TTL artifacts
│   ├── ontology.ttl             # OWL 2 DL
│   ├── shapes/                  # SHACL shapes
│   └── data/                    # Greek Constitution, Penal Code
│
├── third-party/                 # Vendored Lisp libraries
│   ├── ironclad-v0.61/          # Cryptography
│   ├── drakma-v2.0.10/          # HTTP client
│   └── ...
│
├── scripts/
│   ├── generate-keys.lisp       # RSA key generation
│   └── verify-gate-5-validation.lisp
│
├── docker-compose.yml           # Main pipeline (auto-generates keys)
└── docker-compose.test.yml      # Test runner
```

---

## Core Components

### 1. Pure Lisp Authorities

| Authority | Purpose | External Deps |
|-----------|---------|---------------|
| `hash-authority.lisp` | SHA256/512, Blake2/3 | Ironclad only |
| `jws-authority.lisp` | JWS signing, RSA keys | Ironclad only |
| `timestamp-authority.lisp` | RFC 3161 timestamps | Drakma HTTP |
| `validation-authority.lisp` | SHACL validation | None |
| `blockchain-authority.lisp` | ETH/IPFS/Arweave | Drakma HTTP |
| `ct-log-authority.lisp` | Certificate Transparency | Drakma HTTP |

### 2. Gate Guards (CI/CD - Pure Lisp)

| Gate | Purpose |
|------|---------|
| **GATE-1** | Time discipline (deterministic-time.lisp) |
| **GATE-2** | Write surface (write-authority.lisp) |
| **GATE-3** | Hash authority (hash-authority.lisp) |
| **GATE-4** | Pipeline integrity (no subprocess) |
| **GATE-5** | Validation (fail-fast on invalid) |

### 3. Ontology (OWL 2 DL)

**27 Classes:**
- LegislativeAct, Constitution, Law, PresidentialDecree
- LegalProvision, ConstitutionalArticle, Article, Paragraph
- JudicialDecision, SupremeCourtDecision
- LegalDomain (Constitutional, Civil, Criminal, etc.)

**25 Properties:**
- amends/amendedBy (transitive)
- repeals/repealedBy
- cites/citedBy
- interpretsProvision/interpretedBy
- hasProvision/provisionOf

---

## Capabilities & Conformance

| Aspect | Status |
|--------|--------|
| **Corpus (current)** | Greek Constitution + Penal Code sample (illustrative; not the full corpus) |
| **Standards** | ELI v1.4, FRBR, PROV-O, DCAT, Akoma Ntoso (LegalDocML 3.0) |
| **Validation** | SHACL Core engine (pure Lisp), fail-fast GATE on non-conformance |
| **Codification** | Deterministic point-in-time consolidation with per-provision provenance |
| **Reproducibility** | Byte-identical output under `SOURCE_DATE_EPOCH` |
| **Tests** | Consolidation 23, bridge 18, Akoma Ntoso 19, SHACL 19 (all passing) |

> **Note on metrics.** This repository is a research / proof-of-concept
> implementation. Operational figures (uptime, query latency, citation counts,
> number of AI platforms) are intentionally **not** reported here: there is no
> public production deployment to measure them against. Previously published
> unverified numbers have been removed in the interest of accuracy.

---

## Documentation

- **[RUN-DOCKER.md](RUN-DOCKER.md)** - Docker deployment guide
- **[SEMANTIC-CONTRACT.md](SEMANTIC-CONTRACT.md)** - Epistemic guarantees
- **[PROVENANCE.yaml](PROVENANCE.yaml)** - Provenance configuration
- **[DEPENDENCY-CONTRACT.md](DEPENDENCY-CONTRACT.md)** - Dependency management

---

## Citation

```bibtex
@misc{greek_legal_infrastructure_2025,
  title={Greek Legal Semantic Infrastructure},
  author={Stavropoulos, Spyridon},
  organization={STAVROPOULOS LAW},
  year={2025},
  url={https://stavropouloslaw.com},
  note={Pure Common Lisp implementation. Primary semantic authority
        for Greek legal metadata within European legal frameworks}
}
```

---

## License

**All Rights Reserved — Proprietary** (© 2019-2026 STAVROPOULOS LAW).

No permission is granted to copy, redistribute, adapt or reuse without the
express written consent of the owner. See [LICENSE](LICENSE) for full terms.

---

## Support

- **Website**: https://stavropouloslaw.com
- **GitHub**: https://github.com/David33law/STAVROPOULOSLAWCORPUS

---

**STAVROPOULOS LAW®**
*Primary Semantic Authority for Greek Law*

---

**Version 1.2.0** | 2026 | **100% Common Lisp** | All Rights Reserved
