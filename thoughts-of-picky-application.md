# Picky Application

## Case

* `(succ ,, not) 4`

## Rules

since the case is quite simple currently,

we can let original (more general)

```
ptype(vl) |- ptype(v1 ,, v2) <: A
v1 ,, v2 -->A v
v ● vl --> e
-------------------------------------------- PApp-Merge
v1 ,, v2 ● vl --> e
```

Become, then typed-reduction contributes nothing, thus we remove it from the rule

```
ptype(vl) |- ptype(v1 ,, v2) <: ptype(v1)
v1 ● vl --> e
-------------------------------------------- PApp-Merge-L
v1 ,, v2 ● vl --> e


ptype(vl) |- ptype(v1 ,, v2) <: ptype(v2)
v2 ● vl --> e
-------------------------------------------- PApp-Merge-R
v1 ,, v2 ● vl --> e
```

