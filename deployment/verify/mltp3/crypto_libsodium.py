"""crypto_libsodium.py — builder-side Ed25519 via the VETTED libsodium library
(23.3.0) through a thin ctypes binding. NO homemade cryptography: the primitive
is libsodium's `crypto_sign_*`. Used ONLY by build_fixtures.py (the deterministic
builder). Neither Verifier A (Go) nor Verifier B (Node) imports this module — the
two verifiers share only schemas.json and the immutable fixtures.

Fail-closed: if libsodium is not loadable, raises CryptoBackendUnavailable so the
builder aborts. A verifier that cannot load its own vetted backend must emit the
typed result CRYPTO_BACKEND_UNAVAILABLE and never accept a signature.
"""
import base64
import ctypes
import hashlib

SODIUM_NAMES = ("libsodium.so.23", "libsodium.so", "libsodium.so.26")


class CryptoBackendUnavailable(RuntimeError):
    pass


def _load():
    last = None
    for name in SODIUM_NAMES:
        try:
            lib = ctypes.CDLL(name)
            if lib.sodium_init() < 0:
                raise CryptoBackendUnavailable("sodium_init failed")
            return lib, name
        except OSError as e:  # pragma: no cover
            last = e
    raise CryptoBackendUnavailable(f"libsodium not loadable: {last}")


_LIB, _LIBNAME = _load()
_LIB.sodium_version_string.restype = ctypes.c_char_p
_LIB.sodium_library_version_major.restype = ctypes.c_int
_LIB.sodium_library_version_minor.restype = ctypes.c_int


def backend_info() -> dict:
    """Real evidence (C1.3): release version from sodium_version_string(), not the
    soname/filename. Also the loaded object path and the ABI major.minor."""
    import os
    soname = _LIBNAME
    path = soname
    for base in ("/usr/lib/x86_64-linux-gnu", "/lib/x86_64-linux-gnu"):
        cand = os.path.join(base, soname)
        if os.path.exists(cand):
            path = os.path.realpath(cand)
            break
    return {"library": "libsodium",
            "release_version": _LIB.sodium_version_string().decode(),
            "soname": soname,
            "loaded_path": path,
            "abi": "%d.%d" % (_LIB.sodium_library_version_major(), _LIB.sodium_library_version_minor())}


def backend_id() -> str:
    b = backend_info()
    return "libsodium %s (soname %s, ABI %s)" % (b["release_version"], b["soname"], b["abi"])


def b64u(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).decode().rstrip("=")


def keypair_from_seed(seed: bytes):
    """seed(32) -> (public_bytes(32), secret_bytes(64)). Deterministic."""
    if len(seed) != 32:
        raise ValueError("seed must be 32 bytes")
    pk = ctypes.create_string_buffer(32)
    sk = ctypes.create_string_buffer(64)
    if _LIB.crypto_sign_seed_keypair(pk, sk, seed) != 0:
        raise CryptoBackendUnavailable("crypto_sign_seed_keypair failed")
    return pk.raw, sk.raw


def sign(secret64: bytes, msg: bytes) -> bytes:
    sig = ctypes.create_string_buffer(64)
    slen = ctypes.c_ulonglong(0)
    if _LIB.crypto_sign_detached(sig, ctypes.byref(slen), msg,
                                 ctypes.c_ulonglong(len(msg)), secret64) != 0:
        raise CryptoBackendUnavailable("crypto_sign_detached failed")
    return sig.raw


def verify(public32: bytes, msg: bytes, sig: bytes) -> bool:
    if len(sig) != 64 or len(public32) != 32:
        return False
    return _LIB.crypto_sign_verify_detached(sig, msg, ctypes.c_ulonglong(len(msg)),
                                            public32) == 0


def ed25519_thumbprint(public32: bytes) -> str:
    """RFC 7638 JWK thumbprint (SHA-256, base64url no pad) — same convention as
    deployment/verify/verify-authority-bundle.py:ed25519_jwk_thumbprint."""
    canon = '{"crv":"Ed25519","kty":"OKP","x":"%s"}' % b64u(public32)
    return b64u(hashlib.sha256(canon.encode("utf-8")).digest())


if __name__ == "__main__":
    # RFC 8032 TEST 2 — official vector, confirmed identically by Go + Node in run.sh.
    seed = bytes.fromhex("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb")
    pk, sk = keypair_from_seed(seed)
    assert pk.hex() == "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c"
    sig = sign(sk, bytes.fromhex("72"))
    assert sig.hex() == ("92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da"
                         "085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00")
    assert verify(pk, bytes.fromhex("72"), sig)
    print(f"crypto_libsodium: RFC 8032 TEST 2 OK — backend {backend_id()}")
