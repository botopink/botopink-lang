----- SOURCE CODE -- main.bp
```botopink
import {io.terminal.print} from "std";

behavior Greeter {
    fn greet(self: Self, punct: string) -> string;
}

type Bob(name: string) implement Greeter {
    fn greet(self: Self, punct: string) -> string {
        return "hi " + self.name + punct;
    }
}

type Ann(age: i32) implement Greeter {
    fn greet(self: Self, punct: string) -> string {
        return "ann " + self.age.toString() + punct;
    }
}

type Pet implement Greeter {
    Dog(name: string),
    Cat(lives: i32),

    fn greet(self: Self, punct: string) -> string {
        return case self {
            Dog(name) -> "woof " + name + punct;
            Cat(lives) -> "meow " + lives.toString() + punct;
        };
    }
}

type Door(name: string) implement Closeable {
    fn close(self: Self) -> void {
        print("closed " + self.name);
    }
}

type Registry(names: string[]) implement Index<string, i32> {
    pub fn at(self: Self, key: string) -> ?i32 {
        val found = self.names.indexOf(key);
        if (found < 0) return null;
        return found;
    }
}

fn welcome(g: Greeter) -> string {
    return g.greet("!");
}

fn make(old: bool) -> Greeter {
    if (old) return Ann(age: 70);
    return Bob(name: "b");
}

fn shut(c: Closeable) -> void {
    c.close();
}

fn lookup(m: Index<string, i32>, key: string) -> i32 {
    return m.at(key) ?? -1;
}

pub fn main() -> void {
    print(welcome(Bob(name: "bob")));
    print(welcome(make(true)));
    print(welcome(make(false)));
    print(welcome(Pet.Dog(name: "rex")));
    print(welcome(Pet.Cat(lives: 9)));
    val all: Greeter[] = [Bob(name: "x"), Ann(age: 3), Pet.Cat(lives: 1)];
    for (all) { g ->
        print(g.greet("?"));
    }
    shut(Door(name: "front"));
    val r = Registry(names: ["ana", "bo"]);
    print(lookup(r, "bo"));
    print(lookup(r, "zz"));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__lookup', 2}, {'__bp_priv__make', 1}, {'__bp_priv__shut', 1}, {'__bp_priv__welcome', 1}]}.
{attributes, []}.
{labels, 65}.

{function, welcome, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, welcome}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 2}}.
    {put_list, {x, 0}, {x, 2}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, greet}, {x, 0}}.
    {call_last, 3, {f, 17}, 1}.

{function, make, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, make}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 24}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Ann}, {integer, 70}]}}.
    {deallocate, 1}.
    return.
  {label, 24}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Bob}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, shut, 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, shut}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, close}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, lookup, 2, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, lookup}, 2}.
  {label, 9}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 2}}.
    {put_list, {x, 0}, {x, 2}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, at}, {x, 0}}.
    {call, 3, {f, 17}}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {integer, -1}, {x, 0}}.
  {label, 26}.
    {deallocate, 3}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {literal, <<"bob">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Bob}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 5}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {literal, <<"rex">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Pet__v__dog}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Pet__v__cat}, {integer, 9}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Pet__v__cat}, {integer, 1}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Ann}, {integer, 3}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Bob}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {literal, <<"front">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Door}, {x, 0}]}}.
    {call, 1, {f, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"ana">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Registry}, {x, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {literal, <<"zz">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__lookup', 2, 58}.
  {label, 57}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__lookup'}, 2}.
  {label, 58}.
    {call_only, 2, {f, 9}}.

{function, '__bp_priv__make', 1, 60}.
  {label, 59}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__make'}, 1}.
  {label, 60}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__shut', 1, 62}.
  {label, 61}.
    {line, [{location, "test@main.erl", 15}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__shut'}, 1}.
  {label, 62}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__welcome', 1, 64}.
  {label, 63}.
    {line, [{location, "test@main.erl", 16}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__welcome'}, 1}.
  {label, 64}.
    {call_only, 1, {f, 3}}.

{function, '-bp_method-', 3, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-bp_method-'}, 3}.
  {label, 17}.
    {test, is_map, {f, 18}, [{x, 1}]}.
    {bif, map_get, {f, 0}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext_only, 2, {extfunc, erlang, apply, 2}}.
  {label, 18}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test, is_tuple, {f, 19}, [{x, 1}]}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 1}], {x, 0}}.
    {jump, {f, 20}}.
  {label, 19}.
    {move, {x, 1}, {x, 0}}.
  {label, 20}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, split, 2}}.
    {test, is_nonempty_list, {f, 21}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test, is_nil, {f, 22}, [{x, 2}]}.
    {jump, {f, 21}}.
  {label, 22}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_atom, 1}}.
    {jump, {f, 23}}.
  {label, 21}.
    {move, {y, 2}, {x, 0}}.
  {label, 23}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, apply, 3}, 3}.

{function, '__bp_print', 1, 28}.
  {label, 27}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 28}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 32}.
  {label, 31}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 32}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 30}}.

{function, '-bp_show_elem-', 1, 34}.
  {label, 33}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 34}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 30}}.

{function, '__bp_show', 2, 30}.
  {label, 29}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 30}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 42}, [{x, 0}]}.
    {test, is_eq, {f, 41}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 43}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 45}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 44}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 44}, [{x, 0}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 50}}.
  {label, 49}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 50}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 30}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
  {label, 46}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 36}, 2}.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 48}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 36}.
  {label, 35}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 36}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 51}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 38}, 3}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 38}.
  {label, 37}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 53}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 40}.
  {label, 39}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 40}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 30}}.
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

{function, '-main/0-fun-0-', 1, 56}.
  {label, 55}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 56}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 2}}.
    {put_list, {x, 0}, {x, 2}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, greet}, {x, 0}}.
    {call, 3, {f, 17}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@Bob.S
```erlang
{module, test@main@@Bob}.
{exports, [{greet, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 44}.

{function, greet, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Bob.erl", 1}]}.
    {func_info, {atom, test@main@@Bob}, {atom, greet}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, test@main@@Bob}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"hi ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 38}.
  {label, 37}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_get'}, 2}.
  {label, 38}.
    {test, is_eq_exact, {f, 39}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 39}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 41}.
  {label, 40}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_format'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Bob">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 43}.
  {label, 42}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_behaviors'}, 0}.
  {label, 43}.
    {move, {literal, [test@main@@Greeter]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 6}.
  {label, 5}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_print'}, 1}.
  {label, 6}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 10}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 10}.
  {label, 9}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '-bp_show_top-'}, 1}.
  {label, 10}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '-bp_show_elem-', 1, 12}.
  {label, 11}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '-bp_show_elem-'}, 1}.
  {label, 12}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '__bp_show', 2, 8}.
  {label, 7}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_show'}, 2}.
  {label, 8}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 20}, [{x, 0}]}.
    {test, is_eq, {f, 19}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 23}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 22}, [{x, 0}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 28}}.
  {label, 27}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 28}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 25}, [{x, 0}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, undefined}]}.
  {label, 24}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 14}, 2}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 26}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 14}.
  {label, 13}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_tagged'}, 2}.
  {label, 14}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 16}, 3}.
  {label, 30}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '__bp_render'}, 1}.
  {label, 16}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 31}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 18}.
  {label, 17}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '-bp_render_pair-'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
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

