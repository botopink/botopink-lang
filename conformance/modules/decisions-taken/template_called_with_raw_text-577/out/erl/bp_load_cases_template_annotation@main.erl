-module(bp_load_cases_template_annotation@main).
-export(['_botopink_main'/0, main/1]).
-export([logout/1, main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__array_first'/1]).

%% behavior string

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

%%% Decision 311 — the template annotation `#[f @`…`]`: the template call

%%% `f @`…`` written as an annotation. `query` is a template function whose

%%% second parameter receives the annotated declaration (question s29-a); the

%%% text is captured unevaluated, as at a call site, and its `${…}` holes are

%%% the template's own syntax (decision 577 (1)): it reads each one's

%%% expression from `compiler.text(q)`. What the template records goes where

%%% a decorator's does: typed meta of the method, read by the owner's

%%% decorator on `decl.methods` (`m.meta(Query)`, question s29-b: a method's

%%% decorators run before its owner's), and typed meta of a function, read by

%%% `compiler.typeInfo(f).meta(Query)`. A template annotation sits beside a

%%% decorator, and its text may span lines. `decl.params` is a method's own

%%% parameter list.

%% type Query: sql, params

%% type Audit: level

%% behavior Users

logout(User) ->
    <<User/binary, " out">>.

main() ->
    Statements = case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(array_first([{bp_load_cases_template_annotation@main@@Repository, [<<"find(self, id): select * from users where id = $1 limit 1 <- id">>, <<"byName(self, name, minAge): select * from users where name = $1 and age > $2 <- name, minAge (audit 2)">>]}])) of
        undefined ->
            [];
        __bp_nullish ->
            __bp_nullish
    end,
    '__bp_print'([iolist_to_binary(lists:join(<<" | ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, Statements)))]),
    M = array_first([{bp_load_cases_template_annotation@main@@Query, <<"delete from sessions where user = $1">>, [<<"user">>]}]),
    '__bp_print'([<<('__bp_text'(erlang:element(2, case M of
        undefined ->
            erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} m! at src/main.bp:118:11">>});
        __bp_opt_118_12 ->
            __bp_opt_118_12
    end)))/binary, " <- ", ('__bp_text'(iolist_to_binary(lists:join(<<", ">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, erlang:element(3, case M of
        undefined ->
            erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} m! at src/main.bp:118:29">>});
        __bp_opt_118_30 ->
            __bp_opt_118_30
    end))))))/binary>>]),
    '__bp_print'([logout(<<"ana">>)]).

% What `#[repository]` records: one statement per method that carries a query.

%% type Repository: statements

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/template_annotation|*">>.

array_first(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Self, 0).

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__array_first'(A0) -> array_first(A0).
