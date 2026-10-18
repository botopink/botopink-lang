----- SOURCE CODE -- main.bp
```botopink
pub fn main() {
    val b = Bytes.fromUtf8("hello");
    print(b.length());
    print(b.slice(1, 3).length());
    val c = b.concat(Bytes.fromUtf8("!"));
    print(c.length());
    print(b == Bytes.fromUtf8("hello"));
    val r = b.toUtf8();
    print(r);
    val parts = "a,b,c".split(",");
    print(parts);
    print("hello".at(1));
    print("hello".at(9));
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__bytes_slice'/3]).

%% behavior Bytes

main() ->
    B = <<"hello">>,
    '__bp_print'([byte_size(B)]),
    '__bp_print'([byte_size(bytes_slice(B, 1, 3))]),
    C = <<(B)/binary, (<<"!">>)/binary>>,
    '__bp_print'([byte_size(C)]),
    '__bp_print'([(B =:= <<"hello">>)]),
    R = (fun(__B) -> case unicode:characters_to_binary(__B) of __S when is_binary(__S) -> {ok, __S}; _ -> {error, <<"Bytes.toUtf8: not valid UTF-8">>} end end)(B),
    '__bp_print'([R]),
    Parts = (fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(<<"a,b,c">>, <<",">>),
    '__bp_print'([Parts]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"hello">>, 1)]),
    '__bp_print'([(fun(__S, __I) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case (__J >= 0) andalso (__J < __N) of true -> unicode:characters_to_binary([lists:nth(__J + 1, __L)]); false -> undefined end end)(<<"hello">>, 9)]).

bytes_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__B, __A, __E) -> __N = byte_size(__B), __S = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, binary:part(__B, __S, erlang:max(__F - __S, 0)) end)(Self, Start, End);
        false ->
            (fun(__B, __A) -> __N = byte_size(__B), __S = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, binary:part(__B, __S, __N - __S) end)(Self, Start)
    end.

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

'__bp_priv__bytes_slice'(A0, A1, A2) -> bytes_slice(A0, A1, A2).
```

----- RUN LOG -----
```logs
5
2
6
true
Ok("hello")
["a", "b", "c"]
e
null
```
