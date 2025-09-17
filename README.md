# gstreamer-zig
Zig bindings for GStreamer multimedia framework

## Prerequisites

This library requires GStreamer development packages to be installed on your system.

### macOS (Homebrew)
```bash
brew install gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
```

**For development/LSP support**, set the pkg-config path:
```bash
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### macOS (GStreamer.framework)
Download and install the GStreamer framework from [gstreamer.freedesktop.org](https://gstreamer.freedesktop.org/download/)

**For development/LSP support**:
```bash
export PKG_CONFIG_PATH="/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### Linux (Ubuntu/Debian)
```bash
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

### Linux (Fedora/RHEL)
```bash
sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel
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
const gstreamer = b.dependency("gstreamer", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("gstreamer", gstreamer.module("gstreamer"));
```

## Building

```bash
zig build
```


