----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(String)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const func = (s) => {
    return s;
};
    return func("hello");
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