{function, '-bp_stringify-', 1, 34}.
  {label, 33}.
    {line, [{location, "test@main@@Bob.erl", 2}]}.
    {func_info, {atom, test@main@@Bob}, {atom, '-bp_stringify-'}, 1}.
  {label, 34}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 35}.
    {test, is_integer, {f, 36}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 36}.
    {call, 1, {f, 10}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- test@main@@Ann.S
```erlang
{module, test@main@@Ann}.
{exports, [{greet, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 44}.

{function, greet, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Ann.erl", 2}]}.
    {func_info, {atom, test@main@@Ann}, {atom, greet}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, test@main@@Ann}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"ann ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 38}.
  {label, 37}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_get'}, 2}.
  {label, 38}.
    {test, is_eq_exact, {f, 39}, [{x, 1}, {atom, age}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 39}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 41}.
  {label, 40}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_format'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"age">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Ann">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 43}.
  {label, 42}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_behaviors'}, 0}.
  {label, 43}.
    {move, {literal, [test@main@@Greeter]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 6}.
  {label, 5}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_print'}, 1}.
  {label, 6}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 10}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 10}.
  {label, 9}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '-bp_show_top-'}, 1}.
  {label, 10}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '-bp_show_elem-', 1, 12}.
  {label, 11}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '-bp_show_elem-'}, 1}.
  {label, 12}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '__bp_show', 2, 8}.
  {label, 7}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_show'}, 2}.
  {label, 8}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 20}, [{x, 0}]}.
    {test, is_eq, {f, 19}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 23}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 22}, [{x, 0}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 28}}.
  {label, 27}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 28}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 25}, [{x, 0}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, undefined}]}.
  {label, 24}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 14}, 2}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 26}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 14}.
  {label, 13}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_tagged'}, 2}.
  {label, 14}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 16}, 3}.
  {label, 30}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '__bp_render'}, 1}.
  {label, 16}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 31}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 18}.
  {label, 17}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '-bp_render_pair-'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
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

{function, '-bp_stringify-', 1, 34}.
  {label, 33}.
    {line, [{location, "test@main@@Ann.erl", 3}]}.
    {func_info, {atom, test@main@@Ann}, {atom, '-bp_stringify-'}, 1}.
  {label, 34}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 35}.
    {test, is_integer, {f, 36}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 36}.
    {call, 1, {f, 10}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- test@main@@Pet.S
```erlang
{module, test@main@@Pet}.
{exports, [{greet, 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 45}.

{function, greet, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Pet.erl", 3}]}.
    {func_info, {atom, test@main@@Pet}, {atom, greet}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, test@main@@Pet__v__dog}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"woof ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 2, {atom, test@main@@Pet__v__cat}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"meow ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 38}.
    {case_end, {x, 0}}.
  {label, 4}.
    {deallocate, 6}.
    return.

{function, '__bp_format', 1, 40}.
  {label, 39}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_format'}, 1}.
  {label, 40}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 2, {atom, test@main@@Pet__v__dog}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Pet.Dog">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 2, {atom, test@main@@Pet__v__cat}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"lives">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Pet.Cat">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Pet">>}, nil]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 44}.
  {label, 43}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_behaviors'}, 0}.
  {label, 44}.
    {move, {literal, [test@main@@Greeter]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 7}.
  {label, 6}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_print'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 11}.
  {label, 10}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '-bp_show_top-'}, 1}.
  {label, 11}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '-bp_show_elem-', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '-bp_show_elem-'}, 1}.
  {label, 13}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '__bp_show', 2, 9}.
  {label, 8}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_show'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 21}, [{x, 0}]}.
    {test, is_eq, {f, 20}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 22}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 24}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 23}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 23}, [{x, 0}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 29}}.
  {label, 28}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 29}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 26}, [{x, 0}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, undefined}]}.
  {label, 25}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 15}, 2}.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 27}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 15}.
  {label, 14}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_tagged'}, 2}.
  {label, 15}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 17}, 3}.
  {label, 31}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '__bp_render'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 33}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '-bp_render_pair-'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
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

