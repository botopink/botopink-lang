-module(bp_load_cases_meta_field_tuple_and_field_key@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_first'/1]).

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

%%% Decision 298 — a meta record's field may hold a tuple of data and a

%%% `Type.Field<T>`: each is rebuilt where the meta is read, the tuple as

%%% written (`#(1, 9)`) and the field as its run-time form, `Field(Book,

%%% "pages")` (decision 631). Read back here on every target (144 B-19).

%% import Type, Type__Field

%% type Span: range, label

%% type Sort: by, keys

%% type Book: title, pages

main() ->
    S = array_first([{bp_load_cases_meta_field_tuple_and_field_key@main@@Span, {1, 9}, <<"Book">>}]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(S) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    R = case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)(S) of
        undefined ->
            {0, 0};
        __bp_nullish@1 ->
            __bp_nullish@1
    end,
    '__bp_print'(['__bp_add'(erlang:element(1, R), erlang:element(2, R))]),
    O = array_first([{bp_load_cases_meta_field_tuple_and_field_key@main@@Sort, {std@types@@Type__Field, {'__bp_type', bp_load_cases_meta_field_tuple_and_field_key@main@@Book, [{bp_load_cases_meta_field_tuple_and_field_key@main@@Book, 3}]}, <<"pages">>, <<"">>, []}, [{std@types@@Type__Field, {'__bp_type', bp_load_cases_meta_field_tuple_and_field_key@main@@Book, [{bp_load_cases_meta_field_tuple_and_field_key@main@@Book, 3}]}, <<"pages">>, <<"">>, []}]}]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(3, _Opt2) end)((fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)(O)) of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case erlang:length((fun(undefined) -> undefined; (_Opt4) -> erlang:element(3, _Opt4) end)(O)) of
        undefined ->
            0;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/meta_field_tuple_and_field_key|*">>.

array_first(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Self, 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__array_first'(A0) -> array_first(A0).
