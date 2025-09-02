const std = @import("std");
const core = @import("../core.zig");
const element = @import("../element.zig");
const sample = @import("../sample.zig");

pub const c = core.c;
pub const Sample = sample.Sample;

pub const AppSink = struct {
    el: element.Element,

    pub fn init(name: ?[*:0]const u8) !AppSink {
        const el = try element.Element.init("appsink", name);
        return AppSink{ .el = el };
    }

    pub fn deinit(self: AppSink) void {
        self.el.deinit();
    }

    pub inline fn asElement(self: AppSink) element.Element {
        return self.el;
    }

    pub fn pullSample(self: AppSink) ?Sample {
        var gstSample: ?core.GstSample = null;
        c.g_signal_emit_by_name(self.el.ptr, "pull-sample", &gstSample);
        if (gstSample) |p| {
            return Sample{ .ptr = p };
        }
        return null;
    }

    pub fn pullPreroll(self: AppSink) ?Sample {
        var gstSample: ?core.GstSample = null;
        c.g_signal_emit_by_name(self.el.ptr, "pull-preroll", &gstSample);
        if (gstSample) |p| {
            return Sample{ .ptr = p };
        }
        return null;
    }

    pub fn tryPullSample(self: AppSink, timeout: u64) ?Sample {
        _ = timeout;
        return self.pullSample();
    }

    pub fn isEos(self: AppSink) bool {
        var is_eos: c_int = 0;
        c.g_object_get(self.el.ptr, "eos", &is_eos, @as(?*anyopaque, null));
        return is_eos != 0;
    }

    pub fn setCaps(self: AppSink, caps: *c.GstCaps) void {
        c.g_object_set(self.el.ptr, "caps", caps, @as(?*anyopaque, null));
    }

    pub fn setDrop(self: AppSink, drop: bool) void {
        c.g_object_set(self.el.ptr, "drop", @as(c_int, if (drop) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setMaxBuffers(self: AppSink, max_buffers: u32) void {
        c.g_object_set(self.el.ptr, "max-buffers", @as(c_uint, max_buffers), @as(?*anyopaque, null));
    }

    pub fn setSync(self: AppSink, sync: bool) void {
        c.g_object_set(self.el.ptr, "sync", @as(c_int, if (sync) 1 else 0), @as(?*anyopaque, null));
    }

    pub fn setEmitSignals(self: AppSink, emit: bool) void {
        c.g_object_set(self.el.ptr, "emit-signals", @as(c_int, if (emit) 1 else 0), @as(?*anyopaque, null));
    }

    pub const CallbacksBuilder = struct {
        eos_func: ?*const fn (*AppSink, ?*anyopaque) void = null,
        new_preroll_func: ?*const fn (*AppSink, ?*anyopaque) void = null,
        new_sample_func: ?*const fn (*AppSink, ?*anyopaque) void = null,
        user_data: ?*anyopaque = null,

        const Builder = @This();

        pub fn init() Builder {
            return Builder{};
        }

        pub fn onEos(self: Builder, func: *const fn (*AppSink, ?*anyopaque) void) Builder {
            return Builder{
                .eos_func = func,
                .new_preroll_func = self.new_preroll_func,
                .new_sample_func = self.new_sample_func,
                .user_data = self.user_data,
            };
        }

        pub fn onNewPreroll(self: Builder, func: *const fn (*AppSink, ?*anyopaque) void) Builder {
            return Builder{
                .eos_func = self.eos_func,
                .new_preroll_func = func,
                .new_sample_func = self.new_sample_func,
                .user_data = self.user_data,
            };
        }

        pub fn onNewSample(self: Builder, func: *const fn (*AppSink, ?*anyopaque) void) Builder {
            return Builder{
                .eos_func = self.eos_func,
                .new_preroll_func = self.new_preroll_func,
                .new_sample_func = func,
                .user_data = self.user_data,
            };
        }

        pub fn userData(self: Builder, data: ?*anyopaque) Builder {
            return Builder{
                .eos_func = self.eos_func,
                .new_preroll_func = self.new_preroll_func,
                .new_sample_func = self.new_sample_func,
                .user_data = data,
            };
        }

        const CallbackContext = struct {
            eos_func: ?*const fn (*AppSink, ?*anyopaque) void,
            new_preroll_func: ?*const fn (*AppSink, ?*anyopaque) void,
            new_sample_func: ?*const fn (*AppSink, ?*anyopaque) void,
            user_data: ?*anyopaque,
            app_sink: *AppSink,
        };

        fn eosWrapper(gst_element: ?*anyopaque, context: ?*anyopaque) callconv(.c) void {
            if (context) |ctx| {
                const callback_ctx: *CallbackContext = @alignCast(@ptrCast(ctx));
                if (callback_ctx.eos_func) |func| {
                    func(callback_ctx.app_sink, callback_ctx.user_data);
                }
            }
            _ = gst_element;
        }

        fn newPrerollWrapper(gst_element: ?*anyopaque, context: ?*anyopaque) callconv(.c) c_int {
            if (context) |ctx| {
                const callback_ctx: *CallbackContext = @alignCast(@ptrCast(ctx));
                if (callback_ctx.new_preroll_func) |func| {
                    func(callback_ctx.app_sink, callback_ctx.user_data);
                }
            }
            _ = gst_element;
            return 0; // GST_FLOW_OK
        }

        fn newSampleWrapper(gst_element: ?*anyopaque, context: ?*anyopaque) callconv(.c) c_int {
            if (context) |ctx| {
                const callback_ctx: *CallbackContext = @alignCast(@ptrCast(ctx));
                if (callback_ctx.new_sample_func) |func| {
                    func(callback_ctx.app_sink, callback_ctx.user_data);
                }
            }
            _ = gst_element;
            return 0; // GST_FLOW_OK
        }

        pub fn apply(self: Builder, app_sink: *AppSink, allocator: std.mem.Allocator) !void {
            const context = try allocator.create(CallbackContext);
            context.* = CallbackContext{
                .eos_func = self.eos_func,
                .new_preroll_func = self.new_preroll_func,
                .new_sample_func = self.new_sample_func,
                .user_data = self.user_data,
                .app_sink = app_sink,
            };

            if (self.eos_func != null) {
                _ = c.g_signal_connect_data(app_sink.el.ptr, "eos", @ptrCast(&eosWrapper), context, null, 0);
            }
            if (self.new_preroll_func != null) {
                _ = c.g_signal_connect_data(app_sink.el.ptr, "new-preroll", @ptrCast(&newPrerollWrapper), context, null, 0);
            }
            if (self.new_sample_func != null) {
                _ = c.g_signal_connect_data(app_sink.el.ptr, "new-sample", @ptrCast(&newSampleWrapper), context, null, 0);
            }
        }
    };
};
