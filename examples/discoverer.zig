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

fn printTags(info: gst.DiscovererInfo, allocator: std.mem.Allocator) !void {
    std.debug.print("Tags:\n", .{});
    const tags = info.getTags() orelse {
        std.debug.print("  no tags\n", .{});
        return;
    };

    if (tags.get(.video_codec)) |codec| {
        std.debug.print("  Video codec: {s}\n", .{codec});
    }
    if (tags.get(.audio_codec)) |codec| {
        std.debug.print("  Audio codec: {s}\n", .{codec});
    }
    if (tags.get(.container_format)) |format| {
        std.debug.print("  Container: {s}\n", .{format});
    }
    if (tags.get(.encoder)) |enc| {
        std.debug.print("  Encoder: {s}\n", .{enc});
    }
    if (tags.get(.bitrate)) |br| {
        std.debug.print("  Bitrate: {d} kbps\n", .{br / 1000});
    }
    if (tags.get(.maximum_bitrate)) |br| {
        std.debug.print("  Max bitrate: {d} kbps\n", .{br / 1000});
    }
    if (tags.get(.date_time)) |dt| {
        defer dt.deinit();
        const str = try dt.toIso8601(allocator);
        defer allocator.free(str);
        std.debug.print("  Date/Time: {s}\n", .{str});
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

    try printTags(info, allocator);

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

fn run(init: std.process.Init) !void {
    const allocator = init.gpa;

    const args = try init.minimal.args.toSlice(allocator);
    defer allocator.free(args);

    if (args.len < 2) {
        return error.MissingUriArgument;
    }

    try gst.init_check(args);
    defer gst.deinit();

    const discoverer = try gst.Discoverer.init(gst.ClockTime.fromSeconds(15));
    defer discoverer.deinit();

    const info = try discoverer.discoverUri(allocator, args[1]);
    defer info.deinit();

    if (info.getResult() != .ok) {
        std.debug.print("Discovery failed: {s}\n", .{@tagName(info.getResult())});
        return;
    }

    try printDiscovererInfo(info, allocator);
}

pub fn main(init: std.process.Init) !void {
    try gst.macosMainSimple(run, init);
}
