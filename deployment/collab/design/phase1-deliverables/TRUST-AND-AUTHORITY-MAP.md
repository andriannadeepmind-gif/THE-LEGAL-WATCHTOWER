# TRUST-AND-AUTHORITY-MAP — THE LEGAL WATCHTOWER at `e621dbe1`

| | |
|---|---|
| **Source commit** | `e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03` |
| **Source tree** | `23b7a6f4450f50d151d38e13020bee9872e73bcd` |
| **Historical baseline** | `57c0cd868c80f87df8e298c9aa75b8ccf2503391` |
| **Corroboration commit** | `2b910271f11fc462eee1378fb9a77623c791fcbf` |
| **Generated** | 2026-08-26T00:36:43Z |
| **Coverage** | 35,640 tracked paths enumerated and classified; 100/100 delta paths read |
| **Evidence classes** | mechanically-proved 73 · empirically-reproduced 2 · source-grounded 23 · unresolved 6 |
| **Unresolved items** | 6 (§10) |
| **Self SHA-256** | `5880ea6b98a1099cf4765c09bc20010b46fd368bd118f98eb4df62c2f58e81a5` |
| **Self-hash convention** | SHA-256 of this file with the 64 hex characters on the line above replaced by 64 zeros. |

---

## 1. The central fact

**There is no authority in this system at this commit.**

Not "weak authority", not "authority pending review". The old authority was removed structurally,
and the new authority was specified and not built. Between the producer and the published corpus
there is now a gap that no code spans.

```
  PRODUCER (untrusted by design)          AUTHORITY (does not exist)
  ────────────────────────────            ─────────────────────────
  the whole Common Lisp system            admission kernel K
  uid 11002                               :specification-only
  writes candidates/ only                 no implementation, no language
       │                                        │
       │  candidate bundle                      │  transition certificate
       ▼                                        ▼
  ╔════════════════════╗                  ╔════════════════════╗
  ║  candidates/       ║ ──── capture ──▶ ║  authority store   ║
  ║  producer-owned    ║   quarantine     ║  :absent-by-design ║
  ║  MUTABLE           ║   + recompute    ║  writer :disabled  ║
  ╚════════════════════╝                  ╚════════════════════╝
                                                 │
                                          ✖ nothing runs here
                                                 │
                                          ┌──────▼───────┐
                                          │ latest, site │  ← last written by the old authority
                                          └──────────────┘
```

`[EV-K-001, EV-K-002, EV-K-003]`

---

## 2. Trust boundaries as they now stand

### 2.1 Producer / authority — an OS boundary, not a code boundary

The separation is deliberately not a source-code gate. Three system identities with pinned UIDs
are created by `authority-v2/capability/identities.sh`:

| Identity | UID | Authority store | Candidates |
|---|---:|---|---|
| `lawmax-authority` | 11001 | `rwx` (sole writer) | `r-x` via readers group |
| `lawmax-producer` | 11002 | **none** (0750, not in either group) | `rwx` |
| `lawmax-reader` | 11003 | `r-x` (serving) | `r-x` |

The store is `lawmax-authority:lawmax-readers 0750`; the producer belongs to neither, so it has
neither read nor write. The same UIDs appear verbatim in `docker-compose.yml`, so host and container
identities coincide.

The boundary proof is unusually careful. `producer-os-boundary-test.sh` first *removes* every
permission-based explanation — the producer is made the owner of `releases/` at mode 0700, and a
positive control confirms it can write there without a mount — then applies a read-only bind mount
in a private namespace and requires the write to fail with **`EROFS(30)`, not `EACCES(13)`**,
checking the errno numerically. The mount's read-only state is confirmed from
`/proc/self/mountinfo`, not from `mount(8)`'s exit code. Without root, `setpriv` or `unshare`,
it exits 2 BLOCKED and never reports a pass.

That is the right shape for this claim. It has not been executed in any environment this study can
see `[EV-U-001]`.

### 2.2 Producer / candidate store — no boundary, and the system says so

