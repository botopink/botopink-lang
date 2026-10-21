# generic_fn_value_called_untyped

A generic function that writes its type parameter as text, bound to a local with no written type and called through it,
answers what the direct call does on every target: the call binds the type parameter from its argument, so a float keeps
its decimal part, a string its text and a tuple its `#(…)` form.
