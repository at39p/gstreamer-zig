const std = @import("std");
const core = @import("core.zig");

const c = core.c;
const GstStructure = core.GstStructure;
const Fraction = @import("Fraction.zig").Fraction;

pub const Structure = struct {
    ptr: ?GstStructure,
    owned: bool,

    // Constructor functions
    pub fn init(name: [*:0]const u8) !Structure {
        const ptr = c.gst_structure_new_empty(name);
        if (ptr == null) {
            return error.StructureCreationFailed;
        }
        return .{ .ptr = ptr, .owned = true };
    }

    pub fn initFromString(str: [*:0]const u8) !Structure {
        const ptr = c.gst_structure_new_from_string(str);
        if (ptr == null) {
            return error.InvalidStructureString;
        }
        return .{ .ptr = ptr, .owned = true };
    }

    pub fn copy(self: Structure) !Structure {
        const self_ptr = self.ptr orelse @panic("Structure.copy() called on consumed Structure - cannot copy structure after ownership was transferred");
        const ptr = c.gst_structure_copy(self_ptr);
        if (ptr == null) {
            return error.StructureCopyFailed;
        }
        return .{ .ptr = ptr, .owned = true };
    }

    /// Frees structure if owned. No-op if borrowed. Safe to use with defer.
    pub fn deinit(self: Structure) void {
        if (self.ptr) |p| {
            if (self.owned) {
                c.gst_structure_free(p);
            }
        } else {
            std.log.warn("Structure.deinit() called on already-consumed Structure (this is safe but unnecessary - GStreamer already freed it)", .{});
        }
    }

    // Name and metadata functions
    pub fn getName(self: Structure) ?[]const u8 {
        const ptr = self.ptr orelse @panic("Structure.getName() called on consumed Structure - cannot use structure after ownership was transferred");
        const name = c.gst_structure_get_name(ptr);
        if (name == null) return null;
        return std.mem.span(name);
    }

    pub fn hasName(self: Structure, name: [*:0]const u8) bool {
        const ptr = self.ptr orelse @panic("Structure.hasName() called on consumed Structure - cannot use structure after ownership was transferred");
        return c.gst_structure_has_name(ptr, name) != 0;
    }

    pub fn setName(self: Structure, name: [*:0]const u8) void {
        const ptr = self.ptr orelse @panic("Structure.setName() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set_name(ptr, name);
    }

    // Field access and manipulation
    pub fn hasField(self: Structure, fieldname: [*:0]const u8) bool {
        const ptr = self.ptr orelse @panic("Structure.hasField() called on consumed Structure - cannot use structure after ownership was transferred");
        return c.gst_structure_has_field(ptr, fieldname) != 0;
    }

    pub fn hasFieldTyped(self: Structure, fieldname: [*:0]const u8, field_type: c.GType) bool {
        const ptr = self.ptr orelse @panic("Structure.hasFieldTyped() called on consumed Structure - cannot use structure after ownership was transferred");
        return c.gst_structure_has_field_typed(ptr, fieldname, field_type) != 0;
    }

    pub fn getFieldType(self: Structure, fieldname: [*:0]const u8) c.GType {
        const ptr = self.ptr orelse @panic("Structure.getFieldType() called on consumed Structure - cannot use structure after ownership was transferred");
        return c.gst_structure_get_field_type(ptr, fieldname);
    }

    pub fn getValue(self: Structure, fieldname: [*:0]const u8) ?*const c.GValue {
        const ptr = self.ptr orelse @panic("Structure.getValue() called on consumed Structure - cannot use structure after ownership was transferred");
        return c.gst_structure_get_value(ptr, fieldname);
    }

    pub fn setValue(self: Structure, fieldname: [*:0]const u8, value: *const c.GValue) void {
        const ptr = self.ptr orelse @panic("Structure.setValue() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set_value(ptr, fieldname, value);
    }

    pub fn removeField(self: Structure, fieldname: [*:0]const u8) void {
        const ptr = self.ptr orelse @panic("Structure.removeField() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_remove_field(ptr, fieldname);
    }

    pub fn removeAllFields(self: Structure) void {
        const ptr = self.ptr orelse @panic("Structure.removeAllFields() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_remove_all_fields(ptr);
    }

    // Typed getter functions
    pub fn getBoolean(self: Structure, fieldname: [*:0]const u8) ?bool {
        const ptr = self.ptr orelse @panic("Structure.getBoolean() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.gboolean = undefined;
        if (c.gst_structure_get_boolean(ptr, fieldname, &value) != 0) {
            return value != 0;
        }
        return null;
    }

    pub fn getInt(self: Structure, fieldname: [*:0]const u8) ?i32 {
        const ptr = self.ptr orelse @panic("Structure.getInt() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.gint = undefined;
        if (c.gst_structure_get_int(ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getUint(self: Structure, fieldname: [*:0]const u8) ?u32 {
        const ptr = self.ptr orelse @panic("Structure.getUint() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.guint = undefined;
        if (c.gst_structure_get_uint(ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getInt64(self: Structure, fieldname: [*:0]const u8) ?i64 {
        const ptr = self.ptr orelse @panic("Structure.getInt64() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.gint64 = undefined;
        if (c.gst_structure_get_int64(ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getUint64(self: Structure, fieldname: [*:0]const u8) ?u64 {
        const ptr = self.ptr orelse @panic("Structure.getUint64() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.guint64 = undefined;
        if (c.gst_structure_get_uint64(ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getDouble(self: Structure, fieldname: [*:0]const u8) ?f64 {
        const ptr = self.ptr orelse @panic("Structure.getDouble() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.gdouble = undefined;
        if (c.gst_structure_get_double(ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getString(self: Structure, fieldname: [*:0]const u8) ?[*:0]const u8 {
        const ptr = self.ptr orelse @panic("Structure.getString() called on consumed Structure - cannot use structure after ownership was transferred");
        const result = c.gst_structure_get_string(ptr, fieldname);
        if (result != null) {
            return result;
        }
        return null;
    }

    pub fn getFraction(self: Structure, fieldname: [*:0]const u8) ?Fraction {
        const ptr = self.ptr orelse @panic("Structure.getFraction() called on consumed Structure - cannot use structure after ownership was transferred");
        var num: c.gint = undefined;
        var den: c.gint = undefined;
        if (c.gst_structure_get_fraction(ptr, fieldname, &num, &den) != 0) {
            return Fraction{ .numerator = num, .denominator = den };
        }
        return null;
    }

    pub fn getEnum(self: Structure, fieldname: [*:0]const u8, enum_type: c.GType) ?i32 {
        const ptr = self.ptr orelse @panic("Structure.getEnum() called on consumed Structure - cannot use structure after ownership was transferred");
        var value: c.gint = undefined;
        if (c.gst_structure_get_enum(ptr, fieldname, enum_type, &value) != 0) {
            return value;
        }
        return null;
    }

    // Typed setter functions (using GstStructure's set with varargs)
    pub fn setBoolean(self: Structure, fieldname: [*:0]const u8, value: bool) void {
        const ptr = self.ptr orelse @panic("Structure.setBoolean() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_BOOLEAN, @as(c.gboolean, if (value) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setInt(self: Structure, fieldname: [*:0]const u8, value: i32) void {
        const ptr = self.ptr orelse @panic("Structure.setInt() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_INT, @as(c.gint, value), @as(?*anyopaque, null));
    }

    pub fn setUint(self: Structure, fieldname: [*:0]const u8, value: u32) void {
        const ptr = self.ptr orelse @panic("Structure.setUint() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_UINT, @as(c.guint, value), @as(?*anyopaque, null));
    }

    pub fn setInt64(self: Structure, fieldname: [*:0]const u8, value: i64) void {
        const ptr = self.ptr orelse @panic("Structure.setInt64() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_INT64, @as(c.gint64, value), @as(?*anyopaque, null));
    }

    pub fn setUint64(self: Structure, fieldname: [*:0]const u8, value: u64) void {
        const ptr = self.ptr orelse @panic("Structure.setUint64() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_UINT64, @as(c.guint64, value), @as(?*anyopaque, null));
    }

    pub fn setDouble(self: Structure, fieldname: [*:0]const u8, value: f64) void {
        const ptr = self.ptr orelse @panic("Structure.setDouble() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_DOUBLE, @as(c.gdouble, value), @as(?*anyopaque, null));
    }

    pub fn setString(self: Structure, fieldname: [*:0]const u8, value: [*:0]const u8) void {
        const ptr = self.ptr orelse @panic("Structure.setString() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.G_TYPE_STRING, value, @as(?*anyopaque, null));
    }

    pub fn setFraction(self: Structure, fieldname: [*:0]const u8, fraction: Fraction) void {
        const ptr = self.ptr orelse @panic("Structure.setFraction() called on consumed Structure - cannot use structure after ownership was transferred");
        c.gst_structure_set(ptr, fieldname, c.gst_fraction_get_type(), fraction.numerator, fraction.denominator, @as(?*anyopaque, null));
    }

    // Utility functions
    /// Returns a Zig-allocated copy of the structure string. Caller must free
    /// with allocator.free().
    ///
    /// `gst_structure_to_string` is transfer full and GStreamer offers no
    /// borrowed equivalent, so allocating is the only way to hand this back
    /// safely.
    pub fn toStringAlloc(self: Structure, allocator: std.mem.Allocator) ![]u8 {
        const ptr = self.ptr orelse @panic("Structure.toStringAlloc() called on consumed Structure - cannot use structure after ownership was transferred");
        const str = c.gst_structure_to_string(ptr);
        if (str == null) return error.StructureStringFailed;
        defer c.g_free(str);
        return try allocator.dupe(u8, std.mem.span(str));
    }

    pub fn nFields(self: Structure) u32 {
        const ptr = self.ptr orelse @panic("Structure.nFields() called on consumed Structure - cannot use structure after ownership was transferred");
        return @intCast(c.gst_structure_n_fields(ptr));
    }

    pub fn nthFieldName(self: Structure, index: u32) ?[*:0]const u8 {
        const ptr = self.ptr orelse @panic("Structure.nthFieldName() called on consumed Structure - cannot use structure after ownership was transferred");
        const result = c.gst_structure_nth_field_name(ptr, index);
        if (result != null) {
            return result;
        }
        return null;
    }

    pub fn isEqual(self: Structure, other: Structure) bool {
        const ptr = self.ptr orelse @panic("Structure.isEqual() called on consumed Structure - cannot use structure after ownership was transferred");
        const other_ptr = other.ptr orelse @panic("Structure.isEqual() called with consumed other Structure - cannot compare consumed structures");
        return c.gst_structure_is_equal(ptr, other_ptr) != 0;
    }

    pub fn canIntersect(self: Structure, other: Structure) bool {
        const ptr = self.ptr orelse @panic("Structure.canIntersect() called on consumed Structure - cannot use structure after ownership was transferred");
        const other_ptr = other.ptr orelse @panic("Structure.canIntersect() called with consumed other Structure - cannot compare consumed structures");
        return c.gst_structure_can_intersect(ptr, other_ptr) != 0;
    }

    pub fn intersect(self: Structure, other: Structure) ?Structure {
        const self_ptr = self.ptr orelse @panic("Structure.intersect() called on consumed Structure - cannot use structure after ownership was transferred");
        const other_ptr = other.ptr orelse @panic("Structure.intersect() called with consumed other Structure - cannot intersect consumed structures");
        const ptr = c.gst_structure_intersect(self_ptr, other_ptr);
        if (ptr != null) {
            return Structure{ .ptr = ptr, .owned = true };
        }
        return null;
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
