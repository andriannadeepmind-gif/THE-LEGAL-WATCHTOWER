# PHASE-2 COMMON LISP NATIVE DESIGN

Phase: 2 — BLIND FRONTIER ARCHITECTURE
Date: 2026-08-26
Depends on: PHASE-2-FRONTIER-ARCHITECTURE.md,
PHASE-2-AUTHORITY-AND-STATE-MODEL.md

This document states where Common Lisp semantics are **materially load-bearing**
for the Watchtower, where they are merely convenient, and — §13 — where they are
**not claimed at all**. The creator directive forbids cosmetic use and forbids
manual imitation of CLOS, conditions and the MOP. It also forbids transliterating
a Python/Java/JavaScript design into Lisp. §13 exists so that the claim can be
attacked precisely.

The single strongest claim is §1 and it is not about elegance.

---

## 1. THE DECISIVE REASON: NO EXTRACTION STEP AND NO RE-IMPLEMENTATION STEP

ACL2 is an interactive theorem prover whose logic is a subset of ANSI Common Lisp,
and it is an integrated programming and proof environment that has been in
sustained industrial use since the mid-1990s at AMD, Centaur, IBM, Intel, Kestrel,
Motorola/Freescale, Oracle and Rockwell Collins [RL-014].

Therefore the derivation kernel `K_v` — the pure, total function carrying all of
the Watchtower's legal and epistemic semantics — can be:

- **written** as ordinary applicative Common Lisp,
- **admitted and proved** in ACL2,
- **compiled and executed** on the same host,

with **no extraction step, no re-implementation and no FFI**.

### 1.0 What is and is not claimed about the gap

*(Corrected in the third audit round, finding HF-025. The first two versions
asserted claim **WC-1** (see PHASE-2-REPORT.md §4A). It is withdrawn: it was the
single most load-bearing overstatement in the package.)*

The separation is **narrowed and localised**, not removed. Precisely:

| | Status |
|---|---|
| Translation seam (verify in language X, run language Y) | **removed** — there is no translation step |
| Re-implementation seam (verify a model, hand-write the code) | **removed** |
| **Logic-to-execution seam** | **narrowed, not closed** — see below |

Three residual seams, each named rather than waved past:

1. **Guard verification.** ACL2's logical semantics and the host's execution
   semantics coincide for a guard-verified function *on guard-satisfying inputs*.
   Off the guard, the logic still assigns a value but raw execution need not agree.
   The kernel is therefore required to be **guard-verified in full**, and every
   entry point re-checks its guard at the boundary; a guard violation is a
   condition, not undefined behaviour.
2. **ACL2-specific surface syntax.** `declare (xargs ...)`, `mbe`, `defthm` and
   friends are ACL2 forms, not ANSI CL forms. The kernel is written in the
   intersection dialect and a small frozen compatibility shim makes the ACL2 forms
   inert under plain CL. The shim is part of the trusted computing base and is
   *not* verified.
3. **Host conformance.** ACL2's arithmetic, character and string semantics are
   defined by its logic; SBCL's are defined by ANSI plus implementation choices.
   Agreement is expected and is *probed* — kernel functions are executed under the
   ACL2 evaluator and under SBCL over the regression corpus, and divergence is
   fault F9 — but probing is sampling, not proof.

Residual (1)+(3) is exactly **DF-011**, which is OPEN and is the largest unproved
dependency in the design. Residual (2) is recorded as **DF-048**.

Claims **WC-1** and **WC-2** are withdrawn and appear nowhere in this package.

Every other candidate proof platform is *worse on this axis*, which is the actual
comparative claim: Rocq/Coq 9.0 [RL-053] and Lean require extraction to a different
language or a verified interpreter, reintroducing seam (1) *plus* a translation
seam the ACL2 arrangement does not have (D20, iteration DC-20-2); TLA+ verifies a
*model* of the system, not the system [RL-016]. The claim is **comparative and
bounded**, not absolute.

This is the reason Common Lisp is selected, and it is a *correctness* reason, not
an aesthetic one. Remove ACL2 and the language choice would have to be re-argued
from scratch.

### 1.1 The proof boundary, drawn precisely

```
┌───────────── KERNEL K_v ─────────────┐ ┌──── VERIFICATION KERNEL V_w ────┐
│ ANSI CL, applicative subset admitted │ │ ANSI CL, applicative subset      │
│ by ACL2                              │ │ admitted by ACL2 — INDEPENDENTLY │
│ · no side effects, I/O, threads,     │ │   authored, separately proved    │
│   CLOS or conditions                 │ │ · shares NO code with K_v (I-42) │
│ · total, measure-bearing, guard-     │ │   beyond ANSI CL + the frozen    │
│   verified                           │ │   decoder library                │
│ · every conclusion stamped with v    │ │ · reads R and A|_R directly;     │
│ contains: the fold; evidence algebra;│ │   never reads K_v's output       │
│ temporal algebra; label propagation; │ │ contains: admit-p (I-46);        │
│ argument construction and defeat;    │ │ publication-critical invariant   │
│ docket admissibility; reopening-     │ │ verdicts; self-model falsifier   │
│ predicate evaluation; plan derivation│ │ outcomes                         │
└──────────────────────────────────────┘ └──────────────────────────────────┘
        used by every office                    used by the Inspectorate only
                    ▲  pure data in, pure data out ▲
                    │        disagreement = fault F15
                    │
┌─────────────────────────────── SHELL ─────────────────────────────────┐
│ SBCL 2.6.x [RL-038]                                                    │
│ CLOS protocols · custom method combination · conditions and restarts   │
│ · MOP metaclasses · package locks · threads · core images · I/O        │
│ contains: offices, warrants, observation, custody, scheduling,         │
│ persistence, publication surface, human interfaces                     │
└───────────────────────────────────────────────────────────────────────┘
```

