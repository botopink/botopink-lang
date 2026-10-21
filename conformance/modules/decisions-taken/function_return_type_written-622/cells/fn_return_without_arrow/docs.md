# fn_return_without_arrow

Decisions 622, 846: a return type is written behind `->`. `fn double(x: i32) i32` has no arrow, so it is refused at its
name, `fn-return-missing`, the hint naming `-> i32`; the parser no longer reads a type with no `->` as a bodyless declaration.
