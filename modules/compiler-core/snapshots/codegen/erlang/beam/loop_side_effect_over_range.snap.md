----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    @print(i);
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- RUN LOG -----
```logs
```
