----- SOURCE CODE -- main.bp
```botopink
val Vec2 = type(
    x: f64,
    y: f64) {
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
-module(test@main).

%% type Vec2: x, y
```

----- ERLANG -- test@main@@Vec2.erl
```erlang
-module(test@main@@Vec2).
-export([lengthSq/1, scale/2, '__bp_get'/2, '__bp_format'/1]).

lengthSq(Self) ->
    ((element(2, Self) * element(2, Self)) + (element(3, Self) * element(3, Self))).

scale(Self, Factor) ->
    (element(2, Self) * Factor).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "Vec2", [{"x", element(2, V)}, {"y", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
