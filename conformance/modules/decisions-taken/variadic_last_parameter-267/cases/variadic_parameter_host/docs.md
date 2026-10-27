# variadic_parameter_host

A `declare fn` bound to a host function takes a variadic like any function. commonJS hands the host its arguments one by one, erlang and beam one list. wasm has no host, so it refuses the program where the host function is first called (decision 267).
