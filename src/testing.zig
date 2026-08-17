//! Test-only helper shared by every source file.
//!
//! Zig analyzes lazily: a `pub` declaration with no call site is never
//! type-checked. Most of a bindings library is exactly that, so without a
//! forced reference, type errors in unused bindings stay invisible to
//! `zig build`. Each file ends with
//!
//!     test {
//!         @import("testing").refAllDeclsRecursive(@This());
//!     }
//!
//! which gives every declaration in that file a call site.

const std = @import("std");
const c = @import("c");

/// References every public declaration of `T`, descending into declarations
/// that are themselves namespaces so methods on a struct are reached too.
///
/// `std.testing.refAllDecls` stops at the namespace it is given, which would
/// reference `Element` but none of `Element`'s methods.
///
/// Note this walks *declarations*, not imports: `@import` is not a declaration,
/// and `@typeInfo().decls` lists only `pub` ones. A file therefore only gets
/// analyzed if something imports it, which is why each file carries its own
/// test rather than a central list trying to name them all.
pub fn refAllDeclsRecursive(comptime T: type) void {
    inline for (comptime std.meta.declarations(T)) |decl| {
        const field = @field(T, decl.name);
        if (@TypeOf(field) == type) {
            // The translate-c namespace is not our code, and walking it costs
            // far more than it catches.
            if (field == c) continue;
            // Guards the `pub const Self = @This()` idiom from recursing forever.
            if (field != T) switch (@typeInfo(field)) {
                .@"struct", .@"enum", .@"union", .@"opaque" => refAllDeclsRecursive(field),
                else => {},
            };
        }
        _ = &@field(T, decl.name);
    }
}
