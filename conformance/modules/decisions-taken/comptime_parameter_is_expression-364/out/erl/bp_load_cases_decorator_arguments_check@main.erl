-module(bp_load_cases_decorator_arguments_check@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__passwordsMatch'/1, '__bp_priv__handleFree'/1, '__bp_priv__passwordNotHandle'/1, '__bp_priv__array_first'/1]).

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

%%% Decision 280, example 1 (`01-checker/examples/decorator-arguments-280.md`)

%%% — `#[check]` on a type and on a function. Every parameter is `comptime`;

%%% `@Decl<T>` binds `T` to the annotated declaration, so `rule` is checked

%%% as an `fn(v: Account) -> bool` and `at` as a field of `Account` (`.confirm`,

%%% `Type.Field<T>` of decision 308); `code` takes a variant written as

%%% declared. The body reads the field key's `name` and the variant as values,

%%% each `x.value` of its `comptime x: @Expr<T>` (decision 364); `rule` is an

%%% `@Expr` of a function, which has no `.value` — the function form is told

%%% apart by the declaration's kind (question `s35-b`).

%% import Type, DeclKind, Type__Field

%% type Code
%%   Custom
%%   Required
%%   TooShort
%%   Mismatch

%% type Account: handle, password, confirm

passwordsMatch(A) ->
    (erlang:element(3, A) =:= erlang:element(4, A)).

handleFree(A) ->
    (erlang:element(2, A) =/= <<"admin">>).

passwordNotHandle(A) ->
    (not (string:find(erlang:element(3, A), erlang:element(2, A)) =/= nomatch)).

main() ->
    lists:foreach(fun(C) ->
        '__bp_print'([<<('__bp_text'(erlang:element(3, C)))/binary, " (", ('__bp_text'(erlang:element(4, C)))/binary, ")">>])
    end, [{bp_load_cases_decorator_arguments_check@main@@Check, <<"confirm">>, <<"passwords differ">>, <<"custom">>}, {bp_load_cases_decorator_arguments_check@main@@Check, <<"handle">>, <<"handle taken">>, <<"mismatch">>}]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(3, _Opt0) end)(array_first([{bp_load_cases_decorator_arguments_check@main@@Check, <<"rule">>, <<"the password holds the handle">>, <<"rule">>}])) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    A = {bp_load_cases_decorator_arguments_check@main@@Account, <<"ana">>, <<"abc">>, <<"abd">>},
    '__bp_print'([passwordsMatch(A)]),
    '__bp_print'([handleFree(A)]),
    '__bp_print'([passwordNotHandle(A)]).

% What `#[check]` records, once per annotation: the field it is `at` (`"type"`

% for none, `"rule"` on a function), the message and the code's kind.

%% type Check: at, message, kind

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/decorator_arguments_check|*">>.

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

'__bp_priv__passwordsMatch'(A0) -> passwordsMatch(A0).

'__bp_priv__handleFree'(A0) -> handleFree(A0).

'__bp_priv__passwordNotHandle'(A0) -> passwordNotHandle(A0).

'__bp_priv__array_first'(A0) -> array_first(A0).
