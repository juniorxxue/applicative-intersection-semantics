# Applicative Merge

## Problem

`((\x. x) ,, 3) 4` cannot be type checked and cannot be reduced

but it should be

## Related Rules

```
T |- e2 => A   T ; S, A |- e1 => A -> B
----------------------------------------- TApp1
T ; S |- e1 e2 => B


T, x : A ; S |- e => B
------------------------------ TLam2
T ; S, A |- \x. e => A -> B


disjoint A B        T |- e1 => A   T |- e2 => B
----------------------------------------------- TMerge
T |- e1 ,, e2 => A & B


T; S |- e1,,e2 => B   S, A |- B <: C
----------------------------------------------- T-Merge-pick
T; S, A |- e1,,e2 => C


ptype(vl) |- ptype(v1 ,, v2) <: A
v1 ,, v2 -->A v
v ● vl --> e
-------------------------------------------- PApp-Merge
v1 ,, v2 ● vl --> e
```

## Proposal One

### Typing

We look at typing fristly

```
4 => Int     . ; Int |- (\x. x ,, 3) => Int -> Int
----------------------------------------------------- TApp1
.;. |- ((\x. x) ,, 3) 4 => Int
```

Intuitively,  `. ; Int |- (\x. x ,, 3) => Int -> Int`  is valid if `Int |- \x .x => Int -> Int`

```
----------------------- TVar
x : Int ; . |- x => Int
------------------------------ TLam2
Int |- \x. x => Int -> Int
```

So `T-Merge-pick` should accpet this.

**New: T-Merge-pick rule is valid if one term of merge can infer some type under argument stack.**

```
T; S, A |- e1 => C
------------------------------------------- T-Merge-pick-L
T; S, A |- e1,,e2 => C

T; S, A |- e2 => C
------------------------------------------- T-Merge-pick-R
T; S, A |- e1,,e2 => C
```

```4 => Int     . ; Int |- (\x. x ,, 3) => Int -> Int
             . ; Int |- \x. x => Int -> Int
             ------------------------------------- T-Merge-pick-L
4 => Int     . ; Int |- (\x. x ,, 3) => Int -> Int
----------------------------------------------------- TApp1
.;. |- ((\x. x) ,, 3) 4 => Int
```

But what about `succ ,, not 4`,  that's the reason we create the `T-merge-pick` rule.

```
--------------------------------
Int |- Int -> Int <: Int -> Int    (\x. x+1) <= Int -> Int
---------------------------------------------------------- TAnn
Int |- succ => Int -> Int
------------------------------------ T-Merge-Pick-R
Int |- succ ,, not => Int -> Int
------------------------------------ TApp 1
.;. |- succ ,, not 4 => Int
```

`Int |- Int -> Int <: Int -> Int` is werid, since

we only have

```
---------------- AS-Refl
. |- A <: A 
```

**how about**

```
---------------- AS-Refl
S |- A <: A
```

### Reduction

And then reduction part

```
ptype(vl) |- ptype(v1 ,, v2) <: A
v1 ,, v2 -->A v
v ● vl --> e
-------------------------------------------- PApp-Merge
v1 ,, v2 ● vl --> e
```

```
Int |- ptype(\x.x ,, (3 : Int)) <: 
-------------------------------------------------- PApp-Merge
\x.x ,, (3 : Int) ● (3 : Int) --> (3 : Int)
```

**Oops, not principle type for `\x.x` **

Well, how do we treat `(\x. x) 4` before in the reduction? We simply do the subsititution!

Why we need `ptype`, we try to avoid seeking help from `typing` in the reduction rule.

How snow's type system deal with `succ ,, not 4` , I guess it should be `((succ ,, not) : (Int -> Int)) 4`.

## Misc

Some angles to do thinking

* How it behave in snow's type system (full annotation one)?
* How it behave in classicl lambda calculus?
* What's its original intention?