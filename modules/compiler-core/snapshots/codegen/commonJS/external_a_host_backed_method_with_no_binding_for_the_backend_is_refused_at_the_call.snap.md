----- SOURCE CODE -- main.bp
```botopink
pub type Probe(n: i32) {
    #[@external(.Erlang("""element(2, $0)"""))]
    pub declare fn raw(self: Self) -> i32;
}

pub fn main() {
    @print(Probe(n: 1).raw());
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `Probe.raw` has no implementation for the node backend
  ┌─ :7:24
  │
7 │     @print(Probe(n: 1).raw());
  │                        ^
```

