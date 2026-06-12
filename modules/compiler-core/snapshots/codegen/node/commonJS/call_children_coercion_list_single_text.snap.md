----- SOURCE CODE -- main.bp
```botopink
fn node() -> string { return "n"; }
fn box(children: Children) -> string { return "x"; }
val many = box([node(), node()]);
val one = box(node());
val txt = box("hi");
```

----- JAVASCRIPT -- main.js
```javascript
function node() {
    return "n";
}

function box(children) {
    return "x";
}

const many = box([node(), node()]);

const one = box(node());

const txt = box("hi");
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript









```

----- RUN LOG -----
```logs
```
