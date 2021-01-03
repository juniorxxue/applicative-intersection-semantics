#lang racket
(require redex)

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number x (lambda (x) e) (e e) (e doublecomma e) (e : tau)) ;; doublecomma for merge operator
  (tau ::= int bool top (tau -> tau) (tau & tau)) ;; & for intersection types
  (Gamma ::= ((x tau) ...)) ;; type context
  (Psi ::= (tau ...)) ;; stack of args
  #:binding-forms
  (lambda (x) e :refers-to x)
  )

(default-language L)

(define-judgment-form L
  #:mode (sub I I)
  #:contract (sub tau tau)
  [-------------------- "sub-int"
   (sub int int)]
  [-------------------- "sub-bool"
   (sub bool bool)]
  [-------------------- "sub-top"
   (sub tau top)]
  [(sub tau_3 tau_1)
   (sub tau_2 tau_4)
   -------------------- "sub-arrow"
   (sub (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(sub tau_1 tau_2)
   (sub tau_1 tau_3)
   -------------------- "sub-and"
   (sub tau_1 (tau_2 & tau_3))]
  [(sub tau_1 tau_3)
   -------------------- "sub-andl"
   (sub (tau_1 & tau_2) tau_3)]
  [(sub tau_2 tau_3)
   -------------------- "sub-andr"
   (sub (tau_1 & tau_2) tau_3)]
  )

(test-judgment-holds (sub int top))
(test-judgment-holds (sub (top -> top) (int -> top)))

;; subtyping reflexivity

(define (sub-reflexivity-holds? tau)
  (judgment-holds (sub ,tau ,tau)))

;; (redex-check L tau (sub-reflexivity-holds? (term tau)))

;; subtyping transitivity

(define-judgment-form L
  #:mode (sub-trans I I I)
  [(sub-trans tau_1 tau_2 tau_3) (sub tau_1 tau_2) (sub tau_2 tau_3)]
  )

;; (redex-check L #:satisfying (sub-trans tau_1 tau_2 tau_3) (judgment-holds (sub tau_1 tau_3)))

;; applicative subtyping
(define-judgment-form L
  #:mode (appsub-ambi I I O)
  #:contract (appsub-ambi Psi tau tau)
  [-------------------- "appsub-refl"
   (appsub-ambi () tau tau)]
  [(sub tau_3 tau_1)
   (appsub-ambi (tau ...) tau_2 tau_4)
   -------------------- "appsub-fun"
   (appsub-ambi (tau_3 tau ...) (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(appsub-ambi Psi tau_1 tau_3)
   -------------------- "appsub-andl"
   (appsub-ambi Psi (tau_1 & tau_2) tau_3)]
  [(appsub-ambi Psi tau_2 tau_3)
   -------------------- "appsub-andr"
   (appsub-ambi Psi (tau_1 & tau_2) tau_3)]
  )

;; justify the rules, uncomment lines below to see ambiuguities
;; (show-derivations (build-derivations (appsub-ambi (int) ((int -> int) & (bool -> bool)) (int -> int))))
;; (show-derivations (build-derivations (appsub-ambi (int) ((int -> int) & (int -> bool)) tau)))


;; modify the rules of andl, andr
(define-judgment-form L
  #:mode (appsub I I O)
  #:contract (appsub Psi tau tau)
  [-------------------- "appsub-refl"
   (appsub () tau tau)]
  [(sub tau_3 tau_1)
   (appsub (tau ...) tau_2 tau_4)
   -------------------- "appsub-fun"
   (appsub (tau_3 tau ...) (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(appsub Psi tau_1 tau_3)
   -------------------- "appsub-andl"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  [(appsub Psi tau_2 tau_3)
   -------------------- "appsub-andr"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  )
