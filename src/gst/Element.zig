const std = @import("std");
const core = @import("core.zig");
const caps = @import("Caps.zig");
const pad = @import("Pad.zig");
const Event = @import("Event.zig").Event;

pub const c = core.c;
pub const GstElement = core.GstElement;
pub const GstPipeline = core.GstPipeline;
pub const State = core.State;
pub const StateChangeReturn = core.StateChangeReturn;
pub const Format = @import("Format.zig").Format;
pub const Caps = caps.Caps;
pub const Pad = pad.Pad;

pub const Element = struct {
    ptr: GstElement,

    pub fn init(factory_name: [*:0]const u8, name: ?[*:0]const u8) !Element {
        const ptr = c.gst_element_factory_make(factory_name, name);
        if (ptr == null) {
            return error.ElementCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    pub fn deinit(self: Element) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn link(self: Element, dest: Element) !void {
        if (c.gst_element_link(self.ptr, dest.ptr) == 0) {
            return error.LinkFailed;
        }
    }

    pub fn linkFiltered(self: Element, dest: Element, ca: Caps) !void {
        if (c.gst_element_link_filtered(self.ptr, dest.ptr, ca.ptr) == 0) {
            return error.LinkFilteredFailed;
        }
    }

    pub fn linkToMany(self: Element, elements: []const Element) !void {
        if (elements.len == 0) return;

        // Link self to first element
        try self.link(elements[0]);

        // Link remaining elements in sequence
        for (elements[0 .. elements.len - 1], elements[1..]) |current, next| {
            try current.link(next);
        }
    }

    pub fn linkMany(elements: []const Element) !void {
        if (elements.len < 2) return;

        for (elements[0 .. elements.len - 1], elements[1..]) |current, next| {
            try current.link(next);
        }
    }

    pub fn setState(self: Element, state: State) StateChangeReturn {
        const result = c.gst_element_set_state(self.ptr, @intCast(@intFromEnum(state)));
        return @enumFromInt(result);
    }

    pub const GetStateResult = struct { state: State, pending: State, return_val: StateChangeReturn };

    pub fn getState(self: Element, timeout: u64) !GetStateResult {
        var state: c_uint = undefined;
        var pending: c_uint = undefined;

        const result = c.gst_element_get_state(self.ptr, &state, &pending, timeout);

        return .{
            .state = @enumFromInt(state),
            .pending = @enumFromInt(pending),
            .return_val = @enumFromInt(result),
        };
    }

    pub fn queryPosition(self: Element, format: Format) ?i64 {
        var value: i64 = undefined;
        if (c.gst_element_query_position(self.ptr, @intFromEnum(format), &value) == 0) {
            return null;
        }
        return value;
    }

    pub fn queryDuration(self: Element, format: Format) ?i64 {
        var value: i64 = undefined;
        if (c.gst_element_query_duration(self.ptr, @intFromEnum(format), &value) == 0) {
            return null;
        }
        return value;
    }

    /// Sets multiple properties from a struct literal. Field names are passed
    /// to GObject as-is; GObject treats `-` and `_` as equivalent in property
    /// names, so `.is_live = true` targets the `is-live` property.
    ///
    /// Example:
    /// ```zig
    /// src.set(.{ .pattern = 18, .is_live = true, .num_buffers = 100 });
    /// ```
    ///
    /// For runtime-determined property names or names that collide with Zig
    /// keywords, use `setProperty` directly.
    pub fn set(self: Element, props: anytype) void {
        const info = @typeInfo(@TypeOf(props));
        if (info != .@"struct") @compileError("Element.set expects a struct literal");
        inline for (info.@"struct".fields) |field| {
            self.setProperty(field.name.ptr, @field(props, field.name));
        }
    }

    pub fn setProperty(self: Element, property_name: [*:0]const u8, value: anytype) void {
        const ValueType = @TypeOf(value);
        switch (ValueType) {
            [*:0]const u8 => {
                c.gst_util_set_object_arg(@ptrCast(self.ptr), property_name, value);
            },
            i32, c_int => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, value), @as(?*anyopaque, null));
            },
            i64, c_long, isize => {
                // Always pass 64 bits: G_TYPE_INT64 properties read a gint64
                // vararg, and c_long is only 32-bit on some platforms.
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(i64, value), @as(?*anyopaque, null));
            },
            i8, i16 => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, value), @as(?*anyopaque, null));
            },
            u8, u16, u32, c_uint => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_uint, value), @as(?*anyopaque, null));
            },
            u64, c_ulong, usize => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(u64, value), @as(?*anyopaque, null));
            },
            f64 => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(f64, value), @as(?*anyopaque, null));
            },
            comptime_int => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, value), @as(?*anyopaque, null));
            },
            comptime_float => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(f64, value), @as(?*anyopaque, null));
            },
            bool => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, if (value) 1 else 0), @as(?*anyopaque, null));
            },
            else => {
                switch (@typeInfo(ValueType)) {
                    .@"enum" => {
                        c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, @intFromEnum(value)), @as(?*anyopaque, null));
                    },
                    .pointer => |ptr| {
                        if (ptr.child == u8 or (ptr.size == .one and @typeInfo(ptr.child) == .array and @typeInfo(ptr.child).array.child == u8)) {
                            _ = c.gst_util_set_object_arg(@ptrCast(self.ptr), property_name, @as([*:0]const u8, @ptrCast(value)));
                        } else {
                            @compileError("Unsupported property type");
                        }
                    },
                    else => @compileError("Unsupported property type"),
                }
            },
        }
    }

    /// Borrowed name, as `GST_OBJECT_NAME`. No allocation, valid while the
    /// element is alive.
    ///
    /// Not thread-safe: this reads the name without taking the object lock, so
    /// it is only sound while you know nothing is renaming the element. If in
    /// doubt use `getNameAlloc`, which is what upstream advises.
    pub inline fn getName(self: Element) ?[:0]const u8 {
        const obj: *c.GstObject = @ptrCast(self.ptr);
        if (obj.name == null) return null;
        return std.mem.span(obj.name);
    }

    /// Owned copy of the element's name, as `gst_object_get_name`: takes the
    /// object lock, so this is safe against concurrent renames. Caller frees
    /// with `allocator.free()`.
    pub fn getNameAlloc(self: Element, allocator: std.mem.Allocator) !?[]u8 {
        const name = c.gst_element_get_name(self.ptr);
        if (name == null) return null;
        defer c.g_free(name);
        return try allocator.dupe(u8, std.mem.span(name));
    }

    pub fn makeFromUri(uri_type: UriType, uri: [*:0]const u8, elementname: ?[*:0]const u8) !Element {
        var err: ?*c.GError = null;
        const ptr = c.gst_element_make_from_uri(@intFromEnum(uri_type), uri, elementname, &err);
        if (ptr == null) {
            if (err) |e| {
                std.log.err("Failed to create element from URI: {s}", .{e.message});
            }
            return error.ElementCreationFailed;
        }
        return .{ .ptr = ptr };
    }

    /// Connects to a signal on the element.
    ///
    /// Supported callback signatures:
    ///   - `fn (Element) void`
    ///   - `fn (Element, Pad) void` (e.g. "pad-added")
    ///   - `fn (Element, Pad, ?*anyopaque) void` — third argument is `user_data`
    ///
    /// `user_data` must be a pointer (or null) that outlives the connection;
    /// it is stored by GLib and handed back to the callback.
    pub fn connect(self: Element, signal_name: [*:0]const u8, comptime callback_fn: anytype, user_data: anytype) u64 {
        const callback_info = @typeInfo(@TypeOf(callback_fn));
        if (callback_info != .@"fn") {
            @compileError("callback_fn must be a function");
        }

        const params = callback_info.@"fn".params;
        comptime {
            if (params.len < 1 or params.len > 3)
                @compileError("callback must take (Element), (Element, Pad) or (Element, Pad, ?*anyopaque)");
            if ((params[0].type orelse void) != Element)
                @compileError("first callback parameter must be gst.Element");
            if (params.len >= 2 and (params[1].type orelse void) != Pad)
                @compileError("second callback parameter must be gst.Pad");
        }

        const wrapper = struct {
            fn c_wrapper(arg1: ?*anyopaque, arg2: ?*anyopaque, arg3: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
                const elem_ptr = arg1 orelse @panic("Signal callback received null instance - GStreamer contract violation");
                const element = Element{ .ptr = @ptrCast(@alignCast(elem_ptr)) };

                if (params.len == 1) {
                    callback_fn(element);
                    return;
                }

                const pad_ptr = arg2 orelse @panic("Signal callback received null pad - GStreamer contract violation");
                const new_pad = Pad{ .ptr = @ptrCast(@alignCast(pad_ptr)) };

                if (params.len == 2) {
                    callback_fn(element, new_pad);
                } else {
                    callback_fn(element, new_pad, arg3);
                }
            }
        }.c_wrapper;

        const converted_user_data: ?*anyopaque = switch (@typeInfo(@TypeOf(user_data))) {
            .pointer => @ptrCast(@constCast(user_data)),
            .null => null,
            .optional => |opt| if (@typeInfo(opt.child) == .pointer)
                (if (user_data) |p| @ptrCast(@constCast(p)) else null)
            else
                @compileError("user_data must be a pointer or null"),
            else => @compileError("user_data must be a pointer or null; it is stored for the lifetime of the connection, so a temporary value would dangle"),
        };

        const id = c.g_signal_connect_data(@as(?*c.GObject, @ptrCast(self.ptr)), signal_name, @as(c.GCallback, @ptrCast(&wrapper)), converted_user_data, null, 0);
        return @intCast(id);
    }

    pub fn connectSwapped(self: Element, signal_name: [*:0]const u8, callback: *const fn () callconv(.c) void, user_data: ?*anyopaque) !u64 {
        const id = c.g_signal_connect_data(@ptrCast(self.ptr), signal_name, @ptrCast(callback), user_data, null, c.G_CONNECT_SWAPPED);
        if (id == 0) {
            return error.SignalConnectionFailed;
        }
        return @intCast(id);
    }

    pub fn disconnect(self: Element, handler_id: c_ulong) void {
        c.g_signal_handler_disconnect(@ptrCast(self.ptr), handler_id);
    }

    pub fn getStaticPad(self: Element, name: [*:0]const u8) ?Pad {
        const currentPad = c.gst_element_get_static_pad(@ptrCast(self.ptr), name);
        if (currentPad) |p| {
            return Pad{ .ptr = p };
        }
        return null;
    }

    /// Requests a pad from a request pad template (e.g. "sink_%u" on a muxer).
    /// The caller owns the returned pad: release it with
    /// `gst_element_release_request_pad()` and then `Pad.deinit()`.
    pub fn requestPadSimple(self: Element, name: [*:0]const u8) !Pad {
        const currentPad = c.gst_element_request_pad_simple(@ptrCast(self.ptr), name);
        if (currentPad == null) {
            return error.PadRequestFailed;
        }
        return Pad{ .ptr = currentPad };
    }

    /// Sends an event to the element.
    ///
    /// Example:
    /// ```zig
    /// var event = try Event.initEos();
    /// defer event.deinit(); // Safe - will warn if called after sendEvent
    /// try element.sendEvent(&event);
    /// // event.ptr is now null, deinit() will warn but not crash
    /// ```
    pub fn sendEvent(self: Element, event: *Event) !void {
        const event_ptr = event.ptr orelse return error.SendEventFailed;
        event.ptr = null; // Consume the event by nulling the pointer
        if (c.gst_element_send_event(self.ptr, event_ptr) == 0) {
            // Note: GStreamer still took ownership even on failure
            return error.SendEventFailed;
        }
    }

    /// Synchronizes the element's state with its parent container.
    /// This is typically called after adding an element to a bin/pipeline
    /// that is already in a non-NULL state.
    ///
    /// Returns an error if the sync failed or a state change is already pending.
    pub fn syncStateWithParent(self: Element) !void {
        if (c.gst_element_sync_state_with_parent(self.ptr) == 0) {
            return error.StateSyncFailed;
        }
    }
};

pub const UriType = enum(c_uint) {
    unknown = 0,
    sink = 1,
    src = 2,
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
