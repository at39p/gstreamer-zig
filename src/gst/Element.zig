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

    pub fn setProperty(self: Element, property_name: [*:0]const u8, value: anytype) void {
        const ValueType = @TypeOf(value);
        switch (ValueType) {
            [*:0]const u8 => {
                c.gst_util_set_object_arg(@ptrCast(self.ptr), property_name, value);
            },
            i32, c_int => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, value), @as(?*anyopaque, null));
            },
            i64, c_long => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_long, value), @as(?*anyopaque, null));
            },
            i8, i16 => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_int, value), @as(?*anyopaque, null));
            },
            isize => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_long, value), @as(?*anyopaque, null));
            },
            u8, u16, u32, c_uint => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_uint, value), @as(?*anyopaque, null));
            },
            u64, c_ulong, usize => {
                c.g_object_set(@ptrCast(self.ptr), property_name, @as(c_ulong, value), @as(?*anyopaque, null));
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

    pub inline fn getName(self: Element) ?[*:0]const u8 {
        return c.gst_element_get_name(self.ptr);
    }

    pub fn factory(factory_name: [*:0]const u8) ElementFactory {
        return ElementFactory.init(factory_name);
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

    /// Connects element to signals.
    pub fn connect(self: Element, signal_name: [*:0]const u8, comptime callback_fn: anytype, user_data: anytype) u64 {
        const CallbackType = @TypeOf(callback_fn);
        const callback_info = @typeInfo(CallbackType);

        if (callback_info != .@"fn") {
            @compileError("callback_fn must be a function");
        }

        const params = callback_info.@"fn".params;

        const wrapper = struct {
            fn c_wrapper(arg1: ?*anyopaque, arg2: ?*anyopaque, arg3: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
                if (params.len == 0) @panic("Callback must have at least one parameter");

                const param1_type = params[0].type orelse @panic("First parameter type unknown");
                if (param1_type != Element) @panic("First parameter must be Element");

                const elem_ptr = arg1 orelse @panic("Missing element argument");
                const element = Element{ .ptr = @ptrCast(@alignCast(elem_ptr)) };

                if (params.len == 1) {
                    callback_fn(element);
                    return;
                }

                if (params.len < 2) @panic("Unexpected parameter count");
                const param2_type = params[1].type orelse @panic("Second parameter type unknown");
                if (param2_type != Pad) @panic("Second parameter must be Pad");

                const pad_ptr = arg2 orelse @panic("Missing pad argument");
                const new_pad = Pad{ .ptr = @ptrCast(@alignCast(pad_ptr)) };

                if (params.len == 2) {
                    callback_fn(element, new_pad);
                    return;
                }

                if (params.len == 3) {
                    callback_fn(element, new_pad, arg3);
                    return;
                }

                @panic("Unsupported callback signature for signal");
            }
        }.c_wrapper;

        const converted_user_data: ?*anyopaque = switch (@typeInfo(@TypeOf(user_data))) {
            .pointer => @ptrCast(user_data),
            .null => null,
            .optional => |opt| if (user_data == null) null else switch (@typeInfo(opt.child)) {
                .pointer => @ptrCast(user_data),
                else => @ptrCast(&user_data),
            },
            else => @ptrCast(@constCast(&user_data)),
        };

        const id = c.g_signal_connect_data(@as(?*c.GObject, @ptrCast(self.ptr)), signal_name, @as(c.GCallback, @ptrCast(&wrapper)), converted_user_data, null, 0);
        return @intCast(id);
    }

    test "connect" {}

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

    pub fn requestPadSimple(self: Element, name: [*:0]const u8) !Pad {
        const currentPad = c.gst_element_request_pad_simple(@ptrCast(self.ptr), name);
        if (currentPad == null) {
            return error.PadRequestFailed;
        }
        return currentPad;
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

const ElementFactory = struct {
    factory_name: [*:0]const u8,
    element_name: ?[*:0]const u8,
    properties: std.array_list.Managed(Property),
    allocator: std.mem.Allocator,

    const Property = struct {
        name: [*:0]const u8,
        value: PropertyValue,
    };

    const PropertyValue = union(enum) {
        string: [*:0]const u8,
        int: c_int,
        long: c_long,
        uint: c_uint,
        ulong: c_ulong,
        float: f32,
        double: f64,
        boolean: bool,
        enum_val: c_int,
    };

    fn init(factory_name: [*:0]const u8) ElementFactory {
        return .{
            .factory_name = factory_name,
            .element_name = factory_name, // If no name was provided, just use factory_name
            .properties = std.array_list.Managed(Property).init(std.heap.page_allocator),
            .allocator = std.heap.page_allocator,
        };
    }

    pub fn make(factory_name: [*:0]const u8) ElementFactory {
        return ElementFactory.init(factory_name);
    }

    pub fn name(self: ElementFactory, element_name: [*:0]const u8) ElementFactory {
        var result = self;
        result.element_name = element_name;
        return result;
    }

    pub fn property(self: ElementFactory, property_name: [*:0]const u8, value: anytype) ElementFactory {
        var result = self;

        const ValueType = @TypeOf(value);
        const prop_value = switch (ValueType) {
            []const u8, [*:0]const u8 => PropertyValue{ .string = @as([*:0]const u8, @ptrCast(value)) },
            i32, c_int => PropertyValue{ .int = @as(c_int, value) },
            i64, c_long => PropertyValue{ .long = @as(c_long, value) },
            u32, c_uint => PropertyValue{ .uint = @as(c_uint, value) },
            u64 => PropertyValue{ .ulong = @as(c_ulong, value) },
            f32 => PropertyValue{ .float = @as(f32, value) },
            f64 => PropertyValue{ .double = @as(f64, value) },
            comptime_int => PropertyValue{ .int = @as(c_int, value) },
            comptime_float => PropertyValue{ .double = @as(f64, value) },
            bool => PropertyValue{ .boolean = value },
            else => switch (@typeInfo(ValueType)) {
                .@"enum" => PropertyValue{ .enum_val = @as(c_int, @intFromEnum(value)) },
                .pointer => |ptr| blk: {
                    if (ptr.child == u8 or (ptr.size == .one and @typeInfo(ptr.child) == .array and @typeInfo(ptr.child).array.child == u8)) {
                        break :blk PropertyValue{ .string = @as([*:0]const u8, @ptrCast(value)) };
                    } else {
                        @compileError("Unsupported property type");
                    }
                },
                else => @compileError("Unsupported property type"),
            },
        };

        result.properties.append(.{
            .name = property_name,
            .value = prop_value,
        }) catch @panic("Failed to add property");

        return result;
    }

    pub fn build(self: ElementFactory) !Element {
        const ptr = c.gst_element_factory_make(self.factory_name, self.element_name);
        if (ptr == null) {
            self.properties.deinit();
            return error.ElementCreationFailed;
        }

        const element = Element{ .ptr = ptr };

        // Apply all properties
        for (self.properties.items) |prop| {
            switch (prop.value) {
                .string => |val| c.gst_util_set_object_arg(@ptrCast(element.ptr), prop.name, val),
                .int => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .long => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .uint => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .ulong => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .float => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .double => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
                .boolean => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, @as(c_int, if (val) 1 else 0), @as(?*anyopaque, null)),
                .enum_val => |val| c.g_object_set(@ptrCast(element.ptr), prop.name, val, @as(?*anyopaque, null)),
            }
        }

        self.properties.deinit();
        return element;
    }

    pub fn deinit(self: ElementFactory) void {
        self.properties.deinit();
    }
};
