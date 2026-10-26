//// A template method declared in another module over a generic behavior —

//// the shape of decision 415's `query<E>(comptime self: @Expr<QueryContext<E>>,

//// comptime q: @Expr<string>)`: the importer calls it on a value of a type

//// that implements the behavior.

const code = require("../std/code.js");

// behavior Store
//   fn fetch(...)

Object.defineProperty(exports, "__bp_priv__", { value: { code } });
