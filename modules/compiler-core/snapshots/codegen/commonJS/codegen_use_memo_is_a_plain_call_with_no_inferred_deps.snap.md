----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Use<Element, i32> {
    initial;
}
#[@use]
fn memo() -> @Use<Element, i32> {
    0;
}
#[@use]
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
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

async function memo() {
    0;
}

async function Counter() {
    const { count, setCount } = await state(0);
    const doubled = await memo(() => {
    return (count * 2);
});
    new Element();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
