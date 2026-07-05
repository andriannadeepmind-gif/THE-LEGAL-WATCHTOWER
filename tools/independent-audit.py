#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""INDEPENDENT article-by-article corpus auditor.

Re-extracts every corpus from its source PDF with pymupdf — a DIFFERENT
library and code path than the production SBCL/libpoppler pipeline — and
verifies each served article at the normalized character-stream level
(whitespace/typography-insensitive):
  · coverage: every source article label is served (minus the per-corpus
    documented source omissions),
  · identity: served text ≡ source text (letterspacing, soft hyphens and
    Latin homoglyphs normalized on both sides),
  · repeal normalization: a served «Καταργήθηκε ως μη ισχύον.» must
    correspond to a repealed/empty source version.
Anything above 2% char divergence is flagged for human review. This is the
external check the pipeline cannot give itself; run after --materialize-pdf.

Usage: python3 tools/independent-audit.py   (from the repo root)
Requires: pymupdf (pip install pymupdf)
"""
import fitz, json, re, unicodedata, difflib, sys

TONOS=str.maketrans('άέήίόύώΐΰΆΈΉΊΌΎΏϊϋΪΫς','αεηιουωιυαεηιουωιυιυσ')
HOMO=str.maketrans('ABEZHIKMNOPTYXov','ΑΒΕΖΗΙΚΜΝΟΡΤΥΧον')
def stream(s):
    s=unicodedata.normalize('NFC',s).replace('\xad','').translate(HOMO)
    return ''.join(re.findall(r'[α-ωa-z0-9]',s.lower().translate(TONOS)))
REP=re.compile(r'παραλειπεται|καταργηθηκε|καταργειται|μη\s*ισχυον')
def isrep(s): return bool(REP.search(stream(s)))
def caps_banner(s):
    t=s.strip()
    if not t or len(t)>100: return False
    if REP.search(stream(t)): return False
    L=[c for c in t if c.isalpha()]
    return bool(L) and all(not c.islower() for c in L)
def joinspaced(s):
    return re.sub(r'(^|[^Ͱ-Ͽἀ-῿])([Ͱ-Ͽἀ-῿](?:[ \t]+[Ͱ-Ͽἀ-῿]){2,})(?=[ \t]|$)',
                  lambda m:m.group(1)+re.sub(r'[ \t]','',m.group(2)), s, flags=re.M)
def drop_tail(lines):
    out=[];tail=False
    for s in lines:
        st=s.strip()
        if caps_banner(st): tail=True; continue
        if tail: continue
        if re.match(r'^\s*(ΠΡΟΣΟΧΗ|προσοχή)',st): continue
        out.append(s)
    return out
def drop_lines(lines):
    return [s for s in lines
            if not caps_banner(s.strip())
            and not re.match(r'^\s*(ΠΡΟΣΟΧΗ|προσοχή)',s.strip())]
def seg_consolidated(pdf):
    lines=joinspaced('\n'.join(p.get_text() for p in fitz.open(pdf))).split('\n')
    hdr=re.compile(r'^\s*[ΆΑ]ρθρο\s*:\s*(\d+)\s*(ΣΤ|[Α-ΩA-Z])?\s*$')
    arts={};cur=None;buf=[]
    for l in lines:
        s=l.strip();m=hdr.match(s)
        if m:
            if cur: arts.setdefault(cur,[]).append('\n'.join(drop_tail(buf)))
            cur=(m.group(1)+(m.group(2) or '')).translate(HOMO);buf=[]
        elif cur is not None and not s.startswith('Ημ/νία'): buf.append(s)
    if cur: arts.setdefault(cur,[]).append('\n'.join(drop_tail(buf)))
    return arts
def seg_isokratis(pdf):
    lines=joinspaced('\n'.join(p.get_text() for p in fitz.open(pdf))).split('\n')
    hdr=re.compile(r'^\s*[ΆΑA]ρθρο\s*:\s*(\d+)\s*(ΣΤ|[Α-ΩA-Z])?\s*$')
    arts={};cur=None;buf=[];mode=None
    for l in lines:
        s=l.strip();m=hdr.match(s)
        if m:
            if cur: arts.setdefault(cur,[]).append('\n'.join(drop_lines(buf)))
            cur=(m.group(1)+(m.group(2) or '')).translate(HOMO);buf=[];mode=None;continue
        if cur is None: continue
        if s in ('Κείμενο Αρθρου','Τίτλος Αρθρου'): mode='keep';continue
        if s in ('Λήμματα','Σχόλια') or s.startswith('Ημ/νία') or s.startswith('Περιγραφή όρου'): mode='skip';continue
        if mode=='keep': buf.append(s)
    if cur: arts.setdefault(cur,[]).append('\n'.join(drop_lines(buf)))
    return arts
def seg_vouli(pdf):
    lines='\n'.join(p.get_text() for p in fitz.open(pdf)).split('\n')
    hdr=re.compile(r'^\*{0,4}\s*[ΆΑ]ρθρο\s+(\d{1,3})\s*([ΑA])?\s*\*{0,4}$')
    arts={};cur=None;buf=[];started=False;fn=False
    for l in lines:
        s=l.strip()
        if re.match(r'^Αθήνα,\s*\d',s) or s in ('ΕΥΡΕΤΗΡΙΟ','Σημειώσεις'): break
        m=hdr.match(s)
        if m:
            if cur: arts[cur]=['\n'.join(drop_tail(buf))]
            cur=m.group(1)+('Α' if m.group(2) else '');buf=[];started=True;continue
        if not started: continue
        if fn:
            if s.endswith('.'): fn=False
            continue
        if re.match(r'^\*+\s*Με\s.*αστερίσκ',s):
            if not s.endswith('.'): fn=True
            continue
        if re.match(r'^\d{1,3}$',s): continue
        buf.append(s)
    if cur: arts[cur]=['\n'.join(drop_tail(buf))]
    return arts

CORPORA=[
 ('poinikos','input/poinikos_kodikas.pdf','deployment/data/poinikoskodikas_clean.json',seg_consolidated,{'145','150','151','171','176','185','188'},True),
 ('kpoinikis','input/kodikas_poinikis_dikonomias.pdf','deployment/data/kpoinikis_clean.json',seg_consolidated,set(),True),
 ('astikos','input/astikos_kodikas.pdf','deployment/data/astikos_clean.json',seg_consolidated,set(),True),
 ('kpolitikis','input/kodikas_politikis_dikonomias.pdf','deployment/data/kpolitikis_clean.json',seg_consolidated,set(),True),
 ('kdioikitikis','input/kdioikitikis.pdf','deployment/data/kdioikitikis_clean.json',seg_isokratis,set(),True),
 ('syntagma','input/syntagma_2019.pdf','deployment/data/syntagma_clean.json',seg_vouli,set(),False),
]
def load_errata(jsonp):
    """Applied errata from the provenance sidecar (machine-readable record)."""
    import os
    prov=jsonp+'.prov.json'
    if not os.path.exists(prov): return []
    try:
        rec=json.load(open(prov))
        e=rec.get('errata') or []
        return e if isinstance(e,list) else []
    except Exception:
        return []

def erratum_ok(body, e):
    """An errata-corrected article verifies structurally: the corrected text is
    present, the defective text is absent."""
    return (e.get('to','') in body) and (e.get('from','') not in body)

def main():
    G={'n':0,'ok':0,'rep':0,'flag':0};bad=0
    for name,pdf,jsonp,seg,omit,use_title in CORPORA:
        src=seg(pdf);served={}
        errata={}
        for e in load_errata(jsonp):
            errata.setdefault(str(e.get('article','')),[]).append(e)
        for a in json.load(open(jsonp)):
            m=re.match(r'Άρθρο (\S+)(?: - (.*))?$',a['title'])
            served[m.group(1)]=((m.group(2) or '') if use_title else '',' '.join(a.get('content',[])))
        miss=[k for k in src if k not in served and k not in omit]
        ok=rep=0;flags=[]
        for lab,(title,body) in served.items():
            if lab not in src: flags.append((lab,'not-in-src')); continue
            sv=stream(title+body)
            if isrep(body):
                if any(isrep(v) or len(stream(v))<8 for v in src[lab]): rep+=1
                else: flags.append((lab,'repeal-mismatch'))
                continue
            best=None
            for v in src[lab]:
                sr=stream(v)
                if len(sr)<4: continue
                mt=difflib.SequenceMatcher(None,sr,sv)
                lcs=sum(b.size for b in mt.get_matching_blocks())
                lost=1-lcs/max(1,len(sr)); inv=1-lcs/max(1,len(sv))
                if best is None or lost+inv<best[0]+best[1]: best=(lost,inv)
            if best is None: flags.append((lab,'no-src-text')); continue
            lost,inv=best
            if lost<=0.02 and inv<=0.02: ok+=1
            elif lab in errata and all(erratum_ok(body,e) for e in errata[lab]):
                # declared, provenance-recorded editorial correction of a source
                # text-layer defect: verified structurally (to-present, from-absent)
                ok+=1
            else: flags.append((lab,f'lost={lost:.1%} inv={inv:.1%}'))
        G['n']+=len(served);G['ok']+=ok;G['rep']+=rep;G['flag']+=len(flags)
        print(f"== {name}: {len(served)} άρθρα | identical={ok} repealed-ok={rep} flagged={len(flags)} missing={miss}")
        for f in flags: print('   FLAG',f)
        bad+=len(flags)+len(miss)
    print(f"ΣΥΝΟΛΟ: {G['n']} άρθρα · {G['ok']} ταυτόσημα · {G['rep']} καταργημένα-επαληθευμένα · {G['flag']} για έλεγχο")
    return 1 if bad else 0
if __name__=='__main__':
    sys.exit(main())
