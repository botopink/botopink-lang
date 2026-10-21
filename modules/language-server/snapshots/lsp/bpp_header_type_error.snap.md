----- SOURCE
```botopink
type Props(title: string)

val size: string = props.title.length();
---
<h1>{props.title}</h1>
```

----- DIAGNOSTICS
(2,31)–(2,32)  error  type mismatch: expected string, got i32
