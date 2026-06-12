----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn memo() -> @Context<Element, i32> {
    0;
}
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
function state(initial) {
    initial;
}

function memo() {
    0;
}

function Counter() {
    const { count, setCount } = useState(0);
    const doubled = useMemo(() => {
    return (count * 2);
}, [count]);
    Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
