----- SOURCE CODE -- main.bp
```botopink
type D(id: i32) {
    fn bad(self: Self) -> string {
        val z: string = self.id;
        return z;
    }
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: type mismatch
  ┌─ :3:30
  │
3 │         val z: string = self.id;
  │                              ^

  expected: string
  found:    i32
```

