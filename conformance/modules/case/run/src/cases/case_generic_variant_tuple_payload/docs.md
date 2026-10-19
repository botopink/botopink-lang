# case_generic_variant_tuple_payload

A variant pattern takes the type of its payload from the matched value's type argument, so a tuple pattern nested in it (`.Some(#(a, b))` over a `Maybe<#(i32, i32)>`) binds the tuple's elements.
