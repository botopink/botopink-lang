> A field typed `?fn(string) -> string` holds a lambda written against that type; a call
> through the field, directly with `?.(…)` or through a local narrowed by `!= null`,
> answers the function's `string` on every target.
