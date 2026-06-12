----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
}
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
