pub const core = @import("gst/core.zig");
pub const element = @import("gst/Element.zig");

// Expose GLib as a separate "namespace"
pub const glib = @import("glib/glib.zig");

// Expose the C bindings for advanced usage
pub const c = core.c;
pub const pipeline = @import("gst/Pipeline.zig");
pub const bin = @import("gst/Bin.zig");
pub const caps = @import("gst/Caps.zig");
pub const errors = @import("gst/errors.zig");
pub const bus = @import("gst/Bus.zig");
pub const message = @import("gst/Message.zig");
pub const properties = @import("gst/properties.zig");
pub const sample = @import("gst/Sample.zig");
pub const buffer = @import("gst/Buffer.zig");
pub const pad = @import("gst/Pad.zig");
pub const stream = @import("gst/Stream.zig");
pub const clock = @import("gst/Clock.zig");

/// App
pub const appsink = @import("gst/app/AppSink.zig");
pub const appsrc = @import("gst/app/AppSrc.zig");

pub const GstElement = core.GstElement;
pub const Element = element.Element;
pub const UriType = element.UriType;

pub const GstPipeline = core.GstPipeline;
pub const Pipeline = pipeline.Pipeline;

pub const GstBin = bin.GstBin;
pub const Bin = bin.Bin;

pub const Bus = bus.Bus;
pub const Message = message.Message;
pub const Caps = caps.Caps;
pub const CapsBuilder = caps.CapsBuilder;
pub const Fraction = caps.Fraction;
pub const Pad = pad.Pad;
pub const Stream = stream.Stream;
pub const StreamCollection = stream.StreamCollection;
pub const Clock = @import("gst/clock.zig").Clock;

pub const AppSink = appsink.AppSink;
pub const AppSrc = appsrc.AppSrc;
pub const Sample = sample.Sample;
pub const Buffer = buffer.Buffer;

pub const State = core.State;
pub const StateChangeReturn = core.StateChangeReturn;
pub const GetStateResult = Element.GetStateResult;

pub const GStreamerError = errors.GStreamerError;

pub const Version = core.Version;

// Time constants (all in nanoseconds)
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

// Utility functions
pub const objectUnref = core.objectUnref;

pub const macosMain = core.macosMain;
pub const macosMainSimple = core.macosMainSimple;

// Video
pub const video = @import("gst/video/video.zig");
pub const videoinfo = @import("gst/video/VideoInfo.zig");
pub const videoformat = @import("gst/video/VideoFormat.zig");
pub const videoformatinfo = @import("gst/video/VideoFormatInfo.zig");
pub const videoframe = @import("gst/video/VideoFrame.zig");

pub const VideoInfo = videoinfo.VideoInfo;
pub const VideoFormat = videoformat.VideoFormat;
pub const VideoFormatInfo = videoformatinfo.VideoFormatInfo;
pub const VideoFrame = videoframe.VideoFrame;
pub const VideoFrameFlags = videoframe.VideoFrameFlags;
