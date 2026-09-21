//! format: the width predicate on hand-built documents (decision 65).
//!
//! `fits` is what a measured group asks; `fitsPinned` is what every group still
//! waiting for its canonical broken form asks. Both are exercised here on a
//! document built by hand — no source, no parser — so the predicate is tested
//! apart from any construct that happens to use it.

const std = @import("std");
const formatMod = @import("../../format.zig");
const Doc = formatMod.Doc;
const Formatter = formatMod.Formatter;

/// `xs` then three links, each behind a `softline`, nested +4: the shape the
/// method chain builds. Flat it is `xs.aaa().bbb().ccc()` — 20 columns.
fn chain(f: *Formatter) !*const Doc {
    const links = try f.concat(
        try f.concat(f.softline(), try f.text(".aaa()")),
        try f.concat(
            try f.concat(f.softline(), try f.text(".bbb()")),
            try f.concat(f.softline(), try f.text(".ccc()")),
        ),
    );
    return f.concat(try f.text("xs"), try f.nest(formatMod.INDENT, links));
}

fn expectRender(doc: *const Doc, width: usize, want: []const u8) !void {
    const got = try formatMod.render(std.testing.allocator, doc, width);
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings(want, got);
}

test "fits: a measured group renders flat when its flat spelling fits, and breaks every softline when it does not" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    const doc = try f.groupMeasured(try chain(&f));
    try expectRender(doc, 20, "xs.aaa().bbb().ccc()");
    try expectRender(doc, 19,
        \\xs
        \\    .aaa()
        \\    .bbb()
        \\    .ccc()
    );
}

test "fits: what follows the group on the line is charged, so the boundary is exact" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    // 20 columns of chain plus the `;` after it: 21 fit, 20 do not.
    const doc = try f.concat(try f.groupMeasured(try chain(&f)), try f.text(";"));
    try expectRender(doc, 21, "xs.aaa().bbb().ccc();");
    try expectRender(doc, 20,
        \\xs
        \\    .aaa()
        \\    .bbb()
        \\    .ccc();
    );
}

test "fits: a break after the group ends the line — what is beyond it is not charged" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    // Statements are joined by hardlines; the next statement's 60 columns must
    // not make this group break.
    const long = "a_statement_that_is_much_wider_than_the_width_and_lives_below";
    const doc = try f.concat(
        try f.groupMeasured(try chain(&f)),
        try f.concat(f.hardline(), try f.text(long)),
    );
    try expectRender(doc, 20, "xs.aaa().bbb().ccc()\n" ++ long);
}

test "fits: a hardline or a forceBreak inside the group means the flat spelling does not exist" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    // A link holding a lambda with a statement body carries a hardline.
    const body = try f.concat(
        try f.concat(try f.text(".map({ x ->"), try f.nest(formatMod.INDENT, try f.concat(f.hardline(), try f.text("x;")))),
        try f.concat(f.hardline(), try f.text("})")),
    );
    const doc = try f.groupMeasured(try f.concat(
        try f.text("xs"),
        try f.nest(formatMod.INDENT, try f.concat(try f.concat(f.softline(), try f.text(".take(1)")), try f.concat(f.softline(), body))),
    ));
    try expectRender(doc, 200,
        \\xs
        \\    .take(1)
        \\    .map({ x ->
        \\        x;
        \\    })
    );

    const forced = try f.groupMeasured(try f.concat(try f.text("a"), try f.forceBreak(try f.concat(f.softline(), try f.text("b")))));
    try expectRender(forced, 200, "a\nb");
}

test "fitsPinned: a group whose construct is not enabled renders flat past the width" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    // The same chain, pinned: the scan this formatter always had stops at the
    // first `concat` and answers "fits" for any non-negative budget, so the
    // output is byte-identical to what it was before `fits` was repaired.
    const doc = try f.concat(try f.group(try chain(&f)), try f.text(";"));
    try expectRender(doc, 10, "xs.aaa().bbb().ccc();");
}

test "fits: a measured group nested in a pinned one is decided at the column it really starts" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var f = Formatter.init(arena.allocator());

    // `f(` + chain + `)`: the pinned call group stays flat, the chain inside it
    // measures from column 2 and charges the `)` — 23 columns, so 23 fits and 22 breaks.
    const doc = try f.group(try f.concat(
        try f.text("f("),
        try f.concat(try f.groupMeasured(try chain(&f)), try f.text(")")),
    ));
    try expectRender(doc, 23, "f(xs.aaa().bbb().ccc())");
    try expectRender(doc, 22,
        \\f(xs
        \\    .aaa()
        \\    .bbb()
        \\    .ccc())
    );
}
