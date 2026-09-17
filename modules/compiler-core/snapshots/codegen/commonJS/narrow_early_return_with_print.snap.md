----- SOURCE CODE -- main.bp
```botopink
fn greet(x: ?string) -> string {
    if (x == null) { return "nobody"; };
    return "hello " + x;
}
fn main() {
    @print(greet("world"));
    @print(greet(null));
}
```

----- JAVASCRIPT -- main.js
```javascript
function greet(x) {
    if ((x == null)) { return "nobody"; }
    return ("hello " + x);
}

function main() {
    console.log(greet("world"));
    console.log(greet(null));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
hello world
nobody
```
