----- SOURCE CODE -- main.bp
```botopink
type D(id: i32) {
    fn get(self: Self) { return self.id; }
}
fn main() {
    val d = D(id: 1);
    val a: string = d.get();
    @print(a);
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: type mismatch
  ┌─ :6:23
  │
6 │     val a: string = d.get();
  │                       ^

  expected: string
  found:    i32
```

