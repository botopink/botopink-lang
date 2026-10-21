----- SOURCE CODE -- std/functions.bp
```botopink
//// std/functions — combinators over function values (decision 738).
////
//// Plain functions of a std module, imported by path:
//// `import {functions.compose} from "std";`. A function's type is
//// `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
//// backing, so the module runs on every target.
////
//// No import (decision 106: a root module).

/// The argument, unchanged.
pub fn identity<A>(x: A) -> A {
    return x;
}

/// `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.
pub fn compose<A, B, C>(f: fn(a: A) -> B, g: fn(b: B) -> C) -> fn(A) -> C {
    return { a -> g(f(a)) };
}

/// `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.
pub fn flip<A, B, C>(f: fn(a: A, b: B) -> C) -> fn(B, A) -> C {
    return { b, a -> f(a, b) };
}

/// A function answering `x` whatever it is given. The argument is typed
/// `unknown` (decision 668: no parameter would bind a type for it), so one
/// binding takes any argument.
pub fn constant<A>(x: A) -> fn(unknown) -> A {
    return { ignored -> x };
}

test "functions.identity" {
    assert identity(42) == 42;
    assert identity("hi") == "hi";
    assert identity(true);
}

test "functions.compose runs left to right" {
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    val f = compose(double, addOne);
    assert f(3) == 7;
    assert f(0) == 1;
}

test "functions.compose with a string transform" {
    val shout: fn(string) -> string = { s -> s + "!" };
    val greet: fn(string) -> string = { s -> "Hello, " + s };
    val greetAndShout = compose(greet, shout);
    assert greetAndShout("world") == "Hello, world!";
}

test "functions.flip reverses the argument order" {
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    val rsub = flip(sub);
    assert rsub(3, 10) == 7;
}

test "functions.constant ignores its argument" {
    val always42 = constant(42);
    assert always42("anything") == 42;
    assert always42(0) == 42;
}

```

----- BEAM ASSEMBLY -- std/functions.S
```erlang
{module, std@functions}.
{exports, [{identity, 1}, {compose, 2}, {flip, 1}, {constant, 1}]}.
{attributes, []}.
{labels, 16}.
%%% std/functions — combinators over function values (decision 738).
%%% 
%%% Plain functions of a std module, imported by path:
%%% `import {functions.compose} from "std";`. A function's type is
%%% `fn(A) -> B`; no `Function` contract names it. Pure botopink, no host
%%% backing, so the module runs on every target.
%%% 
%%% No import (decision 106: a root module).
%% The argument, unchanged.

