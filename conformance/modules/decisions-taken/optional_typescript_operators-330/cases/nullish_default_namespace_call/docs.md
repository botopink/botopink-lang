# nullish_default_namespace_call

`a ?? ns.f()` with a call through a module namespace as the default — a std module's and one of the
package's own — calls that module's function only when `a` is absent, on every target (decision 330).
