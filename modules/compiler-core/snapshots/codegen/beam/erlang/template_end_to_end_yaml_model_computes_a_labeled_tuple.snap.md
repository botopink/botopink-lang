----- SOURCE CODE -- main.bp
```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));
}
val cfg = conf "yaml";
fn main() {
    @print(cfg.port + 1);
}
```

----- COMPTIME BEAM ASSEMBLY -- template conf
```erlang
{module, template_module}.
{exports, [{conf, 1}, {main, 1}]}.
{attributes, []}.
{labels, 19}.

{function, conf, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, conf}, 1}.
  {label, 2}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, text, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, length}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_len', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 8000}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 10}}.
  {label, 10}.
    {move, {atom, true}, {y, 1}}.
    {jump, {f, 12}}.
  {label, 12}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, bp_comptime_template, expr, 1}, 4}.

{function, main, 1, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 4}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 14}, [{x, 0}]}.
    {test, test_arity, {f, 14}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {'try', {y, 15}, {f, 15}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_reply', 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {try_end, {y, 15}}.
    {jump, {f, 16}}.
  {label, 15}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, throw}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 18}, [{x, 0}]}.
    {test, test_arity, {f, 18}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, '__bp_template_fail'}]}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_json', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"fail">>}, {atom, message}, {y, 13}, {atom, param}, {y, 1}, {atom, span}, {y, 14}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 5}}.
    {jump, {f, 17}}.
  {label, 18}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, '__bp_text', 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 17}}.
  {label, 17}.
  {label, 16}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 14}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 16}.
    {jump, {f, 3}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"yaml">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"yaml">>,
%%             span => #{start => 0, 'end' => 4, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 7, col => 16},
%%     context => #{
%%         source => #{file => <<"">>, line => 7, col => 16},
%%         text => <<"yaml">>,
%%         multiline => false
%%     },
%%     bindings => [],
%%     words => [<<"yaml">>]
%% }
```

----- COMPTIME REPLY -- template conf
```json
{
  "kind": "value",
  "value": {
    "$tuple": [
      8004,
      true
    ]
  }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, cfg/0]).

cfg() ->
    {8004, true}.

main() ->
    '__bp_print'(['__bp_int'((erlang:element(1, cfg()) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:9:21">>)]).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
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
```

----- RUN LOG -----
```logs
8005
```
