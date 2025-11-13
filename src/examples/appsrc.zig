const std = @import("std");
const gst = @import("gst");

var frame_count: u64 = 0;

const contextData = struct {
    video_info: gst.VideoInfo,
};

fn onNeedData(appsrc: *gst.AppSrc, length: u32, context: *contextData) void {
    _ = length;

    if (frame_count == 100) {
        appsrc.endOfStream() catch |err| {
            std.debug.print("Failed to send EOS: {}\n", .{err});
        };
        return;
    }

    std.debug.print("producing frame {d}\n", .{frame_count});

    const r: u8 = if (frame_count % 2 == 0) 0 else 255;
    const g: u8 = if (frame_count % 3 == 0) 0 else 255;
    const b: u8 = if (frame_count % 5 == 0) 0 else 255;

    const buffer = gst.Buffer.init(context.video_info.getSize());
    if (buffer) |buf| {
        buf.setPts(frame_count * 500 * 1000000); // 500ms in nanoseconds (GST_MSECOND equivalent) // TODO: Use GST_MSECOND

        var vframe = gst.VideoFrame.fromBufferWritable(buf, context.video_info) catch |err| {
            std.debug.print("Failed to create video frame: {}\n", .{err});
            return;
        };
        defer vframe.deinit();

        const width = vframe.getWidth();
        const height = vframe.getHeight();

        const stride = vframe.planeStride(0) catch |err| {
            std.debug.print("Failed to get plane stride: {}\n", .{err});
            return;
        };
        const plane_data = vframe.planeData(0) catch |err| {
            std.debug.print("Failed to get plane data: {}\n", .{err});
            return;
        };

        // Iterate over each line of the frame
        var y: u32 = 0;
        while (y < height) : (y += 1) {
            const line_offset = y * @as(u32, @intCast(stride));
            const line_end = @min(line_offset + (4 * width), @as(u32, @intCast(plane_data.len)));

            if (line_offset >= plane_data.len) break;

            const line = plane_data[line_offset..line_end];

            // Iterate over each pixel of 4 bytes in that line
            var x: u32 = 0;
            while (x < width and (x * 4 + 3) < line.len) : (x += 1) {
                const pixel_offset = x * 4;
                line[pixel_offset + 0] = b; // Blue
                line[pixel_offset + 1] = g; // Green
                line[pixel_offset + 2] = r; // Red
                line[pixel_offset + 3] = 0; // X (unused padding)
            }
        }

        appsrc.pushBuffer(buf) catch |err| {
            std.debug.print("Failed to push buffer: {}\n", .{err});
        };
    }

    frame_count += 1;
}

fn run() !void {
    gst.init(null, null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.init("test-appsrc");
    defer pipeline.deinit();

    var videoInfo = try gst.VideoInfo.new();
    defer videoInfo.deinit();

    try videoInfo.setFormat(gst.VideoFormat.bgrx, 320, 240);
    videoInfo.setFPS(gst.Fraction.new(2, 1));

    var appsrc = try gst.AppSrc.init("source");
    defer appsrc.deinit();

    // Configure appsrc properties
    appsrc.setIsLive(true);
    appsrc.setStreamType(.stream);
    appsrc.setFormat(.time);

    // const caps = gst.Caps.builder("video/x-raw")
    //     .field("format", "RGB")
    //     .field("width", 320)
    //     .field("height", 240)
    //     .field("framerate", gst.Fraction.new(30, 1))
    //     .build();
    // defer caps.deinit();

    const caps = try videoInfo.toCaps();
    std.debug.print("caps: {s}\n", .{caps.toString()});

    appsrc.setCaps(caps);

    var context = contextData{
        .video_info = videoInfo,
    };

    // Set up appsrc callbacks
    _ = try appsrc.connectNeedData(onNeedData, &context);

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

pub fn main() !void {
    try gst.macosMainSimple(run);
}
