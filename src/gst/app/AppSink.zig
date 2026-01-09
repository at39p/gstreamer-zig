const std = @import("std");
const core = @import("../core.zig");
const element = @import("../Element.zig");
const sample = @import("../Sample.zig");
const buffer = @import("../Buffer.zig");
const caps = @import("../Caps.zig");

pub const c = core.c;
pub const Sample = sample.Sample;
pub const Buffer = buffer.Buffer;
pub const Caps = caps.Caps;

pub const AppSink = struct {
    el: element.Element,

    pub fn init(name: ?[*:0]const u8) !AppSink {
        const el = try element.Element.init("appsink", name);
        return .{ .el = el };
    }

    pub fn deinit(self: AppSink) void {
        const parent = c.gst_element_get_parent(self.el.ptr);
        if (parent) |p| {
            const pipeline_type = c.gst_pipeline_get_type();
            const is_pipeline = c.g_type_check_instance_is_a(@ptrCast(p), pipeline_type) != 0;
            c.gst_object_unref(p);

            if (is_pipeline) {
                return;
            }
        }
        self.el.deinit();
    }

    pub inline fn asElement(self: AppSink) element.Element {
        return self.el;
    }

    pub const PullError = error{ Eos, Stopped };

    // Core operations
    pub fn pullSample(self: AppSink) PullError!Sample {
        var gstSample: ?core.GstSample = null;
        c.g_signal_emit_by_name(self.el.ptr, "pull-sample", &gstSample);

        if (Sample.fromPtr(gstSample)) |s| {
            return s;
        }

        if (self.isEos()) {
            return error.Eos;
        }

        return error.Stopped;
    }

    pub fn pullPreroll(self: AppSink) PullError!Sample {
        var gstSample: ?core.GstSample = null;
        c.g_signal_emit_by_name(self.el.ptr, "pull-preroll", &gstSample);

        if (Sample.fromPtr(gstSample)) |s| {
            return s;
        }

        if (self.isEos()) {
            return error.Eos;
        }

        return error.Stopped;
    }

    /// Returns null on timeout, error on EOS/stopped, Sample on success
    pub fn tryPullSample(self: AppSink, timeout: u64) PullError!?Sample {
        var gstSample: ?core.GstSample = null;
        c.g_signal_emit_by_name(self.el.ptr, "try-pull-sample", timeout, &gstSample);

        if (Sample.fromPtr(gstSample)) |s| {
            return s;
        }

        if (self.isEos()) {
            return error.Eos;
        }

        return null; // timeout
    }

    pub fn isEos(self: AppSink) bool {
        var is_eos: c_int = 0;
        c.g_object_get(self.el.ptr, "eos", &is_eos, @as(?*anyopaque, null));
        return is_eos != 0;
    }

    // Property setters
    pub fn setCaps(self: AppSink, capability: Caps) void {
        c.g_object_set(self.el.ptr, "caps", capability.ptr, @as(?*anyopaque, null));
    }

    pub fn setDrop(self: AppSink, drop: bool) void {
        const value: c_int = if (drop) 1 else 0;
        c.g_object_set(self.el.ptr, "drop", value, @as(?*anyopaque, null));
    }

    pub fn setMaxBuffers(self: AppSink, max_buffers: u32) void {
        c.g_object_set(self.el.ptr, "max-buffers", max_buffers, @as(?*anyopaque, null));
    }

    pub fn setSync(self: AppSink, sync: bool) void {
        const value: c_int = if (sync) 1 else 0;
        c.g_object_set(self.el.ptr, "sync", value, @as(?*anyopaque, null));
    }

    pub fn setEmitSignals(self: AppSink, emit: bool) void {
        const value: c_int = if (emit) 1 else 0;
        c.g_object_set(self.el.ptr, "emit-signals", value, @as(?*anyopaque, null));
    }

    pub fn setWaitOnEos(self: AppSink, wait: bool) void {
        const value: c_int = if (wait) 1 else 0;
        c.g_object_set(self.el.ptr, "wait-on-eos", value, @as(?*anyopaque, null));
    }

    /// Connect a callback for the "new-sample" signal.
    /// Callback signature: fn(appsink: *AppSink, userdata: T) FlowReturn
    pub fn connectNewSample(self: AppSink, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn newSampleCallback(appsink_ptr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
                const ptr = appsink_ptr orelse @panic("AppSink new-sample callback received null appsink_ptr - GLib signal contract violation");
                var appsink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(ptr)) } };
                const typed_data = convertUserData(UserDataT, data);
                const result = callback(&appsink, typed_data);
                return @intFromEnum(result);
            }
        }.newSampleCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "new-sample",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
    }

    /// Connect a callback for the "new-preroll" signal.
    /// Callback signature: fn(appsink: *AppSink, userdata: T) FlowReturn
    pub fn connectNewPreroll(self: AppSink, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn newPrerollCallback(appsink_ptr: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
                const ptr = appsink_ptr orelse @panic("AppSink new-preroll callback received null appsink_ptr - GLib signal contract violation");
                var appsink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(ptr)) } };
                const typed_data = convertUserData(UserDataT, data);
                const result = callback(&appsink, typed_data);
                return @intFromEnum(result);
            }
        }.newPrerollCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "new-preroll",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
    }

    /// Connect a callback for the "eos" signal.
    /// Callback signature: fn(appsink: *AppSink, userdata: T) void
    pub fn connectEos(self: AppSink, comptime callback: anytype, userdata: anytype) !u64 {
        const UserDataT = @TypeOf(userdata);
        const wrapper = struct {
            fn eosCallback(appsink_ptr: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
                const ptr = appsink_ptr orelse @panic("AppSink eos callback received null appsink_ptr - GLib signal contract violation");
                var appsink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(ptr)) } };
                const typed_data = convertUserData(UserDataT, data);
                callback(&appsink, typed_data);
            }
        }.eosCallback;

        const handler_id = c.g_signal_connect_data(
            self.el.ptr,
            "eos",
            @ptrCast(&wrapper),
            prepareUserData(userdata),
            null,
            0,
        );
        if (handler_id == 0) return error.SignalConnectionFailed;
        return @intCast(handler_id);
    }

    pub const FlowReturn = enum(c_int) {
        ok = c.GST_FLOW_OK,
        not_linked = c.GST_FLOW_NOT_LINKED,
        flushing = c.GST_FLOW_FLUSHING,
        eos = c.GST_FLOW_EOS,
        not_negotiated = c.GST_FLOW_NOT_NEGOTIATED,
        @"error" = c.GST_FLOW_ERROR,
        not_supported = c.GST_FLOW_NOT_SUPPORTED,
    };
};

fn prepareUserData(userdata: anytype) ?*anyopaque {
    const T = @TypeOf(userdata);
    return switch (@typeInfo(T)) {
        .pointer => @ptrCast(@constCast(userdata)),
        else => @ptrCast(@constCast(&userdata)),
    };
}

fn convertUserData(comptime T: type, data: ?*anyopaque) T {
    return switch (@typeInfo(T)) {
        .pointer => @ptrCast(@alignCast(data.?)),
        else => @as(*T, @ptrCast(@alignCast(data.?))).*,
    };
}
