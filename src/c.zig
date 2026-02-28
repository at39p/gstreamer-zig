pub const c = @cImport({
    // Prevent ghook.h from defining GHookList to avoid opaque struct issues
    @cDefine("__G_HOOK_H__", "");
    // Define GHookList as an opaque pointer type that Zig can work with
    @cDefine("GHookList", "void*");

    @cInclude("gst/gst.h");
    @cInclude("gst/app/gstappsrc.h");
    @cInclude("gst/app/gstappsink.h");

    @cInclude("glib.h");
    @cInclude("glib-object.h");
});
