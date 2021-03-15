# Stack and Annotation

Stack can make `Int |- \x. x` type check

This actually provides **equal** amount of information `\x : Int . x`

The reason of choosing full annotation is to use result type to further reduce the result, for example

```
3 ,, True -->Int 3
-------------------------------------------------------- Step-Beta
((\x . x) : Int -> (Int & Int)) (3,,True) --> 3 : Int & Int

and then

3 : Int & Int --> 3 ,, 3
```

## Nested Argument

```
Int |- \x . x => Int
\x : Int . x => Int
```

