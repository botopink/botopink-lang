/// Compile-time string constants for the stdlib .bp source files.
/// Imported by the botopink core type checker to preload primitive interfaces.
/// The .bp/.d.bp sources stay under libs/std/src/ (which is .bp-only); each
/// file is exposed as an anonymous import in build.zig (std_bp_files) and
/// embedded here by name. One `pub const` per stdlib source.
///
/// `primitives.d.bp` is the controller (numeric tower, Bool, String, Function,
/// Array<T>) and `builtins.bp` holds the builtin model (reflection, io, Result,
/// the lazy Iterator<T>, generators, async, Expr<E>, annotations). Both flatten
/// into the global env. The remaining files are concrete `record`/`enum` modules
/// importable via `import {…} from "std";`.
pub const primitives = @embedFile("primitives.d.bp");
pub const builtins = @embedFile("builtins.d.bp");

// "std" package impl modules — importable via `import {…} from "std";`.
// These are NOT flattened into the global env (see comptime.zig std_pkg_modules).
// NOTE: `option`/`result` are NOT modules — they are builtin namespaces lowered
// inline by every backend (see comptime/infer.zig `inferBuiltinNamespaceCall`).
//
// The package registry is DATA-DRIVEN: `build.zig` enumerates the package `.bp`
// files (its `std_pkg_files` list) and generates the `pkg_modules` table, which
// this prelude re-exports. compiler-core therefore names no individual std
// module — adding one touches only `build.zig` + `libs/std/`, never this tree.
pub const pkg_modules = @import("std_pkg").pkg_modules;

// Non-std libs are NOT embedded here: `std` is the one lib the core may name.
// Any other lib (a framework, …) is supplied as ordinary input `.bp` modules by
// the driver and resolved generically through the shared import registry — the
// core knows nothing about any specific framework.
