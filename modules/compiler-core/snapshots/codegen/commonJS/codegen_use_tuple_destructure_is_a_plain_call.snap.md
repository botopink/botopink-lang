----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@context]
fn LikeWidget() -> Element {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
class Element {
}
Element.prototype.__bp = "Element";

function optimistic(base, f) {
    const push = (action) => {
    return f(base, action);
};
    [base, push];
}

function LikeWidget() {
    const [ shown, push ] = optimistic(12, (c, a) => {
    return (c + a);
});
    push(shown);
    new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