`candidates/` is producer-owned and mutable. The delta retracts the word "immutable" in three
separate places, in code and in specification, on the explicit grounds that the owner of a directory
can always change it, including while the authority is reading `[EV-T-009]`.

The honest consequence is drawn: the content-addressed name does not make bytes immutable; it makes
disagreement detectable *after* measurement. The only immutable thing is the captured snapshot.

### 2.3 Candidate / authority — the capture boundary

This is the most developed piece of engineering in the delta. `CAPTURE-PROTOCOL.sexp` states the
threat model as *the producer is an active adversary* and prescribes five ordered steps: refuse
hostile entries; open only beneath the root with `O_NOFOLLOW` on every component; copy to a private
quarantine before judging anything; recompute both roots inside the quarantine from the copy; run
the kernel only on the snapshot.

Two properties make it more than a checklist:

- **Two strictly separate phases.** Phase A copies and computes no hash at all. Phase B measures
  exclusively from the quarantine. The two are cross-checked on `(path, size)`, so "hash computed
  from hostile bytes" is not guarded against — it is not expressible.
- **Anchoring by descriptor, not pathname.** A trusted launcher walks every component from `/` with
  `openat2` and `RESOLVE_BENEATH|RESOLVE_NO_SYMLINKS`, verifies mount id, owner and mode, and hands
  the capture two directory descriptors. The capture never sees a pathname. Below the anchor,
  `RESOLVE_NO_XDEV` is added, so the candidate tree may not span filesystems.

The capability objects are sealed: construction requires a private mint token, post-seal assignment
raises, and `Anchor.reverify()` re-checks dev/ino/mount-id/owner/mode inside the production path,
not merely as an available method.

**Limits the protocol states about itself**, and they are correct: it does not claim the candidate
existed in that state at any single instant — a whole-tree atomic snapshot is not available without
filesystem support. What it claims is that the quarantine holds exactly those bytes, that the two
roots bind them, and that the kernel judges only those. Non-atomicity can therefore cause refusal,
never contamination `[EV-V-005, EV-V-006]`.

It requires Linux ≥ 5.6 and refuses rather than degrading, so on the development platform the entire
boundary is untestable `[EV-V-005]`.

### 2.4 Authority / reader — a boundary with nothing behind it

`corpus-service` runs as 11003, read-only everywhere except two named evidence sub-volumes, sees no
private key, mounts no authority store. It serves `output/`, which was written by the authority that
no longer exists.

---

## 3. Where authority actually resides

| Authority | Holder before the delta | Holder now |
|---|---|---|
| Cut a release commitment | `run-cut-release` (Lisp) | `run-cut-release` — but it emits a *candidate* |
| Attest with RFC-3161 | `run-attest-release` (Lisp) | **deleted**; a conjunct of the unimplemented kernel |
| Append to the transparency log | `tlog-append-root!` (Lisp) | **fails closed**; belongs to the unimplemented kernel |
| Decide a release is attested | `release-attested-p` (Lisp) | **fails closed** |
| Promote `latest` | `promote-latest!` (Lisp) | **fails closed** |
| Hold the private key | every producer container (`:ro`) | `authority-signer` alone — which refuses to run |
| Write the authority store | n/a | `authority-signer` alone — which refuses to run |
| Verify a candidate | n/a | admission kernel — **does not exist** |

`[EV-T-002, EV-T-003, EV-T-005, EV-K-003]`

---

## 4. The disarmament, and how solid it is

The retirement of `--attest-release` is worth setting out, because it is the model the rest of the
system should follow.

1. The function body was **deleted**, not guarded. A body that exists but is unreachable is a guard
   around the wrong shape: one future edit moves the `(error ...)` and the path is alive again.
2. The historical text is frozen in `authority-v2/fixtures/legacy-authority/`, which no `.asd`
   declares.
3. The name is entered in a retired-seat registry with reason, retirement point and replacement,
   and answers honestly instead of reporting "unknown command".
