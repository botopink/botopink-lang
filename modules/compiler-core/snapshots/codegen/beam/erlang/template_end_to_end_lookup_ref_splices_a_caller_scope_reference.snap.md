----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    } else {
        return q.fail("greeting not found in caller scope");
    };
}
val s = refer "x";
fn main() {
    @print(s);
}
```

----- COMPTIME BEAM ASSEMBLY -- template refer
```erlang
{module, template_module}.
{exports, [{refer, 1}, {main, 1}]}.
{attributes, []}.
{labels, 18}.

{function, refer, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, refer}, 1}.
  {label, 2}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"greeting">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, lookup, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"greeting not found in caller scope">>}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, fail, 2}, 4}.
  {label, 10}.
    {move, {y, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, bp_comptime_template, ref, 1}, 4}.

{function, main, 1, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 4}.
    {allocate, 19, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 13}, [{x, 0}]}.
    {test, test_arity, {f, 13}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {'try', {y, 18}, {f, 14}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_reply', 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {try_end, {y, 18}}.
    {jump, {f, 15}}.
  {label, 14}.
    {try_case, {y, 18}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 17}, [{x, 0}, {atom, throw}]}.
    {move, {y, 10}, {x, 0}}.
    {test, is_tuple, {f, 17}, [{x, 0}]}.
    {test, test_arity, {f, 17}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 12}}.
    {get_tuple_element, {x, 0}, 1, {y, 13}}.
    {get_tuple_element, {x, 0}, 2, {y, 14}}.
    {get_tuple_element, {x, 0}, 3, {y, 15}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 17}, [{x, 0}, {atom, '__bp_template_fail'}]}.
    {move, {y, 13}, {y, 1}}.
    {move, {y, 14}, {y, 2}}.
    {move, {y, 15}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_json', 1}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 16}, {atom, param}, {y, 2}, {atom, span}, {y, 17}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 16}}.
  {label, 17}.
    {move, {y, 9}, {y, 4}}.
    {move, {y, 10}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 12}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 8}}.
    {jump, {f, 16}}.
  {label, 16}.
  {label, 15}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 13}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 19}.
    {jump, {f, 3}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"x">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"x">>,
%%             span => #{start => 0, 'end' => 1, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 10, col => 15},
%%     context => #{
%%         source => #{file => <<"">>, line => 10, col => 15},
%%         text => <<"x">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{name => <<"greeting">>, kind => 'Val'},
%%         #{name => <<"refer">>, kind => 'Fn'},
%%         #{name => <<"s">>, kind => 'Val'},
%%         #{name => <<"main">>, kind => 'Fn'}
%%     ]
%% }
```

----- COMPTIME REPLY -- template refer
```json
{
  "kind": "code",
  "source": "greeting"
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).

greeting() ->
    <<"ola mundo">>.

s() ->
    greeting().

main() ->
    '__bp_print'([s()]).

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

----- RUN LOG -----
```logs
ola mundo
```
