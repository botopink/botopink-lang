-module(bp_load_cases_case_multi_subject_patterns@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__classify'/2, '__bp_priv__kind'/2, '__bp_priv__area'/2, '__bp_priv__guarded'/2, '__bp_priv__flags'/2]).

%%% A multi-subject `case a, n { … }` matches every subject against its own

%%% pattern: a literal, a string, a primitive type over a union, a variant that

%%% binds its payload, a guard reading the subjects, `true` / `false`. wasm lowered

%%% the first subject alone and tested no `.multi` pattern, so the first arm

%%% answered every call; beam tested the numbers alone, so a string pattern and

%%% a type arm matched every value (`i32, 0` took `"s"`); commonJS tested a

%%% variant's tag and never bound its payload (`r is not defined`).

%% type Shape
%%   Circle(r)
%%   Square(side)
%%   Empty

classify(A, N) ->
    case {A, N} of
        {0, <<"x">>} ->
            <<"zero-x">>;
        {0, _} ->
            <<"zero">>;
        {_, <<"x">>} ->
            <<"x">>;
        {_, _} ->
            <<"other">>
    end.

kind(V, N) ->
    case {V, N} of
        {I32, 0} when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            <<"int0">>;
        {String, 0} when erlang:is_binary(String) ->
            <<"str0">>;
        {_, _} ->
            <<"any">>
    end.

area(S, K) ->
    case {S, K} of
        {{bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle, R}, 1} ->
            '__bp_int'((R * 100), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:36:33">>);
        {{bp_load_cases_case_multi_subject_patterns@main@@Shape__v__square, Side}, _} ->
            '__bp_int'((Side * K), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:37:39">>);
        {bp_load_cases_case_multi_subject_patterns@main@@Shape__v__empty, _} ->
            (-1);
        {_, _} ->
            0
    end.

guarded(A, B) ->
    case {A, B} of
        {_, _} when (A > B) ->
            <<"gt ", ('__bp_text'(erlang:integer_to_binary(A)))/binary>>;
        {_, _} when (A =:= B) ->
            <<"eq ", ('__bp_text'(erlang:integer_to_binary(B)))/binary>>;
        {_, _} ->
            <<"lt ", ('__bp_text'(erlang:integer_to_binary(B)))/binary>>
    end.

flags(A, B) ->
    case {A, B} of
        {__bp_case_bool_0, __bp_case_bool_1} when ((__bp_case_bool_1 =:= true) andalso (__bp_case_bool_0 =:= true)) ->
            <<"both">>;
        {__bp_case_bool_0@1, __bp_case_bool_1@1} when ((__bp_case_bool_1@1 =:= false) andalso (__bp_case_bool_0@1 =:= true)) ->
            <<"first">>;
        {__bp_case_bool_0@2, __bp_case_bool_1@2} when ((__bp_case_bool_1@2 =:= true) andalso (__bp_case_bool_0@2 =:= false)) ->
            <<"second">>;
        {__bp_case_bool_0@3, __bp_case_bool_1@3} when ((__bp_case_bool_1@3 =:= false) andalso (__bp_case_bool_0@3 =:= false)) ->
            <<"none">>
    end.

main() ->
    '__bp_print'([classify(0, <<"x">>)]),
    '__bp_print'([classify(0, <<"y">>)]),
    '__bp_print'([classify(1, <<"x">>)]),
    '__bp_print'([classify(1, <<"y">>)]),
    '__bp_print'([kind(1, 0)]),
    '__bp_print'([kind(<<"s">>, 0)]),
    '__bp_print'([kind(1, 1)]),
    '__bp_print'([area({bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle, 2}, 1)]),
    '__bp_print'([area({bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle, 2}, 2)]),
    '__bp_print'([area({bp_load_cases_case_multi_subject_patterns@main@@Shape__v__square, 3}, 4)]),
    '__bp_print'([area(bp_load_cases_case_multi_subject_patterns@main@@Shape__v__empty, 9)]),
    '__bp_print'([guarded(5, 2)]),
    '__bp_print'([guarded(3, 3)]),
    '__bp_print'([guarded(1, 7)]),
    '__bp_print'([flags(true, true)]),
    '__bp_print'([flags(true, false)]),
    '__bp_print'([flags(false, true)]),
    '__bp_print'([flags(false, false)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/case_multi_subject_patterns|*">>.

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
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__classify'(A0, A1) -> classify(A0, A1).

'__bp_priv__kind'(A0, A1) -> kind(A0, A1).

'__bp_priv__area'(A0, A1) -> area(A0, A1).

'__bp_priv__guarded'(A0, A1) -> guarded(A0, A1).

'__bp_priv__flags'(A0, A1) -> flags(A0, A1).
