#!/usr/bin/env python3
"""ΔΕΥΤΕΡΗ, ΓΝΗΣΙΑ ΑΝΕΞΑΡΤΗΤΗ ΟΙΚΟΓΕΝΕΙΑ ΜΕΤΡΗΣΗΣ — αναγνώστης s-expressions.

ΓΙΑΤΙ ΥΠΑΡΧΕΙ (κανόνας R5): η πρώτη μου σάρωση ήταν regex, και το census του
ίδιου του corpus είναι επίσης γραμμένο με ripgrep. ΔΥΟ REGEX ΔΕΝ ΕΙΝΑΙ ΔΥΟ
ΟΙΚΟΓΕΝΕΙΕΣ — μοιράζονται την ίδια τυφλότητα: πολυγραμμικές μορφές, συμβολοσειρές,
σχόλια, χαρακτήρες #\( .

Εδώ η μέτρηση γίνεται με ΔΙΑΦΟΡΕΤΙΚΟ ΟΡΙΣΜΟ: το αρχείο τεμαχίζεται σε πραγματικά
tokens Common Lisp (με σεβασμό σε "…", ;…, #|…|#, #\χ, '`,) και μετράει ΘΕΣΕΙΣ
ΚΛΗΣΗΣ — δηλαδή σύμβολο στην ΚΕΦΑΛΗ λίστας. Ένα `uiop:run-program` μέσα σε
συμβολοσειρά ή σχόλιο ΔΕΝ είναι κλήση και δεν μετριέται. Ένα που απλώνεται σε
πέντε γραμμές μετριέται ΜΙΑ φορά, στη γραμμή της κεφαλής.

Η διαφορά των δύο μετρήσεων ΕΙΝΑΙ ΤΟ ΑΠΟΤΕΛΕΣΜΑ: όπου συμφωνούν, ενισχύεται·
όπου διαφέρουν, ονομάζεται ο λόγος.
"""
import json
import os
import sys

RO = "/frozen/ro"

TARGETS = {
    "os-exec":      {"uiop:run-program", "uiop:launch-program", "sb-ext:run-program"},
    "eval":         {"eval", "sb-ext:eval-in-lexenv"},
    "dyn-resolve":  {"intern", "find-symbol", "symbol-function", "funcall", "apply"},
    "read":         {"read", "read-from-string", "with-standard-io-syntax"},
    "silent":       {"ignore-errors"},
    "write-seat":   {"with-open-file", "with-output-to-string"},
    "destructive":  {"delete-file", "sb-posix:unlink", "uiop:delete-directory-tree"},
    "env":          {"uiop:getenv", "sb-posix:getenv", "sb-ext:posix-getenv"},
}
LOOKUP = {sym: cls for cls, syms in TARGETS.items() for sym in syms}

WHITESPACE = " \t\n\r\f"
TERMINATING = '()\'"`,;'


def tokenize(text):
    """Παράγει (token, line, is_open_paren). Σέβεται strings, σχόλια, #| |#, #\\χ."""
    i, n, line = 0, len(text), 1
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1; i += 1; continue
        if c in WHITESPACE:
            i += 1; continue
        if c == ";":                                   # σχόλιο μέχρι τέλος γραμμής
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "#" and i + 1 < n:
            nxt = text[i + 1]
            if nxt == "|":                             # μπλοκ σχόλιο, με φώλιασμα
                depth, i = 1, i + 2
                while i < n and depth:
                    if text.startswith("|#", i):
                        depth -= 1; i += 2
                    elif text.startswith("#|", i):
                        depth += 1; i += 2
                    else:
                        if text[i] == "\n": line += 1
                        i += 1
                continue
            if nxt == "\\":                            # #\χ — ο χαρακτήρας ΔΕΝ είναι σύνταξη
                i += 2
                while i < n and text[i] not in WHITESPACE and text[i] not in TERMINATING:
                    i += 1
                continue
        if c == '"':                                   # συμβολοσειρά με escapes
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2; continue
                if text[i] == '"':
                    i += 1; break
                if text[i] == "\n":
                    line += 1
                i += 1
            continue
        if c == "(":
            yield ("(", line, True); i += 1; continue
        if c == ")":
            yield (")", line, False); i += 1; continue
        if c in "'`,":
            i += 1; continue
        j = i                                          # άτομο / σύμβολο
        while j < n and text[j] not in WHITESPACE and text[j] not in TERMINATING:
            j += 1
        yield (text[i:j], line, False)
        i = j if j > i else i + 1


def scan(path):
    """Επιστρέφει [(κλάση, σύμβολο, γραμμή)] ΜΟΝΟ για σύμβολα σε ΚΕΦΑΛΗ λίστας."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return []
    out, expect_head = [], False
    for tok, line, is_open in tokenize(text):
        if is_open:
            expect_head = True
            continue
        if tok == ")":
            expect_head = False
            continue
        if expect_head:
            sym = tok.lower()
            cls = LOOKUP.get(sym)
            if cls:
                out.append((cls, sym, line))
            expect_head = False
    return out


def main():
    out_path = sys.argv[1]
    roots = ("source", "systems", "authority-v2", "tests", "docker", "scripts")
    rows, files = [], 0
    for root in roots:
        base = os.path.join(RO, root)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames.sort()
            for fn in sorted(filenames):
                if not fn.endswith((".lisp", ".asd")):
                    continue
                full = os.path.join(dirpath, fn)
                rel = os.path.relpath(full, RO)
                files += 1
                for cls, sym, line in scan(full):
                    rows.append((cls, sym, rel, line))

    by_cls = {}
    for cls, sym, rel, line in rows:
        by_cls.setdefault(cls, []).append((sym, rel, line))

    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(";;;; experiment/phase1a/sexp-census.sexp — ΔΕΥΤΕΡΗ ΟΙΚΟΓΕΝΕΙΑ ΜΕΤΡΗΣΗΣ\n")
        fh.write(";;;; Αναγνώστης s-expressions, ΟΧΙ regex. Μετρά ΘΕΣΕΙΣ ΚΛΗΣΗΣ\n")
        fh.write(";;;; (σύμβολο σε κεφαλή λίστας). Συμβολοσειρές, σχόλια και #\\χ ΔΕΝ μετρούν.\n\n")
        fh.write("(:lawmax-sexp-census/1\n")
        fh.write(' :corpus "e621dbe1d00f3a18039b63fc0dfc3ff08ce21a03"\n')
        fh.write(f" :files-parsed {files}\n")
        fh.write(" :method \"tokenizer Common Lisp· κλήση = σύμβολο σε κεφαλή λίστας\"\n")
        fh.write(" :counts (" + " ".join(f"(:{c} {len(v)})" for c, v in sorted(by_cls.items())) + ")\n")
        for cls in sorted(by_cls):
            fh.write(f"\n :{cls}\n  (")
            for sym, rel, line in by_cls[cls]:
                fh.write(f'("{rel}:{line}" "{sym}")\n   ')
            fh.write(")\n")
        fh.write(")\n")

    print(json.dumps({"files_parsed": files,
                      **{c: len(v) for c, v in sorted(by_cls.items())}}, ensure_ascii=False))

main()
