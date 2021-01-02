#lang racket
(require redex)

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number x (lambda (x) e) (e e) (e doublecomma e) (e : tau)) ;; doublecomma for merge operator
  (tau ::= int top (tau -> tau) (tau & tau)) ;; & for intersection types
  (Gamma ::= ((x tau) ...)) ;; type context
  (Psi ::= (tau ...)) ;; stack of args
  #:binding-forms
  (lambda (x) e :refers-to x)
  )

(default-language)

(define-judgment-form L
  #:mode (sub I I)
  #:contract (sub tau tau)
  [-------------------- "sub-int"
   (sub int int)]
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

(redex-check L tau (sub-reflexivity-holds? (term tau)))

;; subtyping transitivity

(define-judgment-form L
  #:mode (sub-trans I I I)
  [(sub-trans tau_1 tau_2 tau_3) (sub tau_1 tau_2) (sub tau_2 tau_3)]
  )

(redex-check L #:satisfying (sub-trans tau_1 tau_2 tau_3) (judgment-holds (sub tau_1 tau_3)))
