----- SOURCE CODE -- main.bp
```botopink
fn run() {
    todo;
}
fn main() {
    run { x ->
        return "done";
    };
}
```

----- JAVASCRIPT -- main.js
```javascript
function run() {
    (() => { throw new Error("not implemented") })();
}

function main() {
    run((x) => {
    return "done";
});
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
