# 03-22

## P1

```
. |- v1 => A     . |- v2 => B      consistency v1 v2
------------------------------------------------------ Typing-Merge-Value
T |- v1,,v2 => A & B
```

Why consistency?

It accepts `1,,1` while reject `1,,2`

`1 : Int & Int` is a value in my system.

```

1 : Int --> Int & (Bool & Int)
------------------------------------------------------------
(1 : Int),,(True : Bool) -->(Int & Bool & Int) 
```

## P2

