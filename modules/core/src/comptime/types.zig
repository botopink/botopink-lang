/// Core type representation for the botopink type system.
///
/// Inspired by Gleam's Type enum with four variants:
///   Named | Func | TypeVar | Union_
///
/// All nodes are allocated in a caller-supplied arena ---- no individual frees.
const std = @import("std");

/// Unique identifier for type variables.
pub const TypeId = u32;

/// A mutable cell holding a TypeVar.
/// Using a pointer to this cell allows unification to mutate the variable
/// in place without invalidating any existing *Type pointers.
pub const TypeCell = struct {
    state: TypeVar,
};

/// The three states of a Hindley-Milner type variable.
pub const TypeVar = union(enum) {
    /// Free variable not yet unified. `level` is the let-binding depth at
    /// which this variable was created ---- used during generalization.
    unbound: struct { id: TypeId, level: usize },
    /// Resolved: follow `type_` to reach the actual type.
    link: *Type,
    /// Generalized (polymorphic) variable inside a type scheme.
    /// Instantiated to a fresh unbound var each time the scheme is used.
    generic: TypeId,
};

/// A botopink type.
pub const Type = union(enum) {
    /// Named type ---- builtin (`Int`, `Float`, `String`, `Bool`) or user-defined.
    /// `args` holds instantiated type parameters for generic types.
    named: struct {
        name: []const u8,
        args: []*Type,
    },
    /// Function type: `fn(params...) -> ret`.
    func: struct {
        params: []*Type,
        ret: *Type,
    },
    /// Type variable ---- may be unbound, linked, or generic.
    typeVar: *TypeCell,
    /// Union type: `A | B | C` ---- produced when branching constructs (e.g. case)
    /// have arms of structurally different types.
    union_: []*Type,

    /// Follow all `.link` chains and return the innermost non-link type.
    /// Never allocates; safe to call on any type.
    pub fn deref(self: *Type) *Type {
        var cur: *Type = self;
        while (true) {
            switch (cur.*) {
                .typeVar => |cell| switch (cell.state) {
                    .link => |linked| cur = linked,
                    else => return cur,
                },
                else => return cur,
            }
        }
    }

    pub fn isUnbound(self: *Type) bool {
        return switch (self.deref().*) {
            .typeVar => |cell| switch (cell.state) {
                .unbound => true,
                else => false,
            },
            else => false,
        };
    }

    pub fn isNamed(self: *Type, name: []const u8) bool {
        return switch (self.deref().*) {
            .named => |n| std.mem.eql(u8, n.name, name),
            else => false,
        };
    }
};
