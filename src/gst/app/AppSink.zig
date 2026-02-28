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
        const ptr = c.gst_app_sink_pull_sample(@ptrCast(self.el.ptr));
        if (Sample.fromPtr(ptr)) |s| {
            return s;
        }
        if (self.isEos()) {
            return error.Eos;
        }
        return error.Stopped;
    }

    pub fn pullPreroll(self: AppSink) PullError!Sample {
        const ptr = c.gst_app_sink_pull_preroll(@ptrCast(self.el.ptr));
        if (Sample.fromPtr(ptr)) |s| {
            return s;
        }
        if (self.isEos()) {
            return error.Eos;
        }
        return error.Stopped;
    }

    /// Returns a Sample on success, error.Eos on end-of-stream, or null on timeout/stopped.
    pub fn tryPullSample(self: AppSink, timeout: u64) PullError!?Sample {
        const ptr = c.gst_app_sink_try_pull_sample(@ptrCast(self.el.ptr), timeout);
        if (Sample.fromPtr(ptr)) |s| {
            return s;
        }
        if (self.isEos()) {
            return error.Eos;
        }
        return null; // timeout
    }

    pub fn isEos(self: AppSink) bool {
        return c.gst_app_sink_is_eos(@ptrCast(self.el.ptr)) != 0;
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

    /// Set callbacks using the GStreamer 1.28+ simple callbacks API.
    ///
    /// Pass an anonymous struct with optional `{function, userdata}` tuple fields:
    ///   - `.eos`                  — fn(*AppSink, T) void
    ///   - `.new_preroll`          — fn(*AppSink, T) FlowReturn
    ///   - `.new_sample`           — fn(*AppSink, T) FlowReturn
    ///   - `.new_event`            — fn(*AppSink, T) bool
    ///   - `.propose_allocation`   — fn(*AppSink, *anyopaque, T) bool
    ///
    /// Each field is optional; omit any callbacks you don't need.
    ///
    /// Example:
    /// ```zig
    /// appsink.setCallbacks(.{
    ///     .new_sample = .{ onNewSample, &ctx },
    ///     .eos        = .{ onEos, &ctx },
    /// });
    /// ```
    pub fn setCallbacks(self: AppSink, callbacks: anytype) void {
        const CallbacksT = @TypeOf(callbacks);
        const cb = c.gst_app_sink_simple_callbacks_new();

        if (@hasField(CallbacksT, "eos")) {
            const entry = callbacks.eos;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsink_ptr: ?*c.GstAppSink, data: c.gpointer) callconv(.c) void {
                    var sink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsink_ptr)) } };
                    if (has_userdata) {
                        fn_ptr(&sink, convertUserData(@TypeOf(entry[1]), data));
                    } else {
                        fn_ptr(&sink);
                    }
                }
            };
            c.gst_app_sink_simple_callbacks_set_eos(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "new_preroll")) {
            const entry = callbacks.new_preroll;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsink_ptr: ?*c.GstAppSink, data: c.gpointer) callconv(.c) c.GstFlowReturn {
                    var sink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsink_ptr)) } };
                    if (has_userdata) {
                        return @intFromEnum(fn_ptr(&sink, convertUserData(@TypeOf(entry[1]), data)));
                    } else {
                        return @intFromEnum(fn_ptr(&sink));
                    }
                }
            };
            c.gst_app_sink_simple_callbacks_set_new_preroll(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "new_sample")) {
            const entry = callbacks.new_sample;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsink_ptr: ?*c.GstAppSink, data: c.gpointer) callconv(.c) c.GstFlowReturn {
                    var sink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsink_ptr)) } };
                    if (has_userdata) {
                        return @intFromEnum(fn_ptr(&sink, convertUserData(@TypeOf(entry[1]), data)));
                    } else {
                        return @intFromEnum(fn_ptr(&sink));
                    }
                }
            };
            c.gst_app_sink_simple_callbacks_set_new_sample(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "new_event")) {
            const entry = callbacks.new_event;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsink_ptr: ?*c.GstAppSink, data: c.gpointer) callconv(.c) c.gboolean {
                    var sink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsink_ptr)) } };
                    if (has_userdata) {
                        return if (fn_ptr(&sink, convertUserData(@TypeOf(entry[1]), data))) 1 else 0;
                    } else {
                        return if (fn_ptr(&sink)) 1 else 0;
                    }
                }
            };
            c.gst_app_sink_simple_callbacks_set_new_event(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        if (@hasField(CallbacksT, "propose_allocation")) {
            const entry = callbacks.propose_allocation;
            const fn_ptr = comptime entry[0];
            const has_userdata = comptime @TypeOf(entry[1]) != @TypeOf(null);
            const wrapper = struct {
                fn thunk(appsink_ptr: ?*c.GstAppSink, query: ?*c.GstQuery, data: c.gpointer) callconv(.c) c.gboolean {
                    var sink = AppSink{ .el = element.Element{ .ptr = @ptrCast(@alignCast(appsink_ptr)) } };
                    if (has_userdata) {
                        return if (fn_ptr(&sink, query, convertUserData(@TypeOf(entry[1]), data))) 1 else 0;
                    } else {
                        return if (fn_ptr(&sink, query)) 1 else 0;
                    }
                }
            };
            c.gst_app_sink_simple_callbacks_set_propose_allocation(cb, wrapper.thunk, prepareUserData(entry[1]), null);
        }

        c.gst_app_sink_set_simple_callbacks(@ptrCast(self.el.ptr), cb);
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
        .null => null,
        .pointer => @ptrCast(@constCast(userdata)),
        else => @compileError("userdata must be a pointer or null"),
    };
}

fn convertUserData(comptime T: type, data: c.gpointer) T {
    return switch (@typeInfo(T)) {
        .pointer => @ptrCast(@alignCast(data.?)),
        else => @compileError("userdata type must be a pointer or null"),
    };
}
