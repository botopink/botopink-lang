//! format: the trailing comma alone decides a delimited list's shape
//! (decisions 166, 243, 345). One case per list kind, in both spellings:
//! written with a comma after the last element the list prints one element per
//! line and keeps the comma; written without, it prints on one line whatever its
//! width — and a list written open without the comma is joined.

const std = @import("std");
const h = @import("helpers.zig");

const alloc = std.testing.allocator;

/// `open` (with the trailing comma) is canonical; `closed` (without) is
/// canonical on one line; the open spelling without the comma joins to `closed`.
fn bothSpellings(open: []const u8, openWithoutComma: []const u8, closed: []const u8) !void {
    try h.assertFormatLossless(alloc, open);
    try h.assertIdempotent(alloc, open);
    try h.assertFormatLossless(alloc, closed);
    try h.assertIdempotent(alloc, closed);
    try h.assertFormatAs(alloc, openWithoutComma, closed);
}

test "format: trailing comma ---- call arguments" {
    try bothSpellings(
        \\fn f() {
        \\    g(
        \\        1,
        \\        2,
        \\    );
        \\}
    ,
        \\fn f() {
        \\    g(
        \\        1,
        \\        2
        \\    );
        \\}
    ,
        \\fn f() {
        \\    g(1, 2);
        \\}
    );
}

test "format: trailing comma ---- parameters" {
    try bothSpellings(
        \\fn f(
        \\    a: i32,
        \\    b: i32,
        \\) -> i32 {
        \\    return a;
        \\}
    ,
        \\fn f(
        \\    a: i32,
        \\    b: i32
        \\) -> i32 {
        \\    return a;
        \\}
    ,
        \\fn f(a: i32, b: i32) -> i32 {
        \\    return a;
        \\}
    );
}

test "format: trailing comma ---- arrays" {
    try bothSpellings(
        \\fn f() {
        \\    val xs = [
        \\        1,
        \\        2,
        \\    ];
        \\}
    ,
        \\fn f() {
        \\    val xs = [
        \\        1,
        \\        2
        \\    ];
        \\}
    ,
        \\fn f() {
        \\    val xs = [1, 2];
        \\}
    );
}

test "format: trailing comma ---- tuples" {
    try bothSpellings(
        \\fn f() {
        \\    val t = #(
        \\        1,
        \\        2,
        \\    );
        \\}
    ,
        \\fn f() {
        \\    val t = #(
        \\        1,
        \\        2
        \\    );
        \\}
    ,
        \\fn f() {
        \\    val t = #(1, 2);
        \\}
    );
}

test "format: trailing comma ---- record fields" {
    try bothSpellings(
        \\type Point(
        \\    x: i32,
        \\    y: i32,
        \\)
    ,
        \\type Point(
        \\    x: i32,
        \\    y: i32
        \\)
    ,
        \\type Point(x: i32, y: i32)
    );
}

test "format: trailing comma ---- enum variants" {
    try bothSpellings(
        \\type Color {
        \\    Red,
        \\    Green,
        \\}
    ,
        \\type Color {
        \\    Red,
        \\    Green
        \\}
    ,
        \\type Color { Red, Green }
    );
}

test "format: trailing comma ---- imports" {
    try bothSpellings(
        \\import {
        \\    a,
        \\    b,
        \\} from "m";
    ,
        \\import {
        \\    a,
        \\    b
        \\} from "m";
    ,
        \\import {a, b} from "m";
    );
}

test "format: trailing comma ---- generic parameters" {
    try bothSpellings(
        \\fn f<
        \\    A,
        \\    B,
        \\>(a: A, b: B) -> A {
        \\    return a;
        \\}
    ,
        \\fn f<
        \\    A,
        \\    B
        \\>(a: A, b: B) -> A {
        \\    return a;
        \\}
    ,
        \\fn f<A, B>(a: A, b: B) -> A {
        \\    return a;
        \\}
    );
}

test "format: trailing comma ---- annotations" {
    try bothSpellings(
        \\#[
        \\    a,
        \\    b,
        \\]
        \\fn f() {}
    ,
        \\#[
        \\    a,
        \\    b
        \\]
        \\fn f() {}
    ,
        \\#[a, b]
        \\fn f() {}
    );
}

test "format: trailing comma ---- a list without it stays on one line past the width" {
    const long =
        \\fn f(aaaaaaaaaaaaaaaaaaaaaaaaaaa: i32, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb: i32, cccccccccccccccccccccccc: i32) -> i32 {
        \\    val xs = [aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb, ccccccccccccc];
        \\    val t = #(aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb, ccccccccccccc);
        \\    return call(aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb, ccccccccccccc);
        \\}
    ;
    try h.assertFormatLossless(alloc, long);
    try h.assertIdempotent(alloc, long);
}
