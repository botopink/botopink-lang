# optional_case_null_and_binder

A `?T` is matched by `null` and `_` alone (decision 980 (1), (4)): `case x { null { … } _ { … } }`, the `_` arm reading the value as `x!`. A present `5` prints `present 5`, an absent value `absent`.
