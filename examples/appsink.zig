const std = @import("std");
const gst = @import("gst");

var sample_count: u32 = 0;

fn onNewSample(appsink: *gst.AppSink) gst.AppSink.FlowReturn {
    const sample = appsink.pullSample() catch |err| return switch (err) {
        error.Eos => .eos,
        error.Stopped => .flushing,
    };
    defer sample.deinit();

    const buffer = sample.getBuffer() orelse return .@"error";

    var map = buffer.mapRead() orelse return .@"error";
    defer map.deinit();

    // Interpret buffer as i16 samples
    const samples = std.mem.bytesAsSlice(i16, map.data[0..map.size]);

    // Compute RMS (root mean square)
    var sum: f64 = 0;
    for (samples) |s| {
        const f: f64 = @as(f64, @floatFromInt(s)) / @as(f64, @floatFromInt(std.math.maxInt(i16)));
        sum += f * f;
    }
    const rms = @sqrt(sum / @as(f64, @floatFromInt(samples.len)));

    std.debug.print("sample {d}: rms = {d:.4}\n", .{ sample_count, rms });
    sample_count += 1;

    if (sample_count >= 20) {
        return .eos;
    }

    return .ok;
}

fn run() !void {
    gst.init(null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.init("appsink-example");
    defer pipeline.deinit();

    const src = try gst.Element.init("audiotestsrc", "src");
    src.setProperty("num-buffers", 20);

    var appsink = try gst.AppSink.init("sink");
    defer appsink.deinit();

    // Set caps for S16 mono audio at 44100 Hz
    const caps = try gst.Caps.fromString("audio/x-raw,format=S16LE,channels=1,rate=44100");
    defer caps.deinit();
    appsink.setCaps(caps);

    // Set up appsink callbacks
    appsink.setCallbacks(.{
        .new_sample = .{ onNewSample, null },
    });

    try pipeline.addMany(&.{ src, appsink.asElement() });
    try src.link(appsink.asElement());

    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    while (bus.timedPop(gst.clock.TIME_NONE)) |message| {
        defer message.deinit();
        switch (message.getType()) {
            .eos => {
                std.debug.print("End of stream\n", .{});
                break;
            },
            .err => {
                _ = message.parseErrorAndPrint() catch {
                    std.debug.print("Unknown error\n", .{});
                };
                break;
            },
            else => {},
        }
    }

    _ = pipeline.setState(.null_state);
}

pub fn main() !void {
    try gst.macosMainSimple(run);
}
