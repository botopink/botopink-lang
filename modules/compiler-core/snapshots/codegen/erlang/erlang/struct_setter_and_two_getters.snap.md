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

----- RUN LOG -----
```logs
Error! Failed to load module 'main' because it cannot be found.
Make sure that the module name is correct and that its .beam file
is in the code path.

Runtime terminating during boot ({undef,[{init,start_it,1,[]},{init,start_em,1,[]},{init,do_boot,3,[]}]})

Crash dump is being written to: erl_crash.dump...done
```
