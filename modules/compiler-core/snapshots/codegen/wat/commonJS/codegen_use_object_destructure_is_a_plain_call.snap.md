----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn Counter() -> @Component<Element, Element> {
    val {count, setCount} = use state(0);
    Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

async function state(initial) {
    initial;
}

async function Counter() {
    const { count, setCount } = await state(0);
    new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
