----- SOURCE CODE -- main.bp
```botopink
interface Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

fn main() {
    val n: i32 = 50;
    @print(n.clamp(0, 10));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Number

main() ->
    N = 50,
    '__bp_print'([number_clamp(N, 0, 10)]).

number_clamp(Self, Lo, Hi) ->
    erlang:min(erlang:max(Self, Lo), Hi).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
10
```
