# case_optional_variant_pattern_refused

A `?T` is matched by `null` and `_` alone (decision 980 (2)): a variant pattern over a `?T`, `.Some(v) { … }`, is refused at the pattern, the error naming the `null` and `_` form — `Option<T>` and `Option.Some` left the language.
