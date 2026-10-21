# lambda_assignment_tail_answers_nothing

Decisions 541 (1) and 583: a lambda typed by its `val`'s annotation, `fn(string)` (it answers nothing), whose body ends in an
assignment (`count = count + 1;`) answers nothing — an assignment is a statement. It used to be typed as answering the
assigned `i32`, refused against the annotation. It prints `<start> 1`.
