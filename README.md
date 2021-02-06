# 		Applicative Intersection Types

Notes : I heavily use [prettify-symbols](https://github.com/juniorxxue/spacemacs.d/blob/master/utils/prettify-redex.el) in emacs, so Redex code may look werid to you :)

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

(succ ,, not) (4 ,, true)

(f : Int & Bool -> Int & Bool ,, g : String -> String) (4 ,, true)
-- (judgment-holds (check empty empty ((((lambda (x) x) : ((int & bool) -> (int & bool))) doublecomma ((lambda (x) x) : (bool -> bool))) (4 doublecomma true)) <= (int & bool)))

-- would it bother to implement, if we use a check here?
```

## Syntax

### Examples

```haskell
true : Bool is a value
1 : Int is a value
(true ,, 1) : (Bool & Int) is a value


(\x . x ,, \x . x ) : (Int -> Int) & (Bool -> Bool)
```

### Rules

```
A, B ::= Int | Top | A -> B | A & B
e ::= T | n | x | \x . e | e1 e2 | e1,,e2 | (e : A)

p ::= T |p n | \x . e
v ::= p : A | \x . e | (p1 : A ,, p2 : B) : A & B

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

### Rules

```
-----------
S |- A <: B
-----------

. |- A <: A    AS-Refl


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

### Discussions

```haskell
-- test cases
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
;; Redex code
(guess (tred (1 : int) int v) v)
;; => '((1 : int))

(guess (tred ((1 : int) doublecomma (true : bool)) int v) v)
;; => '((1 : int))

(guess (tred (1 : int) (int & int) v) v)
;; => '(((1 : int) doublecomma (1 : int)))
```

```
Discussion about typed reduction

Since reduction need some info from arguments to guide pick from merge.
succ ,, not 4 should reduce to succ

succ ,, not 4 --> succ ,, not (4 : Int)

Option 1 we can use typing to do this

S, A |- typeof (v1 ,, v2) <: B
v1 ,, v2 -->B v1
----------------------------------------------- Step-App-Merge-L
(v1 ,, v2) (p : A) --> v1 (p : A)

One thoughts here, actually the type info of merged term can be get from its term

v1 ,, v2 actually is (p1 : A1) ,, (p2 : A2), the type of it is A1 & A2.

Notes: is (\x .x ,, \x. x : Bool -> Bool) 1 valid?

Option 2 is we can modify the typed reduction so that

A |- v1 ,, v2 -->? v’
----------------------------------------------- Step-App-Merge
(v1 ,, v2) (p : A) --> v’ (p : A)

From Snow's words, Typed Reduction is correlated to subtyping relation,
since we have app-subtyping, it's natural if we introduce a context for typed reduction.

TBD
```

```
value def of merge
Removal of merge from value bring some changes to typed reduction
we hope
(1,,true) : (Int&Bool) -->Int (1 : Int)

e1 -->A e1'
Ordinary A
---------------------------- Tred-Merge-L
e1,,e2 -->A e1'

become

e1 : A -->C e1' : C
Ordinary C
---------------------------- Tred-Merge-L
e1,,e2 : A & B -->C e1' : C


UPDATE 2

1 : Int -->Int 1 : Int
1 : Int -->Int 1 : Int
------------------------------------------------------ Tred-And
1 -->(Int & Int) ((1 : Int),,(1 : Int)) : (Int & Int)
```

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
e -->A (T : Top)


not (TopLike C)
C <: A
B <: D
----------------------------------------------------- Tred-Arrow-Annotated
(\x . e) : A -> B   -->(C -> D)     (\x . e) : A -> D


e1 -->B e
Ordinary B
---------------------------- Tred-Merge-L
e1,,e2 : A -->B e


e2 -->C e
Ordinary B
---------------------------- Tred-Merge-R
e1,,e2 : A -->B e


e -->A e1
e -->B e2
--------------------------------- Tred-And
e -->(A & B) e1,,e2 : (A & B)
```
## Parallel Application

### Discussion

```
Noted that we want to add a argument context in typed reduction
to replace

C |- A & B => D
(p1,,p2) : (A & B) -->D (p1' : E)
----------------------------------------------- Step-App-Merge-L
((p1,,p2) : (A & B)) (p : C) --> (p1' : E) (p : C)

The orignal parallel application in TamingMerge
do the job of distributing input values 
to let it correspond to BCD subtyping's distributivity rule

Since our first typing version is to pick one from them, the rules papp-merge

v1 ● vl --> e1   v2 ● vl --> e2
---------------------------------- PApp-Merge
(v1,,v2) ● vl --> e1,,e2

then become

C |- A & B => D
(p1,,p2) : (A & B) -->D (p1' : E)
(p1' : E) ● (p : C) --> e
------------------------------------ PApp-Merge-L
(p1,,p2) : (A & B) ● (p : C) --> e

C |- A & B => D
(p1,,p2) : (A & B) -->D (p2' : E)
(p1' : E) ● (p : C) --> e
------------------------------------ PApp-Merge-R
(p1,,p2) : (A & B) ● (p : C) --> e

found two can be combined as one

Int |- (Int -> Int) & (Bool -> Bool) <: Int -> Int
(\x.x,,\x.true) : (Int -> Int) & (Bool -> Bool) -->(Int -> Int) \x.x : Int -> Int
\x.x : Int -> Int ● (4 : Int) --> 4 : Int
--------------------------------------------------------------------
(\x.x,,\x.true) : (Int -> Int) & (Bool -> Bool) ● (4 : Int)


C <: A      S |- B <: D
------------------------ AS-Fun
S, C |- A -> B <: C -> D


S |- A <: D
------------------------ AS-AndL
S |- A & B <: D


S |- B <: D
------------------------ AS-AndR
S |- A & B <: D


Int & Bool |- (Int -> Int)
-------------------------------------------------------------
Int & Bool |- (Int -> Int) & (Bool -> Bool) <: 


---------------------------------------------------------------------------
(\x.x,,\x.true) : (Int -> Int) & (Bool -> Bool) ● (4 ,, true : Int & Bool)
```

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
(p1 : A ,, p2 : B) : (A & B) -->D v
v ● (p : C) --> e
------------------------------------------- PApp-Merge
(p1 : A ,, p2 : B) : (A & B) ● (p : C) --> e
```

## Reduction

### Discussions

```
1
--> 1 : Int

(\x . x) 1
--> (\x . x) (1 : Int)
--> (\x . x) ● (1 : Int)
--> x [x -> (1 : Int)]
--> 1 : Int
```

```
(\x . x : Int -> Int) ,, (\x . true : Int -> Bool)
--> (\x . x ,, \x . true) : (Int -> Int) & (Int -> Bool)

is (\x . x ,, \x . true) : (Int -> Int) & (Int -> Bool) type check?


|- (Int -> Int) & (Int -> Bool <: (Int -> Int) & (Int -> Bool) . |- (\x . x ,, \x . true) <= (Int -> Int) & (Int -> Bool)
-------------------------------------------------------------------------------------------------------------------------- TAnn
|- (\x . x ,, \x . true) : (Int -> Int) & (Int -> Bool) => (Int -> Int) & (Int -> Bool)



----------------------------------------------------------------
. |- (\x . x ,, \x . true) => (Int -> Int) & (Int -> Bool)
---------------------------------------------------------------
. |- (\x . x ,, \x . true) <= (Int -> Int) & (Int -> Bool)

currently no typing rule checking againt merge
probably add this rule

disjoint A B        T |- e1 <= A   T |- e2 <= B
----------------------------------------------- TMerge-Chk
T |- e1 ,, e2 <= A & B

then works fine with later derivation

x : Int |- x <= Int
---------------------------
. |- \x . x <= Int -> Int
```

```
(\x . x : Int -> Int) ,, (\x . true : Bool -> Bool) 4
--> (\x . x ,, \x . true) : (Int -> Int) & (Bool -> Bool) 4
--> (\x . x ,, \x . true) : (Int -> Int) & (Bool -> Bool) (4 : Int)
--> (\x . x ,, \x . true) : (Int -> Int) & (Bool -> Bool) ● (4 : Int)
--> (\x . x : (Int -> Int)) ● (4 : Int)
--> 4 : Int : Int
--> 4 : Int
```

### Rules

```
-------------
e --> e'
-------------

----------------------- Step-Int-Anno
n --> n : Int


-------------------------------------------------- Step-Merge-Anno
(p1 : A),,(p2 : B) --> (p1 : A),,(p2 : B) : (A & B)


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


e1 : A --> e1' : A1
----------------------------------------------------------- Step-Merge-L
(e1 : A ,, e2 : B) : A & B --> (e1' : A1 ,, e2 : B) : A1 & B


e2 : B --> e2' : B1
---------------------------------------------------------- Step-Merge-R
(p1 : A ,, e2 : B) : A & B --> (p1 : A ,, e2' : B1) : A & B1
```

## Typing

### Discussions

```
Do my system type check with
(\x . x : Int -> Int) ,, (\x . true : Bool -> Bool) 4,,true => Int & Bool

T |- e2 => A   T ; S, A |- e1 => A -> B
----------------------------------------- TApp1
T ; S |- e1 e2 => B

4,,true => Int & Bool ✔
.; Int & Bool |- (\x . x : Int -> Int) ,, (\x . true : Bool -> Bool) => Int & Bool

disjoint A B        T |- e1 => A   T |- e2 => B
----------------------------------------------- TMerge
T |- e1 ,, e2 => A & B

it lacks a stack ctx S

disjoint A B        T; S |- e1 => A   T; S |- e2 => B
-------------------------------------------------- TMerge-New
T; S|- e1 ,, e2 => A & B
```

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

