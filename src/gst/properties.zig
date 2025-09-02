// TODO: This could be removed
const std = @import("std");
const core = @import("core.zig");
pub const c = core.c;

pub const VideoTestSrcPattern = enum(c_int) {
    smpte = 0,
    snow = 1,
    black = 2,
    white = 3,
    red = 4,
    green = 5,
    blue = 6,
    checkers1 = 7,
    checkers2 = 8,
    checkers4 = 9,
    checkers8 = 10,
    circular = 11,
    blink = 12,
    smpte75 = 13,
    zone_plate = 14,
    gamut = 15,
    chroma_zone_plate = 16,
    solid_color = 17,
    ball = 18,
    smpte100 = 19,
    bar = 20,
    pinwheel = 21,
    spokes = 22,
    gradient = 23,
    colors = 24,
};
