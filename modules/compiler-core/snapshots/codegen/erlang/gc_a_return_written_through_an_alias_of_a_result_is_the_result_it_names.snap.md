----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

type ParseError { Empty }

pub type Parser<T> = Result<T, ParseError>;

pub type Checked<T> = Result<T, string>;

fn parsePort(s: string) -> Result<i32, ParseError> {
    if (s == "") throw ParseError.Empty;
    return 8080;
}

fn port(s: string) -> Parser<i32> {
    return parsePort(s);
}

fn check(n: i32) -> Result<i32, string> {
    if (n < 0) throw "negative";
    return n;
}

fn pass(r: Checked<i32>) -> Checked<i32> {
    return r;
}

pub fn main() -> void {
    print(try port("x") catch 0);
    print(try port("") catch 7);
    print(pass(check(4)).unwrapOr(0));
    print(pass(check(-4)).unwrapOr(0));
    print(pass(check(-1)).isError());
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__parsePort'/1, '__bp_priv__port'/1, '__bp_priv__check'/1, '__bp_priv__pass'/1]).

%% type ParseError
%%   Empty

parsePort(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, test@main@@ParseError__v__empty};
        _ ->
            {ok, 8080}
    end.

port(S) ->
    parsePort(S).

check(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, N}
    end.

pass(R) ->
    R.

main() ->
    '__bp_print'([case port(<<"x">>) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end]),
    '__bp_print'([case port(<<"">>) of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            7
    end]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> (0) end end)(pass(check(4)))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> (0) end end)(pass(check((-4))))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(pass(check((-1))))]).

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

'__bp_priv__parsePort'(A0) -> parsePort(A0).

'__bp_priv__port'(A0) -> port(A0).

'__bp_priv__check'(A0) -> check(A0).

'__bp_priv__pass'(A0) -> pass(A0).
```

----- ERLANG -- test@main@@ParseError.erl
```erlang
-module(test@main@@ParseError).
-export(['__bp_format'/1]).

'__bp_format'(test@main@@ParseError__v__empty) -> {variant, "ParseError.Empty", []}.
```

----- RUN LOG -----
```logs
8080
7
4
0
true
```
