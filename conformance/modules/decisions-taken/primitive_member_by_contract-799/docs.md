# Decision 799 — A program adds members to a primitive type through a contract of its own implemented for it — `behavior Shout { default fn tailShout(self: Self) -> string { … } }` then `StringShout implement Shout for string {}`, and `"a+b".tailShout()` answers `a+b!`; no `behavior string`, no `extend` on a primitive; amends 136.

[cases/primitive_behavior_named_like_type_refused/src/main.bp](cases/primitive_behavior_named_like_type_refused/src/main.bp)
[cases/primitive_extend_refused/src/main.bp](cases/primitive_extend_refused/src/main.bp)
[cells/primitive_member_by_contract/src/main.bp](cells/primitive_member_by_contract/src/main.bp)