4. `register-command` **raises** if a retired name is re-registered, and `retire-command!` raises if
   a name is simultaneously active. Accidental resurrection is refused, not merely discouraged.
5. A single `resolve-command` seat decides active / retired / unknown, and both the dispatcher and
   the proofs go through it, so no second resolution path can diverge.
6. The capability contract was rewritten: outputs and side effects now name `candidates/` and no
   longer name `releases/`. The disarm suite asserts this on the live contract object, not on prose.

`[EV-T-005, EV-T-006, EV-T-007]`

Six independent closures for one seat. This is the correct standard, and the rest of the system does
not meet it.

---

## 5. Residual write authority

The demotion did not eliminate direct writes; it moved two of them and added one.

At `e621dbe1`, 40 direct `with-open-file :direction :output` sites remain across 19 first-party
files, against an architecture that declares one write seat `[EV-P-002]`. Sixteen files call
`ironclad:digest-sequence` directly, against an architecture that declares one hash seat
`[EV-P-004]`. Those are structural bypasses of the system's own stated discipline, and the delta
addressed them only where it happened to touch them.

---

## 6. Trust anchors that do not anchor

`SEMANTIC-CONTRACT.md` states a GUARANTEE of blockchain-anchored timestamping and tamper detection.
The code behind it discards the response body — `(declare (ignore response))` — and returns
`(= status 200)` for Arweave and IPFS; the Ethereum branch checks a receipt status field. No branch
checks that the anchored bytes hash to the claimed value `[EV-C-012]`.

An HTTP 200 from a gateway is evidence that a gateway answered. It is not evidence that anything
was anchored, and it is certainly not evidence that tampering would be detected.

---

## 7. The genesis act

The new epoch opens with a sequence-0 `LEGACY-ADOPTION-CERTIFICATE` whose mode is
**evidence-only**: the old history is *bound* so that retroactive rewriting becomes detectable, but
nothing is *inherited* — no authority, no attestation, no conformance. The first release with real
authority is sequence 1, and it must pass the whole kernel.

Verified here, independently of the tooling:

- The certificate's `genesis_policy_hash` equals the actual SHA-256 of the genesis policy file
  `[EV-V-010]`.
- The snapshot's `file_count` of 29,911 equals the exact number of tracked paths under the three
  declared legacy roots: 29,204 + 706 + 1 `[EV-V-009]`.
- The release inventory of 24 (18 content-addressed + 6 timestamp-named) plus 7 historical-run
  artefacts is reproducible from the tree `[EV-V-008]`.

Three things this act does not do:

- It is **unsigned**, and its canonical encoding is `PENDING-EVERPARSE`. Production signature and
  TSA are fail-closed pending an owner-root ceremony that is a declared stop point `[EV-V-011]`.
- It binds `source_commit b26abbd68` — eight commits behind the tree it ships in — and nothing in
  the repository ever reads that field back `[EV-N-016]`. The archive root remains materially valid
  only because no legacy path changed across the delta `[EV-D-004]`.
- Its conformance result, **0 of 24**, is partly analytic: conjunct C5 is a hardcoded `False`
  `[EV-N-015]`. The substantive conclusion survives, because the other five conjuncts are genuine
  filesystem checks and all five fail on all 24 independently `[EV-V-007]`.

The published corpus therefore carries no authority under the epoch that governs it, and cannot
acquire any until a kernel exists.

---

## 8. Roles, keys, ceremony

Five TUF-class roles are modelled: `root` (offline, 1-of-1, self-signed rotation chain, explicit
revocation list), `release`, `targets`, `snapshot`, `timestamp`. Five mandatory protections are
specified: rollback, freeze, key rotation, key revocation, profile lineage `[EV-V-014]`.

Two honest limits are stated in the model itself. TUF conformance is **not claimed** — the normative
text could not be retrieved and implementation from memory is forbidden. And the threshold is 1-of-1
today, with the model noting that one person holding five keys is not a quorum but theatre.

