#lang racket
(require redex)
(require "definition.rkt")

(test-judgment-holds (sub int top))
(test-judgment-holds (sub (top -> top) (int -> top)))

(test-judgment-holds (infer (empty comma x : int) empty (x : int) => int))
(test-judgment-holds (infer empty (empty comma int) (lambda (x) 1) => (int -> int)))

;; subtyping reflexivity
(define (sub-reflexivity-holds? tau)
  (judgment-holds (sub ,tau ,tau)))
(redex-check L tau (sub-reflexivity-holds? (term tau)))


;; subtyping transitivity
(define-judgment-form L
  #:mode (sub-trans I I I)
  [(sub-trans tau_1 tau_2 tau_3) (sub tau_1 tau_2) (sub tau_2 tau_3)])
(redex-check L #:satisfying (sub-trans tau_1 tau_2 tau_3) (judgment-holds (sub tau_1 tau_3)))


;; appsub to sub

(redex-check L #:satisfying (appsub Psi tau_1 tau_2) (judgment-holds (sub tau_1 tau_2)))

;; appsub reflexivity
;; (judgment-holds (appsub empty (int & int) tau) tau)
;; '((int & int) int)
;; sometimes is includes mul
(define (appsub-reflexivity-holds? Psi-var tau-var)
  (not (equal? (member tau-var (judgment-holds (appsub ,Psi-var ,tau-var tau) tau)) #f)))
(redex-check L (Psi tau) (appsub-reflexivity-holds? (term Psi) (term (stack-type Psi tau))))


;; apparently all number is int, true/false is bool
(redex-check L (Gamma number) (judgment-holds (infer Gamma empty number => int)))
(redex-check L Gamma (judgment-holds (infer Gamma empty true => bool)))
(redex-check L Gamma (judgment-holds (infer Gamma empty false => bool)))
;; all ctx with x : int
(redex-check L (Gamma comma x : int) (judgment-holds (infer (Gamma comma x : int) empty x => int)))
