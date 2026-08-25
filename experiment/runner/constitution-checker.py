#!/usr/bin/env python3
"""ΠΥΛΗ ΣΥΝΤΑΓΜΑΤΟΣ — απορρίπτει ΚΑΘΕ διαφορετική ordering/pruning policy.

Δύο ανεξάρτητοι έλεγχοι:
 ① ΤΑΥΤΟΤΗΤΑ: το sha256 του Συντάγματος ΠΡΕΠΕΙ να ταιριάζει με το σφραγισμένο.
   Οποιαδήποτε μεταβολή objectives/διάταξης/κριτηρίων ⇒ ΑΠΟΡΡΙΨΗ.
 ② ΠΕΡΙΕΧΟΜΕΝΟ: σαρώνει κάθε policy/evaluation artifact για ΑΠΑΓΟΡΕΥΜΕΝΕΣ
   κατασκευές κατάταξης/κλαδέματος (§6, §9, §12) και για την ΑΠΟΡΡΙΦΘΕΙΣΑ
   λεξικογραφική V1→V9.
Exit 0 μόνο αν ΚΑΙ ΤΑ ΔΥΟ περνούν. Καμία προειδοποίηση — fail-closed.
"""
import hashlib, json, re, sys, os

SEALED = "5b3ab5bf9561d535adbf5049b975ac2ab8e9a63db32dfb14a07d82d78b729be6"
CONST  = "experiment/OBJECTIVE-CONSTITUTION.json"

FORBIDDEN_RANKING = [
    (r"\bfeature[ _-]?count\b",              "§6 feature count ως κατάταξη"),
    (r"\bscalar[ _-]?score\b",               "§6 scalar score"),
    (r"weighted[ _-]?average",               "§6 αθροιστικό weighted average"),
    (r"\bllm[ _-]?(score|βαθμολογ)",         "§6/§12 LLM βαθμολογία"),
    (r"αριθμ[όο]ς?\s+proofs",                "§6 αριθμός proofs ως κατάταξη"),
    (r"αριθμ[όο]ς?\s+tests",                 "§6 αριθμός tests ως κατάταξη"),
    (r"V1\s*(→|->)\s*V2\s*(→|->)\s*V3",      "ΑΠΟΡΡΙΦΘΕΙΣΑ λεξικογραφική V1→V9"),
    (r"verifiability\s*(→|->)\s*proof\s*(→|->)\s*error",
                                             "ΑΠΟΡΡΙΦΘΕΙΣΑ διάταξη verifiability→proof→error-class"),
]
FORBIDDEN_PRUNING = [
    (r"prun\w*\s+(by|on)\s+(cost|budget|time|token)", "§12 pruning με κόστος/χρόνο/tokens"),
    (r"stagnation\s*(⇒|=>|->)\s*(close|final)",       "§12 stagnation ως closure"),
    (r"fixed\s+number\s+of\s+rounds\s*(⇒|=>|->)",     "§12 σταθερός αριθμός γύρων"),
    (r"consensus\s*(⇒|=>|->)\s*(winner|final)",       "§12 LLM consensus"),
    (r"(δεν\s+βρ[έε]θηκε\s+κ[άα]τι\s+καλ[ύυ]τερο|no\s+better\s+solution\s+found)",
                                                       "§12 «δεν βρέθηκε κάτι καλύτερο»"),
    (r"simplicity\s*(⇒|=>|->)\s*(prefer|win)",        "§9 απλότητα ως πλεονέκτημα χωρίς semantic compression"),
]


PROHIBITION_KEY = re.compile(
    r'(:forbidden[a-z-]*|"forbidden_[a-z_]*"|:excluded[a-z-]*|"excluded_[a-z_]*"'
    r'|"not_seeking"|:apagoreymen[a-z-]*|"s12_forbidden[a-z_]*"|"prohibition")',
    re.I)

def strip_prohibition_blocks(text):
    """ΔΟΜΙΚΟΣ ΔΙΑΧΩΡΙΣΜΟΣ: ένα κείμενο που ΑΠΑΡΙΘΜΕΙ τις απαγορεύσεις δεν τις
    ΕΦΑΡΜΟΖΕΙ. Μηδενίζουμε τα blocks που ανήκουν σε κλειδί-απαγόρευσης, με
    αντιστοίχιση παρενθέσεων/αγκυλών, και σαρώνουμε ΜΟΝΟ ό,τι δηλώνει πολιτική.
    Έτσι ο έλεγχος δεν αυτοπυροβολείται και δεν χαλαρώνει: ό,τι είναι εκτός
    block εξακολουθεί να ελέγχεται πλήρως."""
    out, i, n = [], 0, len(text)
    while i < n:
        m = PROHIBITION_KEY.search(text, i)
        if not m:
            out.append(text[i:]); break
        out.append(text[i:m.start()])
        j = m.end()
        # ο opener μπορεί να είναι σε ΕΠΟΜΕΝΗ γραμμή (μορφή sexp/JSON με νέα
        # γραμμή μετά το κλειδί) — προσπερνάμε ΜΟΝΟ κενά και «:» της JSON
        while j < n and text[j] in " \t\r\n:":
            j += 1
        if j >= n or text[j] not in "([":
            i = m.end(); continue
        opener, closer = text[j], ")" if text[j] == "(" else "]"
        depth, k = 0, j
        while k < n:
            if text[k] == opener: depth += 1
            elif text[k] == closer:
                depth -= 1
                if depth == 0: break
            k += 1
        i = k + 1
    return "".join(out)

def fail(msg):
    print(f"::error::{msg}"); return 1

def main():
    rc = 0
    if not os.path.exists(CONST):
        return fail("ΑΠΩΝ το σφραγισμένο Σύνταγμα")
    h = hashlib.sha256(open(CONST, "rb").read()).hexdigest()
    if h != SEALED:
        rc |= fail(f"ΤΑΥΤΟΤΗΤΑ: {h} ≠ σφραγισμένο {SEALED} — το Σύνταγμα ΤΡΟΠΟΠΟΙΗΘΗΚΕ")
    else:
        print(f"① ΤΑΥΤΟΤΗΤΑ ΣΥΝΤΑΓΜΑΤΟΣ: OK ({h[:16]}…)")

    d = json.load(open(CONST, encoding="utf-8"))
    if not d.get("sealed"):
        rc |= fail("Το Σύνταγμα δεν είναι sealed")
    if d.get("s7_winner_condition", {}).get("kind","").startswith("GREATEST") is False:
        rc |= fail("§7 ΑΛΛΟΙΩΘΗΚΕ: απαιτείται GREATEST feasible capability element")

    targets = [p for p in sys.argv[1:] if os.path.isfile(p)]
    hits = 0
    for p in targets:
        txt = strip_prohibition_blocks(open(p, encoding="utf-8", errors="replace").read()).lower()
        for pat, why in FORBIDDEN_RANKING + FORBIDDEN_PRUNING:
            if re.search(pat, txt, re.I):
                print(f"  ΑΠΑΓΟΡΕΥΜΕΝΟ [{p}]: {why}"); hits += 1
    if hits:
        rc |= fail(f"② ΠΕΡΙΕΧΟΜΕΝΟ: {hits} απαγορευμένες κατασκευές κατάταξης/κλαδέματος")
    else:
        print(f"② ΠΕΡΙΕΧΟΜΕΝΟ: OK ({len(targets)} artifacts σαρώθηκαν)")
    return rc

sys.exit(main())
