----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn memo() -> @Component<i32> {
    return 0;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Element {
}
Element.prototype.__bp = "Element";

async function state(bpContextMap__, initial) {
    return initial;
}

async function memo(bpContextMap__) {
    return 0;
}

async function Counter(bpContextMap__) {
    const { count, setCount } = await state(bpContextMap__, 0);
    const doubled = await memo(bpContextMap__, () => {
    return __bp_int((count * 2), -2147483648, 2147483647, "* on i32 at main.bp:10:46");
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
