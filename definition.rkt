#lang racket
(require redex/reduction-semantics)

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number x (lambda (x) e) (e e) (e doublecomma e) (e : tau))
  (tau ::= int top (tau -> tau) (tau & tau))
  (Gamma ::= ((x tau) ...)) ;; type context
  (Psi ::= (tau ...)) ;; stack of args
  #:binding-forms
  (lambda (x) e :refers-to x)
  )
