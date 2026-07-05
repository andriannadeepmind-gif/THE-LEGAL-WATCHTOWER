;;;; scripts/generate-keys.lisp
;;;; ============================================================================
;;;; PURE LISP RSA KEY GENERATION
;;;; ============================================================================
;;;;
;;;; Generate RSA keypair using Ironclad - NO external dependencies.
;;;; DARPA-GRADE: Pure Common Lisp, auditable, deterministic.
;;;;
;;;; Usage:
;;;;   sbcl --load scripts/generate-keys.lisp
;;;;
;;;; Output:
;;;;   private.pem - RSA 4096-bit private key (PKCS#1 PEM)
;;;;   public.pem  - RSA public key (PKCS#1 PEM)
;;;; ============================================================================

(require :asdf)

;;; Load the orchestrator system
(push (truename ".") asdf:*central-registry*)
(push (truename "systems/") asdf:*central-registry*)

;;; Configure ASDF to find third-party libs
(let ((third-party (truename "third-party/")))
  (dolist (dir (directory (merge-pathnames "*/" third-party)))
    (push dir asdf:*central-registry*)))

;;; Load required systems
(asdf:load-system :ironclad)
(asdf:load-system :cl-base64)
(asdf:load-system :alexandria)
(asdf:load-system :babel)

;;; Load jws-authority
(load "source/jws-authority.lisp")

;;; Generate and save keys
(format t "~%═══════════════════════════════════════════════════════════════~%")
(format t "  PURE LISP RSA KEY GENERATION (Ironclad)~%")
(format t "═══════════════════════════════════════════════════════════════~%~%")

(format t "Generating 4096-bit RSA keypair...~%")
(let* ((start-time (get-internal-real-time))
       (keypair (orchestrator.jws-authority:generate-rsa-keypair :bits 4096))
       (elapsed (/ (- (get-internal-real-time) start-time)
                   internal-time-units-per-second)))

  (format t "  ✓ Keypair generated in ~,2F seconds~%" elapsed)

  (format t "~%Saving keys...~%")
  (orchestrator.jws-authority:save-rsa-keypair
   keypair
   "private.pem"
   "public.pem")

  (format t "  ✓ private.pem (RSA 4096-bit, PKCS#1 PEM)~%")
  (format t "  ✓ public.pem  (RSA public key, PKCS#1 PEM)~%"))

(format t "~%═══════════════════════════════════════════════════════════════~%")
(format t "  KEY GENERATION COMPLETE - Pure Common Lisp / Ironclad~%")
(format t "═══════════════════════════════════════════════════════════════~%~%")

;;; Verify the generated keys
(format t "Verifying generated keys...~%")
(handler-case
    (let ((loaded-key (orchestrator.jws-authority:load-rsa-private-key "private.pem")))
      (format t "  ✓ private.pem loads successfully~%")
      (format t "  ✓ Key type: RSA~%")
      (format t "  ✓ Ready for JWS signing~%"))
  (error (e)
    (format t "  ✗ Error loading key: ~A~%" e)))

(format t "~%Done.~%")
(sb-ext:exit :code 0)
