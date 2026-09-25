----- SOURCE CODE -- main.bp
```botopink
pub fn describe(comptime decl: @Decl) {
    val names = decl.fields.map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = decl.name.slice(0, 3);
    val size = if (decl.name.length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + decl.name + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
type User(name: string, secret: string, age: i32)

fn main() {
    @print(describeUser());
}
```

----- COMPTIME ERLANG -- decorator describe
```erlang
describe(Decl) ->
    Names = '__bp_prim_map'(maps:get(fields, Decl), fun(F) ->
        maps:get(name, F)
    end),
    Upper = '__bp_prim_join'('__bp_prim_map'(Names, fun(N) ->
        '__bp_prim_toUpper'(N)
    end), <<"_">>),
    Hidden = case '__bp_prim_contains'(Names, <<"secret">>) of
        true ->
            <<"hidden">>;
        false ->
            <<"open">>
    end,
    Short = '__bp_prim_slice'(maps:get(name, Decl), 0, 3),
    Size = case ('__bp_prim_length'(maps:get(name, Decl)) =:= 4) of
        true ->
            <<"four">>;
        false ->
            <<"other">>
    end,
    emit('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'('__bp_add'(<<"pub fn describe">>, maps:get(name, Decl)), <<"() -> string { return \"">>), Upper), <<":">>), Hidden), <<":">>), Short), <<":">>), Size), <<"\"; }">>)).

main({Arg0}) ->
    erlang:erase('__bp_emitted'),
    try
        describe(Arg0),
        json:encode(#{kind => <<"ok">>, contributions => lists:reverse('__bp_emitted'())})
    catch
        throw:{'__bp_decorator_fail', Message, Span} ->
            json:encode(#{kind => <<"fail">>, message => '__bp_text'(Message), span => Span});
        Class:Reason ->
            json:encode(#{kind => <<"error">>, message => '__bp_text'({Class, Reason})})
    end.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     kind => 'Type',
%%     name => <<"User">>,
%%     fields => [
%%         #{name => <<"name">>, typeName => <<"string">>, annotations => []},
%%         #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
%%         #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
%%     ],
%%     variants => [],
%%     methods => [],
%%     returnType => <<"">>,
%%     annotations => [#{name => <<"describe">>, args => []}]
%% }
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "kind": "ok",
  "contributions": [
    "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
  ]
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([describeUser/0]).

%% behavior String

%% behavior Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

%% type User: name, secret, age

main() ->
    '__bp_print'([describeUser()]).

describeUser() ->
    <<"NAME_SECRET_AGE:hidden:Use:four">>.

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> '__bp_tagged'(element(1, V), V);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) when is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(atom_to_list(A), "__v__") of [P, _] -> list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- ERLANG -- test@main@@User.erl
```erlang
-module(test@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, secret) -> element(3, V);
'__bp_get'(V, age) -> element(4, V).

'__bp_format'(V) -> {record, "User", [{"name", element(2, V)}, {"secret", element(3, V)}, {"age", element(4, V)}]}.
```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
