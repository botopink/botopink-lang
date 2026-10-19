# Decision 622 — Every function writes its return type, `-> void` included: `fn m(self: Self) -> void { … }`, `pub fn main() -> void { … }`; a `fn` with no `->` is refused at its name, `fn-return-missing`, `write -> void, or the type it answers`.

[cases/fn_tail_in_void/src/main.bp](cases/fn_tail_in_void/src/main.bp)
[cases/fn_tail_value/src/main.bp](cases/fn_tail_value/src/main.bp)
