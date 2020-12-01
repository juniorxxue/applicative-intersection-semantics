#lang racket
(require redex)
(define-language AppL
  (e ::= ;; term
     n ;; int
     x ;; variable
     (λ x e) ;; abstraction
     (e e) ;; application
     (e ◇ e) ;; merge
     (x : A) ;; annotation
     )
  (n ::=
     number)
  (A B C D ::= ;; type
     Int ;; int type
     Bool ;; bool type
     Top ;; top type
     (A → B) ;; function type
     (A & B) ;; intersection type
     )
  (Γ ::=
     · ;; empty
     (Γ ◃ x : A)) ;; bind (x : A) in T

  (Ψ ::=
     · ;; empty
     (Ψ ◃ A)) ;; with argument S : A

  (x ::= variable-not-otherwise-mentioned))

(define-judgment-form AppL
  #:mode (sub I I I)
  #:contract (sub A <: B)
  [--------------- sub_int
   (sub Int <: Int)]
  [--------------- sub_bool
   (sub Bool <: Bool)]
  [--------------- sub_top
   (sub A <: Top)]
  [(sub C <: A)
   (sub B <: D)
   ------------------------ sub_arrow
   (sub (A → B) <: (C → D))]
  [(sub A <: B)
   (sub A <: C)
   --------------------- sub_and
   (sub A <: (B & C))]
  [(sub A <: C)
   --------------------- sub_andl
   (sub (A & B) <: C)]
  [(sub B <: C)
   --------------------- sub_andr
   (sub (A & B) <: C)])

(test-equal (judgment-holds (sub Int <: Top)) #t)
(test-equal (judgment-holds (sub (Top → Top) <: (Int → Top))) #t)

(define-judgment-form AppL
  #:mode (appsub I I I I O)
  #:contract (appsub Ψ ⊢ A <: B)
  [-------------------- appsub_refl
   (appsub · ⊢ A <: A)]
  [(sub C <: A)
   (appsub Ψ ⊢ B <: D)
   ---------------------------- appsub_fun
   (appsub (Ψ ◃ C) ⊢ (A → B) <: (C → D))]
  [(appsub (Ψ ◃ C) ⊢ A <: D)
   ---------------------------- appsub_andl
   (appsub (Ψ ◃ C) ⊢ (A & B) <: D)]

  ;; (judgment-holds (appsub (· ◃ Int) ⊢ ((Int → Int) & (Int → Bool)) <: A) A)
  ;; => '((Int → Bool) (Int → Int))
  ;; ambiguity here !!
  
  
  [(appsub (Ψ ◃ C) ⊢ B <: D)
   ---------------------------- appsub_andr
   (appsub (Ψ ◃ C) ⊢ (A & B) <: D)]
  [(appsub (Ψ ◃ A) ⊢ C <: D)
   --------------------------- appsub_and1
   (appsub (Ψ ◃ (A & B)) ⊢ C <: D)]
  [(appsub (Ψ ◃ B) ⊢ C <: D)
   --------------------------- appsub_and2
   (appsub (Ψ ◃ (A & B)) ⊢ C <: D)]
  )


(test-equal (judgment-holds (appsub · ⊢ Int <: A) A)
            (list (term Int)))
(test-equal (judgment-holds (appsub (· ◃ Int) ⊢ (Int → Int) <: A) A)
            (list (term (Int → Int))))
(test-equal (judgment-holds (appsub (· ◃ Int) ⊢ ((Int → Int) & (Bool → Bool)) <: A) A)
            (list (term (Int → Int))))

;; lemma 5 reflexivity
;; Ψ ⊢ Ψ → A <: Ψ → A

;; ·, Int ⊢ Int -> Int <: Int -> Int
(test-equal (judgment-holds (appsub (· ◃ Int) ⊢ (Int → Int) <: A) A)
            (list (term (Int → Int))))

;; ., Int, Int |- Int -> (Int -> Bool) <: Int -> (Int -> Bool)
;; Attention: right associativity should be considered
(test-equal (judgment-holds (appsub ((· ◃ Int) ◃ Int) ⊢ (Int → (Int → Bool)) <: A) A)
            (list (term (Int → (Int → Bool)))))

;; lemma 6 transitivity
;; Ψ1 ⊢ A <: Ψ1 → B
;; Ψ2 ⊢ B <: Ψ2 → C
;; then Ψ2, Ψ1 ⊢ A <: Ψ1 → Ψ2 → C



;; \Psi
;; \Gam
;; \vdash
;; \Righta

(define-metafunction AppL
  lookup : Γ x -> A
  [(lookup (Γ ◃ x : A) x) A]
  [(lookup (Γ ◃ x_1 : A) x_2) (lookup Γ x_2)]
  [(lookup · x) #f])

(define-judgment-form AppL
  #:mode (app-mode I I I I I O)
  #:contract (app-mode Γ Ψ ⊢ e ⇒ A)
  [------------------------- type_int
   (app-mode Γ Ψ ⊢ n ⇒ Int)]
  
  [(where A (lookup Γ x))
   -------------------------- type_var
   (app-mode Γ Ψ ⊢ x ⇒ A)]
  )


#;(define-judgment-form AppL
  #:mode (check-mode I I I I I)
  #:contract (check-mode Ψ ⊢ e ⇐ A)
  )
  
  
