----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
    val code = e.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: e.lookup("Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    return e.custom(root, code);
}
val rows = dsl "select id from Item";
```

----- COMPTIME BEAM ASSEMBLY -- template dsl
```erlang
{module, template_module}.
{exports, [{dsl, 1}, {main, 1}]}.
{attributes, []}.
{labels, 19}.

{function, dsl, 1, 2}.
  {label, 1}.
    {func_info, {atom, template_module}, {atom, dsl}, 1}.
  {label, 2}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"41">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, build, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"Item">>}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_comptime_template, lookup, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"field">>}, {atom, span}, {literal, #{start => 7, 'end' => 9, line => 1}}, {atom, label}, {literal, <<"property">>}, {atom, ref}, {y, 3}, {atom, children}, nil]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 10}}.
  {label, 10}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"select">>}, {atom, span}, {literal, #{start => 0, 'end' => 6, line => 1}}, {atom, label}, {literal, <<"keyword">>}, {atom, ref}, {atom, undefined}, {atom, children}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 12}}.
  {label, 12}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext_last, 3, {extfunc, bp_comptime_template, custom, 3}, 4}.

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
%%     '__bp_capture' => <<"e">>,
%%     text => <<"select id from Item">>,
%%     parts => [
%%         #{
%%             kind => <<"Text">>,
%%             text => <<"select id from Item">>,
%%             span => #{start => 0, 'end' => 19, line => 1}
%%         }
%%     ],
%%     source => #{file => <<"">>, line => 8, col => 16},
%%     context => #{
%%         source => #{file => <<"">>, line => 8, col => 16},
%%         text => <<"select id from Item">>,
%%         multiline => false
%%     },
%%     bindings => [
%%         #{
%%             name => <<"Item">>,
%%             kind => 'Fn',
%%             identity => <<"shapes@@Item">>,
%%             local => <<"Item">>
%%         }
%%     ],
%%     words => [<<"select">>, <<"id">>, <<"from">>, <<"Item">>]
%% }
```

----- COMPTIME REPLY -- template dsl
```json
{
  "ast": {
    "children": [
      {
        "children": [],
        "kind": "field",
        "label": "property",
        "ref": {
          "identity": "shapes@@Item",
          "kind": "Fn",
          "local": "Item",
          "name": "Item"
        },
        "span": {
          "end": 9,
          "line": 1,
          "start": 7
        }
      }
    ],
    "kind": "select",
    "label": "keyword",
    "ref": null,
    "span": {
      "end": 6,
      "line": 1,
      "start": 0
    }
  },
  "kind": "custom",
  "source": "41"
}
```

