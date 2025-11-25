const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;
pub const GstCaps = core.GstCaps;

pub const Fraction = core.Fraction;

pub const Caps = struct {
    ptr: GstCaps,

    pub fn new() !Caps {
        const ptr = c.gst_caps_new_empty();
        if (ptr == null) {
            return error.CapsCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn newAny() !Caps {
        const ptr = c.gst_caps_new_any();
        if (ptr == null) {
            return error.CapsCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn newSimple(media_type: [*:0]const u8) !Caps {
        const ptr = c.gst_caps_new_empty_simple(media_type);
        if (ptr == null) {
            return error.CapsCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn fromString(str: [*:0]const u8) !Caps {
        const ptr = c.gst_caps_from_string(str);
        if (ptr == null) {
            return error.InvalidCapsString;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: Caps) void {
        c.gst_caps_unref(self.ptr);
    }

    pub fn copy(self: Caps) !Caps {
        const ptr = c.gst_caps_copy(self.ptr);
        if (ptr == null) {
            return error.CapsCopyFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn toString(self: Caps) [*:0]const u8 {
        return c.gst_caps_to_string(self.ptr);
    }

    pub inline fn isFixed(self: Caps) bool {
        return c.gst_caps_is_fixed(self.ptr) != 0;
    }

    pub inline fn isEqual(self: Caps, other: Caps) bool {
        return c.gst_caps_is_equal(self.ptr, other.ptr) != 0;
    }

    pub inline fn isSubset(self: Caps, superset: Caps) bool {
        return c.gst_caps_is_subset(self.ptr, superset.ptr) != 0;
    }

    pub inline fn isAny(self: Caps) bool {
        return c.gst_caps_is_any(self.ptr) != 0;
    }

    pub inline fn isEmpty(self: Caps) bool {
        return c.gst_caps_is_empty(self.ptr) != 0;
    }

    pub inline fn canIntersect(self: Caps, other: Caps) bool {
        return c.gst_caps_can_intersect(self.ptr, other.ptr) != 0;
    }

    pub fn intersect(self: Caps, other: Caps) !Caps {
        const ptr = c.gst_caps_intersect(self.ptr, other.ptr);
        if (ptr == null) {
            return error.CapsIntersectFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn merge(self: *Caps, other: Caps) void {
        self.ptr = c.gst_caps_merge(self.ptr, other.ptr);
    }

    pub fn append(self: *Caps, other: Caps) void {
        c.gst_caps_append(self.ptr, other.ptr);
    }

    pub inline fn getSize(self: Caps) u32 {
        return c.gst_caps_get_size(self.ptr);
    }

    pub inline fn getStructure(self: Caps, index: u32) ?*c.GstStructure {
        return c.gst_caps_get_structure(self.ptr, @intCast(index));
    }

    pub fn builder(media_type: [*:0]const u8) CapsBuilder {
        return CapsBuilder.init(media_type) catch unreachable;
    }
};

pub const CapsBuilder = struct {
    caps: Caps,

    pub fn init(media_type: [*:0]const u8) !CapsBuilder {
        const caps = try Caps.newSimple(media_type);
        return .{ .caps = caps };
    }

    pub fn field(self: CapsBuilder, name: [*:0]const u8, value: anytype) CapsBuilder {
        // Get the first (and only) structure from the caps
        const structure = c.gst_caps_get_structure(self.caps.ptr, 0);

        const T = @TypeOf(value);
        switch (T) {
            i32, c_int => {
                c.gst_structure_set(structure, name, c.G_TYPE_INT, @as(c_int, value), @as(?*anyopaque, null));
            },
            i64, c_long => {
                c.gst_structure_set(structure, name, c.G_TYPE_INT64, @as(c_long, value), @as(?*anyopaque, null));
            },
            u32, c_uint => {
                c.gst_structure_set(structure, name, c.G_TYPE_UINT, @as(c_uint, value), @as(?*anyopaque, null));
            },
            u64 => {
                c.gst_structure_set(structure, name, c.G_TYPE_UINT64, @as(c_ulong, value), @as(?*anyopaque, null));
            },
            f32 => {
                c.gst_structure_set(structure, name, c.G_TYPE_FLOAT, @as(f32, value), @as(?*anyopaque, null));
            },
            f64 => {
                c.gst_structure_set(structure, name, c.G_TYPE_DOUBLE, @as(f64, value), @as(?*anyopaque, null));
            },
            comptime_int => {
                c.gst_structure_set(structure, name, c.G_TYPE_INT, @as(c_int, value), @as(?*anyopaque, null));
            },
            comptime_float => {
                c.gst_structure_set(structure, name, c.G_TYPE_DOUBLE, @as(f64, value), @as(?*anyopaque, null));
            },
            []const u8, [*:0]const u8 => {
                c.gst_structure_set(structure, name, c.G_TYPE_STRING, value, @as(?*anyopaque, null));
            },
            bool => {
                c.gst_structure_set(structure, name, c.G_TYPE_BOOLEAN, @as(c_int, if (value) 1 else 0), @as(?*anyopaque, null));
            },
            Fraction => {
                c.gst_structure_set(structure, name, c.gst_fraction_get_type(), value.numerator, value.denominator, @as(?*anyopaque, null));
            },
            else => {
                // Check if it's an optional type
                if (@typeInfo(T) == .optional) {
                    if (value) |v| {
                        // Convert the unwrapped value to a consistent type for GStreamer
                        const VType = @TypeOf(v);
                        if (@typeInfo(VType) == .int) {
                            // Convert all integers to i32 for consistency
                            return self.field(name, @as(i32, @intCast(v)));
                        } else {
                            return self.field(name, v);
                        }
                    } else {
                        // Skip setting field if value is null
                        return self;
                    }
                }

                // Check if it's a comptime string
                if (@typeInfo(T) == .pointer) {
                    const ptr_info = @typeInfo(T).pointer;
                    if (ptr_info.size == .one and @typeInfo(ptr_info.child) == .array) {
                        const array_info = @typeInfo(ptr_info.child).array;
                        if (array_info.child == u8) {
                            c.gst_structure_set(structure, name, c.G_TYPE_STRING, @as([*:0]const u8, value), @as(?*anyopaque, null));
                            return self;
                        }
                    }
                }
                @compileError("Unsupported field type: " ++ @typeName(T));
            },
        }
        return self;
    }

    pub fn build(self: CapsBuilder) Caps {
        return self.caps;
    }
};
