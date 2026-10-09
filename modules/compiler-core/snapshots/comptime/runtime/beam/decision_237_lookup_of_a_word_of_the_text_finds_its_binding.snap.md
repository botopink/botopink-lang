----- SOURCE CODE -- main.bp
```botopink
pub type Card(
    title: string,
)
pub type Badge(
    n: i32,
)
val unrelated = 1;
pub fn ui(comptime q: @Expr<string>) -> @Expr<string> {
    val count = q.bindings().length;
    val hit = q.lookup("Badge");
    if (hit) { b ->
        return q.build("\"" + b.name + "/" + b.local + "\"");
    } else {
        return q.fail("Badge is a word of the text and in scope");
    };
}
val s = ui "<Card title=\"x\"><Badge/></Card>";
```

----- COMPTIME BEAM ASSEMBLY -- template ui
```erlang
{module, template_module}.
{exports, [{ui, 1}, {main, 1}]}.
{attributes, []}.
{labels, 20}.

{function, ui, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, ui}, 1}.
  {label, 2}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_template, bindings, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {atom, length}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_len', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"Badge">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, lookup, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 10}}.
  {label, 10}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 12}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"Badge is a word of the text and in scope">>}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, fail, 2}, 5}.
  {label, 12}.
    {move, {y, 0}, {y, 1}}.
    {move, {atom, name}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"/">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, local}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, get, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"\"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, '__bp_add', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_template, build, 2}, 5}.

{function, main, 1, 4}.
  {label, 3}.
    {func_info, {atom, template_module}, {atom, main}, 1}.
  {label, 4}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 15}, [{x, 0}]}.
    {test, test_arity, {f, 15}, [{x, 0}, 1]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {'try', {y, 15}, {f, 16}}.
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
    {jump, {f, 17}}.
  {label, 16}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 19}, [{x, 0}, {atom, throw}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 19}, [{x, 0}]}.
    {test, test_arity, {f, 19}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 19}, [{x, 0}, {atom, '__bp_template_fail'}]}.
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
    {jump, {f, 18}}.
  {label, 19}.
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
    {jump, {f, 18}}.
  {label, 18}.
  {label, 17}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 15}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 16}.
    {jump, {f, 3}}.

%% main/1 argument — an external term, not part of the module:
%% Arg0 = #{
%%     '__bp_capture' => <<"q">>,
%%     text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
%%             span => #{start => 0, 'end' => 33, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 17, col => 12},
%%     context => #{
%%         source => #{file => <<"">>, line => 17, col => 12},
%%         text => <<"<Card title=\\\"x\\\"><Badge/></Card>">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{
%%             name => <<"Card">>,
%%             kind => 'Record_',
%%             identity => <<"main@@Card">>,
%%             local => <<"Card">>
%%         },
%%         #{
%%             name => <<"Badge">>,
%%             kind => 'Record_',
%%             identity => <<"main@@Badge">>,
%%             local => <<"Badge">>
%%         }
%%     ],
%%     words => [<<"Card">>, <<"title">>, <<"x">>, <<"Badge">>]
%% }
```

----- COMPTIME REPLY -- template ui
```json
{
  "kind": "code",
  "source": "\"Badge/Badge\""
}
```

