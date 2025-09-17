const std = @import("std");
const core = @import("core.zig");
const message = @import("message.zig");

pub const c = core.c;
pub const GstBus = *c.GstBus;
pub const GstMessage = *c.GstMessage;

pub const Bus = struct {
    ptr: GstBus,

    pub fn deinit(self: Bus) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn popMessage(self: Bus, timeout: u64, types: message.MessageType) ?message.Message {
        if (c.gst_bus_timed_pop_filtered(self.ptr, timeout, @intFromEnum(types))) |msg| {
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
    pub fn poll(self: Bus, events: message.MessageType, timeout: u64) ?message.Message {
        if (c.gst_bus_poll(self.ptr, @intFromEnum(events), timeout)) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Timed pop without filtering
    pub fn timedPop(self: Bus, timeout: u64) ?message.Message {
        if (c.gst_bus_timed_pop(self.ptr, timeout)) |msg| {
            return message.Message{ .ptr = msg };
        }
        return null;
    }

    // Set flushing state
    pub fn setFlushing(self: Bus, flushing: bool) void {
        c.gst_bus_set_flushing(self.ptr, if (flushing) 1 else 0);
    }

    // Post a message to the bus
    pub fn post(self: Bus, msg: message.Message) bool {
        return c.gst_bus_post(self.ptr, msg.ptr) != 0;
    }

    // Add a watch to the bus - returns source ID, 0 on error
    pub fn addWatch(self: Bus, func: MessageHandler) !u32 {
        const Wrapper = struct {
            fn callback(_: [*c]c.GstBus, msg: [*c]c.GstMessage, user_data: ?*anyopaque) callconv(.c) c_int {
                const handler: MessageHandler = @ptrCast(@alignCast(user_data));
                const result = handler(message.Message{ .ptr = msg });
                return if (result) 1 else 0;
            }
        };
        const result = c.gst_bus_add_watch(self.ptr, Wrapper.callback, @ptrCast(@constCast(func)));
        if (result == 0) {
            return error.AddWatchToBusFailed;
        }

        return result;
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
};

// Function pointer type for bus watch callback
pub const BusFunc = *const fn (bus: [*c]c.GstBus, msg: [*c]c.GstMessage, user_data: ?*anyopaque) callconv(.c) c_int;

// Sync handler function type
pub const BusSyncHandler = *const fn (bus: [*c]c.GstBus, msg: [*c]c.GstMessage, user_data: ?*anyopaque) callconv(.c) c.GstBusSyncReply;

// Callback type for addWatch
pub const MessageHandler = *const fn (msg: message.Message) bool;