**Why the kernel has no CLOS.** ACL2 admits neither generic functions nor
conditions. Putting the legal semantics in CLOS would forfeit every ACL2-discharged
obligation (the count is derived at sealing time and recorded in the seal). This is
a real cost — the kernel is written in a plainer style — and it is accepted because
mechanical verification of the legal semantics dominates expressiveness of the
legal semantics (Tier 3 O9 versus no competing objective).

### 1.2 How kernel purity is actually established

*(Corrected in the third audit round, finding HF-026. The previous version asserted
claim **WC-3**. That is **not a purity check**. `OPEN`, `READ`, `RANDOM`,
`GET-UNIVERSAL-TIME`, `DELETE-FILE` and `SET-PPRINT-DISPATCH` are all symbols in
the `COMMON-LISP` package. A kernel that imports nothing but `COMMON-LISP` can
still open a socket.)*

Purity rests on three things, in descending order of strength:

1. **ACL2 admissibility — the actual guarantee.** ACL2's logic has no notion of a
   side effect. A function that calls `OPEN` cannot be admitted at all: the
   definitional principle rejects it. So the kernel's purity is a *consequence of
   the proof obligation being discharged*, not something checked alongside it.
   This is the load-bearing mechanism and it is the reason the kernel is defined by
   what ACL2 will accept rather than by a package boundary.
2. **A symbol denylist over `COMMON-LISP` itself.** A build-time audit walks the
   kernel's code and rejects any reference to an enumerated set of effectful or
   nondeterministic ANSI symbols (file, stream, `RANDOM`, time-of-day, `THE`-unsafe
   coercions, `EVAL`, `INTERN` on fresh strings, and the pretty-printer dispatch
   table). This catches purity violations *before* the ACL2 run, so the failure is
   fast and legible; it does not establish purity by itself.
3. **Signature discipline.** `A|_R` is a parameter, not a global reached through
   `*artifact-store*`; the environment object never enters the kernel. This is what
   makes (1) achievable at all — a kernel that fetched bytes on demand could not be
   admitted.

Non-kernel packages are still not importable by the kernel, but that constraint is
hygiene, not the purity argument.

---

## 2. MULTI-METHOD DISPATCH: COUNTS-AS IS GENUINELY THREE-ARGUMENT

The institutional classification relation is *A counts as B in context C*
[RL-010]. It dispatches on three independent taxonomies simultaneously:

- the **act** (its brute type),
- the **institutional context** (which office, which docket, which legal order),
- the **subject** (which instrument class, which evidentiary class).

```lisp
(defgeneric counts-as (act context subject)
  (:documentation
   "Institutional classification. Returns the institutional fact type the
    brute act constitutes in this context for this subject, or NIL if the
    act constitutes nothing."))

(defmethod counts-as ((act gazette-issue-observation)
                      (ctx  authentication-context)
                      (subj signed-container))
  ;; verifying the National Printing House officer signature on the container
  ;; constitutes an evidentiary determination, not an authority determination
  'evidentiary-determination)

(defmethod counts-as ((act gazette-issue-observation)
                      (ctx  registry-context)
                      (subj signed-container))
  ;; the same brute act in the Registry constitutes nothing at all:
  ;; the Registry has no evidentiary power (SA-1)
  nil)
```

The same brute act constitutes different institutional facts — or nothing — in
different contexts. In a single-dispatch language this becomes a visitor, a
registry table, or a chain of conditionals, all of which the creator directive
names explicitly as forbidden imitations. Here it is the language's own dispatch,
which means: the method set is introspectable, `compute-applicable-methods` can
enumerate exactly what an act can constitute, and adding an office cannot silently
change an existing classification.

**What is *not* claimed:** multiple dispatch is not unique to Common Lisp. What is
claimed is that this relation is genuinely three-argument, that hand-rolled
dispatch is forbidden by C11, and that CLOS provides it directly with
introspection.

---

## 3. CUSTOM METHOD COMBINATION: WARRANT CHECKING BECOMES A LANGUAGE-LEVEL PROPERTY

This is the mechanism that makes "an act without power has no institutional
effect" **structural** rather than conventional (D02).

`DEFINE-METHOD-COMBINATION`'s long form computes the effective method from the
applicable methods and their qualifiers, and can implement arbitrary control
structure and arbitrary processing of qualifiers [RL-042]. So:

The act-context variables must be **proclaimed special**. Without `defvar`, `let`
would establish *lexical* bindings, and the `:record` methods — compiled in a
different lexical environment — would not see them at all:

```lisp
(defvar *act-warrant-results* nil)
(defvar *act-outcome* :no-act)
```

