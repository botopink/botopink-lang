----- SOURCE
```botopink
import {area} from "shapes.geometry";

pub fn main() {
    @print(area(2));
}
```

----- DIAGNOSTICS
(0,19)–(0,36)  error  "shapes.geometry" is this package — write import {geometry.area};
