----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement Renderable
fn render() -> Element {
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";
Element.prototype.__bp_b_Renderable = true;

function render() {
    return new Element();
}

Object.defineProperty(exports, "__bp_priv__", { value: { Element, render } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
