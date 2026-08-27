const std = @import("std");
const core = @import("core.zig");
const message = @import("Message.zig");
const clock = @import("Clock.zig");

const c = core.c;
const GstBus = core.GstBus;
const GstMessage = core.GstMessage;
const ClockTime = clock.ClockTime;
const Io = std.Io;

pub const Bus = struct {
    ptr: GstBus,

    pub fn deinit(self: Bus) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn popMessage(self: Bus, timeout: ClockTime, types: message.MessageType) ?message.Message {
        if (c.gst_bus_timed_pop_filtered(self.ptr, @bitCast(timeout), @intFromEnum(types))) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Basic message retrieval without timeout
    pub fn pop(self: Bus) ?message.Message {
        if (c.gst_bus_pop(self.ptr)) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Filtered pop without timeout
    pub fn popFiltered(self: Bus, types: message.MessageType) ?message.Message {
        if (c.gst_bus_pop_filtered(self.ptr, @intFromEnum(types))) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Peek at next message without removing it
    pub fn peek(self: Bus) ?message.Message {
        if (c.gst_bus_peek(self.ptr)) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Check if there are pending messages
    pub fn havePending(self: Bus) bool {
        return c.gst_bus_have_pending(self.ptr) != 0;
    }

    // Poll for messages with timeout
    pub fn poll(self: Bus, events: message.MessageType, timeout: ClockTime) ?message.Message {
        if (c.gst_bus_poll(self.ptr, @intFromEnum(events), @bitCast(timeout))) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Timed pop without filtering
    pub fn timedPop(self: Bus, timeout: ClockTime) ?message.Message {
        if (c.gst_bus_timed_pop(self.ptr, @bitCast(timeout))) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Set flushing state
    pub fn setFlushing(self: Bus, flushing: bool) void {
        c.gst_bus_set_flushing(self.ptr, if (flushing) 1 else 0);
    }

    /// Post a message to the bus.
    pub fn post(self: Bus, msg: *message.Message) bool {
        const msg_ptr = msg.ptr orelse return false;
        msg.ptr = null; // Consume the message by nulling the pointer
        return c.gst_bus_post(self.ptr, msg_ptr) != 0;
    }

    // Add a watch to the bus with full control over priority and user data
    // The context will be passed to both the handler and destroy_fn
    // Returns source ID or error
    pub fn addWatchFull(
        self: Bus,
        priority: i32,
        comptime Context: type,
        context: *Context,
        handler: *const fn (ctx: *Context, msg: message.Message) bool,
        destroy_fn: ?*const fn (ctx: *Context) void,
    ) !u32 {
        const Wrapper = struct {
            const HandlerData = struct {
                context: *Context,
                handler: *const fn (ctx: *Context, msg: message.Message) bool,
                destroy_fn: ?*const fn (ctx: *Context) void,
            };

            fn callback(_: [*c]c.GstBus, msg: [*c]c.GstMessage, user_data: ?*anyopaque) callconv(.c) c_int {
                const msg_ptr = msg orelse @panic("Bus watch callback received null message - GStreamer contract violation");
                const data: *HandlerData = @ptrCast(@alignCast(user_data));
                const result = data.handler(data.context, message.Message{ .ptr = msg_ptr });
                return if (result) 1 else 0;
            }

            fn destroy(user_data: ?*anyopaque) callconv(.c) void {
                const data: *HandlerData = @ptrCast(@alignCast(user_data));
                if (data.destroy_fn) |destroy_handler| {
                    destroy_handler(data.context);
                }
                // Free the wrapper data structure
                const allocator = std.heap.c_allocator;
                allocator.destroy(data);
            }
        };

        // Allocate wrapper data on the heap so it persists
        const allocator = std.heap.c_allocator;
        const handler_data = try allocator.create(Wrapper.HandlerData);
        handler_data.* = .{
            .context = context,
            .handler = handler,
            .destroy_fn = destroy_fn,
        };

        const result = c.gst_bus_add_watch_full(
            self.ptr,
            priority,
            Wrapper.callback,
            handler_data,
            Wrapper.destroy,
        );

        if (result == 0) {
            allocator.destroy(handler_data);
            return error.AddWatchToBusFailed;
        }

        return result;
    }

    /// Add a watch callback to the bus that will be invoked for each message.
    /// The callback should return `true` to continue watching, `false` to remove the watch.
    ///
    /// This follows the Zig standard library convention where context is the first
    /// callback parameter (similar to `std.sort`).
    ///
    /// **With context pointer:**
    /// ```zig
    /// const id = try bus.addWatch(&main_loop, handleMessage);
    ///
    /// fn handleMessage(loop: *glib.MainLoop, msg: gst.Message) bool {
    ///     if (msg.getType() == .eos) {
    ///         loop.quit();
    ///         return false;
    ///     }
    ///     return true;
    /// }
    /// ```
    ///
    /// **Without context (inline function):**
    /// ```zig
    /// const id = try bus.addWatch({}, struct {
    ///     fn handle(_: void, msg: gst.Message) bool {
    ///         std.debug.print("Message: {}\n", .{msg.getType()});
    ///         return true;
    ///     }
    /// }.handle);
    /// ```
    ///
    /// **Without context (external function):**
    /// ```zig
    /// const id = try bus.addWatch({}, handleMessage);
    ///
    /// fn handleMessage(_: void, msg: gst.Message) bool {
    ///     return msg.getType() != .eos;
    /// }
    /// ```
    pub fn addWatch(
        self: Bus,
        context: anytype,
        comptime callback: fn (@TypeOf(context), message.Message) bool,
    ) !u32 {
        const Context = @TypeOf(context);

        comptime {
            if (Context != void and @typeInfo(Context) != .pointer) {
                @compileError("context must be a pointer type (e.g., *T) or void ({})");
            }
        }

        const Wrapper = struct {
            fn cCallback(
                _: [*c]c.GstBus,
                msg: [*c]c.GstMessage,
                user_data: ?*anyopaque,
            ) callconv(.c) c_int {
                const msg_ptr = msg orelse @panic("Bus watch callback received null message - GStreamer contract violation");
                const ctx: Context = if (Context == void) {} else @ptrCast(@alignCast(user_data));

                const result = callback(ctx, message.Message{ .ptr = msg_ptr });
                return if (result) 1 else 0;
            }
        };

        const user_data: ?*anyopaque = if (Context == void)
            null
        else
            @ptrCast(@constCast(context));

        const source_id = c.gst_bus_add_watch(self.ptr, Wrapper.cCallback, user_data);
        if (source_id == 0) return error.AddWatchToBusFailed;

        return source_id;
    }

    // Remove a watch from the bus
    pub fn removeWatch(_: Bus, watch_id: u32) bool {
        return c.g_source_remove(watch_id) != 0;
    }

    // Add signal watch (for GLib signal-based message handling)
    pub fn addSignalWatch(self: Bus) void {
        c.gst_bus_add_signal_watch(self.ptr);
    }

    // Remove signal watch
    pub fn removeSignalWatch(self: Bus) void {
        c.gst_bus_remove_signal_watch(self.ptr);
    }

    // Set sync handler
    pub fn setSyncHandler(self: Bus, func: ?BusSyncHandler, user_data: ?*anyopaque) void {
        c.gst_bus_set_sync_handler(self.ptr, @ptrCast(func), user_data, null);
    }

    // Enable sync message emission
    pub fn enableSyncMessageEmission(self: Bus) void {
        c.gst_bus_enable_sync_message_emission(self.ptr);
    }

    // Disable sync message emission
    pub fn disableSyncMessageEmission(self: Bus) void {
        c.gst_bus_disable_sync_message_emission(self.ptr);
    }

    /// The bus as an async sequence of messages, for applications that run on
    /// `std.Io` instead of a GLib main loop.
    pub fn stream(self: Bus) Stream {
        return .{ .bus = self };
    }

    pub const Stream = struct {
        bus: Bus,

        /// Awaits the next message, suspending the calling task while
        /// GStreamer has nothing to say, so other tasks keep running. Returns
        /// null once the bus stops delivering, e.g. it was set flushing.
        ///
        /// Transfer full: the caller owns the message and must `deinit` it.
        ///
        /// The bus itself is the queue, so no message is missed between calls.
        /// One unit of concurrency is used per message, which is cheap for a
        /// bus: it carries state changes, warnings and errors, not data.
        ///
        /// A pop already in flight cannot be interrupted - `gst_bus_timed_pop`
        /// is a blocking call and Zig cannot cancel one - so a canceled task
        /// observes the cancelation after the next message arrives.
        pub fn next(self: Stream, io: Io) Io.ConcurrentError!?message.Message {
            // `concurrent`, not `async`: `async` is allowed to run the pop
            // inline on this thread, which would block it instead of
            // suspending this task.
            var pending = try io.concurrent(timedPopBlocking, .{self.bus});
            return pending.await(io);
        }

        fn timedPopBlocking(bus: Bus) ?message.Message {
            return bus.timedPop(clock.TIME_NONE);
        }
    };
};

// Sync handler function type
pub const BusSyncHandler = *const fn (bus: [*c]c.GstBus, msg: [*c]c.GstMessage, user_data: ?*anyopaque) callconv(.c) c.GstBusSyncReply;

test {
    @import("testing").refAllDeclsRecursive(@This());
}
