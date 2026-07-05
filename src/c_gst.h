// Prevent ghook.h from defining GHookList to avoid opaque struct issues
#define __G_HOOK_H__
#define GHookList void*

#define G_DEFINE_AUTOPTR_CLEANUP_FUNC(TypeName, func)
#define G_DEFINE_AUTO_CLEANUP_CLEAR_FUNC(TypeName, func)
#define G_DEFINE_AUTO_CLEANUP_FREE_FUNC(TypeName, func, none)

#define GLIB_VERSION_MIN_REQUIRED 150016

#include <gst/gst.h>
#include <gst/app/gstappsrc.h>
#include <gst/app/gstappsink.h>
#include <gst/video/video.h>
#include <gst/pbutils/pbutils.h>
#include <glib.h>
#include <glib-object.h>
