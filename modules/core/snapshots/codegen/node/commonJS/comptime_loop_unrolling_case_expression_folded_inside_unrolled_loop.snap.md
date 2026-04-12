----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = case cmd {
                "calc" -> input * 2;
                "noop" -> input;
                else -> 0;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: ["calc", "noop", "help"] }
];
process.stdout.write(JSON.stringify(results));
```

----- JAVASCRIPT -- main.js
```javascript
const COMMANDS = ["calc", "noop", "help"];

function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = (input * 2);
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;
    return output;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```
