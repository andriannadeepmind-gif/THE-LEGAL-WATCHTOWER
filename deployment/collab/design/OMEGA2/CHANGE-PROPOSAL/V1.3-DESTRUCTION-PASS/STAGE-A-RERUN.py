#!/usr/bin/env python3
# STAGE A — ΝΤΕΤΕΡΜΙΝΙΣΤΙΚΗ ΕΠΑΝΕΚΤΕΛΕΣΗ ΤΩΝ ΜΗΧΑΝΙΚΩΝ ΑΝΤΙΠΑΡΑΔΕΙΓΜΑΤΩΝ A1–A4
#
# Τρέξε από τη ρίζα του repo:
#   python3 deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-DESTRUCTION-PASS/STAGE-A-RERUN.py
#
# Τι κάνει (μόνο ανάγνωση του repo· γράφει ΜΟΝΟ τα δύο αρχεία εξόδου δίπλα στο script):
#   1. `git archive <HEAD>` σε ΑΠΟΜΟΝΩΜΕΝΟ προσωρινό κατάλογο (ποτέ στο working tree).
#   2. Επανεκτελεί ΚΑΘΕ `mechanical.command` των COMPLETED-A1..A4.json μέσα στο αντίγραφο
#      (οι απόλυτες διαδρομές /home/user/THE-LEGAL-WATCHTOWER αντιστοιχίζονται στο αντίγραφο).
#   3. Εκτελεί τους ΣΥΓΓΡΑΦΕΙΣ-ΣΤΟ-STAGE-A ελέγχους προκείμενης για τα 4 ARGUMENT-ONLY ευρήματα
#      (ο αντίπαλος δεν έδωσε εντολή· η εντολή εδώ ελέγχει μόνο την ΤΕΚΜΗΡΙΩΣΙΜΗ προκείμενη).
#   4. Συγκρίνει actual με claimed (κανονικοποίηση whitespace + διαδρομών), καταγράφει exit code
#      και SHA-256 του πραγματικού output.
#   5. Γράφει STAGE-A-RERUN-EVIDENCE.json και αποδίδει STAGE-A-ADJUDICATION.md από το
#      STAGE-A-ADJUDICATION.json (η κρίση) + τα τεκμήρια (ΚΑΜΙΑ χειροκίνητη αντιγραφή digests).
# Exit 0 = όλες οι εντολές εκτελέστηκαν και η απόδοση ολοκληρώθηκε. Exit 2 = λείπει είσοδος.
import hashlib, json, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ORIG = '/home/user/THE-LEGAL-WATCHTOWER'
ADVERSARIES = ['A1', 'A2', 'A3', 'A4']

# Έλεγχοι προκείμενης που συνέγραψε ο συντάκτης στο Stage A για τα ARGUMENT-ONLY ευρήματα.
# Κάθε εντολή τυπώνει ΜΟΝΟ γραμμές κειμένου προδιαγραφής και μετρήσεις (grep -c) — καμία κρίση.
AUTHORED_PREMISE_CHECKS = {
    'A1-F11': (
        "V=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md; "
        "C=deployment/LAWMAX-CPEI-TARGET-SPEC.md; "
        "sed -n '270,271p' $V; sed -n '151p;160p;163p' $C; "
        "printf 'public-type restriction on envelope fields in v1.3 s6 (Matter|Case|Client, lines 256-275): %s\\n' "
        "\"$(sed -n '256,275p' $V | grep -c 'Matter\\|Case\\|Client')\""
    ),
    'A1-F12': (
        "M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; "
        "T=deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; "
        "printf 'tree_size in s8.3 (383-423): %s\\n' \"$(sed -n '383,423p' $M | grep -c 'tree_size')\"; "
        "printf 'recency/age bound on revocation checkpoint in MLTP: %s\\n' "
        "\"$(grep -c 'revocation.*max_staleness\\|revocation.*staleness\\|revocation.*recency\\|checkpoint.*age' $M)\"; "
        "sed -n '360p;402p;410p' $M; sed -n '59,61p' $T"
    ),
    'A2-13': (
        "M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; "
        "T=deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; "
        "printf 'tree_size monotonicity rule in s8.3 (383-423): %s\\n' \"$(sed -n '383,423p' $M | grep -c 'tree_size')\"; "
        "printf 'monotone/rollback wording in MLTP: %s\\n' \"$(grep -ci 'monoton\\|rollback\\|older prefix' $M)\"; "
        "sed -n '402p' $M; sed -n '59,61p' $T"
    ),
    'A2-14': (
        "M=deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md; "
        "T=deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md; P=deployment/PROOF-CARRYING-LAW.md; "
        "K=deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md; "
        "sed -n '24,25p' $T; sed -n '108p' $P; sed -n '21,22p' $T; sed -n '33p' $K; "
        "printf 'RSA modulus floor in MLTP: %s\\n' \"$(grep -ci 'modulus\\|RSA-[0-9]' $M)\"; "
        "printf 'Ed25519 verification variant pin in MLTP (RFC 8032|ZIP215|cofactor|small-order): %s\\n' "
        "\"$(grep -c 'RFC 8032\\|RFC8032\\|ZIP215\\|cofactor\\|small-order' $M)\"; "
        "printf 'fingerprint encoding rule in MLTP (DER|SPKI|RFC 7638|JWK thumbprint): %s\\n' "
        "\"$(grep -c 'DER\\|SPKI\\|RFC 7638\\|JWK thumbprint' $M)\"; "
        "printf 'alg<->key-type binding rule in MLTP: %s\\n' "
        "\"$(grep -c 'alg.*key type\\|key type.*alg\\|alg.*matches.*key\\|delegated key.*alg' $M)\""
    ),
}

