const std = @import("std");
const core = @import("core.zig");
const element = @import("Element.zig");

pub const c = core.c;
pub const GstBin = core.GstBin;
pub const Element = element.Element;
pub const State = core.State;
pub const StateChangeReturn = core.StateChangeReturn;

pub const Bin = struct {
    ptr: GstBin,

    // TODO: The thoughts behind this is to have "init" across all types
    // Find out if we makes _any_ sense.
    pub fn init(name: [*:0]const u8) !Bin {
        return try new(name);
    }

    pub fn new(name: [*:0]const u8) !Bin {
        const bin = c.gst_bin_new(name);
        if (bin == null) {
            return error.BinCreationFailed;
        }
        return Bin{ .ptr = @ptrCast(bin) };
    }

    pub fn deinit(self: Bin) void {
        c.gst_object_unref(@ptrCast(self.ptr));
    }

    pub fn add(self: Bin, el: Element) !void {
        if (c.gst_bin_add(self.ptr, el.ptr) == 0) {
            return error.FailedToAddElement;
        }
    }

    pub fn remove(self: Bin, el: Element) !void {
        if (c.gst_bin_remove(self.ptr, el.ptr) == 0) {
            return error.FailedToRemoveElement;
        }
    }

    pub fn getByName(self: Bin, name: [*:0]const u8) !Element {
        if (c.gst_bin_get_by_name(self.ptr, name)) |ptr| {
            return Element{ .ptr = ptr };
        }
        return error.BinNotFound;
    }

    pub fn getByNameRecurseUp(self: Bin, name: [*:0]const u8) !Element {
        if (c.gst_bin_get_by_name_recurse_up(self.ptr, name)) |ptr| {
            return Element{ .ptr = ptr };
        }
        return error.BinNotFound;
    }

    pub fn getByInterface(self: Bin, iface: c.GType) !Element {
        if (c.gst_bin_get_by_interface(self.ptr, iface)) |ptr| {
            return Element{ .ptr = ptr };
        }
        return error.BinNotFound;
    }

    pub fn recalculateLatency(self: Bin) bool {
        return c.gst_bin_recalculate_latency(self.ptr) != 0;
    }

    pub fn syncChildrenStates(self: Bin) bool {
        return c.gst_bin_sync_children_states(self.ptr) != 0;
    }

    pub fn setState(self: Bin, state: State) StateChangeReturn {
        const result = c.gst_element_set_state(@ptrCast(self.ptr), @intCast(@intFromEnum(state)));
        return @enumFromInt(result);
    }

    pub fn getState(self: Bin, timeout: u64) !Element.GetStateResult {
        var state: c_uint = undefined;
        var pending: c_uint = undefined;

        const result = c.gst_element_get_state(@ptrCast(self.ptr), &state, &pending, timeout);

        return .{
            .state = @enumFromInt(state),
            .pending = @enumFromInt(pending),
            .return_val = @enumFromInt(result),
        };
    }

    pub fn getNumChildren(self: Bin) u32 {
        return c.GST_BIN_NUMCHILDREN(self.ptr);
    }

    pub fn setSuppressedFlags(self: Bin, flags: c.GstElementFlags) void {
        c.gst_bin_set_suppressed_flags(self.ptr, flags);
    }

    pub fn getSuppressedFlags(self: Bin) c.GstElementFlags {
        return c.gst_bin_get_suppressed_flags(self.ptr);
    }

    pub fn getName(self: Bin) ?[*:0]const u8 {
        return c.gst_element_get_name(@ptrCast(self.ptr));
    }

    pub fn findUnlinkedPad(self: Bin, direction: c.GstPadDirection) ?*c.GstPad {
        return c.gst_bin_find_unlinked_pad(self.ptr, direction);
    }

    pub fn asElement(self: Bin) Element {
        return Element{ .ptr = @ptrCast(self.ptr) };
    }

    pub fn addMany(self: Bin, elements: []const Element) !void {
        for (elements) |el| {
            try self.add(el);
        }
    }

    pub fn removeMany(self: Bin, elements: []const Element) !void {
        for (elements) |el| {
            try self.remove(el);
        }
    }

    pub fn fromDescription(bin_description: [*:0]const u8, ghost_unlinked_pads: bool) !Bin {
        var err: ?*c.GError = null;
        const element_ptr = c.gst_parse_bin_from_description(bin_description, if (ghost_unlinked_pads) 1 else 0, &err);

        if (err) |e| {
            c.g_error_free(e);
            return error.ParseError;
        }

        if (element_ptr == null) {
            return error.BinCreationFailed;
        }

        return Bin{ .ptr = @ptrCast(element_ptr) };
    }
};
