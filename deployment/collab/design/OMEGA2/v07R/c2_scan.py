"""C2 — mechanical delete-the-patches scan.

Claim under test: the reduced kernel contains NO break-specific guard, i.e. its safety comes
from the general laws and not from fourteen special cases. Documentation is not a guard, so
Python comments and string literals are excluded via tokenize, and TLA+ block comments via
their delimiters. Only executable code is scanned.
"""
import io, re, tokenize, pathlib

PAT = re.compile(r"\b([AB]-[1-8])\b")


def py_hits(path):
    out = []
    try:
        toks = tokenize.generate_tokens(io.StringIO(path.read_text()).readline)
        for t in toks:
            if t.type in (tokenize.COMMENT, tokenize.STRING):
                continue
            if PAT.search(t.string):
                out.append((t.start[0], t.string.strip()))
    except Exception as e:
        out.append((0, f"<scan error: {e}>"))
    return out


def tla_hits(path):
    text = re.sub(r"\(\*.*?\*\)", "", path.read_text(), flags=re.S)
    out = []
    for i, line in enumerate(text.splitlines(), 1):
        code = line.split("\\*")[0]
        if PAT.search(code):
            out.append((i, code.strip()))
    return out


def scan(kernel_dir):
    hits = []
    for f in sorted(pathlib.Path(kernel_dir).glob("*.py")):
        hits += [(f.name, i, s) for i, s in py_hits(f)]
    for f in sorted(pathlib.Path(kernel_dir).glob("*.tla")):
        hits += [(f.name, i, s) for i, s in tla_hits(f)]
    return hits
