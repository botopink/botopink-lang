# behavior_value_unknown_field

B-162 (decision 791): a value typed by a behavior — here a `Component<View>`, the lambda a component call makes — answers only the members the behavior, and what it extends, declares; `c.zzz` is an unknown field, refused at the name. `Component<R>` declares `run`, which stays callable.
