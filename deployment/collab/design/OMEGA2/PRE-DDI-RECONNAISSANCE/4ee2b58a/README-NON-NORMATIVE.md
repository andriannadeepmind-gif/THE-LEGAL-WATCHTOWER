# PRE-DDI RECONNAISSANCE — NON-NORMATIVE ARCHIVAL PACKAGE

```
STATUS:                        EXTERNAL_INPUT
CLASSIFICATION:                NON_NORMATIVE / NON_AUTHORITATIVE
PINNED_COMMIT:                 4ee2b58a8df0941845ab786bd0ff859844b94dde
PINNED_TREE:                   ad71185a26b3beb39da6d50c09f567cff0475def
ACTIVE_BRANCH_MOVED_TO:        720452abe72cf986d5431d629b8d7385fd68acd7
VERIFIED_AGAINST_720452ab:     NO
DANGLING_EXTERNAL_PROVENANCE:  YES
DELTA_REVALIDATION_REQUIRED:   YES (after Review #6)
AUTHORIZES_DDI-1:              NO
BYTES:                         IMMUTABLE — original hashes preserved
```

---

## 1. What this package is

Five reconnaissance artifacts plus their hash manifest, produced by a read-only
survey of this repository at the pinned commit and archived here **verbatim**.

They are **external input** to a future decision. They are **not**:

- canonical model facts,
- qualification evidence,
- authorization to begin `DDI-1` or any deferred-data import,
- authorization to begin Option A / full build,
- a substitute for any gate, corpus run, kernel run or independent check.

## 2. Prohibition on consumption

No file in this directory may be consumed by the canonical model, by `ROOT.sexp`,
by any registry, by any generator, or by any gate or acceptance script — **not
before a delta revalidation performed after Review #6**.

The pinned commit `4ee2b58a…` is **not** the current tip of the branch this survey
read. The active branch subsequently moved to `720452ab…`. **Nothing in this
package has been verified against `720452ab…`.** Every count, table, identifier,
line reference and verdict here is asserted **only** against the pinned tree
`ad71185a…`. Any divergence introduced after the pin is unmeasured.

## 3. Contents and integrity

| file | sha256 | bytes |
|---|---|---|
| `PRE-DDI-INDEPENDENT-CENSUS.md` | `d3cbf43d862d572f4eb551af3611d6fe935f0f7071033768d3965adf47dd7d70` | 91 259 |
| `DDI-1-4-EXECUTION-MATRIX.sexp` | `88bcba9e090b9e5702f19356d7a50e4b3b73ebbfd76bdd139cfce4d1246fb869` | 1 115 148 |
| `DDI-DEPENDENCY-AND-ORDER.md` | `195ddc52bdaa1da4117dc18fa2738158273aa0b67a2df96c4b52eee0228902be` | 311 505 |
| `OPTION-A-ORIGINAL-20-GATE-SURVIVAL-MATRIX.md` | `9c3be959231565d89106e277a9cbdc07fe1deb18daddc2d87b303212471d0399` | 101 628 |
| `POST-DDI-FULL-BUILD-READINESS.md` | `1cba400035a42137a3383ea7a46e19dee7ed5061e5fb47458b5161a62659c598` | 540 824 |
| `SHA256SUMS.txt` | manifest of the five above | 496 |

Verification (from this directory):

```
sha256sum -c SHA256SUMS.txt      # must report 5/5 OK
```

The five artifacts and the manifest are archived **byte-identical** to the
externally produced originals. They are immutable: any edit invalidates the
manifest and destroys the package's self-verifying property.

## 4. Pre-archival scan — findings

A pre-commit scan of all six files was performed before archiving.

**Clean (zero occurrences):** model names, vendor names, model identifiers,
session identifiers, authorship trailers, credentials, API keys, private keys,
bearer tokens, e-mail addresses, external URLs, absolute temporary-directory
paths. The 108 occurrences of the string `claude` are, without exception, names
of objects that already exist in this repository — `CLAUDE.md`, the dialogue
files `0146/0153/0160/0161/0162/0163/0164-claude.md`, and branch refs.
The 19 `/tmp/…` occurrences are quoted lines of this repository's own gate
script, reproduced as source evidence.

**Finding K3 — methodological role vocabulary (532 lines, with K4).** The
artifacts use the terms `agent`, `skeptic`, `hunter` and `orchestrator` to name
the independent adversarial review roles under which the evidence was produced,
and record, as a production fact, that the survey was interrupted by resource
limits and resumed. Domain occurrences of `orchestrator.*`, `orchestrator*.asd`,
`orchestrator-cli`, `SEAT-AI-CORPUS-DUMP`, `AI-DIALOGUE.md` and `LLM` are model
vocabulary and were excluded from this finding.

**Finding K4 — dangling external provenance.** The artifacts cite working-set
locators — `WORK/…` (209), `W/…` (43), `RO/…` (4), `$RO` (1), `scratchpad` (3),
`deliverables/…` (7), `BRIEF.md` (1) — that referred to a **temporary working
set which was not archived**.

Consequences of K4, binding:

- These strings are **not repository paths**.
- They must **not** be used as executable dependencies.
- They must **not** be used as evidence locators.
- **No file or directory may be created anywhere in this repository in order to
  satisfy them.**
- They are retained solely as historical, unresolvable provenance.

## 5. Creator's disposition (binding, and strictly bounded)

The creator adjudicated K3 and K4 and directed archival **as-is**:

> Οι όροι `agent`, `skeptic`, `hunter` και `orchestrator` κρίνονται εδώ ως
> περιγραφές μεθοδολογικών ρόλων ελέγχου και όχι ως ταυτότητες
> AI/model/vendor/session. Το ίδιο το κανονιστικό πρωτόκολλο του repository
> χρησιμοποιεί όρους ανεξάρτητων agents/κριτών. Η φράση περί session-limit
> διατηρείται αποκλειστικά ως ιστορικό γεγονός παραγωγής του εξωτερικού
> evidence. Δεν αποτελεί model identity, commit attribution ή canonical fact.

This adjudication:

- does **not** permit model names or vendor names anywhere;
- does **not** permit authorship or session trailers anywhere;
- does **not** change the general rule for canonical, normative or production
  artifacts;
- applies **only** to the exact, already hash-pinned bytes of this
  `NON_NORMATIVE / EXTERNAL_INPUT` package.

**Why as-is:** preserving the bytes protects the integrity of the evidence. The
alternative — editing 532 lines of an evidence record — would have invalidated
the manifest, changed the identity of the package, and introduced a non-zero
risk of corrupting the very findings being archived. The 532 lines were
therefore **not** cleaned, replaced or transformed.

## 6. Standing constraints

- `PRE-DDI RECONNAISSANCE ARCHIVED AS IMMUTABLE NON-NORMATIVE INPUT.`
- Original hashes preserved; pinned to `4ee2b58a…` / `ad71185a…`.
- **Delta revalidation against the then-current tip is required after Review #6**
  before any statement in this package may be relied upon.
- **`DDI-1` is not authorized.** Option A is not authorized. No phase opens by
  itself; only the creator approves and merges phases.
