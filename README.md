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
-- this encounter problem due to disjoiness
```

See T-App2 derivations


```haskell

	
                                       . |- (succ ,, f : Int -> Bool) => (Int -> Int) & (Int -> Bool)      (Int -> Int) & (Int -> Bool) <: Int -> Bool
                                      --------------------------------------------------------------------------------------------------------- TSub
                         3 => Int      . |- (succ ,, f : Int -> Bool) <= (Int -> Bool)
                       --------------------------------------------------------------------------------------------------------------------- TApp2
. |- Bool <: Bool        succ ,, f : Int -> Bool 3 <= Bool
------------------------------------------------------------------------------------------------------------------------------------- TAnn (triggers check)
succ ,, f : Int -> Bool) 3 : Bool => Bool
```