TARGET_FILES = [
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/MACHINE-LEGAL-TRUST-PROTOCOL.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/CHANGE-PROPOSAL-v1.3.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/PUBLIC-OBSERVATORY-QUALIFICATION-TESTS.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-KILL-WITNESSES.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-SEMANTIC-CROSSWALK.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/SUPERSEDED-REGISTER.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/AS-IS-EVIDENCE-MANIFEST.md',
    'deployment/collab/design/OMEGA2/CHANGE-PROPOSAL/V1.3-CONSISTENCY-AUDIT.sh',
    'deployment/PROOF-CARRYING-LAW.md',
    'deployment/LAWMAX-TRUST-BOOTSTRAP-SPEC.md',
    'deployment/LAWMAX-KEY-LIFECYCLE-SPEC.md',
    'deployment/LAWMAX-UNIVERSAL-SOURCE-CONTRACT.md',
    'deployment/LAWMAX-PROOF-OBJECT-SPEC.md',
    'deployment/LAWMAX-CPEI-TARGET-SPEC.md',
    'deployment/verify/canonical-serialization-spec.md',
    'source/authority-evidence-replay.lisp',
]


def sha256_text(s):
    return hashlib.sha256(s.encode('utf-8')).hexdigest()


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def run(cmd, cwd):
    r = subprocess.run(['bash', '-c', cmd], cwd=cwd, capture_output=True, text=True,
                       env={'PATH': os.environ.get('PATH', '/usr/bin:/bin'),
                            'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8'})
    return r.returncode, r.stdout + r.stderr


