# print_generator_through_unknown_panics

A generator (`AsyncIter<T>`) reaching an `unknown` slot through a generic parameter a call binds to one — a generic body compiled once for every instantiation, so the build refusal cannot catch it — keeps decision 1104's dynamic case: the same named panic on every target, `wasm cannot print a generator value dynamically yet`, caught here through `std.failure.attempt` so its exact message compares equal across targets instead of an uncaught process exit.
