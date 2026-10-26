-module(bp_load_cases_wasm_host_async@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__run'/0]).

%%% Front 140 step 5 (decisions 392–394) — `Async` on wasm behaves as a Promise,

%%% under wasmtime (`wasi`: `wasi:clocks/monotonic-clock` + `wasi:io/poll`) and

%%% under node (`browser`: the loader's `setTimeout`, the JS event loop), and the

%%% answers equal commonJS's and erlang's. `delay`, `race`, `raceOf` and

%%% `spawnAll` are declared here with the bindings std carries on Node and the

%%% BEAM and decision 393's adapters on wasm (std's own wasm bindings are

%%% `02/97` step 17's). `raceOf` answers the first thunk to SETTLE: the block

%%% that awaits 30 ms loses to the 10 ms delay (392 (1)); `race` over started

%%% tasks answers the first to settle — element zero here too, since erlang's

%%% eager tasks answer element zero; `spawnAll` keeps the order of the input.

%%% Every line is printed from one task chain: the order of effects between

%%% concurrent tasks is no target's contract (335 (2)).

%% external fn delay -> erlang template

%% external fn race -> erlang template

%% external fn raceOf -> erlang template

%% external fn spawnAll -> erlang template

%% @Async — eager lowering
run() ->
    First = (fun(__BpA0) -> try ((fun(__Ts) -> case __Ts of [] -> erlang:error(<<"async.raceOf: empty task list">>); _ -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {error, __C, __E} end} end) end, lists:seq(1, length(__Ts))), case (receive {BpRef, __W} -> __W end) of {ok, __V} -> __V; {error, __C2, __E2} -> erlang:raise(__C2, __E2, []) end end end)(__BpA0)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)([fun() ->
        (fun() ->
            (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(30, 0),
            <<"a">>
        end)()
    end, fun() ->
        (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(10, <<"b">>)
    end]),
    '__bp_print'([<<"raceOf ", ('__bp_text'(First))/binary>>]),
    R = (fun(__BpA0) -> try ((fun(__Fs) -> case __Fs of [] -> erlang:error(<<"async.race: empty task list">>); _ -> hd(__Fs) end end)(__BpA0)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)([(fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(5, <<"x">>), (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(60, <<"y">>)]),
    '__bp_print'([<<"race ", ('__bp_text'(R))/binary>>]),
    All = (fun(__BpA0) -> try ((fun(__Ts) -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, __I, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {crash, __C, __E} end} end) end, lists:seq(1, length(__Ts))), [case (receive {BpRef, BpJ, __X} -> __X end) of {ok, __V} -> __V; {crash, __C2, __E2} -> erlang:raise(__C2, __E2, []) end || BpJ <- lists:seq(1, length(__Ts))] end)(__BpA0)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)([fun() ->
        (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(20, <<"one">>)
    end, fun() ->
        (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(5, <<"two">>)
    end, fun() ->
        (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(1, <<"three">>)
    end]),
    '__bp_print'([<<"spawnAll ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, All)))))/binary>>]),
    N = (fun(__BpA0, __BpA1) -> try ((fun(__M, __V) -> timer:sleep(__M), __V end)(__BpA0, __BpA1)) catch error:{__BpT, __BpM} when __BpT =:= panic orelse __BpT =:= todo orelse __BpT =:= integer_overflow orelse __BpT =:= bp_host -> erlang:error({__BpT, __BpM}); error:{bp_assert, __BpA, __BpB, __BpD} -> erlang:error({bp_assert, __BpA, __BpB, __BpD}); error:{bp_assert, __BpA, __BpB} -> erlang:error({bp_assert, __BpA, __BpB}); throw:'__bp_break' -> erlang:throw('__bp_break'); throw:{__BpT, __BpM} when __BpT =:= '__bp_cond_break' orelse __BpT =:= '__bp_cond_continue' orelse __BpT =:= '__bp_try' orelse __BpT =:= '__bp_gen_stop' -> erlang:throw({__BpT, __BpM}); throw:{'__bp_gen_end', __BpA, __BpB, __BpD} -> erlang:throw({'__bp_gen_end', __BpA, __BpB, __BpD}); __BpC:__BpE -> erlang:error({bp_host, unicode:characters_to_binary(io_lib:format("~tp", [__BpE]))}) end end)(0, 7),
    '__bp_print'(['__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:68:13">>)]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/wasm_host_async|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__run'() -> run().
