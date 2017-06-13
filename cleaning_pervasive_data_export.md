Things to check for

```
^[^"]
\n"\n
"\\"$
(^|,)"[^0-9YV]"(,|$)    replace with \1""\2
```

To find quote marks where they're not supposed to be:
```
[^,"\n]"[^,"\n]
[a-z0-9.';:!@#$%^&*()]"[a-z0-9.';:!@#$%^&*()]
```
