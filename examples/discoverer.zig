// This example uses gstreamer's discoverer api
// https://gstreamer.freedesktop.org/data/doc/gstreamer/head/gst-plugins-base-libs/html/GstDiscoverer.html
// To detect as much information from a given URI.
// The amount of time that the discoverer is allowed to use is limited by a timeout.
// This allows to handle e.g. network problems gracefully. When the timeout hits before
// discoverer was able to detect anything, discoverer will report an error.
// In this example, we catch this error and stop the application.
// Discovered information could for example contain the stream's duration or whether it is
// seekable (filesystem) or not (some http servers).

const std = @import("std");
const gst = @import("gst");

fn printTags(info: gst.DiscovererInfo) void {
    std.debug.print("Tags:\n", .{});
    if (info.getTagsString()) |tags| {
        defer gst.c.g_free(tags);
        std.debug.print("  {s}\n", .{tags});
    } else {
        std.debug.print("  no tags\n", .{});
    }
}

fn printStreamInfo(stream: gst.DiscovererStreamInfo, allocator: std.mem.Allocator) void {
    std.debug.print("Stream:\n", .{});
    if (stream.getStreamId()) |id| {
        std.debug.print("  Stream id: {s}\n", .{id});
    }

    if (stream.getCaps()) |caps| {
        defer caps.deinit();
        const caps_str = caps.toStringAlloc(allocator) catch {
            std.debug.print("  Format: (allocation failed)\n", .{});
            return;
        };
        defer allocator.free(caps_str);

        std.debug.print("  Format: {s}\n", .{caps_str});
    } else {
        std.debug.print("  Format: --\n", .{});
    }
}

fn printDiscovererInfo(info: gst.DiscovererInfo, allocator: std.mem.Allocator) !void {
    std.debug.print("URI: {s}\n", .{info.getUri()});
    std.debug.print("Duration: {f}\n", .{info.getDuration()});

    printTags(info);

    const top_stream = info.getStreamInfo() orelse return error.NoStreamInfo;
    defer top_stream.deinit();
    printStreamInfo(top_stream, allocator);

    const stream_list = info.getStreamList();
    defer stream_list.deinit();

    std.debug.print("Children streams:\n", .{});
    var it = stream_list.iterator();
    while (it.next()) |stream| {
        printStreamInfo(stream, allocator);
    }
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return error.MissingUriArgument;
    }

    try gst.init_check(args);
    defer gst.deinit();

    const discoverer = try gst.Discoverer.init(gst.ClockTime.fromSeconds(15));
    defer discoverer.deinit();

    const info = try discoverer.discoverUri(args[1]);
    defer info.deinit();

    if (info.getResult() != .ok) {
        std.debug.print("Discovery failed: {s}\n", .{@tagName(info.getResult())});
        return;
    }

    try printDiscovererInfo(info, allocator);
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
