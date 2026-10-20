----- SOURCE CODE -- main.bp
```botopink
type Val {
    Num(n: i32),
    Text(s: string),

    fn str(self: Self) -> string {
        return case self {
            Text(s: t) -> t;
            _ -> "";
        };
    }
}

fn find(kind: i32) -> ?Val {
    if (kind == 1) return Val.Text(s: "a");
    if (kind == 2) return Val.Num(n: 40);
    return null;
}

fn contains(xs: string[], x: string) -> Result<void, string> {
    if (xs.indexOf(x) < 0) throw "missing";
    return;
}

fn pair(s: string) -> Result<#(string, string), string> {
    if (s == "") throw "empty";
    return #(s, s.toUpper());
}

fn label(s: string, loud: bool) -> string {
    val mark = case loud {
        true -> 1;
        false -> 0;
    };
    val parts = if (s == "") [] else [s, s];
    return parts.join("-") + mark.toString();
}

fn verdict(r: Result<void, string>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> e;
    };
}

fn both(s: string) -> Result<string, string> {
    val p = try pair(s);
    return p._0 + p._1;
}

fn text(r: Result<string, string>) -> string {
    return case r {
        Ok(v) -> v;
        Error(e) -> e;
    };
}

pub fn main() -> void {
    print(label("ab", true));
    print(label("", false));
    print("abc".contains("b"));
    print(verdict(contains(["a"], "b")));
    print(text(both("a")));
    print(text(both("")));
    print([1, 2, 3].fill("z"));
    print(find(1)?.str() ?? "none");
    print(find(3)?.str() ?? "none");
    print(Val.Num(n: 2).str().length);
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__Array_fill', 2}, {'__bp_priv__Array_range', 2}, {'__bp_priv__Array_repeat', 2}, {'__bp_priv__both', 1}, {'__bp_priv__contains', 2}, {'__bp_priv__find', 1}, {'__bp_priv__label', 2}, {'__bp_priv__pair', 1}, {'__bp_priv__text', 1}, {'__bp_priv__verdict', 1}]}.
{attributes, []}.
{labels, 127}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 26}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 31}}.
  {label, 29}.
  {label, 27}.
    {deallocate, 6}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 32}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 31}}.
  {label, 35}.
  {label, 33}.
    {deallocate, 6}.
    return.

{function, find, 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, find}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 36}, [{y, 0}, {integer, 1}]}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Val__v__text}, {x, 0}]}}.
    {deallocate, 1}.
    return.
  {label, 36}.
    {test, is_eq_exact, {f, 37}, [{y, 0}, {integer, 2}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Val__v__num}, {integer, 40}]}}.
    {deallocate, 1}.
    return.
  {label, 37}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, contains, 2, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, contains}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 40}}.
    {test, is_lt, {f, 38}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"missing">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, pair, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, pair}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, uppercase, 1}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, label, 2, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, label}, 2}.
  {label, 13}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 45}, [{y, 2}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 45}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 46}, [{y, 3}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 46}.
    {move, {x, 1}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 44}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{y, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 48}}.
  {label, 47}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 48}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call, 2, {f, 50}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 84}}.
    {deallocate, 9}.
    return.

{function, verdict, 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, verdict}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"ok">>}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 87}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 88}.
    {case_end, {x, 0}}.
  {label, 86}.
    {deallocate, 2}.
    return.

{function, both, 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, both}, 1}.
  {label, 17}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {deallocate, 4}.
    return.
  {label, 90}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 84}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, text, 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, text}, 1}.
  {label, 19}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 91}}.
  {label, 92}.
    {test, is_tagged_tuple, {f, 93}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 91}}.
  {label, 93}.
    {case_end, {x, 0}}.
  {label, 91}.
    {deallocate, 3}.
    return.

{function, main, 0, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 21}.
    {allocate, 9, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {literal, <<"ab">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {literal, <<"abc">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 94}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {atom, true}, {x, 0}}.
  {label, 95}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 9}}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 17}}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 17}}.
    {call, 1, {f, 19}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"z">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 97}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_eq, {f, 99}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, test@main@@Val, str, 1}}.
  {label, 100}.
    {test, is_ne_exact, {f, 98}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 101}}.
  {label, 98}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 101}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_eq, {f, 103}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, test@main@@Val, str, 1}}.
  {label, 104}.
    {test, is_ne_exact, {f, 102}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 105}}.
  {label, 102}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 105}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Val__v__num}, {integer, 2}]}}.
    {call_ext, 1, {extfunc, test@main@@Val, str, 1}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '_botopink_main', 0, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 21}, 0}.

{function, main, 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, 'Array_fill', 2, 97}.
  {label, 96}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, 'Array_fill'}, 2}.
  {label, 97}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 2, {f, 5}, 2}.

{function, '__bp_priv__Array_fill', 2, 108}.
  {label, 107}.
    {line, [{location, "test@main.erl", 16}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_fill'}, 2}.
  {label, 108}.
    {call_only, 2, {f, 97}}.

{function, '__bp_priv__Array_range', 2, 110}.
  {label, 109}.
    {line, [{location, "test@main.erl", 17}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_range'}, 2}.
  {label, 110}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__Array_repeat', 2, 112}.
  {label, 111}.
    {line, [{location, "test@main.erl", 18}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_repeat'}, 2}.
  {label, 112}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__both', 1, 114}.
  {label, 113}.
    {line, [{location, "test@main.erl", 19}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__both'}, 1}.
  {label, 114}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__contains', 2, 116}.
  {label, 115}.
    {line, [{location, "test@main.erl", 20}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__contains'}, 2}.
  {label, 116}.
    {call_only, 2, {f, 9}}.

{function, '__bp_priv__find', 1, 118}.
  {label, 117}.
    {line, [{location, "test@main.erl", 21}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__find'}, 1}.
  {label, 118}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__label', 2, 120}.
  {label, 119}.
    {line, [{location, "test@main.erl", 22}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__label'}, 2}.
  {label, 120}.
    {call_only, 2, {f, 13}}.

{function, '__bp_priv__pair', 1, 122}.
  {label, 121}.
    {line, [{location, "test@main.erl", 23}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__pair'}, 1}.
  {label, 122}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__text', 1, 124}.
  {label, 123}.
    {line, [{location, "test@main.erl", 24}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__text'}, 1}.
  {label, 124}.
    {call_only, 1, {f, 19}}.

{function, '__bp_priv__verdict', 1, 126}.
  {label, 125}.
    {line, [{location, "test@main.erl", 25}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__verdict'}, 1}.
  {label, 126}.
    {call_only, 1, {f, 15}}.

{function, '-bp_indexOf-', 3, 40}.
  {label, 39}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '-bp_indexOf-'}, 3}.
  {label, 40}.
    {test, is_nonempty_list, {f, 41}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 42}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 42}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 40}}.
  {label, 41}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '__bp_print', 1, 52}.
  {label, 51}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 52}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 56}.
  {label, 55}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 56}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '-bp_show_elem-', 1, 58}.
  {label, 57}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 58}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '__bp_show', 2, 54}.
  {label, 53}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 54}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 66}, [{x, 0}]}.
    {test, is_eq, {f, 65}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 67}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 68}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 68}, [{x, 0}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 74}}.
  {label, 73}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 74}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 71}, [{x, 0}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
  {label, 70}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 60}, 2}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 72}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 60}.
  {label, 59}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 60}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 75}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 62}, 3}.
  {label, 76}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 62}.
  {label, 61}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 62}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 77}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 78}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 64}.
  {label, 63}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 64}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 80}.
  {label, 79}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 80}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 81}.
    {test, is_integer, {f, 82}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 82}.
    {call, 1, {f, 56}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 50}.
  {label, 49}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_join-'}, 2}.
  {label, 50}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_add', 2, 84}.
  {label, 83}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_add'}, 2}.
  {label, 84}.
    {test, is_binary, {f, 85}, [{x, 0}]}.
    {test, is_binary, {f, 85}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 85}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_prim_append', 2, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 15}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 106}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 106}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@Val.S
```erlang
{module, test@main@@Val}.
{exports, [{str, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, str, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Val.erl", 3}]}.
    {func_info, {atom, test@main@@Val}, {atom, str}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, test@main@@Val__v__text}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 2}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main@@Val.erl", 4}]}.
    {func_info, {atom, test@main@@Val}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 2, {atom, test@main@@Val__v__num}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"n">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val.Num">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 8}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 2, {atom, test@main@@Val__v__text}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"s">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val.Text">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 9}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
ab-ab1
0
true
missing
aA
empty
["z", "z", "z"]
a
none
0
```
