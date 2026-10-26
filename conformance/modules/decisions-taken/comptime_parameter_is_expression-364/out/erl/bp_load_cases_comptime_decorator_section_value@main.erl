-module(bp_load_cases_comptime_decorator_section_value@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__label'/1, '__bp_priv__fallback'/0, '__bp_priv__styled'/0, '__bp_priv__array_first'/1]).

%% type Bp__Tok__Pad
%%   All(_inner)

%% type Bp__Tok__Pad__All
%%   __4
%%   __8

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

%%% `conformance/docs.md` § Sections of an enum, decisions 331 and 364 — a decorator's

%%% `@Expr<T>.value` holds a value under a section (`#[mark(.Pad.All.4)]`),

%%% and a function of the module the decorator reaches may write one

%%% (`fallback()`): both cross into the decorator's comptime module as the

%%% qualified constructor inference resolved, on both runtimes. The parent

%%% binary re-read the argument and the body as written, untyped:

%%% `{error,{badmap,'Pad'}}` at the annotation.

%% type Tok
%%   Bold
%%   Pad(_inner)

label(T) ->
    case T of
        {bp_load_cases_comptime_decorator_section_value@main@@Tok__v__pad, P} ->
            case P of
                {bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__v__all, A} ->
                    case A of
                        bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All__v__4 ->
                            <<"pad-4">>;
                        bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All__v__8 ->
                            <<"pad-8">>
                    end
            end;
        bp_load_cases_comptime_decorator_section_value@main@@Tok__v__bold ->
            <<"bold">>
    end.

fallback() ->
    {bp_load_cases_comptime_decorator_section_value@main@@Tok__v__pad, {bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__v__all, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All__v__8}}.

styled() ->
    <<"styled">>.

main() ->
    Labels = case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(array_first([{bp_load_cases_comptime_decorator_section_value@main@@Mark, [<<"pad-4">>, <<"bold">>, <<"pad-8">>], <<"pad-8">>}])) of
        undefined ->
            [];
        __bp_nullish ->
            __bp_nullish
    end,
    '__bp_print'([iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Labels)))]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(3, _Opt1) end)(array_first([{bp_load_cases_comptime_decorator_section_value@main@@Mark, [<<"pad-4">>, <<"bold">>, <<"pad-8">>], <<"pad-8">>}])) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([styled()]).

% What `#[mark]` records: each token's label, and the fallback's.

%% type Mark: labels, fallback

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/comptime_decorator_section_value|*">>.

array_first(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Self, 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__label'(A0) -> label(A0).

'__bp_priv__fallback'() -> fallback().

'__bp_priv__styled'() -> styled().

'__bp_priv__array_first'(A0) -> array_first(A0).
