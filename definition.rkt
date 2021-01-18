#lang racket
(require redex)

(provide L sub appsub infer check)

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number top false true x (lambda (x) e) (e e) (e doublecomma e) (e : tau));; doublecomma for merge operator
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
  [(sub top tau_3)
   -------------------- "sub-top-arrow"
   (sub tau_1 (tau_2 tau_3))]
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
;; (show-derivations (build-derivations
;;                    (appsub-ambi (empty comma int) ((int -> int) & (bool -> bool)) (int -> int))))
;; (show-derivations (build-derivations
;;                    (appsub-ambi (empty comma int) ((int -> int) & (int -> bool)) tau)))


(define-metafunction L
  stack-type : Psi tau -> tau
  [(stack-type empty tau_1) tau_1]
  [(stack-type (Psi comma tau_1) tau_2) (tau_1 -> (stack-type Psi tau_2))])

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
   (side-condition ,(not (judgment-holds (sub tau_2 (stack-type Psi top)))))
   ;; (side-condition (not (judgment-holds (appsub Psi tau_2 tau_3))))
   -------------------- "appsub-andl"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  [(appsub Psi tau_2 tau_3)
   (side-condition ,(not (judgment-holds (sub tau_1 (stack-type Psi top)))))
   ;; (side-condition (not (judgment-holds (appsub Psi tau_1 tau_3))))
   -------------------- "appsub-andr"
   (appsub Psi (tau_1 & tau_2) tau_3)]
  )



;; justify the rules, uncomment lines below to see ambiuguities
;; check it out, ambi will be rejectd !!!

;; (judgment-holds (appsub (empty comma int) ((int -> int) & (int -> bool)) tau) tau)


(define-metafunction L
  lookup : Gamma x -> tau or #f
  [(lookup (Gamma comma x : tau) x) tau]
  [(lookup (Gamma comma x_1 : tau) x_2) (lookup Gamma x_2)]
  [(lookup empty x) #f])


(define-judgment-form L
  #:mode (infer I I I I O)
  #:contract (infer Gamma Psi e => tau)
  [---------------------------------- "typing-int"
   (infer Gamma empty number => int)]
  [---------------------------------- "typing-top"
   (infer Gamma empty top => top)]
  [---------------------------------- "typing-true"
   (infer Gamma empty true => bool)]
  [---------------------------------- "typing-false"
   (infer Gamma empty false => bool)]
  [(where tau (lookup Gamma x))
   ---------------------------------- "typing-var"
   (infer Gamma empty x => tau)]
  [(infer (Gamma comma x : tau_1) Psi e => tau_2)
   ---------------------------------- "typing-lam-2"
   (infer Gamma (Psi comma tau_1) (lambda (x) e) => (tau_1 -> tau_2))]
  [(appsub Psi tau_1 tau_2)
   (check Gamma empty e <= tau_1)
   ---------------------------------- "typing-anno"
   (infer Gamma Psi (e : tau_1) => tau_2)]
  [(infer Gamma empty e_2 => tau_1)
   (infer Gamma (Psi comma tau_1) e_1 => (tau_1 -> tau_2))
   ---------------------------------- "typing-app-1"
   (infer Gamma Psi (e_1 e_2) => tau_2)]
  [(infer Gamma empty e_1 => tau_1)
   (infer Gamma empty e_2 => tau_2)
   ---------------------------------- "typing-merge"
   (infer Gamma empty (e_1 doublecomma e_2) => (tau_1 & tau_2))]
  )

(define-judgment-form L
  #:mode (check I I I I I)
  #:contract (check Gamma Psi e <= tau)
  [(check (Gamma comma x : tau_1) empty e <= tau_2)
   ---------------------------------- "typing-lam-1"
   (check Gamma empty (lambda (x) e) <= (tau_1 -> tau_2))]
  [(infer Gamma empty e_2 => tau_1)
   (check Gamma empty e_1 <= (tau_1 -> tau_2))
   ---------------------------------- "typing-app-2"
   (check Gamma empty (e_1 e_2) <= tau_2)]
  [(infer Gamma empty e => tau_2)
   (sub tau_2 tau_1)
   ---------------------------------- "typing-sub"
   (check Gamma empty e <= tau_1)]
  )
