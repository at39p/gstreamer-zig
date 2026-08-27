// This example demonstrates how to use the gstreamer bindings in conjunction
// with Zig's async I/O. The example waits for either an error to occur, or for
// an EOS message. When a message notifying about either of both is received,
// the message stream is finished.

const std = @import("std");
const gst = @import("gst");

// Runs alongside the message loop. Awaiting the bus suspends the task that
// waits for messages rather than blocking a thread, so these lines keep
// coming while the pipeline has nothing to report.
fn printPosition(io: std.Io, pipeline: gst.Pipeline) void {
    while (true) {
        io.sleep(.fromMilliseconds(500), .awake) catch return; // canceled
        const position = pipeline.element.queryPosition(.time) orelse continue;
        std.debug.print("position: {f}\n", .{gst.ClockTime.fromNseconds(@intCast(position))});
    }
}

fn run(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const pipeline_str = try std.mem.joinZ(arena, " ", args[1..]);

    try gst.init_check(args);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.initLaunch(pipeline_str);
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    try pipeline.start();

    var position = try io.concurrent(printPosition, .{ io, pipeline });
    defer position.cancel(io);

    // The bus as an async sequence of messages.
    const messages = bus.stream();

    // Run until our message loop finishes, e.g. EOS/error happens.
    while (try messages.next(io)) |msg| {
        defer msg.deinit();

        // Determine whether we want to quit: on EOS or error message
        // we quit, otherwise simply continue.
        switch (msg.getType()) {
            .eos => break,
            .err => {
                msg.parseErrorAndPrint() catch std.debug.print("Unknown error\n", .{});
                break;
            },
            else => {},
        }
    }

    _ = pipeline.setState(.null_state);
}

pub fn main(init: std.process.Init) !void {
    try gst.macosMainSimple(run, init);
}
