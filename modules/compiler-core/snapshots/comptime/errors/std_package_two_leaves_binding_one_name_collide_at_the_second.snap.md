----- SOURCE CODE
import {url.parse, json.parse} from "std";

fn main() {
    val u = parse("http://a");
}

----- ERROR
error: import-name-collision: `parse` is already bound by the import of `url.parse`; `json.parse` would bind it again
  ┌─ :1:20
  │
1 │ import {url.parse, json.parse} from "std";
  │                    ^

  hint: Rename one of the two with `as` (`url.parse as parseUrl`), or import the namespace and qualify the call.
