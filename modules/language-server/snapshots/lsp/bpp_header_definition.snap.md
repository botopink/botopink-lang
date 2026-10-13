----- SOURCE
```botopink
type Props(title: string)
pub fn twice(x: i32) -> i32 {
    return x * 2;
}

val size = props.title.length();
val p: Props = props;
       ↑
---
<h1>{props.title}</h1>
```

----- DEFINITION at (line 6, char 7)
uri: file:///Card.bpp
range: (0,5) → (0,10)
in file:///Card.bpp:
  type Props(title: string)
       ^^^^^
