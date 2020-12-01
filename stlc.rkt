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
  (Γ ::= ;; context
     · ;; empty
     (Γ ◃ x : A)) ;; bind (x : A) in T

  (ψ ::= ;; arguments given
     · ;; empty
     (ψ ◃ A)) ;; with argument S : A

  (x ::= variable-not-otherwise-mentioned))

(define-judgment-form AppL
  #:mode (subtype I I I)
  #:contract (subtype A <: B)
  [--------------- sub_int
   (subtype Int <: Int)]
  [--------------- sub_top
   (subtype A <: Top)]
  [(subtype C <: A)
   (subtype B <: D)
   ------------------------ sub_arrow
   (subtype (A → B) <: (C → D))]
  [(subtype A <: B)
   (subtype A <: C)
   --------------------- sub_and
   (subtype A <: (B & C))]
  [(subtype A <: C)
   --------------------- sub_andl
   (subtype (A & B) <: C)]
  [(subtype B <: C)
   --------------------- sub_andr
   (subtype (A & B) <: C)])

(test-equal (judgment-holds (subtype Int <: Top)) #t)
(test-equal (judgment-holds (subtype (Top → Top) <: (Int → Top))) #t)

(define-judgment-form AppL
  #:mode (appsub I I I I O)
  #:contract (appsub ψ ⊢ A <: B)
  [-------------------- appsub_refl
   (appsub · ⊢ A <: A)]
  [(subtype C <: A)
   (appsub ψ ⊢ B <: D)
   ---------------------------- appsub_fun
   (appsub (ψ ◃ C) ⊢ (A → B) <: D)]
  [(appsub (ψ ◃ C) ⊢ A <: D)
   ---------------------------- appsub_andl
   (appsub (ψ ◃ C) ⊢ (A & B) <: D)]
  [(appsub (ψ ◃ C) ⊢ B <: D)
   ---------------------------- appsub_andr
   (appsub (ψ ◃ C) ⊢ (A & B) <: D)]
  [(appsub (ψ ◃ A) ⊢ C <: D)
   --------------------------- appsub_and1
   (appsub (ψ ◃ (A & B)) ⊢ C <: D)]
  [(appsub (ψ ◃ B) ⊢ C <: D)
   --------------------------- appsub_and2
   (appsub (ψ ◃ (A & B)) ⊢ C <: D)]
  )

(test-equal (judgment-holds (appsub · ⊢ Int <: A) A)
            (list (term Int)))
(test-equal (judgment-holds (appsub (· ◃ Int) ⊢ (Int → Int) <: A) A)
            (list (term Int)))
(test-equal (judgment-holds (appsub (· ◃ Int) ⊢ ((Int → Int) & (Bool → Bool)) <: A) A)
            (list (term Int)))
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
  
  
