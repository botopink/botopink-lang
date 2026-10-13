# optional_method_absent_receiver

`recv?.m(args)` over an absent receiver is absent and calls nothing; over a present one it is the
method's answer — a local, a call and an array element as the receiver, a primitive method answering
an integer, a string and a bool, on every target (decision 330).