{function, identity, 1, 3}.
  {label, 2}.
    {line, [{location, "std@functions.erl", 1}]}.
    {func_info, {atom, std@functions}, {atom, identity}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
%% `f`, then `g`: `compose(f, g)(a)` is `g(f(a))`.

{function, compose, 2, 5}.
  {label, 4}.
    {line, [{location, "std@functions.erl", 2}]}.
    {func_info, {atom, std@functions}, {atom, compose}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {deallocate, 2}.
    return.
%% `f` with its two arguments swapped: `flip(f)(b, a)` is `f(a, b)`.

{function, flip, 1, 7}.
  {label, 6}.
    {line, [{location, "std@functions.erl", 3}]}.
    {func_info, {atom, std@functions}, {atom, flip}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.
%% A function answering `x` whatever it is given. The argument is typed
%% `unknown` (decision 668: no parameter would bind a type for it), so one
%% binding takes any argument.

{function, constant, 1, 9}.
  {label, 8}.
    {line, [{location, "std@functions.erl", 4}]}.
    {func_info, {atom, std@functions}, {atom, constant}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.

{function, '-compose/2-fun-0-', 3, 11}.
  {label, 10}.
    {line, [{location, "std@functions.erl", 3}]}.
    {func_info, {atom, std@functions}, {atom, '-compose/2-fun-0-'}, 3}.
  {label, 11}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 3}.
    return.

{function, '-flip/1-fun-1-', 3, 13}.
  {label, 12}.
    {line, [{location, "std@functions.erl", 4}]}.
    {func_info, {atom, std@functions}, {atom, '-flip/1-fun-1-'}, 3}.
  {label, 13}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-constant/1-fun-2-', 2, 15}.
  {label, 14}.
    {line, [{location, "std@functions.erl", 5}]}.
    {func_info, {atom, std@functions}, {atom, '-constant/1-fun-2-'}, 2}.
  {label, 15}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn parse(s: string) -> Result<array<#(string, string)>, string> {
    if (s == "") throw "empty";
    return [#(s, s.toUpper())];
}

fn pairsOf(r: Result<array<#(string, string)>, string>) -> string {
    val none: array<#(string, string)> = [];
    return r.unwrapOr(none).map({ p -> [p._0, "=>", p._1].join("") }).join("|");
}

pub fn main() -> void {
    print(pairsOf(parse("a")));
    print(pairsOf(parse("")).length);
    val double: fn(i32) -> i32 = { n -> n * 2 };
    val addOne: fn(i32) -> i32 = { n -> n + 1 };
    print(functions.compose(double, addOne)(3));
    val shout: fn(string) -> string = { s -> s + "!" };
    print(functions.compose(shout, shout)("hi"));
    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
    print(functions.flip(sub)(3, 10));
    print(functions.constant(42)("x"));
}

import {io.terminal.print} from "std";
import {functions} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__pairsOf', 1}, {'__bp_priv__parse', 1}]}.
{attributes, []}.
{labels, 69}.

{function, parse, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, parse}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 12}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 12}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, string, uppercase, 1}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, pairsOf, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, pairsOf}, 1}.
  {label, 5}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 14}}.
  {label, 13}.
    {move, {y, 1}, {x, 0}}.
  {label, 14}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 16}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 18}, 6}.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {call, 1, {f, 5}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 52}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@functions, compose, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, std@functions, compose, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@functions, flip, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {integer, 10}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {integer, 42}, {x, 0}}.
    {call_ext, 1, {extfunc, std@functions, constant, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__pairsOf', 1, 66}.
  {label, 65}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__pairsOf'}, 1}.
  {label, 66}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__parse', 1, 68}.
  {label, 67}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__parse'}, 1}.
  {label, 68}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 20}.
  {label, 19}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 20}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 24}.
  {label, 23}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 24}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 22}}.

{function, '-bp_show_elem-', 1, 26}.
  {label, 25}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 26}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 22}}.

{function, '__bp_show', 2, 22}.
  {label, 21}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 22}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 34}, [{x, 0}]}.
    {test, is_eq, {f, 33}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 35}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 37}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 36}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 36}, [{x, 0}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 42}}.
  {label, 41}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 42}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 22}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 39}, [{x, 0}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, undefined}]}.
  {label, 38}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 28}, 2}.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 40}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 28}.
  {label, 27}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 28}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 43}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 43}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 43}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 30}, 3}.
  {label, 44}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 30}.
  {label, 29}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 30}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 45}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 46}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 32}.
  {label, 31}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 32}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 22}}.
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

{function, '-bp_stringify-', 1, 48}.
  {label, 47}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 48}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 49}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 49}.
    {test, is_integer, {f, 50}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 50}.
    {call, 1, {f, 24}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 18}.
  {label, 17}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_join-'}, 2}.
  {label, 18}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-pairsOf/1-fun-0-', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-pairsOf/1-fun-0-'}, 1}.
  {label, 16}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"=>">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 18}}.
    {deallocate, 4}.
    return.

{function, '-main/0-fun-1-', 1, 52}.
  {label, 51}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-1-'}, 1}.
  {label, 52}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 53}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 53}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:14:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-2-', 1, 56}.
  {label, 55}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 56}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 57}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 57}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at test@main.bp:15:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 58}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-3-', 1, 60}.
  {label, 59}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 60}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-4-', 2, 62}.
  {label, 61}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-4-'}, 2}.
  {label, 62}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 63}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 63}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at test@main.bp:19:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 64}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
a=>A
0
7
hi!!
7
42
```
