----- SOURCE
```botopink
pub struct Users { name: string }
pub fn q<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    val code = e.build("[1, 2]");
    val kw = CustomNode(kind: "kw", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
    val col = CustomNode(kind: "col", span: Span(7, 11, 1), label: "property", ref: e.lookup("Users"), children: []);
    val root = CustomNode(kind: "root", span: Span(0, 0, 1), label: "none", ref: null, children: [kw, col]);
    return e.custom(root, code);
}
val xs = q "select name";
                    ↑
```

----- HOVER at (line 8, char 20)
kind: markdown

```botopink
pub struct Users
```
