----- SOURCE CODE -- main.bp
```botopink
fn log(msg: string) {
    @print(msg);
}
fn main() {
    log("started");
    val x = 42;
    log("done");
}
```

----- JAVASCRIPT -- main.js
```javascript
function log(msg) {
    console.log(msg);
}

function main() {
    log("started");
    const x = 42;
    log("done");
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
started
done
```
