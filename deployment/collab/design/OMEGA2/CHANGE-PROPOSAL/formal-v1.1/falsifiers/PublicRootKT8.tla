---- MODULE PublicRootKT8 ----
EXTENDS PublicRoot
\* §1.2(a): κανένας δημοσιευμένος ισχυρισμός χωρίς official source.
INV_NoPublishWithoutEvidence == \A c \in Claims : published[c] => official[c]
====
