# fn_return_missing

Decision 622: every function writes its return type, `-> void` included. `greet` answers nothing and writes no `->`;
it is refused at its name, `fn-return-missing`, the message naming what to write: `-> void`, or the type it answers.
