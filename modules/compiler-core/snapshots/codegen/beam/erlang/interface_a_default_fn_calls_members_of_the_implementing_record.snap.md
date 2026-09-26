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
-module(test@main).
-export(['_botopink_main'/0, main/1]).

%% behavior Bounded

%% type Money: cents

main() ->
    M = test@main@@Money:clamp({test@main@@Money, 500}, {test@main@@Money, 0}, {test@main@@Money, 120}),
    '__bp_print'([element(2, M)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@Money.erl
```erlang
-module(test@main@@Money).
-compile({no_auto_import,[min/2, max/2]}).
-export([min/2, max/2, clamp/3, '__bp_get'/2, '__bp_format'/1]).

min(Self, Other) ->
    case (element(2, Self) < element(2, Other)) of
        true ->
            Self;
        false ->
            Other
    end.

max(Self, Other) ->
    case (element(2, Self) > element(2, Other)) of
        true ->
            Self;
        false ->
            Other
    end.

clamp(Self, Lo, Hi) ->
    min(max(Self, Lo), Hi).

'__bp_get'(V, cents) -> element(2, V).

'__bp_format'(V) -> {record, "Money", [{"cents", element(2, V)}]}.
```

----- RUN LOG -----
```logs
120
```
