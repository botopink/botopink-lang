----- SOURCE CODE -- main.bp
```botopink
val Counter = type(
    count: i32 = 0) {
    fn inc(self: Self) {
        self.count += 1;
    }
};
```

----- COMPILE DIAGNOSTIC -- main
```text
error: a `Counter` is immutable — its field `count` cannot be assigned
  ┌─ :4:9
  │
4 │         self.count += 1;
  │         ^

  hint: Build a new value instead: `Counter(..self, count: <value>)`.
```

