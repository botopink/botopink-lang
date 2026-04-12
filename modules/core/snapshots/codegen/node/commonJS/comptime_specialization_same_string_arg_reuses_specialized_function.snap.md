----- SOURCE CODE -- main.bp
```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$1("Memória alta");
    const r3 = build_$0("Log replicado");
}

function build_$0(name) {
    const prefix = "INFO";
    return ((prefix + ": ") + name);
}

function build_$1(name) {
    const prefix = "WARN";
    return ((prefix + ": ") + name);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```
