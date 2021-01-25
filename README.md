# Applicative Intersection Types

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

-- would it bother to implement, if we use a check here
```

## Syntax

```
A, B ::= Int | Top | A -> B | A & B
e ::= T | n | x | \x . e | e1 e2 | e1,,e2 | (e : A)
p ::= T | n | \x . e | e1,,e2
v ::= p : A | \x . e
T ::= . | T, x : A
S ::= . | S, A
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

```
--------------
e -->A e'
--------------


------------------ Tred-Int
n -->Int n

Ordinary A
TopLike A
------------------- Tred-Top
e -->A T

not (TopLike C)
C <: A
B <: D
-------------------------------------------- Tred-Arrow-Annotated
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

## Step

```
--------------
e --> e'
--------------

v here satisfies value v

----------------- Step-Top
Top v -> Top

v -->A v'
------------------------------------------------ Step-Beta-Anno
((\x . e1) : A -> B) v  --> (e1 [x |-> v']) : B

v -->A v'
------------------- Step-Anno-Typed
v : A --> v'

e --> e'
-------------------- Step-Anno
e : A --> e' : A

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