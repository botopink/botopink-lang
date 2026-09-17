----- SOURCE CODE -- main.bp
```botopink
behavior Bounded {
    fn min(self: Self, other: Self) -> Self;
    fn max(self: Self, other: Self) -> Self;

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

type Money(
    cents: i32,
) implement Bounded {
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
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

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
