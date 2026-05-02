const std = @import("std");
const core = @import("core.zig");

pub const c = core.c;
pub const GstCaps = core.GstCaps;
pub const Fraction = @import("Fraction.zig").Fraction;
pub const Structure = @import("Structure.zig").Structure;

pub const Caps = struct {
    ptr: ?GstCaps,

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
        if (self.ptr) |p| {
            c.gst_caps_unref(p);
        } else {
            std.log.warn("Caps.deinit() called on already-consumed Caps (this is safe but unnecessary - GStreamer already freed it)", .{});
        }
    }

    pub fn copy(self: Caps) !Caps {
        const ptr = self.ptr orelse @panic("Caps.copy() called on consumed Caps - cannot copy caps that were already passed to a function taking ownership");
        const copied_ptr = c.gst_caps_copy(ptr);
        if (copied_ptr == null) {
            return error.CapsCopyFailed;
        }
        return .{ .ptr = copied_ptr };
    }

    pub fn toString(self: Caps) [*:0]const u8 {
        const ptr = self.ptr orelse @panic("Caps.toString() called on consumed Caps - cannot convert to string caps that were already passed to a function taking ownership");
        return c.gst_caps_to_string(ptr);
    }

    /// Returns a Zig-allocated copy of the caps string. Caller must free with allocator.free().
    pub fn toStringAlloc(self: Caps, allocator: std.mem.Allocator) ![]const u8 {
        const ptr = self.ptr orelse @panic("Caps.toStringAlloc() called on consumed Caps - cannot convert to string caps that were already passed to a function taking ownership");
        const glib_str = c.gst_caps_to_string(ptr);
        defer c.g_free(glib_str);
        return allocator.dupe(u8, std.mem.span(glib_str));
    }

    pub inline fn isFixed(self: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.isFixed() called on consumed Caps - cannot check if caps are fixed after being passed to a function taking ownership");
        return c.gst_caps_is_fixed(ptr) != 0;
    }

    pub inline fn isEqual(self: Caps, other: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.isEqual() called on consumed Caps - cannot compare caps that were already passed to a function taking ownership");
        const other_ptr = other.ptr orelse @panic("Caps.isEqual() called with consumed 'other' Caps - cannot compare caps that were already passed to a function taking ownership");
        return c.gst_caps_is_equal(ptr, other_ptr) != 0;
    }

    pub inline fn isSubset(self: Caps, superset: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.isSubset() called on consumed Caps - cannot check subset after being passed to a function taking ownership");
        const superset_ptr = superset.ptr orelse @panic("Caps.isSubset() called with consumed 'superset' Caps - cannot check subset after being passed to a function taking ownership");
        return c.gst_caps_is_subset(ptr, superset_ptr) != 0;
    }

    pub inline fn isAny(self: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.isAny() called on consumed Caps - cannot check if caps are 'any' after being passed to a function taking ownership");
        return c.gst_caps_is_any(ptr) != 0;
    }

    pub inline fn isEmpty(self: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.isEmpty() called on consumed Caps - cannot check if caps are empty after being passed to a function taking ownership");
        return c.gst_caps_is_empty(ptr) != 0;
    }

    pub inline fn canIntersect(self: Caps, other: Caps) bool {
        const ptr = self.ptr orelse @panic("Caps.canIntersect() called on consumed Caps - cannot check intersection after being passed to a function taking ownership");
        const other_ptr = other.ptr orelse @panic("Caps.canIntersect() called with consumed 'other' Caps - cannot check intersection after being passed to a function taking ownership");
        return c.gst_caps_can_intersect(ptr, other_ptr) != 0;
    }

    pub fn intersect(self: Caps, other: Caps) !Caps {
        const ptr = self.ptr orelse @panic("Caps.intersect() called on consumed Caps - cannot intersect caps that were already passed to a function taking ownership");
        const other_ptr = other.ptr orelse @panic("Caps.intersect() called with consumed 'other' Caps - cannot intersect caps that were already passed to a function taking ownership");
        const result_ptr = c.gst_caps_intersect(ptr, other_ptr);
        if (result_ptr == null) {
            return error.CapsIntersectFailed;
        }
        return .{ .ptr = result_ptr };
    }

    /// Merge another Caps into this one.
    pub fn merge(self: *Caps, other: *Caps) void {
        const self_ptr = self.ptr orelse @panic("Caps.merge() called on consumed Caps - cannot merge into caps that were already passed to a function taking ownership");
        const other_ptr = other.ptr orelse return;
        other.ptr = null; // Consume other by nulling the pointer
        self.ptr = c.gst_caps_merge(self_ptr, other_ptr);
    }

    /// Append another Caps to this one.
    pub fn append(self: *Caps, other: *Caps) void {
        const self_ptr = self.ptr orelse @panic("Caps.append() called on consumed Caps - cannot append to caps that were already passed to a function taking ownership");
        const other_ptr = other.ptr orelse return;
        other.ptr = null; // Consume other by nulling the pointer
        c.gst_caps_append(self_ptr, other_ptr);
    }

    pub inline fn getSize(self: Caps) u32 {
        const ptr = self.ptr orelse @panic("Caps.getSize() called on consumed Caps - cannot get size of caps that were already passed to a function taking ownership");
        return c.gst_caps_get_size(ptr);
    }

    /// Returns owned copy. Caller must deinit.
    pub inline fn getStructure(self: Caps, index: u32) !?Structure {
        const ptr = self.ptr orelse @panic("Caps.getStructure() called on consumed Caps - cannot get structure from caps that were already passed to a function taking ownership");
        const structure_ptr = c.gst_caps_get_structure(ptr, @intCast(index));
        if (structure_ptr == null) return null;

        // Copy the structure so caller owns it
        const copied_ptr = c.gst_structure_copy(structure_ptr);
        if (copied_ptr == null) return error.StructureCopyFailed;

        return Structure{ .ptr = copied_ptr, .owned = true };
    }

    /// Returns borrowed reference. Parent owns memory. Safe to deinit (no-op).
    pub inline fn getStructureRef(self: Caps, index: u32) ?Structure {
        const ptr = self.ptr orelse @panic("Caps.getStructureRef() called on consumed Caps - cannot get structure from caps that were already passed to a function taking ownership");
        const structure_ptr = c.gst_caps_get_structure(ptr, @intCast(index));
        if (structure_ptr == null) return null;
        return Structure{ .ptr = structure_ptr, .owned = false };
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
        const ptr = self.caps.ptr orelse @panic("CapsBuilder.field() called on consumed CapsBuilder - this should not happen");
        const structure = c.gst_caps_get_structure(ptr, 0);

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
            [*:0]const u8 => {
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
