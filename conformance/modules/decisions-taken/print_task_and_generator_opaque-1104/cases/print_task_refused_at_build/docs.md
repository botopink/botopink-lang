# print_task_refused_at_build

`print` of a value whose static type is a task (`Async<T>`) is refused at build (decision 1104), naming the type and `print-task`, identically on all four targets.
