----- SOURCE CODE -- main.bp
```botopink
enum Color { Red, Green }
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (removedKeywordEnum)
  ┌─ :1:1
  │
1 │ enum Color { Red, Green }

  unexpected `enum`
```

