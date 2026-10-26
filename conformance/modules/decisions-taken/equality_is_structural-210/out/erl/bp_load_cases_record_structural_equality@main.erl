-module(bp_load_cases_record_structural_equality@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__same'/2]).

%%% Decision 210 — `==` compares by value on every target. Two records of the

%%% same type with equal fields are equal, recursively through a nested

%%% record, a tuple, an `Array` and an enum variant's payload; two values of

%%% different types are never equal, however alike their fields (decision 21:

%%% a value carries its declaring type); `!=` is the negation. erlang and beam

%%% compare one term (`=:=`); commonJS and wasm answered `false` for two equal

%%% records — a reference and a pointer — and now call an equality generated

%%% per compared type. A generic body (`same<T>`) answers by value too.

%%% Decision 211: `==` is always field by field — a method named `equals`

%%% has no special role and `==` never calls user code.

%% type Person: name, age

%% type Vec: name, age

%% type Team: lead, size

%% type Loose: n

%% type Shape
%%   Circle(r)
%%   Rect(w, h)
%%   Dot

same(A, B) ->
    (A =:= B).

main() ->
    Built = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(<<"Ana,x">>, <<",">>), 0) of
        undefined ->
            <<"">>;
        __bp_nullish ->
            __bp_nullish
    end,
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =:= {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, Built, 30} =:= {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =:= {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 31})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =:= {bp_load_cases_record_structural_equality@main@@Person, <<"Bia">>, 30})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =/= {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =/= {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 31})]),
    P = {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30},
    '__bp_print'([(P =:= P)]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Team, {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30}, 3} =:= {bp_load_cases_record_structural_equality@main@@Team, {bp_load_cases_record_structural_equality@main@@Person, Built, 30}, 3})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Team, {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30}, 3} =:= {bp_load_cases_record_structural_equality@main@@Team, {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 29}, 3})]),
    T1 = {1, <<"a">>},
    A = case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)((fun(__S, <<>>) -> [<<__C/utf8>> || <<__C/utf8>> <= __S]; (__S, __X) -> string:split(__S, __X, all) end)(<<"a;y">>, <<";">>), 0) of
        undefined ->
            <<"">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end,
    T2 = {1, A},
    T3 = {1, <<"b">>},
    T4 = {2, <<"a">>},
    '__bp_print'([(T1 =:= T2)]),
    '__bp_print'([(T1 =:= T3)]),
    '__bp_print'([(T1 =/= T4)]),
    Xs = [{bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30}, {bp_load_cases_record_structural_equality@main@@Person, <<"Bia">>, 25}],
    Ys = [{bp_load_cases_record_structural_equality@main@@Person, Built, 30}, {bp_load_cases_record_structural_equality@main@@Person, <<"Bia">>, 25}],
    Zs = [{bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30}],
    '__bp_print'([(Xs =:= Ys)]),
    '__bp_print'([(Xs =:= Zs)]),
    '__bp_print'([(Xs =/= Zs)]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Shape__v__circle, 2} =:= {bp_load_cases_record_structural_equality@main@@Shape__v__circle, 2})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Shape__v__circle, 2} =:= {bp_load_cases_record_structural_equality@main@@Shape__v__circle, 3})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Shape__v__rect, 1, 2} =:= {bp_load_cases_record_structural_equality@main@@Shape__v__rect, 1, 2})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Shape__v__rect, 1, 2} =:= {bp_load_cases_record_structural_equality@main@@Shape__v__circle, 1})]),
    '__bp_print'([(bp_load_cases_record_structural_equality@main@@Shape__v__dot =:= bp_load_cases_record_structural_equality@main@@Shape__v__dot)]),
    '__bp_print'([(bp_load_cases_record_structural_equality@main@@Shape__v__dot =/= {bp_load_cases_record_structural_equality@main@@Shape__v__circle, 0})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =:= {bp_load_cases_record_structural_equality@main@@Vec, <<"Ana">>, 30})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30} =/= {bp_load_cases_record_structural_equality@main@@Vec, <<"Ana">>, 30})]),
    '__bp_print'([same({bp_load_cases_record_structural_equality@main@@Person, Built, 30}, {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30})]),
    '__bp_print'([same({bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 30}, {bp_load_cases_record_structural_equality@main@@Person, <<"Ana">>, 1})]),
    '__bp_print'([same(T1, T2)]),
    '__bp_print'([same([1, 2], [1, 2])]),
    '__bp_print'([same({bp_load_cases_record_structural_equality@main@@Shape__v__rect, 1, 2}, {bp_load_cases_record_structural_equality@main@@Shape__v__rect, 1, 2})]),
    '__bp_print'([({bp_load_cases_record_structural_equality@main@@Loose, 1} =:= {bp_load_cases_record_structural_equality@main@@Loose, 2})]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/record_structural_equality|*">>.

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

'__bp_priv__same'(A0, A1) -> same(A0, A1).
