----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

async function state(bpContextMap__, initial) {
    return initial;
}

async function Counter(bpContextMap__) {
    const { count, setCount } = await state(bpContextMap__, 0);
    return new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
