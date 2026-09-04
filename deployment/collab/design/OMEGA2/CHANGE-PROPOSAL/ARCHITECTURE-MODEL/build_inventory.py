#!/usr/bin/env python3
"""Emit files-and-roles.sexp: classify EVERY tracked file exactly once (no-loss). Governance-scope files get a
per-file role; the rest are covered by directory rules -> OUT_OF_SCOPE_WITH_REASON. Deterministic (sorted)."""
import subprocess, os, hashlib
HERE=os.path.dirname(os.path.abspath(__file__)); ROOT=os.path.abspath(os.path.join(HERE,'..','..','..','..','..','..'))
files=sorted(subprocess.check_output(['git','-C',ROOT,'ls-files']).decode().splitlines())
CPP='deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/'
AM=CPP+'ARCHITECTURE-MODEL/'
def role(p):
    # --- new canonical architecture-model system (governance scope) ---
    if p.startswith(AM+'GENERATED/'):        return 'GENERATED_VIEW','deterministically generated from the canonical model'
    if p.startswith(AM+'FIXTURES/'):         return 'TEST_OR_FIXTURE','golden PASS/FAIL model-law fixture'
    if p.startswith(AM+'KERNEL/') or p.startswith(AM+'CHECKER/') or (p.startswith(AM) and p.endswith('.py')) or p.endswith('ARCHITECTURE-MODEL-GATE.sh'):
        return 'PRODUCTION_CODE','architecture-governance machinery (NEW; not LAWMAX product source/ or systems/)'
    if p.endswith('TOOLCHAIN.sexp'):         return 'CANONICAL_MODEL_INPUT','pinned toolchain identities (part of the model root)'
    if p==AM+'MODEL-MIGRATION-CONFLICT-LEDGER.md': return 'ARCHITECTURE_DECISION','migration conflict adjudications'
    if p==AM+'ROOT-OPERATOR-DECISION-PACKET.md':   return 'ARCHITECTURE_DECISION','single-operator decision packet'
    if p.startswith(AM+'REPORTS/'):          return 'HISTORICAL_EVIDENCE','model-run evidence report'
    if p.startswith(AM) and p.endswith('.sexp'):   return 'CANONICAL_MODEL_INPUT','canonical model module (single source of truth)'
    if p.startswith(AM) and p.endswith('.md'):     return 'AUTHORED_NORMATIVE_PROSE','architecture-model authored doc'
    # --- migration inputs (registries + schemas) ---
    if p==CPP+'SUBSYSTEM-REGISTRY.sexp' or p==CPP+'INTERFACE-AND-SCHEMA-REGISTRY.sexp':
        return 'CANONICAL_MODEL_INPUT','v1.6 registry — migration input to the canonical model'
    if p.startswith(CPP) and (p.endswith('-SCHEMAS.sexp')):
        return 'CANONICAL_MODEL_INPUT','versioned schema — type/record facts migration input'
    # --- legacy v1.8 harness + all v1.x audits: HISTORICAL_EVIDENCE / NON_AUTHORITATIVE_GATE ---
    import re
    if re.search(r'/V1\.\d.*(AUDIT|VERIFY|EVIDENCE|MANIFEST|BOOTSTRAP|CONSISTENCY|KILL-WITNESSES|SEMANTIC-CROSSWALK|DESTRUCTION-PASS-RECORD|NARROW-DELTA)', p) or p.endswith('.out'):
        return 'HISTORICAL_EVIDENCE','legacy v1.x verifier/audit/manifest — NON_AUTHORITATIVE_GATE (frozen at 4787b342)'
    # --- generated human tables (per V6I-17 the registries emit these) ---
    if p in (CPP+'ARCHITECTURE-CLOSURE-MATRIX.md',CPP+'PUBLIC-OBSERVATORY-CROSSWALK.md',CPP+'DOMINANCE-MATRIX.md'):
        return 'GENERATED_VIEW','human table generated from the registries/model (V6I-17)'
    # --- private extension contracts ---
    if 'PRIVATE' in p.upper() and p.startswith(CPP):
        return 'DEFERRED_PRIVATE','private extension contract (no public dependency)'
    # --- implementation book (authored construction prose; WP-00 protected) ---
    if '/IMPLEMENTATION-BOOK/' in p:         return 'AUTHORED_NORMATIVE_PROSE','Implementation Book construction detail (execution not authorized)'
    # --- destruction-pass raw journals ---
    if '/V1.3-DESTRUCTION-PASS/' in p:       return 'HISTORICAL_EVIDENCE','v1.3 destruction-pass record'
    # --- authored change proposals + normative contracts + qualification/traceability/superseded ---
    if p.startswith(CPP) and p.endswith('.md'):    return 'AUTHORED_NORMATIVE_PROSE','authored architecture prose / contract'
    if p.startswith('deployment/collab/dialogue/'):return 'HISTORICAL_EVIDENCE','append-only AI-dialogue record'
    if p.startswith('deployment/collab/') and p.endswith('.md'): return 'AUTHORED_NORMATIVE_PROSE','collaboration index/prose'
    if p.startswith('deployment/') and (p.endswith('.md') or p.endswith('.sexp')): return 'AUTHORED_NORMATIVE_PROSE','deployment normative contract/doc'
    # --- directory rules for the bulk (out of the architecture-governance scope) ---
    if p.startswith('source/') or p.startswith('systems/'):  return 'PRODUCTION_CODE','LAWMAX product source (frozen/untouched this pass)'
    if p.startswith('deployment/verify/'):   return 'PRODUCTION_CODE','MLTP verification runtime (product)'
    if p.startswith('tests/'):               return 'TEST_OR_FIXTURE','product test/fixture'
    if p.startswith('third-party/'):         return 'OUT_OF_SCOPE_WITH_REASON','vendored third-party sources (not architecture facts)'
    if p.startswith('output') or p.startswith('input') or p.startswith('"output') or p.startswith('output_run1') or p.startswith('"output_run1'):
        return 'OUT_OF_SCOPE_WITH_REASON','pipeline data/artifacts corpus (not architecture facts)'
    if p.startswith('deployment/self/') or p=='output/.healthy': return 'OUT_OF_SCOPE_WITH_REASON','runtime self-state (restored pre-commit; not a model fact)'
    if p.startswith('.github/') or p.startswith('.') or p in ('CLAUDE.md','README.md'):
        return 'OUT_OF_SCOPE_WITH_REASON','repo meta/config (not an architecture fact)'
    if p.startswith('deployment/'):          return 'OUT_OF_SCOPE_WITH_REASON','other deployment artifact (not in the architecture-governance scope)'
    return 'OUT_OF_SCOPE_WITH_REASON','unmatched tracked file outside the architecture-governance scope'

