----- SOURCE CODE -- main.bp
```botopink
type User(name: string, age: i32, next: ?User)

fn nameOf(u: ?User) -> ?string {
    return u?.name;
}

fn ageOf(u: ?User) -> ?i32 {
    return u?.age;
}

pub fn main() {
    val a = User(name: "ann", age: 3, next: null);
    val b = User(name: "bob", age: 4, next: a);
    @print(nameOf(a));
    @print(nameOf(null));
    @print(ageOf(b));
    @print(b.next?.name);
    @print(a.next?.name);
    @print(b.next?.age ?? 0);
    @print(a == b);
    @print(b.next == a);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__nameOf'/1, '__bp_priv__ageOf'/1]).

%% type User: name, age, next

nameOf(U) ->
    (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(U).

ageOf(U) ->
    (fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(U).

main() ->
    A = {test@main@@User, <<"ann">>, 3, undefined},
    B = {test@main@@User, <<"bob">>, 4, A},
    '__bp_print'([nameOf(A)]),
    '__bp_print'([nameOf(undefined)]),
    '__bp_print'([ageOf(B)]),
    '__bp_print'([(fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(erlang:element(4, B))]),
    '__bp_print'([(fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)(erlang:element(4, A))]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(3, _Opt2) end)(erlang:element(4, B)) of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([(A =:= B)]),
    '__bp_print'([(erlang:element(4, B) =:= A)]).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__nameOf'(A0) -> nameOf(A0).

'__bp_priv__ageOf'(A0) -> ageOf(A0).
```

----- ERLANG -- test@main@@User.erl
```erlang
-module(test@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V);
'__bp_get'(V, next) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "User", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}, {"next", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
ann
null
4
ann
null
3
false
true
```
