# component_call_lambda_in_body

Decision 791 (1): a call of a component makes its lambda in a component body too — `val x: Component<Prop> = mk(2);` in a body written `-> Component<string>` is accepted, and nothing runs until the tree or a `use` runs it.
