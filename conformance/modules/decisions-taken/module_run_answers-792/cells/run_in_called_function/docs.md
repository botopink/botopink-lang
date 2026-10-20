# run_in_called_function

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `run()` written anywhere but directly in a `compiler.init` body — in the body that runs at build
> outside its init, in a function the init body calls, in a body that runs when the program runs — is
> `run-outside-init`, at the call.
