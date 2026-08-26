// This example demonstrates the use of GStreamer's pad probe APIs.
//
// Probes are callbacks that can be installed by the application and will notify
// the application about the states of the dataflow. Those are mostly used for
// changing pipelines dynamically at runtime or for inspecting/modifying buffers or events
//
//                     |-{probe}
//                    /
//    {audiotestsrc} - {fakesink}

const std = @import("std");
const builtin = @import("builtin");
const gst = @import("gst");

// GST_AUDIO_FORMAT_S16 is native-endian.
const AUDIO_FORMAT_S16 = if (builtin.cpu.arch.endian() == .little) "S16LE" else "S16BE";

// This handler gets called for every buffer that passes the pad we probe.
fn probeBuffer(_: gst.Pad, info: gst.PadProbeInfo) gst.PadProbeReturn {
    // Interpret the data sent over the pad as one buffer
    const buffer = info.getBuffer() orelse return .ok;

    // At this point, buffer is only a reference to an existing memory region somewhere.
    // When we want to access its content, we have to map it while requesting the required
    // mode of access (read, read/write).
    // This type of abstraction is necessary, because the buffer in question might not be
    // on the machine's main memory itself, but rather in the GPU's memory.
    // So mapping the buffer makes the underlying memory region accessible to us.
    // See: https://gstreamer.freedesktop.org/documentation/plugin-development/advanced/allocation.html
    var map = buffer.mapRead() orelse return .ok;
    defer map.deinit();

    // We know what format the data in the memory region has, since we requested
    // it by setting the fakesink's caps. So what we do here is interpret the
    // memory region we mapped as an array of signed 16 bit integers.
    const samples = std.mem.bytesAsSlice(i16, map.data[0..map.size]);

    // For buffer (= chunk of samples), we calculate the root mean square:
    var sum: f64 = 0;
    for (samples) |sample| {
        const f = @as(f64, @floatFromInt(sample)) / @as(f64, @floatFromInt(std.math.maxInt(i16)));
        sum += f * f;
    }
    const rms = @sqrt(sum / @as(f64, @floatFromInt(samples.len)));
    std.debug.print("rms: {d}\n", .{rms});

    return .ok;
}

fn run() !void {
    gst.init(null);
    defer gst.deinit();

    // Parse the pipeline we want to probe from a static in-line string.
    // Here we give our audiotestsrc a name, so we can retrieve that element
    // from the resulting pipeline.
    const pipeline = try gst.Pipeline.initLaunch(
        "audiotestsrc name=src ! audio/x-raw,format=" ++ AUDIO_FORMAT_S16 ++ ",channels=1 ! fakesink",
    );
    defer pipeline.deinit();

    // Get the audiotestsrc element from the pipeline that GStreamer
    // created for us while parsing the launch syntax above.
    const src = pipeline.getByName("src") orelse return error.ElementNotFound;
    defer src.deinit();
    // Get the audiotestsrc's src-pad.
    const src_pad = src.getStaticPad("src") orelse return error.PadNotFound;
    defer src_pad.deinit();
    // Add a probe handler on the audiotestsrc's src-pad.
    _ = src_pad.addProbe(gst.PadProbeType.buffer, probeBuffer, null);

    try pipeline.start();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    while (bus.timedPop(gst.clock.TIME_NONE)) |message| {
        defer message.deinit();
        switch (message.getType()) {
            .eos => break,
            .err => {
                message.parseErrorAndPrint() catch {
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
    try gst.macosMainSimple(run, null);
}
