const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Option to specify custom PKG_CONFIG_PATH
    const pkg_config_path = b.option([]const u8, "pkg_config_path", "Custom PKG_CONFIG_PATH for GStreamer");

    _ = b.addModule("gstreamer", .{
        .root_source_file = b.path("src/gstreamer.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "gstreamer-zig",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gstreamer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Set PKG_CONFIG_PATH if provided
    if (pkg_config_path) |path| {
        var arena = std.heap.ArenaAllocator.init(b.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var env_map = std.process.getEnvMap(allocator) catch |err| {
            std.debug.panic("Failed to get environment: {}", .{err});
        };
        env_map.put("PKG_CONFIG_PATH", path) catch |err| {
            std.debug.panic("Failed to set PKG_CONFIG_PATH: {}", .{err});
        };
    }

    lib.linkLibC();
    lib.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary2("glib-2.0", .{ .use_pkg_config = .force });
    lib.linkSystemLibrary2("gobject-2.0", .{ .use_pkg_config = .force });

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gstreamer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib_unit_tests.linkLibC();
    lib_unit_tests.linkSystemLibrary2("gstreamer-1.0", .{ .use_pkg_config = .force });
    lib_unit_tests.linkSystemLibrary2("glib-2.0", .{ .use_pkg_config = .force });
    lib_unit_tests.linkSystemLibrary2("gobject-2.0", .{ .use_pkg_config = .force });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
