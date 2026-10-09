----- SOURCE
```botopink
import {area} from "geometry";

pub fn main() {
    @print(area(2));
}
```

----- DIAGNOSTICS
(0,19)–(0,29)  error  "geometry" is a module of this package — write import {geometry.area};
