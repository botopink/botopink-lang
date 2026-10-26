-module(bp_load_cases_external_result_host_error@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__hostError'/2, '__bp_priv__doubleBody'/1, '__bp_priv__thrownBody'/1, '__bp_priv__answeredBody'/1, '__bp_priv__laterBody'/1, '__bp_priv__show'/1, '__bp_priv__run'/0]).

%%% Decisions 431 (2), 489, 490 — a binding that writes `result: true` answers

%%% `Result<T, HostError>`: a value is `Ok(v)`, and every way the host fails is

%%% `Error(HostError(message, "host", name, detail))`. On commonJS a sync

%%% binding runs in a `try`/`catch` and a `Async` one's rejection is caught;

%%% on erlang and beam the call runs in a `try … catch Class:Reason`, and a

%%% host that answers `{error, R}` is an `Error` too. `name` is the same on

%%% every target: a JavaScript `Error` and an erlang `error` raise are

%%% `HostErrorName.Error`, any other thrown value and an erlang `throw` are

%%% `HostErrorName.Throw`. `message` is the host's text: `e.message` (else

%%% `String(e)`), the erlang reason by `~tp` — an atom here, so both read alike.

%%% `detail`, the stack, is not printed: a backend may leave it empty.

%%% 

%%% wasm has no host that raises: a wasm binding is an opcode, a private fn

%%% (`fn:`, where `result:` is refused, decision 491) or a WASI adapter, and

%%% none of today's adapters fails. Each binding here is a private fn on wasm

%%% that answers the value the other hosts answer.

%% import HostError, HostErrorName

%% external fn double -> erlang template

%% external fn thrown -> erlang template

%% external fn answered -> erlang template

%% external fn later -> erlang template

hostError(Message, Name) ->
    {std@failure@@HostError, Message, <<"host">>, Name, undefined}.

doubleBody(N) ->
    case (N < 0) of
        true ->
            {error, hostError(<<"negative">>, std@failure@@HostErrorName__v__error)};
        _ ->
            {ok, '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:54:14">>)}
    end.

thrownBody(N) ->
    case (N =< 0) of
        true ->
            {error, hostError(<<"refused">>, std@failure@@HostErrorName__v__throw)};
        _ ->
            {ok, N}
    end.

answeredBody(N) ->
    case (N =< 0) of
        true ->
            {error, hostError(<<"refused">>, std@failure@@HostErrorName__v__error)};
        _ ->
            {ok, '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:64:14">>)}
    end.

%% @Async — eager lowering
laterBody(N) ->
    case (N =< 0) of
        true ->
            {error, hostError(<<"late">>, std@failure@@HostErrorName__v__error)};
        _ ->
            {ok, '__bp_int'((N * 3), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:69:14">>)}
    end.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"ok">>, V]);
        {error, E} ->
            '__bp_print'([<<"error">>, erlang:element(2, E), erlang:element(3, E), erlang:element(4, E)])
    end.

%% @Async — eager lowering
run() ->
    show((fun(__BpA0) -> try ((case __BpA0 >= 0 of true -> __BpA0 * 2; false -> erlang:error(negative) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(21)),
    show((fun(__BpA0) -> try ((case __BpA0 >= 0 of true -> __BpA0 * 2; false -> erlang:error(negative) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)((-1))),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> __BpA0; false -> throw(refused) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(5)),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> __BpA0; false -> throw(refused) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(0)),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> {ok, __BpA0 + 1}; false -> {error, refused} end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(1)),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> {ok, __BpA0 + 1}; false -> {error, refused} end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(0)),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> __BpA0 * 3; false -> erlang:error(late) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(2)),
    show((fun(__BpA0) -> try ((case __BpA0 > 0 of true -> __BpA0 * 3; false -> erlang:error(late) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(0)),
    A = case (fun(__BpA0) -> try ((case __BpA0 >= 0 of true -> __BpA0 * 2; false -> erlang:error(negative) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)((-4)) of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            7
    end,
    B = case (fun(__BpA0) -> try ((case __BpA0 > 0 of true -> __BpA0 * 3; false -> erlang:error(late) end)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)((-1)) of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            100
    end,
    '__bp_print'(['__bp_add'(A, B)]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/external_result_host_error|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__hostError'(A0, A1) -> hostError(A0, A1).

'__bp_priv__doubleBody'(A0) -> doubleBody(A0).

'__bp_priv__thrownBody'(A0) -> thrownBody(A0).

'__bp_priv__answeredBody'(A0) -> answeredBody(A0).

'__bp_priv__laterBody'(A0) -> laterBody(A0).

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__run'() -> run().
