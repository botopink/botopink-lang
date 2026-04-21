----- SOURCE CODE -- main.bp
```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Vec2, {x, y}).

lengthSq() ->
    ((Self_x * Self_x) + (Self_y * Self_y)).

scale(Factor) ->
    (Self_x * Factor).
```
