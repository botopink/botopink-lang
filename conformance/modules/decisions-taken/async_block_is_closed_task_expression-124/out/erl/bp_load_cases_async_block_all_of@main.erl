-module(bp_load_cases_async_block_all_of@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__fetchUser'/1, '__bp_priv__launch'/2, '__bp_priv__show'/1, '__bp_priv__run'/0]).

%%% Decision 124 of 1.0.10-beta (front 24, § Cells "`async { }`", first line;

%%% guide.md § 3.1) — `async { … }` creates a `Async` in ANY function: `launch`

%%% is a plain function (it answers a record, not a wrapper), builds two blocks

%%% and passes them to `async.allOf`. Each block's `try await` makes its value

%%% `Result<string, string>`, so each block is `Async<Result<string, string>>`.

%%% 

%%% `allOf` is taken in the shape front 24 step E7 writes —

%%% `allOf(Array<Async<Result<T, E>>>) -> Async<Result<Array<T>, E>>`, started

%%% Tasks, stopping at the first error (the README's open point 3 leaves the

%%% thunk shape of `01-std/02` open; the cell follows E7 and the guide).

%%% Printed from inside `run`.

%%% 

%%% On every target: `std/async` binds on wasm's two hosts (144 B-25, decision

%%% 334), so the blocks run there as state machines under both.

%% import async

%% type Batch: task

%% @Async — eager lowering
fetchUser(Id) ->
    case (Id =< 0) of
        true ->
            {error, <<"user ", ('__bp_text'(erlang:integer_to_binary(Id)))/binary, " does not exist">>};
        _ ->
            {ok, <<"user", ('__bp_text'(erlang:integer_to_binary(Id)))/binary>>}
    end.

launch(A, B) ->
    All = std@async:allOf([(fun() ->
        fetchUser(A)
    end)(), (fun() ->
        fetchUser(B)
    end)()]),
    {bp_load_cases_async_block_all_of@main@@Batch, All}.

show(R) ->
    case R of
        {ok, Names} ->
            '__bp_print'([<<"ok ", ('__bp_text'(iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Names)))))/binary>>]);
        {error, E} ->
            '__bp_print'([<<"error ", ('__bp_text'(E))/binary>>])
    end.

%% @Async — eager lowering
run() ->
    Good = launch(1, 2),
    show(erlang:element(2, Good)),
    Bad = launch(1, 0),
    show(erlang:element(2, Bad)).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/async_block_all_of|*">>.

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

'__bp_priv__fetchUser'(A0) -> fetchUser(A0).

'__bp_priv__launch'(A0, A1) -> launch(A0, A1).

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__run'() -> run().
