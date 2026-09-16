----- SOURCE CODE -- main.bp
```botopink
val greeting = "ola mundo";
pub fn refer(comptime q: @Expr<string>) -> @Expr<string> {
    val hit = q.lookup("greeting");
    if (hit) { b ->
        return b.ref();
    };
    return q.fail("greeting not found in caller scope");
}
val s = refer "x";
fn main() {
    @print(s);
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: the template module did not compile: {[{".botopinkbuild/tmp/template/template_c0f50221cbdb0b53.erl",
                            [{{9,13},
                              erl_lint,
                              {undefined_function,{ref,1},{refer,[1]}}}]}],
                          [{".botopinkbuild/tmp/template/template_c0f50221cbdb0b53.erl",
                            [{{14,1},
                              erl_lint,
                              {unused_function,{'__bp_add',2}}},
                             {{17,1},
                              erl_lint,
                              {unused_function,{'__bp_len',2}}},
                             {{31,1},erl_lint,{unused_function,{text,1}}},
                             {{33,1},erl_lint,{unused_function,{parts,1}}},
                             {{35,1},erl_lint,{unused_function,{source,1}}},
                             {{37,1},erl_lint,{unused_function,{context,1}}},
                             {{39,1},erl_lint,{unused_function,{bindings,1}}},
                             {{46,1},erl_lint,{unused_function,{build,2}}},
                             {{48,1},erl_lint,{unused_function,{custom,3}}},
                             {{52,1},erl_lint,{unused_function,{failAt,3}}},
                             {{54,1},
                              erl_lint,
                              {unused_function,{compilerError,1}}},
                             {{56,1},erl_lint,{unused_function,{expr,1}}},
                             {{58,1},erl_lint,{unused_function,{code,1}}}]}]}
  ┌─ :9:9
  │
9 │ val s = refer "x";
  │         ^

  hint: Thrown while evaluating the template function's body at compile time.
```

