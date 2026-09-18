----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- JAVASCRIPT -- main.js
```javascript
class State {
    constructor(value, set) {
        this.value = value;
        this.set = set;
    }
}
State.prototype.__bp = "State";

function make() {
    return new State(0, (n) => {
});
}

function apply(s) {
    s.set(s.value);
    return s.value;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
