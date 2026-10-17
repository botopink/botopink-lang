# template_name_shadowed_by_local

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> A template function's name follows the scope rule: the nearest binding wins,
> so a parameter or a local of the name is the value a call there calls
> (`fn run(shout: fn(string) -> string) { return shout("x"); }`), and the
> template is the name's everywhere else. Named without a call a template
> function is no value — it exists only while the program compiles — and
> `val f = shout;` is refused where the name is read (`template-function-value`).
