# primitive_static_on_local_is_method

Decision 873 (2), 606 (1): the local `bytes` wins in its body, so `bytes.fromUtf8("b")` is a method call
on a `bytes` value, which has no `fromUtf8`. Refused at the call.
