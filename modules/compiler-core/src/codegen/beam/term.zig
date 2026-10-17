//! BEAM term data model — the single value representation shared by every
//! emitter that targets the BEAM VM.
//!
//! A `Term` describes an Erlang value (not code). `erl_emitter.zig` renders it
//! as Erlang source (`#{kind => 'Record'}`), `beam_emitter.zig` as a BEAM asm
//! operand (`{literal, #{kind => 'Record'}}`). Producers (the `@Decl` handle,
//! decorator/template plain args, comptime values) build a `Term` once and pick
//! the emitter for their target.
//!
//! Terms borrow their slices: build them in an arena that outlives emission.

const std = @import("std");

pub const Term = union(enum) {
    /// Atom by its *unquoted* name (`ok`, `Record`); emitters add quotes.
    atom: []const u8,
    /// Binary holding raw runtime bytes (not source-escaped).
    binary: []const u8,
    integer: i64,
    float: f64,
    /// Rendered as the atoms `true` / `false`.
    boolean: bool,
    /// The empty list.
    nil,
    list: []const Term,
    tuple: []const Term,
    map: []const MapEntry,

    pub const MapEntry = struct {
        key: Term,
        value: Term,
    };

    /// `undefined` — the conventional absent value.
    pub const undefined_atom: Term = .{ .atom = "undefined" };

    pub fn atomOf(name: []const u8) Term {
        return .{ .atom = name };
    }

    pub fn str(bytes: []const u8) Term {
        return .{ .binary = bytes };
    }

    pub fn int(n: i64) Term {
        return .{ .integer = n };
    }

    /// A list; the empty slice renders as `[]` (same value as `.nil`).
    pub fn listOf(items: []const Term) Term {
        return .{ .list = items };
    }

    pub fn tupleOf(items: []const Term) Term {
        return .{ .tuple = items };
    }

    pub fn mapOf(entries: []const MapEntry) Term {
        return .{ .map = entries };
    }

    /// Map entry keyed by an atom — the shape records lower to (`#{name => …}`).
    pub fn field(key: []const u8, value: Term) MapEntry {
        return .{ .key = .{ .atom = key }, .value = value };
    }
};

test "Term: constructors build the expected variants" {
    try std.testing.expectEqualStrings("ok", Term.atomOf("ok").atom);
    try std.testing.expectEqualStrings("hi", Term.str("hi").binary);
    try std.testing.expectEqual(@as(i64, 7), Term.int(7).integer);
    const entries = [_]Term.MapEntry{Term.field("kind", Term.atomOf("Record"))};
    const m = Term.mapOf(&entries);
    try std.testing.expectEqualStrings("kind", m.map[0].key.atom);
    try std.testing.expectEqualStrings("Record", m.map[0].value.atom);
}
