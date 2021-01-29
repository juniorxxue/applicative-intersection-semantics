# Applicative Intersection Types

Notes : I heavily use [prettify-symbols](https://github.com/juniorxxue/spacemacs.d/blob/master/utils/prettify-redex.el) in emacs, so Redex code may look werid to you :)

## Table of Contents

* [Style Guide](#style-guide)
* [Syntax](#syntax)
* [Reduction](#reduction)
* [Subtyping](#subtyping)
* [Application Subtyping](#application-subtyping)
* [Typing](#typing)
* [Ordinary](#ordinary)
* [TopLike](#toplike)
* [Typed Reduction](#typed-reduction)

## Style Guide

```haskell
1 
-- (draw (infer empty empty 1 => tau))

1 : Int
-- (draw (infer empty empty (1 : int) => tau))

lambda (x) x : Int -> Int
-- (draw (infer empty empty ((lambda (x) x) : (int -> int)) => tau))

(lambda (x) x) 4
-- (draw (infer empty empty ((lambda (x) x) 2) => tau))

1 ,, true
-- (draw (infer empty empty (1 doublecomma true) => tau))

1 ,, true : Int & Bool 
-- (draw (infer empty empty ((1 doublecomma true) : (int & bool)) => tau))

(succ ,, not : Int -> Int) 5
-- (draw (infer empty empty (((((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) x) : (bool -> bool))) : (int -> int)) 5) => tau))

(succ ,, f : Int -> Bool) 3 : Bool
-- (draw (infer empty empty (((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) true) : (int -> bool))) => tau))

(succ ,, not) 4
-- (draw (check empty empty ((((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) x) : (bool -> bool))) 4) <= int))

-- would it bother to implement, if we use a check here?
```

## Syntax

### Examples

```haskell
true : Bool is a value
1 : Int is a value
ture : Bool ,, 1 : Int is a value

f : Int -> Int is a value
g : Bool -> Bool is a value
f : Int -> Int ,, g : Bool -> Bool is a value

-- value of merge can be seen as merges of primitive (p : A)
```

### Rules

```
A, B ::= Int | Top | A -> B | A & B
e ::= T | n | x | \x . e | e1 e2 | e1,,e2 | (e : A)
p ::= T | n | \x . e
v ::= p : A | \x . e | v1,,v2
T ::= . | T, x : A
S ::= . | S, A
```

## Reduction

### Examples

```haskell
(\x . x)

(\x . x) 4
--> (\x . x) (4 : Int)
--> (4 : Int)

-- it may have the option (that may be a intuitive one)
-- the problem is
-- system can type check (\x . x) 4
-- while cannot type check (\x . x)
-- so we consider it a special rule
(\x . x) 4
--> (\x . x) (4 : Int)
--> ((\x . x) : (guess Int)) (4 : Int)
--> ((\x . x) : (Int -> Int)) (4 : Int)

-- (f : Int -> Int) ,, (g : Bool -> Bool) 
-- for a merged function, it's already a value
succ ,, not

-- for application with a merged function

-- by meta-function we already have
-- 1) succ ,, not -->(Int -> Int) succ
-- 2) Int | (Int -> Int) & (Bool -> Bool) <: Int -> Int

succ ,, not 4
--> succ ,, not (4 : Int)
--> succ (4 : Int)

(f : int -> int) ,, (g : int -> bool) :  int -> bool
-- we need typed reduction here
--> f : int -> bool -- step-anno-merge-r
```

```scheme
;; redex code to justify
(traces step (term ((((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) x) : (bool -> bool))) 4)))
(traces step (term ((((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) x) : (bool -> bool))) true)))

(traces step (term ((((lambda (x) x) : (int -> int)) doublecomma ((lambda (x) x) : (int -> bool))) : (int -> bool))))
```

![](imgs/reduce_1.png)

### Rules

```
-------------
e --> e'
-------------

----------------------- Step-Int
n --> n : Int


---------------------------- Step-Beta
(\x . e) v --> (e [x -> v])


v -->A v'
------------------------------------------------ Step-Beta-Anno
((\x . e1) : A -> B) v  --> (e1 [x |-> v'])


v1 ,, v2 -->A v1
----------------------------------------------- Step-Anno-Merge-L
(v1 ,, v2) : A --> v1


v1 ,, v2 -->A v2
----------------------------------------------- Step-Anno-Merge-R
(v1 ,, v2) : A --> v2


A |- typeof (v1 ,, v2) <: B
v1 ,, v2 -->B v1
----------------------------------------------- Step-App-Merge-L
(v1 ,, v2) (p : A) --> v1 (p : A)


A |- typeof (v1 ,, v2) <: B
v1 ,, v2 -->B v2
----------------------------------------------- Step-App-Merge-R
(v1 ,, v2) (p : A) --> v2 (p : A)


e1 --> e1'
------------------ Step-App-L
e1 e2 --> e1' e2


e2 --> e2'
------------------ Step-App-R
v e2 --> v e2'


e1 --> e1'
------------------- Step-Merge-L
e1,,e2 --> e1',,e2


e2 --> e2'
------------------- Step-Merge-R
v,,e2 --> v,,e2'
```

## Subtyping

```
------
A <: B     (Subtyping, rule form)
------

Int <: Int         S-Int


A <: Top           S-Top


Top <: D
----------------   S-TopArr
A <: C -> D


C <: A    B <: D
----------------   S-Arrow
A -> B <: C -> D


A <: B    A <: C
----------------   S-And
A <: B & C


A <: C
----------         S-AndL
A & B <: C


B <: C
----------         S-AndR
A & B <: C
```

## Application Subtyping

```
-----------
S |- A <: B
-----------

. |- A <: A    AS-Refl


C <: A      S |- B <: D
------------------------ AS-Fun
S, C |- A -> B <: C -> D


S |- A <: D
------------------------ AS-AndL
S |- A & B <: D


S |- B <: D
------------------------ AS-AndR
S |- A & B <: D
```

## Typing

```
--------------
T; S |- e => A
T |- e <= A
--------------

syntactic sugar:
T |- e => A   ==   T; . |- e => A


|- T
------------ TInt
T |- n => Int


|- T   x : A \in T
--------------------- TVar
T |- x => A


T, x : A |- e <= B
----------------------------- TLam1
T |- \x. e <= A -> B


T, x : A ; S |- e => B
------------------------------ TLam2
T ; S, A |- \x. e => A -> B


S |- A <: B    T |- e <= A
----------------------------- TAnn
T ; S |- e : A => B


T |- e2 => A   T ; S, A |- e1 => A -> B
----------------------------------------- TApp1
T ; S |- e1 e2 => B


T |- e2 => A    T |- e1 <= A -> B
----------------------------------- TApp2
T |- e1 e2 <= B


T |- e => B     B <: A
------------------------- TSub
T |- e <= A


T |- e1 => A   T |- e2 => B
----------------------------- TMerge
T |- e1 ,, e2 => A & B
```

```
not (int -> bool -> int)   (int -> bool)
not (int -> bool) <: (int -> any)



                        ---------------------------------------------------- TLam2
.|- true => bool         .;., int, bool |- (\b . succ) => bool -> B
                     -------------------------------------------------------------------- TApp1
.|- 1 => int         .; ., int |- (\b . succ) true => int -> B
--------------------------------------------------------------------------------------- TApp1
. ; . |- ((\b . succ) true) 1 => B
```

## Ordinary

```
-------------
Ordinary A
-------------

------------------ Ord-Top
Ordinary Top


------------------ Ord-Int
Ordinary Int


------------------ Ord-Arrow
Ordinary (A -> B)
```

## TopLike

```
-------------
TopLike A
-------------

--------------------- TL-Top
TopLike Top


TopLike A
TopLike B
--------------------- TL-And
TopLike (A & B)


TopLike B
-------------------- TL-Arrow
TopLike (A -> B)
```



## Typed Reduction

### Examples

```haskell
1 : Int -->Int 1 : Int
\x . x : Int -> Int  -->(Int -> Top) \x . x : Int -> Top

-- merge case

1 : Int -->Int 1 : Int
Ordinary Int
------------------------------------------
(1 : Int) ,, (true : Bool) -->Int  1 : Int


1 : Int -->Int 1 : Int
1 : Int -->Int 1 : Int
--------------------------------------------
1 : Int -->(Int & Int) (1 : Int) ,, (1 : Int)
```

```scheme
(guess (tred (1 : int) int v) v)
;; => '((1 : int))

(guess (tred ((1 : int) doublecomma (true : bool)) int v) v)
;; => '((1 : int))

(guess (tred (1 : int) (int & int) v) v)
;; => '(((1 : int) doublecomma (1 : int)))
```

### Rules

```
------------------
v-->A v'
------------------


------------------ Tred-Int-Anno
n : Int -->Int n : Int


Ordinary A
TopLike A
------------------- Tred-Top
e : A -->A T : Top


not (TopLike C)
C <: A
B <: D
----------------------------------------------------- Tred-Arrow-Annotated
(\x . e) : A -> B   -->(C -> D)     (\x . e) : A -> D


e1 -->A e1'
Ordinary A
---------------------------- Tred-Merge-L
e1,,e2 -->A e1'


e2 -->A e2'
Ordinary A
---------------------------- Tred-Merge-R
e1,,e2 -->A e2'


e1 -->A e2
e1 -->B e3
---------------------- Tred-And
e1 -->(A & B) e2,,e3
```
