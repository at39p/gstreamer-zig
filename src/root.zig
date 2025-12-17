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
pub const Caps = caps.Caps;
pub const CapsBuilder = caps.CapsBuilder;
pub const Fraction = fraction.Fraction;
pub const Pad = @import("gst/Pad.zig").Pad;
pub const Stream = stream.Stream;
pub const StreamCollection = stream.StreamCollection;
pub const Clock = clock.Clock;
pub const Sample = @import("gst/Sample.zig").Sample;
pub const Buffer = @import("gst/Buffer.zig").Buffer;

// App types
pub const AppSink = @import("gst/app/AppSink.zig").AppSink;
pub const AppSrc = @import("gst/app/AppSrc.zig").AppSrc;

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

// Video namespace and types
pub const video = @import("gst/video/video.zig");
pub const videoframe = @import("gst/video/VideoFrame.zig");

pub const VideoInfo = @import("gst/video/VideoInfo.zig").VideoInfo;
pub const VideoFormat = @import("gst/video/VideoFormat.zig").VideoFormat;
pub const VideoFormatInfo = @import("gst/video/VideoFormatInfo.zig").VideoFormatInfo;
pub const VideoFrame = videoframe.VideoFrame;
pub const VideoFrameFlags = videoframe.VideoFrameFlags;
