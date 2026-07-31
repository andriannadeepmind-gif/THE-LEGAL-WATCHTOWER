# =============================================================================
# LEVEL-7 VCCT-RSM — HERMETIC BUILD: Coq / Perennial 2.0 / Goose / GoTxn
# =============================================================================
# ΓΙΑΤΙ ΥΠΑΡΧΕΙ: η απαίτηση 7 ορίζει crash-safe authority store πάνω σε
# Perennial/GoTxn ΜΕ ΑΠΟΔΕΙΞΗ atomicity/recovery. Ρητή απαγόρευση: «Απαγορεύεται
# νέα χειροποίητη append/intent-log authority με crash tests ως τελικό
# υπόστρωμα». Στο παρόν περιβάλλον Coq ΑΠΩΝ + δίκτυο 403 ⇒ EXTERNALLY-BLOCKED.
#
# ΣΥΝΕΠΕΙΑ ΠΟΥ ΤΗΡΕΙΤΑΙ: ΔΕΝ μπήκε προσωρινό intent-log πίσω από το τελικό
# interface. Το production writer παραμένει ΑΠΕΝΕΡΓΟΠΟΙΗΜΕΝΟ. Χτίζονται ΜΟΝΟ:
# schema, pure state-transition model, certificate format, storage API,
# αρνητικά fixtures, και αυτό το hermetic build.
#
# PINNING: όπως στο everparse.Dockerfile — ακριβή commits + sha256 από τον
# δημιουργό. Placeholders ⇒ σκόπιμη αποτυχία (fail-closed).

ARG DEBIAN_DIGEST=debian:bookworm-slim
FROM ${DEBIAN_DIGEST} AS perennial-build

ARG COQ_VERSION=PIN-REQUIRED
ARG PERENNIAL_COMMIT=PIN-REQUIRED
ARG PERENNIAL_SHA256=PIN-REQUIRED
ARG GOOSE_COMMIT=PIN-REQUIRED
ARG GOOSE_SHA256=PIN-REQUIRED
ARG GOTXN_COMMIT=PIN-REQUIRED
ARG GOTXN_SHA256=PIN-REQUIRED

RUN set -e; \
    for p in "$COQ_VERSION" "$PERENNIAL_COMMIT" "$PERENNIAL_SHA256" \
             "$GOOSE_COMMIT" "$GOOSE_SHA256" "$GOTXN_COMMIT" "$GOTXN_SHA256"; do \
      if [ "$p" = "PIN-REQUIRED" ]; then \
        echo "::error::BLOCKED-TOOLCHAIN: pins Coq/Perennial/Goose/GoTxn ΑΣΥΜΠΛΗΡΩΤΑ."; \
        echo "  Καμία εικασία εκδόσεων από μνήμη — fail-closed κατά την εντολή."; \
        exit 1; \
      fi; \
    done

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git make opam ocaml gcc g++ python3 golang \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY toolchain-sources/ /build/sources/
RUN set -e; cd /build/sources; \
    echo "$PERENNIAL_SHA256  perennial.tar.gz" | sha256sum -c -; \
    echo "$GOOSE_SHA256  goose.tar.gz"         | sha256sum -c -; \
    echo "$GOTXN_SHA256  gotxn.tar.gz"         | sha256sum -c -

# --- ΤΟ GATE: το store model ελέγχεται ΑΠΟΔΕΙΚΤΙΚΑ, όχι με crash tests ------
FROM perennial-build AS store-proof
COPY authority-v2/store/ /work/store/
WORKDIR /work
RUN set -e; \
    make -C /work/store proofs        # atomicity + recovery θεωρήματα
# Τα proof artifacts εξάγονται και δηλώνονται στο proof manifest ως PROVED.
# Χωρίς αυτό το στάδιο, η γραμμή 7 του LEVEL7-COMPLETION-MATRIX ΔΕΝ γίνεται
# PROVED με κανέναν άλλο τρόπο — ούτε με 10.000 crash tests.
