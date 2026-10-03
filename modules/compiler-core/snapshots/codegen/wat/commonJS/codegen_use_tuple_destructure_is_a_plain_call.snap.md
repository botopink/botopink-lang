----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    return #(base, push);
}
fn LikeWidget() -> @Component<Element, Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

class Element {
}
Element.prototype.__bp = "Element";

async function optimistic(base, f) {
    const push = (action) => {
    return f(base, action);
};
    return [base, push];
}

async function LikeWidget() {
    const [ shown, push ] = await optimistic(12, (c, a) => {
    return __bp_int((c + a), -2147483648, 2147483647, "+ on i32 at main.bp:7:57");
});
    push(shown);
    return new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
