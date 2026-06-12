----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- JAVASCRIPT -- main.js
```javascript
const COMMANDS = ["calc", "noop", "help"];

function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    const slug = "calc";
    let output = 0;
    for (const cmd of COMMANDS) {
    (() => { if ((cmd === slug)) { return output = (input * 2); } })();
};
    return output;
}

function execute_$1(input) {
    const slug = "noop";
    let output = 0;
    for (const cmd of COMMANDS) {
    (() => { if ((cmd === slug)) { return output = (input * 2); } })();
};
    return output;
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
```
