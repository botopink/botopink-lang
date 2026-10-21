//! Pattern facts every backend needs, with no backend of its own.
//!
//! A `val assert P = e [catch h];` (decision 8 § 9) binds `P`'s names in the
//! ENCLOSING scope, not in an arm. Each backend lowers that differently, but
//! they all first need the same question answered: does this pattern bind
//! anything at all? When it does not (`val assert 42 = answer catch 0;`), the
//! construct is a pure check and keeps the expression lowering it always had.

const std = @import("std");
const ast = @import("../ast.zig");

/// True when `p` binds at least one name. A variant pattern's payload binds;
/// a list pattern's `bind` elements and its named spread bind; a bare
/// identifier binds unless it names an enum variant — which only the backend
/// knows, so `isVariant` answers it.
pub fn bindsNames(p: ast.Pattern, ctx: anytype, comptime isVariant: fn (@TypeOf(ctx), []const u8) bool) bool {
    return switch (p) {
        .wildcard, .numberLit, .stringLit => false,
        .ident => |n| !isVariant(ctx, n),
        .variant => |v| switch (v.payload) {
            .binding => true,
            .fields => |fs| fs.len > 0,
            .literals => |args| blk: {
                for (args) |a| {
                    if (bindsNames(a, ctx, isVariant)) break :blk true;
                }
                break :blk false;
            },
        },
        .list => |lp| blk: {
            for (lp.elems) |e| {
                if (e == .bind) break :blk true;
            }
            const sp: []const u8 = lp.spread orelse "";
            break :blk sp.len > 0;
        },
        .@"or" => |pats| blk: {
            for (pats) |sub| {
                if (bindsNames(sub, ctx, isVariant)) break :blk true;
            }
            break :blk false;
        },
        .multi => |pats| blk: {
            for (pats) |sub| {
                if (bindsNames(sub, ctx, isVariant)) break :blk true;
            }
            break :blk false;
        },
    };
}

/// `bindsNames` for a backend that has no variant table to consult: a bare
/// identifier counts as a binding.
pub fn bindsNamesPlain(p: ast.Pattern) bool {
    const never = struct {
        fn f(_: void, _: []const u8) bool {
            return false;
        }
    }.f;
    return bindsNames(p, {}, never);
}
