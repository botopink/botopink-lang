----- SOURCE CODE -- main.bp
```botopink
pub type Meter(base: i32) {
    #[@External.Node("""($0.base + $1)"""),
      @External.Erlang("""(element(2, $0) + $1)""")]
    pub declare fn plus(self: Self, n: i32) -> i32;

    #[@External.Node("""[$0.base, $1, $2].join("-")"""),
      @External.Erlang("""iolist_to_binary(lists:join(<<"-">>, [integer_to_binary(element(2, $0)), integer_to_binary($1), $2]))""")]
    pub declare fn label(self: Self, n: i32, tail: string) -> string;

    pub fn twice(self: Self) -> i32 {
        return self.plus(self.base);
    }
}

pub type Level {
    Low,
    High,

    #[@External.Node("""($0.tag === "High" ? $1 * 10 : $1)"""),
      @External.Erlang("""case $0 of 'test@main@@Level__v__high' -> $1 * 10; _ -> $1 end""")]
    pub declare fn scale(self: Self, n: i32) -> i32;
}

pub fn main() {
    val m = Meter(base: 3);
    @print(m.plus(4));
    @print(m.twice());
    @print(m.label(5, "x"));
    @print(Level.High.scale(2));
    @print(Level.Low.scale(2));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `Meter.plus` has no `#[@External.<Target>(…)]` for the wasm backend
  ┌─ :11:21
  │
11 │         return self.plus(self.base);
  │                     ^
```

