const core = @import("core.zig");

pub const c = core.c;

pub const Fraction = struct {
    numerator: i32,
    denominator: i32,

    pub fn new(num: anytype, den: anytype) Fraction {
        return .{ .numerator = @intCast(num), .denominator = @intCast(den) };
    }

    pub inline fn toFloat(self: Fraction) f64 {
        return @as(f64, @floatFromInt(self.numerator)) / @as(f64, @floatFromInt(self.denominator));
    }

    pub inline fn isValid(self: Fraction) bool {
        return self.denominator != 0;
    }

    pub inline fn equals(self: Fraction, other: Fraction) bool {
        return self.numerator == other.numerator and self.denominator == other.denominator;
    }
};
