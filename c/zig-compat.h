#ifndef GSTREAMER_SHIM_H
#define GSTREAMER_SHIM_H

// Prevent the ghook.h header from defining GHookList  
#define __G_HOOK_H__

// Define our opaque pointer version
typedef void *GHookList;

// Include the actual headers
#include <gst/gst.h>
#include <glib.h>
#include <glib-object.h>

#endif
