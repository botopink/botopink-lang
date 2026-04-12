----- SOURCE CODE -- main.bp
```botopink
val Temperature = struct {
    _celsius: f64 = 0.0,
    set celsius(self: Self, value: f64) {
        self._celsius = value;
    }
    get celsius(self: Self) -> f64 {
        return self._celsius;
    }
    get fahrenheit(self: Self) -> f64 {
        return self._celsius * 1.8 + 32.0;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Temperature, {_celsius}).
```