The ceremony tooling is complete and genuinely rehearsable: genesis, rotation, revocation and
recovery all execute with test keys, including a negative control proving the new root does not
self-validate without the chain. Every production command routes to a stop point that exits 3 and
names the out-of-band obligations: air-gapped machine, HSM or offline media with a succession plan,
recorded transcript with witnesses, out-of-band publication on two independent channels
`[EV-V-015]`.

The test private key is deliberately **not** committed. The consequence is stated as a feature: the
fixture is verifiable forever and re-signable never `[EV-N-016 context]`.

---

## 9. Witnesses and split view

The witness layer exists as policy only. Quorum requires three signatures from three
independently-operated witnesses, with independence defined by distinct legal operator, distinct
network infrastructure, and no shared administrative authority with the authority itself. Witnesses
sharing any criterion count as one.

Local fake witnesses carry `:counts-toward-quorum nil` structurally, so they can exercise the policy
without ever satisfying it. `external_quorum_status` is `disabled` and
`split-view-resistance-claim` is `nil`: with no independent witness, the gate is inactive rather
than "0-of-3 satisfied" `[EV-V-013]`.

The C2SP wire format is `blocked-spec-input` — the normative texts could not be retrieved, and the
policy is written to be format-agnostic so that a real serialisation can slot beneath it unchanged.

Anti-freeze is specified: a checkpoint older than 86,400 seconds is rejected however valid its
signature, because validity is not freshness.

---

## 10. Unresolved

| | |
|---|---|
| `EV-U-001` | Whether any recorded proof execution happened as recorded. No receipts, logs or transcripts are committed; this phase executed nothing. |
| `EV-U-002` | Whether `docker build` succeeds today. The declared `--network=none` path provably cannot `[EV-C-008]`; the networked path was not attempted. |
| `EV-U-003` | Whether the capture implementation withstands its adversarial suite. It requires Linux with `openat2` and was not run. |
| `EV-U-004` | Whether the 29,204 published artefacts are correct as Greek law. Outside the reach of any evidence in this repository, and named out of scope by the admission model itself. |
| `EV-U-005` | The baseline's eleven declared static-analysis limitations, inherited unrelieved. |
| `EV-U-006` | The number of os-exec seats. The Phase-1A lane counted seven; `dialogue/0094-claude.md:82` declares nineteen. Not adjudicated here. |

---

## 11. The residual TCB, as the system declares it

Eleven items, declared rather than proved: the F* kernel, the Coq kernel, the OCaml runtime of both
provers, CompCert if enabled, the assembler and linker, libc, the Linux kernel enforcing the
capability separation by DAC, CPU and microcode, SHA-256 collision resistance, Ed25519, and the
correspondence between the CDDL schema and human intent `[EV-V-016]`.

Two of these deserve emphasis. The capability separation rests on kernel DAC alone: there is no
MAC profile, no SELinux or AppArmor policy, and the boundary proof is executional rather than
formal. And the last item is not cryptographic at all — it is the admission that no proof reaches
the question of whether the specification says the right thing.

---

## 12. What the design phase must dominate

1. **Supply an authority path.** A specification no code realises does not discharge the obligation
   the disarmament created.
2. **Make recorded results bind to the code they describe.** Three separate contradictions in this
   phase came from records that no mechanism ties to a tree `[EV-N-004, EV-N-019, EV-N-018]`.
3. **Make the checkers unable to choose their own scope.** Every false green found here came from a
   verifier looking exactly where it expected to succeed — the topology proof at one service, the
   census at one glob, the extension allowlist at three suffixes. The delta fixed two instances of
   this and reintroduced a third.
4. **Close the capability register over the authority architecture.** A gate plenary that cannot
   fail because of an authority defect is not a plenary.
5. **Decide what the 24 published releases are** — evidence, or law. They currently satisfy nothing
   and are served as though they satisfied everything.
6. **Obtain one independent execution.** Every number in the completion matrix is a local,
   unwitnessed number, and at least one of them is arithmetically impossible.
