const std = @import("std");
const gst = @import("gst");

var frame_count: u64 = 0;

fn onNeedData(appsrc: *gst.AppSrc, length: u32, user_data: ?*anyopaque) void {
    _ = user_data;
    _ = length;

    // Create a buffer for RGB video (320x240x3 = 230,400 bytes)
    const buffer_size = 320 * 240 * 3;
    const buffer = gst.Buffer.init(buffer_size);
    if (buffer) |buf| {
        // Set timestamps
        const timestamp = frame_count * 33333333; // ~30 FPS
        buf.setPts(timestamp);
        buf.setDts(timestamp);

        // Fill buffer with RGB test pattern
        var map_info = buf.mapWrite();
        if (map_info) |*info| {
            defer info.deinit();

            // Create a simple test pattern: cycling colors
            const pixels = info.size / 3;
            for (0..pixels) |i| {
                const pixel_idx = i * 3;
                const x = i % 320;
                const y = i / 320;

                // Create color pattern based on position and frame
                info.data[pixel_idx + 0] = @intCast((x + frame_count) % 256); // Red
                info.data[pixel_idx + 1] = @intCast((y + frame_count / 2) % 256); // Green
                info.data[pixel_idx + 2] = @intCast((frame_count * 2) % 256); // Blue
            }
        }

        frame_count += 1;

        // Push the buffer
        appsrc.pushBuffer(buf) catch |err| {
            std.debug.print("Failed to push buffer: {}\n", .{err});
        };
    }
}

fn createAndRun() !void {
    gst.init(null, null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.init("test-appsrc");
    defer pipeline.deinit();

    var appsrc = try gst.AppSrc.init("source");
    defer appsrc.deinit();

    // Configure appsrc properties
    appsrc.setIsLive(true);
    appsrc.setStreamType(.stream);
    appsrc.setFormat(.time);

    const caps = try gst.Caps.fromString("video/x-raw,format=RGB,width=320,height=240,framerate=30/1");
    defer caps.deinit();
    appsrc.setCaps(caps);

    // Set up appsrc callbacks
    const callbacks = gst.AppSrc.AppSrcCallbacks.builder()
        .needData(onNeedData)
        .build();
    try appsrc.setCallbacks(callbacks);

    const videoconvert = try gst.Element.init("videoconvert", "convert");
    const autovideosink = try gst.Element.init("autovideosink", "sink");

    // Add elements to pipeline and link them
    try pipeline.addMany(&[_]gst.Element{ appsrc.asElement(), videoconvert, autovideosink });
    try gst.element.linkMany(&[_]gst.Element{ appsrc.asElement(), videoconvert, autovideosink });

    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    // Wait for EOS or error
    var running = true;
    while (running) {
        const msg = bus.popMessage(std.time.ns_per_ms * 10, .any);
        if (msg) |message| {
            defer message.deinit();

            const msg_type = message.getType();
            switch (msg_type) {
                .eos => {
                    std.debug.print("End of stream reached\n", .{});
                    running = false;
                },
                .err => {
                    const is_quit = message.parseErrorAndPrint() catch {
                        std.debug.print("Unknown error occurred\n", .{});
                        running = false;
                        continue;
                    };
                    if (is_quit) {
                        std.debug.print("Gracefully shutting down...\n", .{});
                    }
                    running = false;
                },
                .warning => {
                    // Handle warnings if needed
                },
                .state_changed => {
                    // Optionally handle state changes
                },
                .info => {
                    // Handle info messages if needed
                },
                else => {
                    // Handle other messages if needed
                },
            }
        }

        // Add a small delay to prevent busy waiting
        std.Thread.sleep(std.time.ns_per_ms * 10);
    }

    // Cleanup
    std.debug.print("Stopping pipeline...\n", .{});
    std.debug.print("Pipeline stopped and cleaned up\n", .{});

    _ = pipeline.setState(.null_state);
}

fn run(_: ?*anyopaque) callconv(.c) c_int {
    createAndRun() catch |err| {
        std.debug.print("Pipeline error: {}\n", .{err});
        return -1;
    };

    return 0;
}

pub fn main() !void {
    try gst.macosMainSimple(run, null);
}