def main():
    repo = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True).stdout.strip()
    if not repo:
        print('not inside a git repository', file=sys.stderr); sys.exit(2)
    head = subprocess.run(['git', '-C', repo, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
    tmp = tempfile.mkdtemp(prefix='stageA-')
    copy = os.path.join(tmp, 'repo')
    os.makedirs(copy)
    tar = subprocess.run(['git', '-C', repo, 'archive', head], capture_output=True)
    subprocess.run(['tar', '-x', '-C', copy], input=tar.stdout, check=True)
    try:
        evidence = {'target_commit': head, 'isolated_copy': 'git archive HEAD → tempfile.mkdtemp (deleted after run)',
                    'file_digests': {f: sha256_file(os.path.join(copy, f)) for f in TARGET_FILES},
                    'findings': {}}

        def norm(s):
            return re.sub(r'\s+', ' ', s.replace(copy, REPO_ORIG)).strip()

        for a in ADVERSARIES:
            d = json.load(open(os.path.join(HERE, f'COMPLETED-{a}.json'), encoding='utf-8'))
            for f in d['findings']:
                fid = f['id']
                rec = {'severity_filed': f['severity'], 'kw_ref': f['kw_ref'],
                       'evidence_class_filed': f['evidence_class'], 'title': f['title']}
                m = f.get('mechanical')
                if m:
                    cmd = m['command'].replace(REPO_ORIG, copy)
                    code, out = run(cmd, copy)
                    claimed = m.get('raw_output', '')
                    rec.update({'command_source': 'adversary', 'command': cmd.replace(copy, REPO_ORIG),
                                'exit_code': code, 'actual_output': out, 'claimed_output': claimed,
                                'reproduces_exactly': norm(out) == norm(claimed),
                                'sha256_actual_output': sha256_text(out)})
                elif fid in AUTHORED_PREMISE_CHECKS:
                    cmd = AUTHORED_PREMISE_CHECKS[fid]
                    code, out = run(cmd, copy)
                    rec.update({'command_source': 'stage-A-authored-premise-check', 'command': cmd,
                                'exit_code': code, 'actual_output': out, 'claimed_output': None,
                                'reproduces_exactly': None, 'sha256_actual_output': sha256_text(out)})
                else:
                    rec.update({'command_source': 'none', 'command': None})
                evidence['findings'][fid] = rec
        json.dump(evidence, open(os.path.join(HERE, 'STAGE-A-RERUN-EVIDENCE.json'), 'w', encoding='utf-8'),
                  ensure_ascii=False, indent=1)
        render(evidence)
        n = len(evidence['findings'])
        ok = sum(1 for v in evidence['findings'].values() if v.get('reproduces_exactly') is True)
        dev = sum(1 for v in evidence['findings'].values() if v.get('reproduces_exactly') is False)
        auth = sum(1 for v in evidence['findings'].values() if v.get('command_source') == 'stage-A-authored-premise-check')
        print(f'target={head} findings={n} adversary-commands-exact={ok} adversary-commands-deviating={dev} authored-premise-checks={auth}')
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def render(ev):
    adj = json.load(open(os.path.join(HERE, 'STAGE-A-ADJUDICATION.json'), encoding='utf-8'))
    F = ev['findings']
    L = []
    w = L.append
    w('# STAGE A — ΑΠΟΦΑΣΗ ΤΕΚΜΗΡΙΩΝ (ADJUDICATION RECORD) ΓΙΑ ΤΑ ΔΙΑΤΗΡΗΜΕΝΑ ΕΥΡΗΜΑΤΑ A1–A4')
    w('')
    w('**Αυτόματα αποδιδόμενο** από `STAGE-A-RERUN.py` (τεκμήρια) + `STAGE-A-ADJUDICATION.json` (κρίση). '
      'Μη επεξεργάσιμο χειροκίνητα — κάθε digest προέρχεται από επανεκτέλεση σε απομονωμένο αντίγραφο.')
    w('')
    w(f"- **Στόχος:** commit `{ev['target_commit']}` (`git archive` σε προσωρινό κατάλογο, διαγράφεται μετά).")
    w(f"- **Μέθοδος:** {adj['method']}")
    w(f"- **Εύρος:** {adj['scope']}")
    w(f"- **Τι ΔΕΝ έγινε:** {adj['not_done']}")
    w('')
    w('## 0. Digests των αρχείων-στόχων στο commit')
    w('')
    w('| αρχείο | sha256 |'); w('|---|---|')
    for f, h in ev['file_digests'].items():
        w(f'| `{f}` | `{h}` |')
    w('')
    # summary counts
    statuses = {}
    for fid, a in adj['findings'].items():
        statuses[a['status'].split(':')[0]] = statuses.get(a['status'].split(':')[0], 0) + 1
    rcs = adj['root_causes']
    sev = {}
    for rc in rcs:
        sev[rc['severity_adjudicated']] = sev.get(rc['severity_adjudicated'], 0) + 1
    w('## 1. Σύνοψη')
    w('')
    w(f"- Ευρήματα: **{len(adj['findings'])}** · CONFIRMED **{statuses.get('CONFIRMED',0)}** · "
      f"DUPLICATE_OF **{statuses.get('DUPLICATE_OF',0)}** · REFUTED_FALSE_POSITIVE **{statuses.get('REFUTED_FALSE_POSITIVE',0)}** · "
      f"UNREPRODUCIBLE **{statuses.get('UNREPRODUCIBLE',0)}**.")
    w(f"- Διακριτές ρίζες (root causes): **{len(rcs)}** — " + ' · '.join(f'{k} **{v}**' for k, v in sorted(sev.items())) + '.')
    ex = sum(1 for v in F.values() if v.get('reproduces_exactly') is True)
    dv = [k for k, v in F.items() if v.get('reproduces_exactly') is False]
    au = [k for k, v in F.items() if v.get('command_source') == 'stage-A-authored-premise-check']
    w(f"- Μηχανικές εντολές αντιπάλων: **{ex + len(dv)}** επανεκτελέστηκαν· **{ex}** ταυτόσημο output· "
      f"**{len(dv)}** με απόκλιση μορφής μόνο ({', '.join(dv)}) — βλ. §4.")
    w(f"- ARGUMENT-ONLY ευρήματα με συγγραφέντα έλεγχο προκείμενης στο Stage A: **{len(au)}** ({', '.join(au)}).")
    w(f"- {adj['kw_coverage_note']}")
    w('')
    w('## 2. Πίνακας κατάστασης ανά εύρημα (ακριβώς ΜΙΑ κατάσταση)')
    w('')
    w('| id | sev (filed) | KW | class (filed) | status | root cause | exit | sha256(actual output) |')
    w('|---|---|---|---|---|---|---|---|')
    for fid, a in adj['findings'].items():
        e = F[fid]
        sha = e.get('sha256_actual_output', '—')
        w(f"| `{fid}` | {e['severity_filed']} | {e['kw_ref']} | {e['evidence_class_filed']} | **{a['status']}** | {a['rc']} | "
          f"{e.get('exit_code','—')} | `{sha[:16] if sha!='—' else sha}` |")
    w('')
    w('## 3. Ρίζες (root causes) — ΜΙΑ εγγραφή ανά ρίζα, με το CONFIRMED αντιπροσωπευτικό εύρημα')
    w('')
    w('Για κάθε ρίζα: invariant (τι ισχυρίζεται η σχεδίαση) · ακριβής θέση στην προδιαγραφή · εντολή · exit code · '
      'αναμενόμενο vs πραγματικό · SHA-256 του τεκμηρίου. Το «πραγματικό» είναι ανάγνωση κειμένου, όχι κρίση επιδιόρθωσης.')
    w('')
    for rc in rcs:
        rep = rc['representative']; e = F[rep]
        w(f"### {rc['rc']} — {rc['title']}")
        w('')
        w(f"- **Αντιπροσωπευτικό:** `{rep}` · **μέλη:** {', '.join('`'+m+'`' for m in rc['members'])} · "
          f"**severity (filed / adjudicated):** {e['severity_filed']} / {rc['severity_adjudicated']}")
        w(f"- **Invariant:** {rc['invariant']}")
        w(f"- **Θέση spec:** {rc['spec_location']}")
        w(f"- **Αναμενόμενο (κατά το spec/witness):** {rc['expected']}")
        w(f"- **Πραγματικό (κείμενο ως έχει):** {rc['actual']}")
        if rc.get('note'):
            w(f"- **Σημείωση Stage A:** {rc['note']}")
        w(f"- **Εντολή ({e['command_source']}):**")
        w('```'); w(e['command']); w('```')
        w(f"- **Exit code:** `{e['exit_code']}` · **SHA-256(actual output):** `{e['sha256_actual_output']}` · "
          f"**ταυτόσημο με claimed:** {e['reproduces_exactly'] if e['reproduces_exactly'] is not None else 'n/a (authored)'}")
        w('- **Πραγματικό output:**')
        w('```'); w(e['actual_output'].rstrip('\n')); w('```')
        w('')
    w('## 4. Αποκλίσεις επανεκτέλεσης (μορφή μόνο — καμία ουσιαστική)')
    w('')
    for d in adj['rerun_deviations']:
        w(f"- `{d['id']}`: {d['deviation']}")
    w('')
    w('## 5. DUPLICATE_OF — υπόλειμμα που διατηρείται στη ρίζα')
    w('')
    for fid, a in adj['findings'].items():
        if a['status'].startswith('DUPLICATE_OF'):
            w(f"- `{fid}` → **{a['status']}** ({a['rc']}): {a['note']}")
    w('')
    w('## 6. Τι ΔΕΝ αποδεικνύει αυτό το record')
    w('')
    for x in adj['limits']:
        w(f'- {x}')
    w('')
    with open(os.path.join(HERE, 'STAGE-A-ADJUDICATION.md'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(l.rstrip() for l in '\n'.join(L).split('\n')))  # rendering only: no trailing whitespace in Markdown


if __name__ == '__main__':
    main()
