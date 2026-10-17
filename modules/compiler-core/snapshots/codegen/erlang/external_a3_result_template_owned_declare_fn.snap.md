----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang( """(fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)($0)"""),
  @External.Node("""(() => { const __n = Number($0); return Number.isFinite(__n) ? { ok: __n } : { error: "not a number" } })()""")]
pub declare fn parseInt(s: string) -> @Result<i32, string>;

fn main() {
    val r = parseInt("42");
    @print(r.unwrapOr(-1));
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([parseInt/1, '__bp_priv__main'/0]).

%% external fn parseInt -> erlang template
parseInt(S) ->
    (fun(__BpA0) -> try ((fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)(__BpA0)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(S).

main() ->
    R = (fun(__BpA0) -> try ((fun(__S) -> try {ok, binary_to_integer(__S)} catch _:_ -> {error, <<"not a number">>} end end)(__BpA0)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(<<"42">>),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ((-1)) end end)(R)]).

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__main'() -> main().
```

----- RUN LOG -----
```logs
42
```
