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
  (T ::= ;; context
     · ;; empty
     (T x : A)) ;; bind (x : A) in T

  (S ::= ;; arguments given
     · ;; empty
     (S : A)) ;; with argument S : A

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
  #:contract (appsub S ⊢ A <: B)
  [-------------------- appsub_refl
   (appsub · ⊢ A <: A)]
  [(subtype C <: A)
   (appsub S ⊢ B <: D)
   ---------------------------- appsub_fun
   (appsub (S : C) ⊢ (A → B) <: D)]
  [(appsub (S : C) ⊢ A <: D)
   ---------------------------- appsub_andl
   (appsub (S : C) ⊢ (A & B) <: D)]
  [(appsub (S : C) ⊢ B <: D)
   ---------------------------- appsub_andr
   (appsub (S : C) ⊢ (A & B) <: D)]
  [(appsub (S : A) ⊢ C <: D)
   --------------------------- appsub_and1
   (appsub (S : (A & B)) ⊢ C <: D)]
  [(appsub (S : B) ⊢ C <: D)
   --------------------------- appsub_and2
   (appsub (S : (A & B)) ⊢ C <: D)]
  )

(test-equal (judgment-holds (appsub · ⊢ Int <: A) A)
            (list (term Int)))
(test-equal (judgment-holds (appsub (· : Int) ⊢ (Int → Int) <: A) A)
            (list (term Int)))
(test-equal (judgment-holds (appsub (· : Int) ⊢ ((Int → Int) & (Bool → Bool)) <: A) A)
            (list (term Int)))