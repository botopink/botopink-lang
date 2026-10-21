# noreturn_body_falls_through_refused

A function declared `-> noreturn` whose body can complete is refused at its name, `noreturn-falls-through` (decision 929): end every path with a `noreturn` call, a `throw` or a loop that never breaks.
