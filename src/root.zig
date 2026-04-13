pub const core = @import("gst/core.zig");
pub const errors = @import("gst/errors.zig");

// Expose GLib as a separate "namespace"
pub const glib = @import("glib/glib.zig");

// Expose the C bindings for advanced usage
pub const c = core.c;

// Module namespaces (for accessing module-level functions and multiple exports)
pub const caps = @import("gst/Caps.zig");
pub const stream = @import("gst/Stream.zig");
pub const fraction = @import("gst/Fraction.zig");
pub const clock = @import("gst/Clock.zig");

// Primary types - imported directly for convenience
const element = @import("gst/Element.zig");
pub const Element = element.Element;
pub const UriType = element.UriType;

pub const Pipeline = @import("gst/Pipeline.zig").Pipeline;
pub const Bin = @import("gst/Bin.zig").Bin;
pub const Bus = @import("gst/Bus.zig").Bus;
pub const Message = @import("gst/Message.zig").Message;
pub const Structure = @import("gst/Structure.zig").Structure;
pub const Caps = caps.Caps;
pub const CapsBuilder = caps.CapsBuilder;
pub const Fraction = fraction.Fraction;
const pad = @import("gst/Pad.zig");
pub const Pad = pad.Pad;
pub const PadProbeType = pad.PadProbeType;
pub const PadProbeReturn = pad.PadProbeReturn;
pub const PadProbeInfo = pad.PadProbeInfo;
pub const Event = pad.Event;
pub const EventType = pad.EventType;
pub const Stream = stream.Stream;
pub const StreamCollection = stream.StreamCollection;
pub const Clock = clock.Clock;
pub const Sample = @import("gst/Sample.zig").Sample;
pub const Buffer = @import("gst/Buffer.zig").Buffer;

// App plugin (libgstapp-1.0)
pub const AppSink = @import("gst/app/AppSink.zig").AppSink;
pub const AppSrc = @import("gst/app/AppSrc.zig").AppSrc;

// Video plugin (libgstreamer-video-1.0)
const video = @import("gst/video/video.zig");
pub const VideoInfo = video.VideoInfo;
pub const VideoFormat = video.VideoFormat;
pub const VideoFormatInfo = video.VideoFormatInfo;
pub const VideoFrame = video.VideoFrame;
pub const VideoFrameFlags = video.VideoFrameFlags;

// Core types - tags, datetime
pub const Tag = @import("gst/Tag.zig").Tag;
pub const TagList = @import("gst/TagList.zig").TagList;
pub const DateTime = @import("gst/DateTime.zig").DateTime;

// pbutils (libgstreamer-pbutils-1.0)
const pbutils = @import("gst/pbutils/pbutils.zig");
pub const Discoverer = pbutils.Discoverer;
pub const DiscovererInfo = pbutils.DiscovererInfo;
pub const DiscovererResult = pbutils.DiscovererResult;
pub const DiscovererStreamInfo = pbutils.DiscovererStreamInfo;

pub const ClockTime = clock.ClockTime;
pub const State = core.State;
pub const StateChangeReturn = core.StateChangeReturn;
pub const GetStateResult = Element.GetStateResult;

pub const GStreamerError = errors.GStreamerError;

pub const Version = core.Version;

// Time constants
pub const SECOND = core.SECOND;
pub const MSECOND = core.MSECOND;
pub const USECOND = core.USECOND;
pub const NSECOND = core.NSECOND;

// Core functions
pub const init = core.init;
pub const init_check = core.init_check;
pub const deinit = core.deinit;
pub const version = core.version;
pub const versionString = core.versionString;

// Element functions
pub const getState = Element.getState;
pub const setProperty = Element.setProperty;
pub const link = Element.link;

// Bus functions
pub const busTimedPopFiltered = Bus.popMessage;
pub const messageGetType = Message.getType;
pub const parseError = Message.parseErrorAndPrint;

// Memory functions
pub const objectUnref = core.objectUnref;

pub const macosMain = core.macosMain;
pub const macosMainSimple = core.macosMainSimple;