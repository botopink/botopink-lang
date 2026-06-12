----- SOURCE CODE
#[@external(erlang)]
pub declare fn str_length(s: string) -> i32;

----- ERROR
error: `@external` expects 2 or 3 arguments: @external(target, [module,] symbol)

  hint: Example: #[@external(erlang, "string", "length")] or #[@external(node, "reverse")]
