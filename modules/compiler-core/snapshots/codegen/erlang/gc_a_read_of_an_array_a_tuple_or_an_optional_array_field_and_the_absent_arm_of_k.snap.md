----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type Field(name: string)

type Form(fields: ?Field[], tags: string[], range: #(i32, i32))

fn make(k: i32) -> ?Form {
    if (k == 0) return null;
    return Form(fields: [Field(name: "email")], tags: ["a", "b"], range: #(1, 2));
}

pub fn main() -> void {
    val f = make(1);
    val tags: string[] = f?.tags ?? [];
    print(tags.join(","));
    val none: string[] = make(0)?.tags ?? [];
    print(none.length);
    val r = f?.range ?? #(0, 0);
    print(r);
    print(f?.fields?.[0]?.name ?? "none");
    print(make(0)?.fields?.[0]?.name ?? "none");
    val empty: ?Form = Form(fields: null, tags: [], range: #(3, 4));
    print(empty?.fields?.[0]?.name ?? "none");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__make'/1]).

%% type Field: name

%% type Form: fields, tags, range

make(K) ->
    case (K =:= 0) of
        true ->
            undefined;
        _ ->
            {test@main@@Form, [{test@main@@Field, <<"email">>}], [<<"a">>, <<"b">>], {1, 2}}
    end.

main() ->
    F = make(1),
    Tags = case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(F) of
        undefined ->
            [];
        __bp_nullish ->
            __bp_nullish
    end,
    '__bp_print'([iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Tags)))]),
    None = case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(3, _Opt1) end)(make(0)) of
        undefined ->
            [];
        __bp_nullish@1 ->
            __bp_nullish@1
    end,
    '__bp_print'([erlang:length(None)]),
    R = case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(4, _Opt2) end)(F) of
        undefined ->
            {0, 0};
        __bp_nullish@2 ->
            __bp_nullish@2
    end,
    '__bp_print'([R]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)(case (fun(undefined) -> undefined; (_Opt4) -> erlang:element(2, _Opt4) end)(F) of
        undefined ->
            undefined;
        __bp_opt_20_20 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_20_20, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt5) -> erlang:element(2, _Opt5) end)(case (fun(undefined) -> undefined; (_Opt6) -> erlang:element(2, _Opt6) end)(make(0)) of
        undefined ->
            undefined;
        __bp_opt_21_26 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_21_26, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    Empty = {test@main@@Form, undefined, [], {3, 4}},
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt7) -> erlang:element(2, _Opt7) end)(case (fun(undefined) -> undefined; (_Opt8) -> erlang:element(2, _Opt8) end)(Empty) of
        undefined ->
            undefined;
        __bp_opt_23_24 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_23_24, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]).

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

'__bp_priv__make'(A0) -> make(A0).
```

----- ERLANG -- test@main@@Field.erl
```erlang
-module(test@main@@Field).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Field", [{"name", erlang:element(2, V)}]}.
```

----- ERLANG -- test@main@@Form.erl
```erlang
-module(test@main@@Form).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, fields) -> erlang:element(2, V);
'__bp_get'(V, tags) -> erlang:element(3, V);
'__bp_get'(V, range) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Form", [{"fields", erlang:element(2, V)}, {"tags", erlang:element(3, V)}, {"range", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
a,b
0
#(1, 2)
email
none
none
```
