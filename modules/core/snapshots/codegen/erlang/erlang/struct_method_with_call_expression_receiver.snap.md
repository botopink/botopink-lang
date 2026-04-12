----- SOURCE CODE -- main.bp
```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(Logger, {_prefix}).

setPrefix(P) ->
    %% self._prefix = ....

log(Msg) ->
    console:log(Self__prefix, Msg).
```
