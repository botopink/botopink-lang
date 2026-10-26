# case_bare_name_arrow_arm

A name alone is not a pattern: to give the matched value a name, bind it in the body (`_ { n -> … }`). The `pattern -> value` arm is no exception: `k -> k + 1` is refused at the arm as `k { … }` is.
