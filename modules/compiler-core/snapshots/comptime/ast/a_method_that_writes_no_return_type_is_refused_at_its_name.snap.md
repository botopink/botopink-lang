----- SOURCE CODE -- main.bp
```botopink
type D(id: i32) {
    fn get(self: Self) { return self.id; }
}
fn main() -> void {
    val d = D(id: 1);
    val a: string = d.get();
    print(a);
}

import {io.terminal.print} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: fn-return-missing: `D.get` writes no return type — write -> void, or the type it answers
  ┌─ main.bp:2:8
  │
2 │     fn get(self: Self) { return self.id; }
  │        ^

  hint: Every function writes its return type, `-> void` included (decision 622).
```

