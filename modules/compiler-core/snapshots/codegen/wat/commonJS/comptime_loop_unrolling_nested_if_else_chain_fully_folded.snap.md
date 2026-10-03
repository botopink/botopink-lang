----- SOURCE CODE -- main.bp
```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    for (COMMANDS) { cmd ->
        if (cmd == slug) {
            if (cmd == "calc") {
                output = input * 2;
            } else if (cmd == "noop") {
                output = input;
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

----- COMPTIME VALUES -- main
```text
ct_0: val COMMANDS = comptime ["calc", "noop", "help"] → ["calc", "noop", "help"]
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

const COMMANDS = ["calc", "noop", "help"];

function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = __bp_int((input * 2), -2147483648, 2147483647, "* on i32 at main.bp:8:32");
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;
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
