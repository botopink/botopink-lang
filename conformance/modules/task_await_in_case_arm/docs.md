# task_await_in_case_arm

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> An `await` may sit in an arm of a `case`, in a branch of an `if` or in a `case` nested in
> an arm, in a generic function as in a plain one: the task suspends there and resumes into
> the arm, with the same answer on every target.
