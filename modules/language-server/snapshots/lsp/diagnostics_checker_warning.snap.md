----- SOURCE
```botopink
pub fn main() -> void {
    var out = [];
    print("x");
}

import {io.terminal.print} from "std";
```

----- DIAGNOSTICS
(1,4)–(1,5)  warning  `out` is born with no element type — annotate it: `var out: unknown[] = [];`
