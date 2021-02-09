# 		Applicative Intersection Types

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
lambda (x) x : Int -> Int
(lambda (x) x) 4
1 ,, true
1 ,, true : Int & Bool 
(succ ,, not : Int -> Int) 5
(succ ,, f : Int -> Bool) 3 : Bool
(succ ,, not) 4
(succ ,, not) (4 ,, true)
(f : Int & Bool -> Int & Bool ,, g : String -> String) (4 ,, true)
```

## Syntax

### Rules

```
A, B ::= Int | Top | A -> B | A & B
e ::= T | n | x | \x . e | e1 e2 | e1,,e2 | (e : A)

p ::= T | n | \x . e | p1,,p2
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

### Rules

```
-----------
S |- A <: B
-----------


---------------- AS-Refl
. |- A <: A 


---------------- AS-Top
. |- A <: Top


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

### Discussions

```
dicussion about amiuguity

--------- PROPOSAL 1 OPEN ------------------

S |- A <: D
not (B <: S -> E)
------------------------ AS-AndL
S |- A & B <: D

for arbitrary E, it's not algorithmic, denied

--------- PROPOSAL 1 CLOSE ------------------

--------- PROPOSAL 2 OPEN ------------------

S |- A <: D
not (B <: S -> Top)
------------------------ AS-AndL
S |- A & B <: D

S -> Top is top-like type,

(string -> char) <: (int -> top) <- that's not what we want
--------- PROPOSAL 2 CLOSE -------------------

--------- PROPOSAL 3 OPEN ------------------

S |- A <: D
not (S <: inputs(B))
------------------------ AS-AndL
S |- A & B <: D


(f: Int -> Int ,, g : Int -> Bool) 4
there's a ambiuguity above
S is Int, B is Int -> Bool, so inputs(Int -> Int) is Int, that works

But what if
(f : Int -> (String -> Int) ,, g : Int -> (Char -> Int)) 4
S is Int here
inputs (Int -> (Char -> Int)) should be Int or Int -> Char?

((f : Int -> (Char -> (String -> Int)) ,, g : Int -> (Char -> (String -> Bool)) 4) 'c'
., Char, Int 
S is probably Int -> Char
inputs (B) is Int? Int -> Char? Int -> Char -> String?
--------- PROPOSAL 3 OPEN CLOSE ------------------

--------- PROPOSAL 4 OPEN ---------------------
(f : Int -> Char -> Bool,, (g : String -> String -> Bool,, h : Bool -> Bool -> Bool)) 3
actually here you want to collect the *first* inputs of g and h
String,Bool
and check that Int is not one of those
so

S,I |- A <: D
not (I in Nextinputs(B))
------------------------ AS-AndL
S,I |- A & B <: D
--------- PROPOSAL 4 CLOSE --------------------
```

## Typed Reduction

### Rules

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


p1 : A -->C p : D
Ordinary C
---------------------------- Tred-Merge-L
p1,,p2 : A & B -->C p : D


p2 : B -->C p : D
Ordinary C
---------------------------- Tred-Merge-L
p1,,p2 : A & B -->C p : D


p : C -->A p1 : D
p : C -->B p2 : E
--------------------------------- Tred-And
p : C -->(A & B) p1,,p2 : (D & E)
```
## Parallel Application

### Rules

```
----------------
v ● vl --> e
----------------

------------------------------- PApp-Abs
\x . e ● v --> e [x |-> v]


v -->A v'
------------------------------------------- PApp-Abs-Anno
\x . e : A -> B ● v --> e [x |-> v'] : B



----------------------- PApp-Top
T ● vl --> T


C |- A & B <: D
p1,,p2 : (A & B) -->D v
v ● (p : C) --> e
------------------------------------------- PApp-Merge
p1,,p2 : (A & B) ● (p : C) --> e
```

## Reduction

### Rules

```
-------------
e --> e'
-------------

----------------------- Step-Int-Anno
n --> n : Int


v1 ● v2 --> e
---------------- Step-PApp
v1 v2 --> e


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
v e2 --> v e2'


-------------------------------------------------- Step-Merge-Anno
(e1 : A),,(e2 : B) --> e1,,e2 : (A & B)


e1 : A --> e : C
----------------------------------------------------------- Step-Merge-L
e1 ,, e2 : A & B --> e ,, e2 : C & B


e2 : B --> e : C
---------------------------------------------------------- Step-Merge-R
p1 ,, e2 : A & B --> p1 ,, e : A & C
```

## Typing

### Rules

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


disjoint A B        T |- e1 => A   T |- e2 => B
----------------------------------------------- TMerge
T |- e1 ,, e2 => A & B


disjoint A B        . |- e1 <= A   . |- e2 <= B    not (HasType (e1,,e2	))
----------------------------------------------------------------------------- TMerge-Chk
. |- e1 ,, e2 <= A & B
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

## HasType

```
------------
HasType e
-----------

------------------- HT-Int
HasType n


------------------- HT-Top
HasType T


HasType e1     HasType e2
-------------------------- HT-Merge
HasType (e1,,e2)
```
