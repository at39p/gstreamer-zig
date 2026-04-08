pub const c_pbutils = @cImport({
    @cInclude("gst/pbutils/pbutils.h");
});

pub const Discoverer = @import("Discoverer.zig").Discoverer;
pub const DiscovererInfo = @import("DiscovererInfo.zig").DiscovererInfo;
pub const DiscovererResult = @import("DiscovererInfo.zig").DiscovererResult;
pub const DiscovererVideoInfo = @import("DiscovererVideoInfo.zig").DiscovererVideoInfo;
pub const DiscovererAudioInfo = @import("DiscovererAudioInfo.zig").DiscovererAudioInfo;
pub const DiscovererStreamInfo = @import("DiscovererStreamInfo.zig").DiscovererStreamInfo;
