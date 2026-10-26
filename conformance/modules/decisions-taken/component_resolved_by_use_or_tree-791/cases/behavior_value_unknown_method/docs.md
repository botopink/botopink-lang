# behavior_value_unknown_method

B-162 (decisions 523, 791): a method call on a value typed by a behavior — here an `Async<string>`, which declares no members — names a member the behavior declares or is refused at the name; `a.zzz()` is an unknown method.
