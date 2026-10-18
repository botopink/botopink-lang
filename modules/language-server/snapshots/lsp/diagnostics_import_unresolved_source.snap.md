----- SOURCE
```botopink
import {start} from "starter";
import {greet} from "core";

pub fn main() {
    print(start() + greet());
}

import {io.terminal.print} from "std";
```

----- DIAGNOSTICS
(1,20)–(1,26)  error  unresolved import source "core" — declare it in botopink.json "dependencies"
