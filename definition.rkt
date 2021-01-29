#lang racket
(require redex)

(provide L sub appsub infer check)

(define-syntax-rule (draw x) (show-derivations (build-derivations x)))
(define-syntax-rule (holds x) (judgment-holds x))
(define-syntax-rule (guess x y) (judgment-holds x y))
(define-syntax-rule (reduce x) (apply-reduction-relation step (term x)))
(define-syntax-rule (reduces x) (apply-reduction-relation* step (term x)))

(define-language L
  (x ::= variable-not-otherwise-mentioned)
  (e ::= number top false true x (lambda (x) e) (e e) (e doublecomma e) (e : tau));; doublecomma for merge operator
  (p ::= number top false true (lambda (x) e) ((lambda (x) e) : (tau -> tau)))
  (v ::= (p : tau) (lambda (x) e) (v doublecomma v))
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


;; (define-metafunction L
;;   stack-to-type : Psi -> tau
;;   [(stack-to-type empty) ]
;;   )

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
   (disjoint tau_1 tau_2)
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

(define-judgment-form L
  #:mode (disjoint I I)
  #:contract (disjoint tau tau)
  [---------------------------------- "disjoint-top-l"
   (disjoint top tau)]
  [---------------------------------- "disjoint-top-r"
   (disjoint tau top)]
  [---------------------------------- "disjoint-int-bool"
   (disjoint int bool)]
  [---------------------------------- "disjoint-bool-int"
   (disjoint bool int)]
  [---------------------------------- "disjoint-int-arr"
   (disjoint int (tau_1 -> tau_2))]
  [---------------------------------- "disjoint-arr-int"
   (disjoint (tau_1 -> tau_2) int)]
  [---------------------------------- "disjoint-bool-arr"
   (disjoint bool (tau_1 -> tau_2))]
  [---------------------------------- "disjoint-arr-bool"
   (disjoint (tau_1 -> tau_2) bool)]
  [(disjoint tau_2 tau_4)
   ---------------------------------- "disjoint-arr"
   (disjoint (tau_1 -> tau_2) (tau_3 -> tau_4))]
  [(disjoint tau_1 tau_3)
   (disjoint tau_2 tau_3)
   ---------------------------------- "disjoint-and-l"
   (disjoint (tau_1 & tau_2) tau_3)]
  [(disjoint tau_1 tau_2)
   (disjoint tau_1 tau_3)
   ---------------------------------- "disjoint-and-r"
   (disjoint tau_1 (tau_2 & tau_3))]
  )

(define-judgment-form L
  #:mode (ordinary I)
  #:contract (ordinary tau)
  [---------------------------------- "ord-top"
   (ordinary top)]
  [---------------------------------- "ord-int"
   (ordinary int)]
  [---------------------------------- "ord-arrow"
   (ordinary (tau_1 -> tau_2))])

(define-judgment-form L
  #:mode (toplike I)
  #:contract (toplike tau)
  [---------------------------------- "tl-top"
   (toplike top)]
  [(toplike tau_1)
   (toplike tau_2)
   ---------------------------------- "tl-and"
   (toplike (tau_1 & tau_2))]
  [(toplike tau_2)
   ---------------------------------- "tl-arrow"
   (toplike (tau_1 -> tau_2))]
  )

(define-judgment-form L
  #:mode (tred I I O)
  #:contract (tred v tau v)
  [---------------------------------- "tred-int"
   (tred (number : int) int (number : int))]
  [---------------------------------- "tred-true"
   (tred (true : bool) bool (true : bool))]
  [---------------------------------- "tred-false"
   (tred (false : bool) bool (false : bool))]
  [(ordinary tau)
   (toplike tau)
   ---------------------------------- "tred-top"
   (tred (e : tau) tau (top : top))]
  [(side-condition (not (judgment-holds (toplike tau_3))))
   (sub tau_3 tau_1)
   (sub tau_2 tau_4)
   ---------------------------------- "tred-arr-anno"
   (tred ((lambda (x) e) : (tau_1 -> tau_2)) (tau_3 -> tau_4) ((lambda (x) e) : (tau_1 -> tau_4)))]
  [(tred e_1 tau e_3)
   (ordinary tau)
   ---------------------------------- "tred-merge-l"
   (tred (e_1 doublecomma e_2) tau e_3)]
  [(tred e_2 tau e_3)
   (ordinary tau)
   ---------------------------------- "tred-merge-r"
   (tred (e_1 doublecomma e_2) tau e_3)]
  [(tred e_1 tau_1 e_2)
   (tred e_1 tau_2 e_3)
   ---------------------------------- "tred-and"
   (tred e_1 (tau_1 & tau_2) (e_2 doublecomma e_3))]
  )

(define step
  (reduction-relation
   L
   #:domain e
   #:codomain e
   (--> number (number : int)
        "step-int-anno")
   (--> true (true : bool)
        "step-true-anno")
   (--> false (false : bool)
        "step-false-anno")
   (--> top (top : top)
        "step-top-anno")
   (--> ((lambda (x) e) v) (substitute e x v)
        "step-beta")
   (--> (((lambda (x) e_1) : (tau_1 -> tau_2)) v_1) (substitute e_1 x v_2)
        (side-condition (judgment-holds (tred v_1 tau_1 v_2)))
        (where v_2 ,(first (judgment-holds (tred v_1 tau_1 v) v)))
        "step-beta-anno")
   ;; (--> (p_1 : tau) (p_2 : tau)
   ;;      (side-condition  (and (judgment-holds (tred p_1 tau p_2))
   ;;                            (equal? #f (redex-match L v (term (p_1 : tau))))))
   ;;      (where p_2 ,(first (judgment-holds (tred p_1 tau p) p)))
        ;; "step-anno-typed")
   (--> ((v_1 doublecomma v_2) (p : tau_1)) (v_1 (p : tau_1))
        (side-condition (let ([merge-tau (first (judgment-holds (infer empty empty (v_1 doublecomma v_2) => tau) tau))])
                          (let ([result-tau (first (judgment-holds (appsub (empty comma tau_1) ,merge-tau tau) tau))])
                            (equal? (term v_1) (first (judgment-holds (tred (v_1 doublecomma v_2) ,result-tau v_3) v_3))))))
        "step-app-merge-l")
   (--> ((v_1 doublecomma v_2) (p : tau_1)) (v_2 (p : tau_1))
        (side-condition (let ([merge-tau (first (judgment-holds (infer empty empty (v_1 doublecomma v_2) => tau) tau))])
                          (let ([result-tau (first (judgment-holds (appsub (empty comma tau_1) ,merge-tau tau) tau))])
                            (equal? (term v_2) (first (judgment-holds (tred (v_1 doublecomma v_2) ,result-tau v_3) v_3))))))
        "step-app-merge-r")
   (--> (e_1 : tau) (e_2 : tau)
        (side-condition (and (not (equal? '() (apply-reduction-relation step (term e_1))))
                             (equal? #f (redex-match L v (term (e_1 : tau))))))
        (where e_2 ,(first (apply-reduction-relation step (term e_1))))
        "step-anno")
   (--> (e_1 e_2) (e_3 e_2)
        (side-condition (not (equal? '() (apply-reduction-relation step (term e_1)))))
        (where e_3 ,(first (apply-reduction-relation step (term e_1))))
        "step-app-l")
   (--> (v e_1) (v e_2)
        (side-condition (not (equal? '() (apply-reduction-relation step (term e_1)))))
        (where e_2 ,(first (apply-reduction-relation step (term e_1))))
        "step-app-r")
   (--> (e_1 doublecomma e_2) (e_3 doublecomma e_2)
        (side-condition (not (equal? '() (apply-reduction-relation step (term e_1)))))
        (where e_3 ,(first (apply-reduction-relation step (term e_1))))
        "step-merge-l")
   (--> (v doublecomma e_1) (v doublecomma e_2)
        (side-condition (not (equal? '() (apply-reduction-relation step (term e_1)))))
        (where e_2 ,(first (apply-reduction-relation step (term e_1))))
        "step-mrege-r")
   ))