```lisp
(define-method-combination institutional ()
  ((warrant   (:warrant))
   (defeater  (:defeater))
   (around    (:around))
   (record    (:record))
   (primary   () :required t))
  "All :warrant methods must succeed before any primary runs; any :defeater method
   may veto; exactly one primary performs the act. :record methods run on every
   exit path, including a non-local one, and see valid act-context bindings on all
   of them — which requires the bindings to be established OUTSIDE the
   UNWIND-PROTECT and the warrant evaluation to happen INSIDE its protected form."
  (let ((form
          `(progn
             (setf *act-warrant-results*
                   (list ,@(mapcar (lambda (m) `(call-method ,m)) warrant)))
             (cond
               ((notevery #'identity *act-warrant-results*)
                (setf *act-outcome* :void-unwarranted)
                (signal-void-act :reason :unwarranted))
               ((some #'identity
                      (list ,@(mapcar (lambda (m) `(call-method ,m)) defeater)))
                (setf *act-outcome* :void-defeated)
                (signal-void-act :reason :defeated))
               (t (multiple-value-prog1
                      (call-method ,(first primary) ,(rest primary))
                    (setf *act-outcome* :performed)))))))
    `(let ((*act-warrant-results* nil)          ; dynamic bindings established
           (*act-outcome* :incomplete))         ; OUTSIDE the unwind-protect
       (unwind-protect
            ,(if around
                 `(call-method ,(first around) (,@(rest around) (make-method ,form)))
                 form)
         ,@(mapcar (lambda (m) `(call-method ,m)) record)))))

(defgeneric issue-entry (office kind payload)
  (:method-combination institutional))

(defmethod issue-entry :warrant ((o tribunal) (k (eql :authority)) payload)
  (holds-power-p o :issue :authority))

(defmethod issue-entry :warrant ((o t) (k t) payload)
  (charter-permits-p (office-id o) k (payload-fact-class payload)))

(defmethod issue-entry :record ((o t) (k t) payload)
  (append-act-record o k payload *act-warrant-results* *act-outcome*))
```

### 3.0 Why the binding sits outside the UNWIND-PROTECT

*(Fourth audit round. The previous form was corrected from `MULTIPLE-VALUE-PROG1`
to `UNWIND-PROTECT`, which fixed *whether* the cleanup ran — but left the `let`
establishing the act-context variables **inside** the protected form. That is a
second, subtler defect of the same kind, and an independent review caught it.)*

Checked against ANSI dynamic-extent semantics, the ordering matters for three
separate reasons:

1. **Binding inside the protected form is dead by cleanup time.** A dynamic binding
   established by `let` is in effect for the dynamic extent of the `let` *body*.
   The cleanup forms of an `unwind-protect` that encloses that `let` run **after**
   the `let` has exited, so the binding is already undone. The `:record` methods
   would see the global value — or, worse, a value left over from an unrelated
   outer act — precisely when recording matters most.
2. **A nested `unwind-protect` inside the `let` is in scope.** With the binding
   outside, the cleanup forms execute *within* the dynamic extent of the `let`, so
   they observe the bindings on every exit path: normal return, `signal-void-act`
   transferring control, an error unwinding to an outer handler, or a `throw`.
3. **`setf` is required, not re-binding.** The warrant results are computed inside
   the protected form and must be *assigned* to the already-established binding.
   Re-binding there would recreate defect (1).

The residual outcome values are therefore meaningful rather than accidental:

| `*act-outcome*` seen by `:record` | Means |
|---|---|
| `:performed` | primary completed normally |
| `:void-unwarranted` | warrant group failed; no primary ran |
| `:void-defeated` | a defeater vetoed; no primary ran |
| `:incomplete` | control left the protected form without reaching any of the above — an error or `throw` from a warrant method, a defeater, or the primary itself |

`:incomplete` is the informative case: it is exactly the state that the earlier
`MULTIPLE-VALUE-PROG1` form could not record at all, and that the intermediate
`UNWIND-PROTECT` form recorded with invalid bindings.

**What this buys, stated exactly.** *(Corrected in the third audit round, finding
HF-027: two of the three original claims were false.)*

| Claim | Status |
|---|---|
| The `:warrant` group is consulted for every applicable method set, so it cannot be forgotten when a new office adds a method | **true** — it is part of effective-method computation |
| `:record` methods run on every exit path | **true only with `UNWIND-PROTECT`.** The earlier form used `MULTIPLE-VALUE-PROG1`, under which a non-local exit from the primary — an error, a `throw`, a restart transfer — skips the record forms entirely. Since `signal-void-act` is *designed* to transfer control, that form failed to record precisely the acts it most needed to record: the void ones. Fixed above. |
| Claim **WC-5** — that the primary is unreachable except through the effective method, making the check unbypassable | **FALSE, and withdrawn.** A method's function object is reachable directly; an office can call an internal helper that performs the same effect; and nothing stops a `defmethod` on a *different* generic function doing the same work. This is why DF-002 was originally mis-classified as merely bounded. |
| The set of institutional generic functions is introspectable | **true** — a build-time audit walks every generic function using this combination and reports any whose applicable-method set lacks a warrant method (adopted in D02 iteration 2 in place of a stricter MOP-level refusal that would have forbidden legitimate `:around` methods) |

The withdrawn claim is exactly why enforcement does not live here. See §3.1.

### 3.1 This is defence in depth, not the guarantee

*(Second-round audit finding HF-022, closing DF-002.)*

A custom method combination polices **generic-function calls only**. An ordinary
function call inside an office bypasses it entirely, and an office can lift the lock
on its own package. The first version recorded this as DF-002 and accepted it as
*bounded*. That was wrong: it left the architecture's central authority guarantee
resting on a mechanism that a single ordinary call defeats.

**Enforcement has moved to the append point.** Admission is a pure, total,
call-path-independent function of the Charter and the entry, evaluated by the
verification kernel `V_w`, which imports no office package:

```lisp
;; in the V_w package; imports ANSI CL and the frozen decoders only
(defun admit-p (charter entry)
  "Total. Decidable. ACL2-admitted. Trusts nothing the caller constructed."
  (and (well-formed-p entry)
       (chain-links-p entry)                        ; prev-commit matches head
       (hlc-monotonic-p entry)
       (charter-permits-p charter                   ; RECONSTRUCTED, not trusted
                          (entry-office entry)
                          (entry-kind entry)
                          (entry-fact-class entry))
       (warrant-derives-from-charter-p charter (entry-warrant entry))
       (warrant-bound-to-digest-p (entry-warrant entry) (entry-digest entry))
       (kind-specific-admissible-p charter entry)))
```

The gate does not *check* the caller's warrant; it independently **reconstructs**
from the Charter whether this office holds this power over this fact class, and
then requires the presented warrant to be a Charter-derived capability bound to
this entry's content digest. A forged, absent, stale, borrowed or scope-mismatched
warrant fails no matter how the call arrived.

This is provable in a way the call-site check never was — PO-046 quantifies over
entries, not over call paths:

```
∀ e. committed(e) ⇒ charter-permits(office(e), kind(e), fact-class(e))
```

The method combination is retained because failing fast at the call site with a
good diagnostic is genuinely useful. It is no longer what makes the invariant true,
and the Lisp claim in §14 is downgraded accordingly.

---

## 4. CONDITIONS AND RESTARTS: DETECTION SEPARATED FROM INSTITUTIONAL REMEDY

The Common Lisp condition system lets a handler in an outer dynamic context select
a named recovery **without unwinding the signalling context** [RL-041]. That is
precisely the institutional shape: the *detector* has no authority to decide the
remedy, and the *office* with authority needs the context in which the remedy
applies.

```lisp
(define-condition institutional-fault (error)
  ((subject :initarg :subject :reader fault-subject)
   (docket  :initarg :docket  :reader fault-docket)))

(define-condition unresolvable-citation (institutional-fault)
  ((citation :initarg :citation :reader fault-citation)))

(define-condition source-mutation-detected (institutional-fault)
  ((held-digest :initarg :held :reader fault-held-digest)
   (new-digest  :initarg :new  :reader fault-new-digest)))

(define-condition label-bound-exhausted (institutional-fault)
  ((belief :initarg :belief :reader fault-belief)))

;; DETECTOR — signals, decides nothing
(defun resolve-citation (citation)
  (or (lookup-norm-identity citation)
      (restart-case (error 'unresolvable-citation :citation citation)
        (use-provisional-reference (ref)
          :report "Bind a provisional reference pending adjudication."
          :interactive read-provisional-reference
          ref)
        (quarantine-instrument ()
          :report "Quarantine the citing instrument."
          :quarantine)
        (open-docket ()
          :report "Open an adjudication docket for this citation."
          (open-citation-docket citation))
        (defer-to-acquisition ()
          :report "Raise an acquisition obligation and defer."
          (raise-acquisition-obligation citation)))))

;; OFFICE — chooses the remedy, and the choice is itself a warranted act
(defun with-tribunal-remedies (thunk)
  (handler-bind
      ((unresolvable-citation
         (lambda (c)
           (let ((remedy (tribunal-select-remedy c)))
             (warranted-act (*acting-office* :select-restart remedy c)
               (invoke-restart remedy))))))
    (funcall thunk)))
```

The restart set **is** the institution's remedy catalogue, enumerable at the point
of failure via `compute-restarts`. Exceptions cannot express this: unwinding
destroys the context in which the remedy must be applied (D24, iteration 1).

**The institutional addition the language does not supply.** Restart selection is
itself a warranted, recorded act. A restart chosen by a policy table would be an
office exercising power without a warrant (D24, iteration 2). This is where the
architecture adds to Pitman's mechanism rather than merely using it.

---

## 5. THE METAOBJECT PROTOCOL: INTERCEPTED PERSISTENCE, ACCESS CONTROL AND WARRANTED EVOLUTION

CLOS is specified with an open implementation whose class, slot-access and
generic-function invocation protocols are themselves programmable [RL-040];
`closer-mop` rectifies cross-implementation gaps and SBCL obeys AMOP's
`validate-superclass` requirements [RL-039, RL-038]. bknr-datastore demonstrates
that MOP-mediated persistence with transactional slot access is proven Common Lisp
practice, not an aspiration [RL-045].

Three uses. *(R4, finding HF-031: these were previously introduced as
"load-bearing", which contradicts their classification in §14 and in I-33 as
defence in depth. They are defence in depth. The contradiction is resolved in
favour of the weaker reading, because that is the one the enforcement analysis of
§3.1 supports.)*

### 5.1 Slot access outside a warranted act

*(Corrected by second-round audit finding HF-024. The first version specialised one
generic function, hooked class redefinition in the wrong place, and claimed a
guarantee stronger than the MOP gives.)*

```lisp
(defclass institutional-class (standard-class) ())

(defmethod validate-superclass ((c institutional-class) (s standard-class)) t)

;; (1) writes
(defmethod (setf slot-value-using-class) :before
    (new (class institutional-class) object slotd)
  (declare (ignore new))
  (check-mutation-warrant object slotd))

;; (2) unbinding — omitted in the first version, and a slot can be unbound
;;     without ever being written
(defmethod slot-makunbound-using-class :before
    ((class institutional-class) object slotd)
  (check-mutation-warrant object slotd))

;; (3) construction legitimately writes slots before any ACT warrant exists,
;;     so it needs a distinct warrant rather than an exemption
(defmethod shared-initialize :around
    ((object institutional-object) slot-names &rest initargs)
  (declare (ignore slot-names initargs))
  (let ((*current-warrant* (require-construction-warrant object)))
    (call-next-method)))

(defun check-mutation-warrant (object slotd)
  (unless (and *acting-office* *current-warrant*)
    (error 'unwarranted-mutation :object object :slot (slot-definition-name slotd)))
  (unless (warrant-covers-p *current-warrant* object slotd)
    (error 'warrant-scope-violation :object object)))
```

**Three corrections to the claim, not just to the code.**

1. **Coverage.** Writes, unbinding and construction are three distinct paths. The
   first version guarded one.
2. **Scope of the MOP guarantee.** The AMOP slot-access protocol is honoured for
   instances of a *custom* metaclass, which institutional classes have. It is **not**
   a portable guarantee for `standard-class`, where implementations may optimise
   access and bypass `slot-value-using-class`. A build-time audit therefore asserts
   that no institutional class is reached through low-level instance access
   (`standard-instance-access` and equivalents). This is an implementation-dependent
   guarantee pinned to SBCL [RL-038, RL-039], recorded as DF-046 — not a language
   guarantee.
3. **Status.** Following §3.1, this is **defence in depth**. The guarantee that
   nothing enters the institution's state without a warrant lives at the append
   point in `V_w`. Unwarranted *in-memory* mutation of a derived store is corrected
   by the next rebuild-and-compare (I-31), because a derived store that disagrees
   with `K_v(R, A|_R)` is unconstitutional by definition. The metaclass catches such
   mutation early and with a good diagnostic; it does not have to be airtight for
   the invariant to hold.

### 5.2 Persistence is a slot property, not a serialization pass

Following the bknr pattern [RL-045], the metaclass marks slots persistent or
transient. Crucially, the authority relation is **inverted** relative to
prevalence: in bknr the live image is the truth; here the record is the truth and
the image is a cache (A12), so persistent slots are *projections* of `K_v(R, A|_R)`, and
the deletability experiment (SA-7) periodically proves it.

### 5.3 Class evolution under a migration warrant

*(Hook corrected by second-round audit finding HF-024.)* The first version guarded
`reinitialize-instance` on the class. That is not the metaobject protocol's
redefinition entry point; `defclass` expansion goes through
`ensure-class-using-class`, which is where the guard belongs.

```lisp
(defmethod ensure-class-using-class :before
    ((class institutional-class) name &key direct-slots &allow-other-keys)
  (let ((new-layout (layout-hash-for name direct-slots)))
    (unless (migration-warrant-for name (layout-hash class) new-layout)
      (error 'unwarranted-redefinition :class name))))

(defmethod update-instance-for-redefined-class :around
    ((obj institutional-object) added discarded plist &key)
  (let ((warrant (current-migration-warrant)))
    (record-instance-migration obj added discarded warrant)
    (call-next-method)))
```

The standard redefinition protocol gives *live* evolution; the metaclass makes it
**warranted and recorded** (I-33). Free redefinition was rejected because it
changes the meaning of already-admitted conclusions with no record that the
meaning changed (D25).

---

## 6. PACKAGES, LOCKS AND SYSTEMS: HYGIENE, PLUS ONE LOAD-BEARING ROLE

*(Retitled and rewritten in the third audit round, finding HF-028. The previous
title framed this facility as an authority boundary and the text asserted claim
**WC-6** (PHASE-2-REPORT.md §4A). Both are wrong, and they survived two audits
because they were written before enforcement moved to the append point.)*

**What a package lock is not.** `sb-ext:lock-package` prevents defining, binding
and redefining symbols in a locked package. It does not prevent *calling* an
unexported symbol — `watchtower/tribunal::internal-fn` is reachable from anywhere
with two colons — and any code can call `sb-ext:unlock-package`. A package lock is
a **hygiene mechanism against accident**, not a capability boundary against intent.
Treating it as authority enforcement was a category error.

**Where office authority actually lives.** At the append point, in `admit-p`, which
reconstructs the power from the Charter and trusts nothing the caller built (I-46,
PO-046). That predicate quantifies over entries; it is indifferent to which package
the calling code lived in, whether that package was locked, and whether the caller
used one colon or two.

One package and one ASDF system per office; `package-inferred-system` inside each
office for file-level dependency deduction [RL-043]; SBCL package locks for
hygiene [RL-038].

```lisp
(defpackage #:watchtower/tribunal
  (:use #:cl #:watchtower/kernel-api)
  (:export #:admit-authority #:admit-interpretation #:classify-cessation
           #:resolve-conflict #:open-docket))

(sb-ext:lock-package '#:watchtower/tribunal)
```

Consequences, graded by how much weight each actually bears:

- *(hygiene)* The **intended** path from one office into another is an exported
  protocol symbol; the lock makes accidental departure from that path noisy. It
  does not make deliberate departure impossible.
- *(hygiene)* The kernel package exports the only *intended* writer of derived
  state (SA-8). Purity itself is established by ACL2 admissibility plus the symbol
  denylist of §1.2 — **not** by the import list, which cannot establish it (see
  §1.2 and finding HF-026).
- **(load-bearing) Kernel disjointness (I-42) is a package-graph property and is
  therefore mechanically checkable.** The build computes the transitive package/system
  closure of `K_v` and of `V_w` and asserts that the intersection is exactly
  `{COMMON-LISP, watchtower/decoders}` — the decoder library being the one
  deliberate, frozen, separately verified shared dependency, because two kernels
  that disagree about what an entry's bytes *mean* are not verifying the same
  thing. Anything else in the intersection fails the build (PO-042). This is the
  mechanism that makes the HF-001 remedy checkable rather than aspirational, and it
  is why claim 6 in §14 is load-bearing in its disjointness role even after being
  downgraded in its authority role.
- *(hygiene)* ASDF gives dependency ordering, not authority: a system boundary is
  not a security boundary [RL-043].

**Why disjointness is different from the rest of this section.** I-42 is a claim
about *what code exists in a closure*, which a package graph decides exactly. The
authority claims were about *what code can do at runtime*, which a package graph
does not decide at all. Same mechanism, two very different epistemic weights — and
conflating them is what produced the error. This is why §14 lists claim 6 as
load-bearing in its disjointness role and defence-in-depth in its authority role
rather than giving it a single grade.

---

## 7. MACROS CONFINED TO THREE DOMAIN LANGUAGES

C11 permits macros only for genuine domain languages or compile-time guarantees.
Three qualify (D23); a fourth (adapter DSL) was rejected as abbreviation.

### 7.1 The Charter language — compile-time detection of authority errors

```lisp
(defcharter watchtower
  (:entrenched ca-1-jurisdictional-limit
               ca-2-monotone-record
               ca-3-derivation-purity
               ca-4-metacognitive-adequacy
               ca-5-deletability
               ca-6-model-containment
               ca-7-inspection-is-negative)

  (office registry
    (powers (issue :source-registration)
            (issue :norm-identity)
            (bind  :external-identifier :defeasible t))
    (forbidden (issue :authority)))          ; SA-5

  (office authentication
    (powers (issue :evidentiary-status))
    (forbidden (issue :authority) (issue :interpretation)))   ; SA-2

  (office inspectorate
    (powers (issue :procedure-invalid) (suspend :publication))
    (forbidden (issue :* :positive t))))     ; SA-4 / CA-7
```

`DEFCHARTER` expands into the power tables, the warrant types, and **compile-time
assertions** that SA-1…SA-6 hold. Declaring two offices with `issue` over the same
fact class is a compile error. That is the compile-time guarantee C11 requires; a
runtime-interpreted charter would discover the same defect only when an act is
attempted (D23, iteration 1).

### 7.2 The Temporal Legal Algebra

```lisp
(deftemporal in-force-p (provision t)
  (and (published-p provision)
       (interval-contains-p (force-interval provision) t)
       (not (ceased-before-p provision t))))

(defcessation annulment
  :effect :ex-tunc
  :scope-from-instrument t
  :reopens (decisions-intersecting-scope))
```

`DEFTEMPORAL` and `DEFCESSATION` emit both the kernel function *and* the ACL2
proof-obligation stub for its totality and its temporal invariant. The macro is
the mechanism that keeps the obligation in sync with the definition — an
obligation maintained by hand drifts.

### 7.3 The protocol/obligation declaration language

```lisp
(definvariant i-04-monotone-degradation
  :statement "(<= (evidence-rank (apply-transform tr x)) (evidence-rank x))"
  :tool :acl2
  :enforcement :kernel
  :violation :void
  :discharges "PO-004")
```

Emits: the runtime assertion where applicable, the ACL2 obligation stub, and an
entry in the machine-readable invariant register that the Inspectorate executes.

**Honest limit.** The macro-expanders generating proof obligations are themselves
part of the trusted computing base and are not verified (DF-029).

---

## 8. DYNAMIC BINDING FOR INSTITUTIONAL CONTEXT — AND NOWHERE ELSE

An institutional act occurs *within* a proceeding. That is dynamic extent, and
dynamic binding is its exact match:

```lisp
(defvar *acting-office*)      ; who is acting
(defvar *current-warrant*)    ; under what power
(defvar *docket*)             ; in which proceeding
(defvar *as-of*)              ; at which point on the legal timeline
(defvar *belief-context*)     ; under which assumption environment
(defvar *environment*)        ; the injected effect source (D14)

(defmacro warranted-act ((office power subject) &body body)
  `(let ((*acting-office* ,office)
         (*current-warrant* (obtain-warrant ,office ,power ,subject)))
     (unless *current-warrant* (signal-void-act :reason :unwarranted))
     ,@body))
```

**Prohibited uses**, stated so the discipline is checkable: no dynamic variable
carries institutional *data* (only context); no dynamic variable is written by the
kernel (which has none); no dynamic variable substitutes for a parameter that
belongs in a function's signature. Context that must survive across a region
boundary is passed as message data, never as a rebinding, because dynamic extent
does not cross threads.

### 8.1 `*environment*` is not a service container

*(Answer to hostile-audit finding HF-011.)* The creator directive forbids
"service-container ceremony", and an injected effect source superficially resembles
dependency injection. It is not, and the difference is checkable:

- `*environment*` is a **single value with dynamic extent**, not a registry. There
  is no `(lookup-service "clock")`, no string or keyword-keyed map, no
  registration step, no lifecycle management, no scoping container object.
- Effects are obtained by calling ordinary generic functions on it —
  `(env-now e)`, `(env-fetch e request)` — so dispatch is CLOS dispatch on the
  environment's class (real / recorded / simulated), not name resolution.
- It exists for one reason with a stated correctness consequence: it is what makes
  `state = K_v(R, A|_R)` true and replay exact (D14). A container exists to decouple
  construction from use, which is a different purpose and is not claimed here.

If the environment ever acquires a name-keyed lookup, it has become a container and
this justification lapses.

---

## 9. CONCURRENCY IN THE SHELL

Single-threaded regions owning their state, communicating by immutable messages
that become record entries (D13). Portable primitives from `bordeaux-threads`
APIv2 [RL-044]; SBCL-specific facilities only where the portable layer does not
reach (package locks, core saving, CAS on structure slots) [RL-058, RL-038].

```lisp
(defstruct (region (:constructor %make-region))
  (name nil :type symbol :read-only t)
  (mailbox (make-mailbox) :read-only t)
  (state nil)                                   ; owned; never shared
  (thread nil))
```

Parallelism lives in two places only:

1. **Observation workers** — stateless, effects via `*environment*`, results enter
   as entries.
2. **Derivation** — read-only over an immutable snapshot, therefore
   order-independent and determinism-preserving (D13, iteration 3).

Mutation is never parallel. This is what keeps `state = K_v(R, A|_R)` true.

---

## 10. PERSISTENCE REALISATION

```
R (record)          append-only file set, hash-chained, Merkle-committed,
                    witness co-signed, qualified-time-anchored     [RL-011, RL-028]
A (artifact store)  content-addressed immutable blobs; signed containers retained
                    verbatim                                        [L4, RL-024]
Derived state       in-memory CLOS graph produced by K_v; checkpointed as a
                    serialised snapshot and optionally an SBCL core image [RL-046]
```

The prevalence tradition is inverted: bknr's transaction-log-plus-snapshot
mechanism is adopted [RL-045], but the *authority* moves from the image to the
record (A12). The image is a cache — necessarily so, since SBCL core images are
explicitly not compatible across runtimes [RL-046], which makes them unusable as
an archival format and perfectly suited as a fast-start cache.

---

## 11. DEPLOYMENT TOPOLOGY

```
┌──────────────────────── one institution image ────────────────────────┐
│  region: registry · observatory-control · archive · authentication    │
│  region: tribunal · doctrine · chronicler · coverage-ephorate         │
│  region: inspectorate (adversarial; separate schedule)                │
│  region: publications                                                 │
│  region: sandbox (deletability experiments, replay, simulation)       │
│  one append point per authority domain; one logical record            │
└───────────────────────────────────────────────────────────────────────┘
        │                                   │
        ▼                                   ▼
┌────────────────────┐          ┌───────────────────────────────┐
│ observation workers│          │ optional VR replica set       │
│ (isolated, stateless)         │ for record availability [RL-012]│
└────────────────────┘          └───────────────────────────────┘
```

Observation workers are isolated processes: a malformed source response, an OCR
crash, or a runaway model call must not touch institutional state. They
communicate only by producing `OBSERVATION` and `PROPOSAL` entries, which is
exactly the limit of their power (SA-9). The isolation is therefore not merely
operational hygiene — it coincides with the constitutional boundary.

---

## 12. WHAT ACL2 CAN AND CANNOT CARRY

**Can** (the ACL2-assigned obligations, enumerated in the requirements Part X
table and counted in the seal): monotone evidentiary degradation; rank-increase requires
new evidence; temporal justification non-emptiness; label soundness; defeat
propagation completeness; no-good superset exclusion; preference relation is a
strict partial order; no arbitrary conflict resolution; authority arguments are
doctrine-free; plan is a function of the self-model; docket admissibility;
reopening predicates are total and decidable; kernel applicativeness; answer
strength is the meet of its leaves; interval algebra soundness (PO-039);
amendment-chain confluence (PO-040); and — added in the second audit round —
**kernel totality under unresolved artifacts** (PO-044) and **call-path-independent
admission** (PO-046), plus the same publication-critical subset proved a second
time over the independent implementation `V_w` (PO-041).

Note what PO-046 does that no call-site mechanism could: it quantifies over
*entries*, not over call paths, so it is insensitive to how the code that produced
the entry was written.

**Cannot**: anything involving CLOS, conditions, threads, I/O or time. Also cannot
carry unbounded-search argumentation semantics: preferred and stable semantics are
computationally hard [RL-056] and admit no decreasing measure, which is exactly why
D08 restricts the admitted default to grounded semantics and marks bounded
preferred search `SEMANTICS-INCOMPLETE`. That restriction is the honest response to
the A3 falsifier firing, not a workaround.

**Unproved boundary**: the correspondence between ACL2's logic and SBCL's execution
is argued, not proved (DF-011). Mitigations: guard verification; differential
execution of kernel functions under ACL2's evaluator and under SBCL on the
regression corpus, with divergence treated as a fault. This reduces the risk; it
does not close the gap, and the gap is stated in the seal's unresolved obligations.

---

## 13. WHAT IS **NOT** CLAIMED AS LISP-SPECIFIC

The acceptance contract forbids claims exceeding their evidence. These parts of the
architecture are **language-neutral** and are not offered as justification for
Common Lisp:

1. **The region/single-writer concurrency topology** (§9). Erlang, Go, Rust and
   others express it as well or better. Its selection in D13 rests on determinism,
   not on Lisp.
2. **The append-only hash-chained record with Merkle commitments** (§10). Entirely
   language-neutral.
3. **Content-addressed artifact storage.** Language-neutral.
4. **Hybrid logical clocks.** Language-neutral.
5. **The deterministic simulation scheduler.** The idea is from a C++ system
   [RL-017]; Lisp neither helps nor hinders.
6. **Viewstamped Replication.** Language-neutral.
7. **The eight-kind type discipline.** Any language with sum types expresses it;
   several express it *better* than CLOS, because a closed sum type gives
   exhaustiveness checking that CLOS class hierarchies do not.

Point 7 is a genuine concession and is recorded as a defeater (DF-032): a language
with closed algebraic data types and pattern-match exhaustiveness would give a
*stronger* static guarantee on kind separation than CLOS does. Common Lisp is
nevertheless selected because §1 (the absence of an extraction seam and a
re-implementation seam) dominates that advantage, and because §3 (warrant checking as an effective-method
property) has no equivalent in those languages. This is a trade, and it is stated
as one.

---

## 14. SUMMARY OF LOAD-BEARING LISP CLAIMS

*(Table revised after the second audit round: claims 2, 5 and 6 are downgraded from
guarantees to defence in depth, because enforcement moved to the append point.)*

| # | Mechanism | Status | What it buys | Evidence | If removed |
|---|---|---|---|---|---|
| 1 | **ACL2 subset kernel** — now **two** of them, `K_v` and `V_w`, independently authored and separately admitted | **load-bearing** | no extraction step and no re-implementation step (seams UP-1, UP-2 remain); the ACL2-assigned obligations; and the independence that closes condition WC-7 (§1, I-41) | RL-014 | the language choice must be re-argued from scratch, and HF-001 reopens |
| 3 | **Multi-method dispatch** | **load-bearing** | counts-as is directly expressible with introspection | RL-040 | hand-rolled registry, forbidden by C11 |
| 4 | Conditions + restarts | material | detection separated from remedy without unwinding | RL-041 | remedies decided by detectors (D24-a) |
| 7 | Dynamic binding | material | institutional context has correct extent | RL-037 | context threaded manually or leaked into data |
| 8 | Three DSL macros | material | authority and temporal errors caught at compile time; proof obligations stay in sync | RL-042, RL-037 | errors deferred to runtime; obligations drift |
| 2 | Custom method combination | **defence in depth** (was: guarantee) | fails fast at the call site with a good diagnostic | RL-042 | nothing invariant-bearing is lost; §3.1 |
| 5 | MOP metaclasses | **defence in depth** (was: guarantee) | early detection of unwarranted in-memory mutation; warranted class evolution | RL-040, RL-045, RL-039 | detection moves to the next rebuild-and-compare; §5.1 |
| 6 | Packages + locks + ASDF | **defence in depth** (was: guarantee) for authority; **load-bearing** for kernel disjointness (I-42) | office hygiene; and the import-closure audit that makes `K_v`/`V_w` independence checkable | RL-038, RL-043 | I-42 becomes unverifiable, which would defeat the HF-001 remedy |

**What the selection now rests on.** Claim 1 — and specifically the fact that ACL2
admits *two* independently written kernels as the same kind of object, so the
verifier is verified by the same machinery that verifies the derivation without
sharing its code. Claim 3. And claim 6 in its disjointness role.

Claims 2 and 5 were the two the first version leaned on hardest for authority, and
the second audit round showed both were bypassable. They earn their place now as
early-failure mechanisms, which is a real but smaller thing, and the table says so.
