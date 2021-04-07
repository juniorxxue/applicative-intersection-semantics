# Check Subsumption

## Origin

in `tred_typing`

```
. |- \x. e <= A -> B
A -> B <: A -> D
->
. |- \x. e <= A -> D
```

requires

```
x : A |- e^x <= B
B <: D
-----------------
x : A |- e^x <= D
```

## Lemma

```
T1, x: A, T2 |- e^x <= B
C <: A
B <: D
->
T1, x: C, T2 |- e^x <= D
```

## Narrowing

```
T1, x: A, T2 |- e^x <= B
C <: A
->
T1, x: C, T2 |- e^x <= B
```

## Counter Example

```
x : Bool |- 2,,x <= Int
-------------------------
```

## Check to Infer

```
T |- e <= A
->
T |- e => B /\ B <: A
```

