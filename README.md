<div align="center">

# gstreamer-zig

**Idiomatic Zig bindings for the [GStreamer](https://gstreamer.freedesktop.org/) multimedia framework**

[![Zig](https://img.shields.io/badge/Zig-0.16.0+-F7A41D?logo=zig&logoColor=white)](https://ziglang.org)
[![GStreamer](https://img.shields.io/badge/GStreamer-1.x-00CC00?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJDNi40OCAyIDIgNi40OCAyIDEyczQuNDggMTAgMTAgMTAgMTAtNC40OCAxMC0xMFMxNy41MiAyIDEyIDJ6IiBmaWxsPSIjZmZmIi8+PC9zdmc+)](https://gstreamer.freedesktop.org/)
[![Status](https://img.shields.io/badge/status-under_development-orange)](#status)

Build multimedia pipelines -- video processing, audio analysis, streaming, transcoding -- with type-safe Zig wrappers around GStreamer's C API.

[Getting Started](#getting-started) | [Examples](#examples) | [API Overview](#api-overview) | [Contributing](#contributing)

</div>

---

## Status

> **Under active development (v0.1.0)** -- The API surface is growing but not yet stable. Contributions and bug reports are welcome.

Currently tested on **macOS**. Linux support is available but not tested.

## Getting Started

### Prerequisites

GStreamer development packages must be installed on your system.

<details>
<summary><b>macOS</b> (Homebrew)</summary>

```sh
brew install gstreamer
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
```

</details>

<details>
<summary><b>Linux</b> (apt)</summary>

```sh
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good
```

</details>

For other platforms, see the [official GStreamer installation guide](https://gstreamer.freedesktop.org/documentation/installing/index.html).

### Add to your project

**`build.zig.zon`**
```zig
.dependencies = .{
    .gstreamer_zig = .{
        .url = "https://github.com/at39p/gstreamer-zig/archive/main.tar.gz",
        // Run `zig build` once -- the compiler will tell you the correct hash
    },
},
```

**`build.zig`**
```zig
const gstreamer_dep = b.dependency("gstreamer_zig", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("gst", gstreamer_dep.module("gstreamer"));

exe.linkLibC();
exe.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
```

### Hello Pipeline

```zig
const std = @import("std");
const gst = @import("gst");

pub fn main() !void {
    gst.init(null);
    defer gst.deinit();

    const pipeline = try gst.Pipeline.initLaunch("videotestsrc ! autovideosink");
    defer pipeline.deinit();

    try pipeline.start();
    defer _ = pipeline.setState(.null_state);

    const bus = try pipeline.getBus();
    defer bus.deinit();

    while (bus.timedPop(gst.clock.TIME_NONE)) |msg| {
        defer msg.deinit();
        switch (msg.getType()) {
            .eos => break,
            .err => {
                _ = msg.parseErrorAndPrint() catch {};
                break;
            },
            else => {},
        }
    }
}
```

## Examples

The repository includes runnable examples that demonstrate different parts of the API:

| Example | Command | Description |
|---------|---------|-------------|
| **launch** | `zig build run-launch -- "pipeline string"` | Parse and run any `gst-launch`-style pipeline |
| **appsrc** | `zig build run-appsrc` | Generate video frames programmatically with `AppSrc` |
| **appsink** | `zig build run-appsink` | Pull audio samples and compute RMS amplitude with `AppSink` |
| **decodebin** | `zig build run-decodebin -- file.mp4` | Auto-detect and decode audio/video with dynamic pad linking |
| **bins** | `zig build run-bins` | Group elements into `Bin` containers |
| **custom-events** | `zig build run-custom-events` | Send custom downstream events with pad probes |
| **srt-transmuxer** | `zig build run-srt` | SRT receive -> MPEG-TS demux -> RTP output |

## API Overview

### Core

| Type | Purpose |
|------|---------|
| `gst.Pipeline` | Top-level pipeline container. Create from code or parse `gst-launch` syntax |
| `gst.Element` | Individual processing node. Create by factory name or URI |
| `gst.Bin` | Generic container for grouping elements |
| `gst.Bus` | Message bus for async notifications (errors, EOS, state changes) |
| `gst.Pad` | Element connection points with probe support |
| `gst.Caps` / `CapsBuilder` | Media type capabilities and negotiation |
| `gst.Structure` | Key-value metadata with typed getters/setters |
| `gst.Buffer` | Data buffer with PTS/DTS timestamps and map/unmap |
| `gst.Sample` | Buffer + caps + segment bundle |
| `gst.Event` | Pipeline events (EOS, flush, seek, custom) |
| `gst.Message` | Bus messages with type-safe parsing |
| `gst.Clock` | Pipeline clock access |

### App

| Type | Purpose |
|------|---------|
| `gst.AppSrc` | Push data into a pipeline programmatically |
| `gst.AppSink` | Pull processed data out of a pipeline |

### Video

| Type | Purpose |
|------|---------|
| `gst.VideoInfo` | Video format, resolution, framerate metadata |
| `gst.VideoFormat` | 80+ pixel format definitions (I420, NV12, RGBA, ...) |
| `gst.VideoFrame` | Map buffers to access pixel data by plane/component |
| `gst.VideoTimeCode` | SMPTE timecode with arithmetic and `std.fmt` support |

### GLib

| Type | Purpose |
|------|---------|
| `gst.glib.MainLoop` | GLib main event loop |
| `gst.glib.DateTime` | Date/time with ISO 8601 formatting |

### Raw C Access

For anything not yet wrapped, access the raw GStreamer C API directly:

```zig
const raw_element = gst.c.gst_element_factory_make("customsrc", "my-source");
```

## Building from source

```sh
git clone https://github.com/at39p/gstreamer-zig.git
cd gstreamer-zig
zig build
```

Run any example:

```sh
zig build run-launch -- "videotestsrc ! autovideosink"
zig build run-appsrc
zig build run-decodebin -- /path/to/file.mp4
```

For non-standard GStreamer installations, pass the pkg-config path:

```sh
zig build -Dpkg_config_path=/opt/gstreamer/lib/pkgconfig
```

## Contributing

Contributions are welcome. The project is in early stages and there's plenty to do:

- Wrapping more GStreamer API surface
- Adding tests
- Linux and Windows testing
- Documentation and examples

## License

See the repository for license information.
