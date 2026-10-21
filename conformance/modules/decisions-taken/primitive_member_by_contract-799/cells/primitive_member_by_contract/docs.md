# primitive_member_by_contract

Decision 799: a program adds members to a primitive type through a contract of its own implemented for it.
`StringShout implement Shout for string {}` gives every `string` the contract's `tailShout`, so `"a+b".tailShout()`
answers `a+b!` and std's own members (`length`) answer beside it; a contract another module declares is implemented
the same way (`Loud`), and `array<T>` takes one written `ArrSecond<T> implement Second<T> for array<T> {}`, whose
required `at` the array's own member meets. The parent binary refused the call, `unknown-primitive-method`.
