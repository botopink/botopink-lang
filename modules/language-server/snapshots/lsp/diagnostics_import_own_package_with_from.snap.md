----- SOURCE
```botopink
import {area} from "shapes.geometry";

pub fn main() -> void {
    print(area(2));
}

import {io.terminal.print} from "std";
```

----- DIAGNOSTICS
(0,19)–(0,36)  error  "shapes.geometry" is this package — write import {geometry.area};
