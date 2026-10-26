-module(bp_load_cases_derived_type_functions@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__titleOf'/1, '__bp_priv__patched'/2, '__bp_priv__kind'/1]).

%%% Decision 307 — std's `Type` answers a NEW record type at build, bound by a

%%% module-level `val` and named after it: `pick`, `omit`, `partial`,

%%% `required` and `merge`, nested and chained, each usable in every type

%%% position, constructed by its fields, read, printed and matched by name, on

%%% all four targets.

%% import Type

%% type Recipe: title, description, servings

%% type Dog: name, age

%% type Breed: breed

%% type Note: text

%% type RecipeTitle: title

%% type RecipeBrief: title, servings

%% type RecipePatch: title, description, servings

%% type RecipeFull: title, description, servings

%% type DogWithBreed: name, age, breed

% A derivation of a derivation, and a nested call as the source.

%% type NotedDog: name, age, breed, text

%% type TitleOnly: title

titleOf(T) ->
    erlang:element(2, T).

patched(R, P) ->
    {bp_load_cases_derived_type_functions@main@@Recipe, case erlang:element(2, P) of
        undefined ->
            erlang:element(2, R);
        __bp_nullish ->
            __bp_nullish
    end, case erlang:element(3, P) of
        undefined ->
            erlang:element(3, R);
        __bp_nullish@1 ->
            __bp_nullish@1
    end, case erlang:element(4, P) of
        undefined ->
            erlang:element(4, R);
        __bp_nullish@2 ->
            __bp_nullish@2
    end}.

% Matched by name: a derived type is its own type, not its source's.

kind(V) ->
    case ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 4)) andalso (erlang:element(1, V) =:= bp_load_cases_derived_type_functions@main@@DogWithBreed)) of
        true ->
            <<"DogWithBreed">>;
        _ ->
            case ((erlang:is_tuple(V) andalso (erlang:tuple_size(V) =:= 3)) andalso (erlang:element(1, V) =:= bp_load_cases_derived_type_functions@main@@Dog)) of
                true ->
                    <<"Dog">>;
                _ ->
                    <<"other">>
            end
    end.

main() ->
    '__bp_print'([titleOf({bp_load_cases_derived_type_functions@main@@RecipeTitle, <<"Feijoada">>})]),
    Brief = {bp_load_cases_derived_type_functions@main@@RecipeBrief, <<"Moqueca">>, 2},
    '__bp_print'([erlang:element(3, Brief)]),
    Before = {bp_load_cases_derived_type_functions@main@@Recipe, <<"Feijoada">>, undefined, 2},
    After = patched(Before, {bp_load_cases_derived_type_functions@main@@RecipePatch, undefined, <<"black beans">>, 6}),
    '__bp_print'([erlang:element(2, After)]),
    '__bp_print'([case erlang:element(3, After) of
        undefined ->
            <<"-">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([erlang:element(4, After)]),
    Full = {bp_load_cases_derived_type_functions@main@@RecipeFull, <<"Acaraj\x{C3}\x{A9}">>, <<"fried">>, 4},
    '__bp_print'([erlang:element(3, Full)]),
    Rex = {bp_load_cases_derived_type_functions@main@@DogWithBreed, <<"Rex">>, undefined, <<"mutt">>},
    Bia = {bp_load_cases_derived_type_functions@main@@Dog, <<"Bia">>, 3},
    '__bp_print'([kind(Rex)]),
    '__bp_print'([kind(Bia)]),
    Mixed = {bp_load_cases_derived_type_functions@main@@DogWithBreed, <<"Lua">>, 3, <<"beagle">>},
    '__bp_print'([<<('__bp_text'(erlang:element(2, Mixed)))/binary, " (", ('__bp_text'(erlang:element(4, Mixed)))/binary, ")">>]),
    Noted = {bp_load_cases_derived_type_functions@main@@NotedDog, <<"Lua">>, 1, <<"poodle">>, <<"calm">>},
    '__bp_print'([erlang:element(5, Noted)]),
    '__bp_print'([erlang:element(2, {bp_load_cases_derived_type_functions@main@@TitleOnly, <<"Vatap\x{C3}\x{A1}">>})]),
    '__bp_print'([{bp_load_cases_derived_type_functions@main@@RecipeTitle, <<"Bob\x{C3}\x{B3}">>}]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/derived_type_functions|*">>.

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

'__bp_priv__titleOf'(A0) -> titleOf(A0).

'__bp_priv__patched'(A0, A1) -> patched(A0, A1).

'__bp_priv__kind'(A0) -> kind(A0).
