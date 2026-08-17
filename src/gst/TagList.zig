const std = @import("std");
const c = @import("../c.zig").c;
const Tag = @import("Tag.zig").Tag;
const DateTime = @import("DateTime.zig").DateTime;

pub const TagList = struct {
    ptr: *c.GstTagList,
    owned: bool = false,

    pub fn deinit(self: TagList) void {
        if (self.owned) {
            c.gst_tag_list_unref(@constCast(self.ptr));
        }
    }

    pub fn nTags(self: TagList) u32 {
        const n = c.gst_tag_list_n_tags(self.ptr);
        return @intCast(n);
    }

    pub fn isEmpty(self: TagList) bool {
        return c.gst_tag_list_is_empty(self.ptr) != 0;
    }

    pub fn nthTagName(self: TagList, index: usize) ?[*:0]const u8 {
        return c.gst_tag_list_nth_tag_name(self.ptr, @intCast(index));
    }

    pub fn getTagSize(self: TagList, tag: [*:0]const u8) u32 {
        return @intCast(c.gst_tag_list_get_tag_size(self.ptr, tag));
    }

    /// Returns a Zig-allocated string representation of the entire tag list.
    /// Caller must free with allocator.free().
    pub fn toStringAlloc(self: TagList, allocator: std.mem.Allocator) ![]const u8 {
        const str = c.gst_tag_list_to_string(self.ptr) orelse return error.TagListStringFailed;
        defer c.g_free(str);
        return allocator.dupe(u8, std.mem.span(str));
    }

    /// Type-safe tag access. The tag's ValueType determines the return type.
    /// Strings and numeric values are borrowed from the tag list (valid for its lifetime).
    /// DateTime is returned as an owned reference — caller must call deinit().
    /// Usage:
    ///   if (tags.get(.title)) |title| { ... }       // ?[]const u8
    ///   if (tags.get(.bitrate)) |br| { ... }         // ?u32
    ///   if (tags.get(.date_time)) |dt| { defer dt.deinit(); ... }
    pub fn get(self: TagList, comptime tag: Tag) ?tag.ValueType {
        switch (tag.ValueType) {
            []const u8 => {
                var value: [*:0]const u8 = undefined;
                if (c.gst_tag_list_peek_string_index(self.ptr, tag.name, 0, @ptrCast(&value)) == 0) return null;
                return std.mem.span(value);
            },
            DateTime => {
                var dt: ?*c.GstDateTime = null;
                if (c.gst_tag_list_get_date_time(self.ptr, tag.name, &dt) == 0) return null;
                return .{ .ptr = dt orelse return null };
            },
            u32 => {
                var value: c.guint = 0;
                if (c.gst_tag_list_get_uint(self.ptr, tag.name, &value) == 0) return null;
                return @intCast(value);
            },
            u64 => {
                var value: c.guint64 = 0;
                if (c.gst_tag_list_get_uint64(self.ptr, tag.name, &value) == 0) return null;
                return @intCast(value);
            },
            f64 => {
                var value: c.gdouble = 0;
                if (c.gst_tag_list_get_double(self.ptr, tag.name, &value) == 0) return null;
                return @floatCast(value);
            },
            else => @compileError("unsupported tag type: " ++ @typeName(tag.ValueType)),
        }
    }

    /// Returns any tag's value as a serialized string, regardless of its underlying type.
    /// Useful for display/debugging. Caller must free with allocator.free().
    pub fn getValueString(self: TagList, allocator: std.mem.Allocator, tag: [*:0]const u8) !?[]const u8 {
        const gvalue = c.gst_tag_list_get_value_index(self.ptr, tag, 0) orelse return null;
        const str = c.gst_value_serialize(gvalue) orelse return null;
        defer c.g_free(str);
        return try allocator.dupe(u8, std.mem.span(str));
    }
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
