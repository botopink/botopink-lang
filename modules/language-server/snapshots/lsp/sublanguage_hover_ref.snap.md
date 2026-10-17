----- SOURCE
```botopink
pub type Users(name: string)
pub fn q(expr e: string) -> anyvalue {
    val code = compiler.build("[1, 2]");
    val kw = CustomNode(kind: "kw", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
    val col = CustomNode(kind: "col", span: Span(7, 11, 1), label: "property", ref: compiler.lookup(e, "Users"), children: []);
    val root = CustomNode(kind: "root", span: Span(0, 0, 1), label: "none", ref: null, children: [kw, col]);
    compiler.custom(root);
    return code;
}
val xs = q @`select name from Users`;
                     ↑
import {compiler.Span, compiler.CustomNode} from "std";
```

----- HOVER at (line 9, char 21)
kind: markdown

```botopink
pub type Users(name: string)
```
