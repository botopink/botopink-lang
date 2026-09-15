----- SOURCE CODE -- main.bp
```botopink
val Element = record implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}

function state(initial) {
    initial;
}

function Counter() {
    const { count, setCount } = useState(0);
    new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
