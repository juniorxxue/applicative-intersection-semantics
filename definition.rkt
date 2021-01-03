#lang racket
(require redex)

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number false true x (lambda (x) e) (e e) (e doublecomma e) (e : tau));; doublecomma for merge operator
  (tau ::= int bool top (tau -> tau) (tau & tau)) ;; & for intersection types
  (Gamma ::= empty (Gamma comma x : tau)) ;; ctx
  (Psi ::= empty (Psi comma tau)) ;; stack of args
  (mode ::= => <=) ;; => for infer and <= for check
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
   (appsub-ambi empty tau tau)]
  [(sub tau_3 tau_1)
   (appsub-ambi Psi tau_2 tau_4)
   -------------------- "appsub-fun"
   (appsub-ambi (Psi comma tau_3) (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(appsub-ambi Psi tau_1 tau_3)
   -------------------- "appsub-andl"
   (appsub-ambi Psi (tau_1 & tau_2) tau_3)]
  [(appsub-ambi Psi tau_2 tau_3)
   -------------------- "appsub-andr"
   (appsub-ambi Psi (tau_1 & tau_2) tau_3)]
  )

;; justify the rules, uncomment lines below to see ambiuguities
;; (show-derivations (build-derivations (appsub-ambi (empty comma int) ((int -> int) & (bool -> bool)) (int -> int))))
;; (show-derivations (build-derivations (appsub-ambi (empty comma int) ((int -> int) & (int -> bool)) tau)))


;; modify the rules of andl, andr
(define-judgment-form L
  #:mode (appsub I I O)
  #:contract (appsub Psi tau tau)
  [-------------------- "appsub-refl"
   (appsub empty tau tau)]
  [(sub tau_3 tau_1)
   (appsub Psi tau_2 tau_4)
   -------------------- "appsub-fun"
   (appsub (Psi comma tau_3) (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(appsub Psi tau_1 tau_3)
   ;; (side-condition (not (judgment-holds (appsub Psi tau_2 tau_3))))
   -------------------- "appsub-andl"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  [(appsub Psi tau_2 tau_3)
   ;; (side-condition (not (judgment-holds (appsub Psi tau_1 tau_3))))
   -------------------- "appsub-andr"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  )

(define-metafunction L
  stack-type : Psi tau -> tau
  [(stack-type empty tau_1) tau_1]
  [(stack-type (Psi comma tau_1) tau_2) (tau_1 -> (stack-type Psi tau_2))])

;; appsub to sub
;; (redex-check L #:satisfying (appsub Psi tau_1 tau_2) (judgment-holds (sub tau_1 tau_2)))

;; appsub reflexivity
;; (judgment-holds (appsub empty (int & int) tau) tau)
;; '((int & int) int)
;; sometimes is includes mul
(define (appsub-reflexivity-holds? Psi-var tau-var)
  (not (equal? (member tau-var (judgment-holds (appsub ,Psi-var ,tau-var tau) tau)) #f)))

;; (redex-check L (Psi tau) (appsub-reflexivity-holds? (term Psi) (term (stack-type Psi tau))))

(define-metafunction L
  lookup : Gamma x -> tau or #f
  [(lookup (Gamma comma x : tau) x) tau]
  [(lookup (Gamma comma x_1 : tau) x_2) (lookup Gamma x_2)]
  [(lookup empty x) #f])

(define-judgment-form L
  #:mode (typeof I I I I O)
  #:contract (typeof Gamma Psi mode e tau)
  [---------------------------------- "typing-int"
   (typeof Gamma empty => number int)]
  [---------------------------------- "typing-true"
   (typeof Gamma empty => true bool)]
  [---------------------------------- "typing-false"
   (typeof Gamma empty => false bool)]
  [(where tau (lookup Gamma x))
   ---------------------------------- "typing-var"
   (typeof Gamma empty => x tau)]
  )

;; apparently all number is int
(redex-check L (Gamma number) (judgment-holds (typeof Gamma empty => number int)))
(redex-check L Gamma (judgment-holds (typeof Gamma empty => true bool)))
(redex-check L Gamma (judgment-holds (typeof Gamma empty => false bool)))