{function, '-bp_stringify-', 1, 35}.
  {label, 34}.
    {line, [{location, "test@main@@Pet.erl", 4}]}.
    {func_info, {atom, test@main@@Pet}, {atom, '-bp_stringify-'}, 1}.
  {label, 35}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 36}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 36}.
    {test, is_integer, {f, 37}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 37}.
    {call, 1, {f, 11}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- test@main@@Door.S
```erlang
{module, test@main@@Door}.
{exports, [{close, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 44}.

{function, close, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Door.erl", 4}]}.
    {func_info, {atom, test@main@@Door}, {atom, close}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, test@main@@Door}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"closed ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 6}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 38}.
  {label, 37}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_get'}, 2}.
  {label, 38}.
    {test, is_eq_exact, {f, 39}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 39}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 41}.
  {label, 40}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_format'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Door">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 43}.
  {label, 42}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_behaviors'}, 0}.
  {label, 43}.
    {move, {literal, [std@primitives@@Closeable]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 6}.
  {label, 5}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_print'}, 1}.
  {label, 6}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 10}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 10}.
  {label, 9}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '-bp_show_top-'}, 1}.
  {label, 10}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '-bp_show_elem-', 1, 12}.
  {label, 11}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '-bp_show_elem-'}, 1}.
  {label, 12}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 8}}.

{function, '__bp_show', 2, 8}.
  {label, 7}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_show'}, 2}.
  {label, 8}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 20}, [{x, 0}]}.
    {test, is_eq, {f, 19}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 23}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 22}, [{x, 0}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 28}}.
  {label, 27}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 28}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 25}, [{x, 0}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 25}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, undefined}]}.
  {label, 24}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 14}, 2}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 26}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 14}.
  {label, 13}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_tagged'}, 2}.
  {label, 14}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 29}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 16}, 3}.
  {label, 30}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '__bp_render'}, 1}.
  {label, 16}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 31}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 18}.
  {label, 17}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '-bp_render_pair-'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 8}}.
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

{function, '-bp_stringify-', 1, 34}.
  {label, 33}.
    {line, [{location, "test@main@@Door.erl", 5}]}.
    {func_info, {atom, test@main@@Door}, {atom, '-bp_stringify-'}, 1}.
  {label, 34}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 35}.
    {test, is_integer, {f, 36}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 36}.
    {call, 1, {f, 10}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- test@main@@Registry.S
```erlang
{module, test@main@@Registry}.
{exports, [{at, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 17}.

{function, at, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Registry.erl", 5}]}.
    {func_info, {atom, test@main@@Registry}, {atom, at}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, test@main@@Registry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 6}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 9}, [{y, 2}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 9}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 11}.
  {label, 10}.
    {line, [{location, "test@main@@Registry.erl", 6}]}.
    {func_info, {atom, test@main@@Registry}, {atom, '__bp_get'}, 2}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, names}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 14}.
  {label, 13}.
    {line, [{location, "test@main@@Registry.erl", 6}]}.
    {func_info, {atom, test@main@@Registry}, {atom, '__bp_format'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"names">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Registry">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 16}.
  {label, 15}.
    {line, [{location, "test@main@@Registry.erl", 6}]}.
    {func_info, {atom, test@main@@Registry}, {atom, '__bp_behaviors'}, 0}.
  {label, 16}.
    {move, {literal, [std@primitives@@Index]}, {x, 0}}.
    return.

{function, '-bp_indexOf-', 3, 6}.
  {label, 5}.
    {line, [{location, "test@main@@Registry.erl", 6}]}.
    {func_info, {atom, test@main@@Registry}, {atom, '-bp_indexOf-'}, 3}.
  {label, 6}.
    {test, is_nonempty_list, {f, 7}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 8}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 8}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 6}}.
  {label, 7}.
    {move, {integer, -1}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
hi bob!
ann 70!
hi b!
woof rex!
meow 9!
hi x?
ann 3?
meow 1?
closed front
1
-1
```
