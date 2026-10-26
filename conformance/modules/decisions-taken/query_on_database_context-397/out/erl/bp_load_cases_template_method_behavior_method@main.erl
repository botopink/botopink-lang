-module(bp_load_cases_template_method_behavior_method@main).
-export(['_botopink_main'/0, main/1]).
-export([wave/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0]).

%%% Decisions 311 (3), 397 (3) — a template method is a name of the call

%%% site's scope; a method the receiver's type has of that name is the

%%% type's, whether written in its body or reached through a behavior it

%%% implements — the behavior's own default included — and a value of a

%%% behavior has the methods it declares. `x.greet "…"` calls that method; on

%%% a type without one, the template method runs.

%% import code

%% behavior Greets

%% behavior Waves

%% type Greeter: who

%% type Waver: name

%% type Visitor: who

wave(W) ->
    '__bp_method'(greet, W, [<<"hi">>]).

main() ->
    '__bp_print'([bp_load_cases_template_method_behavior_method@main@@Greeter:greet({bp_load_cases_template_method_behavior_method@main@@Greeter, <<"Ana">>}, <<"hello">>)]),
    '__bp_print'(['__bp_method'(greet, {bp_load_cases_template_method_behavior_method@main@@Waver, <<"Caio">>}, [<<"hello">>])]),
    '__bp_print'([wave({bp_load_cases_template_method_behavior_method@main@@Waver, <<"Duda">>})]),
    '__bp_print'([<<"template hello, ", ('__bp_text'(erlang:element(2, {bp_load_cases_template_method_behavior_method@main@@Visitor, <<"Bia">>})))/binary>>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/template_method_behavior_method|*">>.

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

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
