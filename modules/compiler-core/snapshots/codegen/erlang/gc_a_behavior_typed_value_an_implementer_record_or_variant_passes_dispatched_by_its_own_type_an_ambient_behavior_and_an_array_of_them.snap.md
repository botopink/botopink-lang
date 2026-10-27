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

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__welcome'/1, '__bp_priv__make'/1, '__bp_priv__shut'/1, '__bp_priv__lookup'/2]).

%% behavior Greeter

%% type Bob: name

%% type Ann: age

%% type Pet
%%   Dog(name)
%%   Cat(lives)

%% type Door: name

%% type Registry: names

welcome(G) ->
    '__bp_method'(greet, G, [<<"!">>]).

make(Old) ->
    case Old of
        true ->
            {test@main@@Ann, 70};
        _ ->
            {test@main@@Bob, <<"b">>}
    end.

shut(C) ->
    '__bp_method'(close, C, []).

lookup(M, Key) ->
    case '__bp_method'(at, M, [Key]) of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end.

main() ->
    '__bp_print'([welcome({test@main@@Bob, <<"bob">>})]),
    '__bp_print'([welcome(make(true))]),
    '__bp_print'([welcome(make(false))]),
    '__bp_print'([welcome({test@main@@Pet__v__dog, <<"rex">>})]),
    '__bp_print'([welcome({test@main@@Pet__v__cat, 9})]),
    All = [{test@main@@Bob, <<"x">>}, {test@main@@Ann, 3}, {test@main@@Pet__v__cat, 1}],
    lists:foreach(fun(G) ->
        '__bp_print'(['__bp_method'(greet, G, [<<"?">>])])
    end, All),
    shut({test@main@@Door, <<"front">>}),
    R = {test@main@@Registry, [<<"ana">>, <<"bo">>]},
    '__bp_print'([lookup(R, <<"bo">>)]),
    '__bp_print'([lookup(R, <<"zz">>)]).

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

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

'__bp_priv__welcome'(A0) -> welcome(A0).

'__bp_priv__make'(A0) -> make(A0).

'__bp_priv__shut'(A0) -> shut(A0).

'__bp_priv__lookup'(A0, A1) -> lookup(A0, A1).
```

----- ERLANG -- test@main@@Bob.erl
```erlang
-module(test@main@@Bob).
-export([greet/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

greet(Self, Punct) ->
    <<"hi ", ('__bp_text'(erlang:element(2, Self)))/binary, Punct/binary>>.

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Bob", [{"name", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [test@main@@Greeter].

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
```

----- ERLANG -- test@main@@Ann.erl
```erlang
-module(test@main@@Ann).
-export([greet/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

greet(Self, Punct) ->
    <<"ann ", ('__bp_text'(erlang:integer_to_binary(erlang:element(2, Self))))/binary, Punct/binary>>.

'__bp_get'(V, age) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Ann", [{"age", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [test@main@@Greeter].

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
```

----- ERLANG -- test@main@@Pet.erl
```erlang
-module(test@main@@Pet).
-export([greet/2, '__bp_format'/1, '__bp_behaviors'/0]).

greet(Self, Punct) ->
    case Self of
        {test@main@@Pet__v__dog, Name} ->
            <<"woof ", ('__bp_text'(Name))/binary, Punct/binary>>;
        {test@main@@Pet__v__cat, Lives} ->
            <<"meow ", ('__bp_text'(erlang:integer_to_binary(Lives)))/binary, Punct/binary>>
    end.

'__bp_format'({test@main@@Pet__v__dog, F0}) -> {variant, "Pet.Dog", [{"name", F0}]};
'__bp_format'({test@main@@Pet__v__cat, F0}) -> {variant, "Pet.Cat", [{"lives", F0}]}.

'__bp_behaviors'() -> [test@main@@Greeter].

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
```

----- ERLANG -- test@main@@Door.erl
```erlang
-module(test@main@@Door).
-export([close/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

close(Self) ->
    '__bp_print'([<<"closed ", ('__bp_text'(erlang:element(2, Self)))/binary>>]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Door", [{"name", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [std@primitives@@Closeable].

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
```

----- ERLANG -- test@main@@Registry.erl
```erlang
-module(test@main@@Registry).
-export([at/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

at(Self, Key) ->
    Found = (fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(erlang:element(2, Self), Key),
    case (Found < 0) of
        true ->
            undefined;
        _ ->
            Found
    end.

'__bp_get'(V, names) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Registry", [{"names", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [std@primitives@@Index].
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
