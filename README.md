# gstreamer-zig
Zig bindings for GStreamer

🚧 Under construction 🚧

## Prerequisites

This bindings requires GStreamer development packages to be installed on your system. [Official installation instructions](https://gstreamer.freedesktop.org/documentation/installing/index.html)

## Get started example
```zig
const std = @import("std");
const gst = @import("gst");
const glib = gst.glib;

var main_loop: ?glib.MainLoop = null;

pub fn main() !void {
    try gst.init_check(null);
    defer gst.deinit();

    main_loop = try glib.MainLoop.init(null, false);
    defer if (main_loop) |loop| loop.deinit();

    const pipeline = try gst.Pipeline.initLaunch("videotestsrc ! autovideosink");
    defer pipeline.deinit();

    const bus = try pipeline.getBus();
    defer bus.deinit();

    const watch_id = try bus.addWatch(struct {
        fn watcher(msg: gst.Message) bool {
            switch (msg.getType()) {
                .err => {
                    _ = msg.parseErrorAndPrint() catch {
                        std.debug.print("Failed to parse error message\n", .{});
                    };
                    main_loop.?.quit();
                    return false;
                },
                .eos => {
                    std.debug.print("End of stream reached\n", .{});
                    main_loop.?.quit();
                    return false;
                },
                .state_changed => {
                    std.debug.print("State changed\n", .{});
                    return true;
                },
                else => {
                    std.debug.print("Got message type: {}\n", .{msg.getType()});
                    return true;
                },
            }
        }
    }.watcher);
    std.debug.print("Added bus watch with ID: {}\n", .{watch_id});

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    main_loop.?.run();

    std.debug.print("Main loop finished\n", .{});
}
```

## Usage

Add as a dependency in your `build.zig.zon`:
```zig
.dependencies = .{
    .gstreamer = .{
        .url = "https://github.com/your-username/gstreamer-zig/archive/main.tar.gz",
        // Add the hash after first fetch
    },
},
```

In your `build.zig`:
```zig
const gstreamer = b.dependency("gstreamer_zig", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("gstreamer", gstreamer_zig.module("gstreamer"));

exe.linkLibC();
exe.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
```

