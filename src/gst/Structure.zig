const std = @import("std");
const core = @import("core.zig");
const caps = @import("Caps.zig");

pub const c = core.c;
pub const GstStructure = core.GstStructure;
pub const Fraction = caps.Fraction;

pub const Structure = struct {
    ptr: *GstStructure,

    // Constructor functions
    pub fn init(name: [*:0]const u8) !Structure {
        const ptr = c.gst_structure_new_empty(name);
        if (ptr == null) {
            return error.StructureCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn initFromString(str: [*:0]const u8) !Structure {
        const ptr = c.gst_structure_new_from_string(str);
        if (ptr == null) {
            return error.InvalidStructureString;
        }
        return .{ .ptr = ptr };
    }

    pub fn copy(self: Structure) !Structure {
        const ptr = c.gst_structure_copy(self.ptr);
        if (ptr == null) {
            return error.StructureCopyFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: Structure) void {
        c.gst_structure_free(self.ptr);
    }

    // Name and metadata functions
    pub fn getName(self: Structure) [*:0]const u8 {
        return c.gst_structure_get_name(self.ptr);
    }

    pub fn hasName(self: Structure, name: [*:0]const u8) bool {
        return c.gst_structure_has_name(self.ptr, name) != 0;
    }

    pub fn setName(self: Structure, name: [*:0]const u8) void {
        c.gst_structure_set_name(self.ptr, name);
    }

    // Field access and manipulation
    pub fn hasField(self: Structure, fieldname: [*:0]const u8) bool {
        return c.gst_structure_has_field(self.ptr, fieldname) != 0;
    }

    pub fn hasFieldTyped(self: Structure, fieldname: [*:0]const u8, field_type: c.GType) bool {
        return c.gst_structure_has_field_typed(self.ptr, fieldname, field_type) != 0;
    }

    pub fn getFieldType(self: Structure, fieldname: [*:0]const u8) c.GType {
        return c.gst_structure_get_field_type(self.ptr, fieldname);
    }

    pub fn getValue(self: Structure, fieldname: [*:0]const u8) ?*const c.GValue {
        return c.gst_structure_get_value(self.ptr, fieldname);
    }

    pub fn setValue(self: Structure, fieldname: [*:0]const u8, value: *const c.GValue) void {
        c.gst_structure_set_value(self.ptr, fieldname, value);
    }

    pub fn removeField(self: Structure, fieldname: [*:0]const u8) void {
        c.gst_structure_remove_field(self.ptr, fieldname);
    }

    pub fn removeAllFields(self: Structure) void {
        c.gst_structure_remove_all_fields(self.ptr);
    }

    // Typed getter functions
    pub fn getBoolean(self: Structure, fieldname: [*:0]const u8) ?bool {
        var value: c.gboolean = undefined;
        if (c.gst_structure_get_boolean(self.ptr, fieldname, &value) != 0) {
            return value != 0;
        }
        return null;
    }

    pub fn getInt(self: Structure, fieldname: [*:0]const u8) ?i32 {
        var value: c.gint = undefined;
        if (c.gst_structure_get_int(self.ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getUint(self: Structure, fieldname: [*:0]const u8) ?u32 {
        var value: c.guint = undefined;
        if (c.gst_structure_get_uint(self.ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getInt64(self: Structure, fieldname: [*:0]const u8) ?i64 {
        var value: c.gint64 = undefined;
        if (c.gst_structure_get_int64(self.ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getUint64(self: Structure, fieldname: [*:0]const u8) ?u64 {
        var value: c.guint64 = undefined;
        if (c.gst_structure_get_uint64(self.ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getDouble(self: Structure, fieldname: [*:0]const u8) ?f64 {
        var value: c.gdouble = undefined;
        if (c.gst_structure_get_double(self.ptr, fieldname, &value) != 0) {
            return value;
        }
        return null;
    }

    pub fn getString(self: Structure, fieldname: [*:0]const u8) ?[*:0]const u8 {
        const result = c.gst_structure_get_string(self.ptr, fieldname);
        if (result != null) {
            return result;
        }
        return null;
    }

    pub fn getFraction(self: Structure, fieldname: [*:0]const u8) ?Fraction {
        var num: c.gint = undefined;
        var den: c.gint = undefined;
        if (c.gst_structure_get_fraction(self.ptr, fieldname, &num, &den) != 0) {
            return Fraction{ .numerator = num, .denominator = den };
        }
        return null;
    }

    pub fn getEnum(self: Structure, fieldname: [*:0]const u8, enum_type: c.GType) ?i32 {
        var value: c.gint = undefined;
        if (c.gst_structure_get_enum(self.ptr, fieldname, enum_type, &value) != 0) {
            return value;
        }
        return null;
    }

    // Typed setter functions (using GstStructure's set with varargs)
    pub fn setBoolean(self: Structure, fieldname: [*:0]const u8, value: bool) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_BOOLEAN, @as(c.gboolean, if (value) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setInt(self: Structure, fieldname: [*:0]const u8, value: i32) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_INT, @as(c.gint, value), @as(?*anyopaque, null));
    }

    pub fn setUint(self: Structure, fieldname: [*:0]const u8, value: u32) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_UINT, @as(c.guint, value), @as(?*anyopaque, null));
    }

    pub fn setInt64(self: Structure, fieldname: [*:0]const u8, value: i64) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_INT64, @as(c.gint64, value), @as(?*anyopaque, null));
    }

    pub fn setUint64(self: Structure, fieldname: [*:0]const u8, value: u64) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_UINT64, @as(c.guint64, value), @as(?*anyopaque, null));
    }

    pub fn setDouble(self: Structure, fieldname: [*:0]const u8, value: f64) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_DOUBLE, @as(c.gdouble, value), @as(?*anyopaque, null));
    }

    pub fn setString(self: Structure, fieldname: [*:0]const u8, value: [*:0]const u8) void {
        c.gst_structure_set(self.ptr, fieldname, c.G_TYPE_STRING, value, @as(?*anyopaque, null));
    }

    pub fn setFraction(self: Structure, fieldname: [*:0]const u8, fraction: Fraction) void {
        c.gst_structure_set(self.ptr, fieldname, c.gst_fraction_get_type(), fraction.numerator, fraction.denominator, @as(?*anyopaque, null));
    }

    // Utility functions
    pub fn toString(self: Structure) [*:0]u8 {
        return c.gst_structure_to_string(self.ptr);
    }

    pub fn nFields(self: Structure) u32 {
        return @intCast(c.gst_structure_n_fields(self.ptr));
    }

    pub fn nthFieldName(self: Structure, index: u32) ?[*:0]const u8 {
        const result = c.gst_structure_nth_field_name(self.ptr, index);
        if (result != null) {
            return result;
        }
        return null;
    }

    pub fn isEqual(self: Structure, other: Structure) bool {
        return c.gst_structure_is_equal(self.ptr, other.ptr) != 0;
    }

    pub fn canIntersect(self: Structure, other: Structure) bool {
        return c.gst_structure_can_intersect(self.ptr, other.ptr) != 0;
    }

    pub fn intersect(self: Structure, other: Structure) ?Structure {
        const ptr = c.gst_structure_intersect(self.ptr, other.ptr);
        if (ptr != null) {
            return Structure{ .ptr = ptr };
        }
        return null;
    }
};
