----- SOURCE CODE -- main.bp
```botopink
record Vec2 {
    x: f64,
    y: f64,
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Vec2, {x, y}).

dot(Other) ->
    ((Self_x * Other_x) + (Self_y * Other_y)).
```
