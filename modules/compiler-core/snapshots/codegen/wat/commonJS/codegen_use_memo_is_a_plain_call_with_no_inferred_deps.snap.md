----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    return initial;
}
fn memo() -> @Component<Element, i32> {
    return 0;
}
fn Counter() -> @Component<Element, Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

async function state(initial) {
    return initial;
}

async function memo() {
    return 0;
}

async function Counter() {
    const { count, setCount } = await state(0);
    const doubled = await memo(() => {
    return (count * 2);
});
    return new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
