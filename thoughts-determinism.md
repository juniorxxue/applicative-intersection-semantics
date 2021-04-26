# Determinism

## Appsub (highly relates to papp)

Lemma

```
C |- A & B <: A
C |- A & B <: B
---------------
A = B
```

go back to case `succ ,, not 4`

```
In Hypothesis:
C |- A & B <: A
C |- A & B <: B
---------------------
We can get A = B
Then how to invert this case


Int |- (Int -> Int) & (Bool -> Bool) <: (Int -> Int)
Int |- (Int -> Int) & (Bool -> Bool) <: (Bool -> Bool)
```

## Reduction

```
not value (e : A)
e --> e'
------------------ Step-Anno
e : A --> e' : A
```

Let's talk about this case

Since our current solution is very similar to snow's, could

should `not value (e : A)` still be needed?

```

1 --> 1 : Int
-------------------------------
1 : Int --> (1 : Int) : Int
```