roles={'CANONICAL_MODEL_INPUT','GENERATED_VIEW','AUTHORED_NORMATIVE_PROSE','ARCHITECTURE_DECISION',
       'HISTORICAL_EVIDENCE','PRODUCTION_CODE','TEST_OR_FIXTURE','DEFERRED_PRIVATE','OUT_OF_SCOPE_WITH_REASON'}
GOV=[]  # per-file governance-scope facts (relevant files)
dircov={}   # dir-rule coverage counts for the bulk
unclassified=[]
from collections import Counter
rc=Counter()
gov_lines=[]
for p in files:
    r,reason=role(p)
    if r is None: unclassified.append(p); continue
    assert r in roles, (p,r)
    rc[r]+=1
    # per-file facts only for governance scope (relevant); bulk covered by dir-role facts
    if p.startswith(CPP) or p.startswith('deployment/collab/dialogue/') or p in ('deployment/LAWMAX-THREAT-MODEL.md','deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md','deployment/LAWMAX-LEGAL-IR-SEMANTIC-CONTRACT.md'):
        gov_lines.append((p,r,reason))
def wq(v): return '"%s"'%v.replace('"','\\"')
out=[';;;; files-and-roles.sexp — every tracked file classified exactly once (no-loss). GENERATED by build_inventory.py.',
     ';;;; Per-file facts cover the architecture-governance scope (relevant files); dir-role facts cover the bulk.',
     ';;;; Roles: CANONICAL_MODEL_INPUT GENERATED_VIEW AUTHORED_NORMATIVE_PROSE ARCHITECTURE_DECISION HISTORICAL_EVIDENCE',
     ';;;;        PRODUCTION_CODE TEST_OR_FIXTURE DEFERRED_PRIVATE OUT_OF_SCOPE_WITH_REASON','']
for p,r,reason in sorted(gov_lines):
    out.append('(fact file %s :role %s :reason %s)'%(wq(p),r,wq(reason)))
out.append('')
# dir-role summary facts (the bulk) — one per top-level rule, with count, for completeness auditing
rulecov=Counter()
for p in files:
    if any(p==g[0] for g in gov_lines): continue
    r,reason=role(p); rulecov[(p.split('/')[0] if '/' in p else p, r, reason)]+=1
for i,((top,r,reason),cnt) in enumerate(sorted(rulecov.items()),1):
    out.append('(fact dir-rule DR-%04d :top %s :role %s :count %d :reason %s)'%(i,wq(top),r,cnt,wq(reason)))
open(os.path.join(HERE,'files-and-roles.sexp'),'w').write('\n'.join(out)+'\n')
print('files total=%d  per-file gov facts=%d  dir-rules=%d  unclassified=%d'%(len(files),len(gov_lines),len(rulecov),len(unclassified)))
print('role counts:',dict(rc))
if unclassified:
    print('UNCLASSIFIED:',unclassified[:10])
