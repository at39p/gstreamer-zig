const std = @import("std");
const gst = @import("gst");

const contextData = struct {
    queue: gst.Element,
};

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try gst.init_check(null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.init("srt-transmuxer");
    defer pipeline.deinit();

    // Create elements
    const source = try gst.Element.factory("srtsrc")
        .property("uri", "srt://127.0.0.1:7001?mode=caller&latency=20&buffer-size=8192")
        .build();

    var queues = std.array_list.Managed(gst.Element).init(allocator);
    defer queues.deinit();

    for (0..4) |i| {
        const queueName = try std.fmt.allocPrintSentinel(allocator, "queue{d}", .{i}, 0);
        defer allocator.free(queueName);

        const queue = try gst.Element.factory("queue")
            .name(queueName)
            .property("max-size-time", 1000000)
            .property("max-size-buffers", 30)
            .property("leaky", "downstream")
            .build();

        try queues.append(queue);
    }

    try pipeline.addMany(queues.items);

    for (queues.items) |q| {
        if (q.getName()) |name| {
            std.debug.print("{s}\n", .{name});
        } else {
            std.debug.print("(unnamed element)\n", .{});
        }
    }

    const demuxer = try gst.Element.init("tsdemux", "demuxer");
    const parse = try gst.Element.init("h264parse", "parser");

    const payloader = try gst.Element.factory("rtph264pay")
        .name("payloader")
        .property("config-interval", 1)
        .build();

    const sink = try gst.Element.factory("udpsink")
        .name("sink")
        .property("host", "127.0.0.1")
        .property("port", 5000)
        .property("sync", false)
        .property("async", false)
        .property("max-lateness", -1)
        .build();

    try pipeline.addMany(&.{ source, demuxer, parse, payloader, sink });

    var context = contextData{
        .queue = queues.items[1],
    };

    _ = demuxer.connect("pad-added", pad_added_handler, &context);

    // Link static elements up to demuxer
    try source.link(queues.items[0]);
    try queues.items[0].link(demuxer);

    // Link elements after demuxer (will be connected via pad-added callback)
    try queues.items[1].linkMany(&.{ parse, queues.items[2], payloader, queues.items[3], sink });

    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    std.debug.print("Starting message loop...\n", .{});

    while (bus.timedPop(gst.clock.TIME_NONE)) |message| {
        defer message.deinit();
        std.debug.print("Received message: {}\n", .{message.getType()});
        switch (message.getType()) {
            .eos => {
                std.debug.print("End of stream reached\n", .{});
                break;
            },
            .err => {
                _ = message.parseErrorAndPrint() catch {
                    std.debug.print("Unknown error occurred\n", .{});
                };
                break;
            },
            else => {},
        }
    }

    // Cleanup
    std.debug.print("Stopping pipeline...\n", .{});
    std.debug.print("Pipeline stopped and cleaned up\n", .{});

    _ = pipeline.setState(.null_state);
}

fn pad_added_handler(element: gst.Element, new_pad: gst.Pad, user_data: ?*anyopaque) void {
    std.debug.print("Pad added callback triggered!\n", .{});

    if (element.getName()) |elementName| {
        std.debug.print("element: {s}\n", .{elementName});
    }

    const name = new_pad.getName() orelse return;

    if (!std.mem.startsWith(u8, name, "video_")) return;

    const data = user_data orelse return;
    const context: *contextData = @ptrCast(@alignCast(data));

    const sink_pad = context.queue.getStaticPad("sink") orelse return;
    defer sink_pad.deinit();

    new_pad.link(sink_pad) catch |err| {
        std.debug.print("Failed to link {s} to queue: {}\n", .{ name, err });
        return;
    };

    std.debug.print("Successfully linked {s} to queue\n", .{name});
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
