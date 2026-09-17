----- SOURCE CODE -- main.bp
```botopink
interface Bounded {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

record Money implement Bounded {
    cents: i32,

    fn min(self: Self, other: Self) -> Self {
        return if (self.cents < other.cents) { self; } else { other; };
    }

    fn max(self: Self, other: Self) -> Self {
        return if (self.cents > other.cents) { self; } else { other; };
    }
}

fn main() {
    val m = Money(cents: 500).clamp(Money(cents: 0), Money(cents: 120));
    @print(m.cents);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-compile({no_auto_import,[min/2, max/2]}).
-export(['_botopink_main'/0, main/1]).

%% interface Bounded

%% record Money: cents

min(Self, Other) ->
    case (maps:get(cents, Self) < maps:get(cents, Other)) of
        true ->
            Self;
        false ->
            Other
    end.

max(Self, Other) ->
    case (maps:get(cents, Self) > maps:get(cents, Other)) of
        true ->
            Self;
        false ->
            Other
    end.

main() ->
    M = clamp(#{cents => 500}, #{cents => 0}, #{cents => 120}),
    '__bp_print'([maps:get(cents, M)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:26:9: function clamp/3 undefined
```
