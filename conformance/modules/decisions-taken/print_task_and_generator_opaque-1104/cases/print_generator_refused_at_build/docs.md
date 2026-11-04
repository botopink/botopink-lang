# print_generator_refused_at_build

`print` of a value whose static type is a generator (`Iter<T>`, `AsyncIter<T>`) is refused at build (decision 1104), naming the type and `print-generator`, identically on all four targets.
