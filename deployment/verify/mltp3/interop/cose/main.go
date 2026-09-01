// COSE_Sign1 interoperability vector (C1.4) using the VETTED, independently
// maintained veraison/go-cose (pinned v1.3.0). NEVER hand-rolls CBOR/COSE.
// Produces and verifies a real COSE_Sign1 over the EXACT MLTP canonical payload
// bytes. Demonstrates that MLTP canonical-JSON signatures and COSE_Sign1 are
// DISTINCT signature constructions (different signed bytes, different container).
//
// modes:
//   go run . make <payload-file> <out.cose>   -> Ed25519 COSE_Sign1 over file bytes
//   go run . verify <payload-file> <in.cose>  -> exit 0 iff valid; 1 iff not
package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"fmt"
	"os"

	"github.com/veraison/go-cose"
)

// deterministic test key from a fixed seed (test-only; not a trusted key)
var seed = []byte("mltp3-cose-interop-seed-32byteslen!!")[:32]

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "usage: make|verify <payload> <cose>")
		os.Exit(2)
	}
	mode, payloadFile, coseFile := os.Args[1], os.Args[2], os.Args[3]
	payload, err := os.ReadFile(payloadFile)
	must(err)
	priv := ed25519.NewKeyFromSeed(seed)
	pub := priv.Public().(ed25519.PublicKey)

	switch mode {
	case "make":
		signer, err := cose.NewSigner(cose.AlgorithmEd25519, priv)
		must(err)
		msg := cose.NewSign1Message()
		msg.Payload = payload
		msg.Headers.Protected.SetAlgorithm(cose.AlgorithmEd25519)
		must(msg.Sign(rand.Reader, nil, signer))
		der, err := msg.MarshalCBOR()
		must(err)
		must(os.WriteFile(coseFile, der, 0644))
		fmt.Printf("COSE_Sign1 written (%d bytes) alg=Ed25519 over %d payload bytes\n", len(der), len(payload))
	case "verify":
		der, err := os.ReadFile(coseFile)
		must(err)
		var msg cose.Sign1Message
		if err := msg.UnmarshalCBOR(der); err != nil {
			fmt.Fprintln(os.Stderr, "unmarshal:", err)
			os.Exit(1)
		}
		verifier, err := cose.NewVerifier(cose.AlgorithmEd25519, pub)
		must(err)
		// bind to the exact MLTP payload bytes
		if string(msg.Payload) != string(payload) {
			fmt.Fprintln(os.Stderr, "payload mismatch: COSE payload != MLTP canonical bytes")
			os.Exit(1)
		}
		if err := msg.Verify(nil, verifier); err != nil {
			fmt.Fprintln(os.Stderr, "verify:", err)
			os.Exit(1)
		}
		fmt.Println("COSE_Sign1 verified (veraison/go-cose, Ed25519) over exact MLTP payload bytes")
	default:
		os.Exit(2)
	}
}

func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
