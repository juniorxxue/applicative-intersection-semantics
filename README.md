# 	Applicative Intersection Types

## Table of Contents

* [Style Guide](#style-guide)
* [Syntax](#syntax)
* [Subtyping](#subtyping)
* [Application Subtyping](#application-subtyping)
* [Typed Reduction](#typed-reduction)
* [Parallel Application](#parallel-application)
* [Reduction](#reduction)
* [Typing](#typing)
* [Ordinary](#ordinary)
* [Disjoint](#disjoint)
* [TopLike](#toplike)
* [HasType](#hastype)

## Style Guide

```haskell
1 
1 : Int
\x.x : Int -> Int
(\x.x) 4
1 ,, true
1 ,, true : Int & Bool 
(succ ,, not : Int -> Int) 5
(succ ,, f : Int -> Bool) 3 : Bool
(succ ,, not) 4
(succ ,, not) (4 ,, true)
(f : Int & Bool -> Int & Bool ,, g : String -> String) (4 ,, true)
(((\x.x) ,, True) : Int -> Bool) 1
((\x.x) ,, 3) 4 -- TBD
```

## Syntax

```haskell
A, B ::= Int | Top | A -> B | A & B
e ::= T | n | x | \x . e | e1 e2 | e1,,e2 | (e : A)

p ::= T | n | \x . e
v ::= p : A | v1 ,, v2

r ::= v | \x . e

-- r ::= p : A | \x . e | v1 ,, v2
-- exists S, . ; S | r => A

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


---------------- AS-Refl
. |- A <: A 


----------------------- AS-Top (removed)
. |- A <: TopLike B


C <: A      S |- B <: D
------------------------ AS-Fun
S, C |- A -> B <: C -> D


S, C |- A <: D
not (C in Nextinputs(B))
------------------------ AS-AndL
S, C |- A & B <: D


S, C |- B <: D
not (C in Nextinputs(A))
------------------------ AS-AndR
S, C |- A & B <: D
```

## Typed Reduction

```
------------------
v -->A v'
------------------


------------------ Tred-Int-Anno
n : Int -->Int n : Int


Ordinary A
TopLike A
------------------- Tred-Top
v -->A (T : Top)


not (TopLike C)
C <: A
B <: D
----------------------------------------------------- Tred-Arrow-Annotated
(\x . e) : A -> B   -->(C -> D)     (\x . e) : A -> D


v1 -->A v1'
Ordinary A
---------------------------- Tred-Merge-L
v1,,v2 -->A v1'


v2 -->A v2'
Ordinary A
---------------------------- Tred-Merge-R
v1,,v2 -->A v2'


v -->A v1
v -->B v2
--------------------------------- Tred-And
v -->(A & B) v1,,v2
```
## Parallel Application

```
----------------
r ● vl --> e
----------------

TopLike A
----------------------------- PApp-Top (Newly Added)
(p : A) ● vl --> (T : Top)


------------------------------- PApp-Abs
\x . e ● v --> e [x |-> v]


v -->A v'
------------------------------------------- PApp-Abs-Anno
\x . e : A -> B ● v --> e [x |-> v'] : B


ptype(vl) |- ptype(v1 ,, v2) <: ptype(v1)
v1 ● vl --> e
-------------------------------------------- PApp-Merge-L
v1 ,, v2 ● vl --> e


ptype(vl) |- ptype(v1 ,, v2) <: ptype(v2)
v2 ● vl --> e
-------------------------------------------- PApp-Merge-R
v1 ,, v2 ● vl --> e
```

## Reduction

```
-------------
e --> e'
-------------

----------------------- Step-Int-Anno
n --> n : Int


r ● vl --> e
---------------- Step-PApp
r vl --> e


v -->A v'
------------------------ Step-Anno-Value
v : A -> v'


not value (e : A)
e --> e'
------------------ Step-Anno
e : A --> e' : A


e1 --> e1'
------------------ Step-App-L
e1 e2 --> e1' e2


e2 --> e2'
------------------ Step-App-R
r e2 --> r e2'


e1 --> e1'
----------------------------------------------------------- Step-Merge-L
e1 ,, e2 --> e1' ,, e2


e2 --> e2'
---------------------------------------------------------- Step-Merge-R
v ,, e2--> v ,, e2'

```

## Principal Type

```
--------------------
ptype e => A
-------------------

------------------ ptype-int
ptype n => Int


------------------ ptype-top
ptype top => Top


------------------ ptype-anno
ptype (e : A) => A


ptype e1 => A   ptype e2 => B 
--------------------------------------------------- ptype-merge
ptype e1,,e2 => A & B
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
------------------ TInt
T |- n => Int


|- T
------------------ TTop
T |- Top => Top


|- T   x : A \in T
--------------------- TVar
T |- x => A


TopLike A
--------------  T-TopLike-Value (removed)
T | r <= A


Toplike A,  T, x: Top |- e <= Top
--------------------------------- T-Lam-Top (removed)
T |- \x. e <= A


TopLike A
----------------- T-Top
T |- \x. e <= A


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


disjoint A B        T |- e1 => A   T |- e2 => B
------------------------------------------------------ TMerge
T |- e1 ,, e2 => A & B


consist v1 v2      . |- v1 => A     . |- v2 => B
------------------------------------------------------ T-Merge-Value
T |- v1,,v2 => A & B


T; S |- e1,,e2 => B   S, A |- B <: C
----------------------------------------------- T-Merge-pick
T; S, A |- e1,,e2 => C
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

## Disjoint

```
-----------------
Disjoint A B
-----------------


------------------- Disjoint-Top-L
Disjoint Top A


------------------- Disjoint-Top-R
Disjoint A Top


------------------------- Disjoint-Int-Arr
Disjoint Int (A1 -> A2)


------------------------- Disjoint-Arr-Int
Disjoint (A1 -> A2) Int


Disjoint B1 B2
----------------------------- Disjoint-Arr-Arr
Disjoint (A1 -> B1) (A2 -> B2)


Disjoint A1 B       Disjoint A2 B
------------------------------------ Disjoint-And-L
Disjoint (A1 & A2) B


Disjoint A B1       Disjoint A B2
------------------------------------ Disjoint-And-R
Disjoint A (B1 & B2)
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
