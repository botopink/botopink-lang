----- SOURCE CODE -- main.bp
```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("INFO", "Log replicado");
    @print(r1);
    @print(r2);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$0("Log replicado");
    console.log(r1);
    console.log(r2);
}

function build_$0(name) {
    const prefix = "INFO";
    return ((prefix + ": ") + name);
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
INFO: Sistema iniciado
INFO: Log replicado
```
