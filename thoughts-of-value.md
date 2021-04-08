# Toughts of Value

## Issue 2020/04/07

in lemma `value_cannot_step_further` , problem encountered

```
\x. x : Top is a value, it can step into (Top : Top)
by typed reduction
since \x. x is also a value and triggers typed reduction
```

What if we introduce another category r

```
p ::= T | n | \x . e
r ::= v | \x . e
v ::= p : A | v1 ,, v2
```

which brings the changes

* we remove unannotated lambda from typed reduction (actually that's what we want)

* some adaptions from reduction

  * in `Step-PApp`, we deal with four case, thus changes into 

    ```
    r ● vl --> e
    ---------------- Step-PApp
    r vl --> e
    ```

    * `(T : Top) 3`
    *  `(\x. x) 3`
    * `(\x. x : Int -> Int) 3`
    * `(succ ,, not) 3`

  * in `Step-Anno-Value`, we stay with `v : A` to trigger typed reduction

  * `Step-App-R`, change into

  ```
  e2 --> e2'
  ------------------ Step-App-R
  r e2 --> r e2'
  ```

  * `Step-Merge-R` stays the same, since currently we won't `\x.e` appear into the merge

## Form 1

```
p ::= T | n | \x . e | p1,,p2
v ::= p : A | \x . e
```

### Pros

```
the typing info is at top-level, it's easy to fetch from anontaion

C |- A & B <: D
(p1,,p2) : (A & B) -->D (p : E)
(p : E) ● (p : C) --> e
------------------------------------ PApp-Merge
(p1,,p2) : (A & B) ● (p : C) --> e
```

### Cons

```
problem about this def is
1,,True : Int & Bool is a well-typed value
1,,True : Bool & Int is also a well-typed value by subsumption rule.

we represent the same value with two different forms!

so the lemma
Lemma merge_typing : 
value (p1,,p2 :: A & B) -> . |- p1,,p2 <= A & B  -> . |- p1 <= A /\ . |- p2 <= B 
is not valid here
```

## Form 2

```
p ::= T | n | \x . e | p1,,p2
v ::= p : A | \x . e | (v1,,v2) : A & B
```

```
p ::= T | n | \x . e | p1,,p2
v ::= p : A | \x . e | (p1 : A ,, p2 : B) : A & B
```

### Pros

```
which makes (1 : Int ,, True : Bool) : Int & Bool become a value

- the typing info is also at top-level
```

### Cons

```
- repated typing information 
- not-scablable, inappropritate for merge more than two values

[((1 : Int ,, True : Bool) : (Int & Bool) ,, ('c' : Char)) :] (Int & Bool) & Char
which kinda werid
```

## Form 3

```
p ::= T | n | \x . e
v ::= p : A | \x . e | v1,,v2
```

```
p ::= T | n | \x . e
v ::= p : A | \x . e | p1 : A ,, p2 : B
```

### Pros

```
- it's similar to snow's, possibly better for some lemmas
- kinda intuitive
```

### Cons

```
- typing info is not at top-level, we may need a metafunction to fetch typing in PApp-Merge
- not-scalable?

1 : Int ,, True : Bool
```

## Special App

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
------------------------------------------- PApp-Merge (denied)
(p1 : A ,, p2 : B) ● (p : C) --> e

ptype(vl) |- ptype(v1 ,, v2) <: A
v1 ,, v2 -->A v
v ● vl --> e
-------------------------------------------- PApp-Merge
v1 ,, v2 ● vl --> e
```

```
according to snow's words

PApp-Merge is redunant here.

succ ,, not 4
--> succ ,, not (4 : Int)
we hide picky rule here
--> 5 : Int

how about adding a type stack for PAPP

S |- v ● vl --> e
so what's the introduction and elimination

ptype(v2) |- v1 ● v2 --> e
--------------------------- Step-PApp
v1 v2 --> e
```



## Reduction

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


e1 : A --> e : C
----------------------------------------------------------- Step-Merge-L
e1 : A ,, e2 : B --> e : C ,, e2 & B


e2 : B --> e : C
---------------------------------------------------------- Step-Merge-R
v ,, e2 : B --> v ,, e : C
```