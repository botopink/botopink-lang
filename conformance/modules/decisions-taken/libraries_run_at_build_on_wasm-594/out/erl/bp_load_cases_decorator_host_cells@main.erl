-module(bp_load_cases_decorator_host_cells@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, label/0, '__bp_priv__bangBody'/1, '__bp_priv__tagged'/1]).

%%% Decisions 341, 434 — a decorator body calls a host function, and the

%%% function travels into the decorator module; comptime runs on the wasm

%%% runtime for every target, which answers `bang` by its `compiler.external(.Wasm)(fn: …)`

%%% cell (its `compiler.external(.Erlang)` cell is never run at build, decision 452). A std host function travels the same way, reached through its

%%% namespace (`hash.contentHash`) or a leaf import (`contentHash`), and

%%% answers std-wasm's text. One comptime answer, so the four targets print

%%% the same. Before decision 341, every such call was `call to undefined

%%% function bang/1` in the decorator module.

%% import hash

%% import digest

%% external fn bang -> erlang template

bangBody(Value) ->
    <<Value/binary, "!">>.

tagged(Name) ->
    <<((fun(__BpA0) -> try (<<(__BpA0)/binary, "!">>) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(Name))/binary, " ", ('__bp_text'(std@hash:contentHash(Name)))/binary>>.

%% type Point: x, y

main() ->
    '__bp_print'([label()]),
    '__bp_print'([<<((fun(__BpA0) -> try (<<(__BpA0)/binary, "!">>) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(<<"run">>))/binary, " ", ('__bp_text'(std@hash:contentHash(<<"Point">>)))/binary>>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/decorator_host_cells|*">>.

label() ->
    <<"Point! de553cf 70c9d2a9">>.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'__bp_priv__bangBody'(A0) -> bangBody(A0).

'__bp_priv__tagged'(A0) -> tagged(A0).
