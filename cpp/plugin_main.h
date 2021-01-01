#pragma once

#include <limits.h>
#include <stdio.h>

enum MayaPythonCExtStatus {
    UNKNOWN_FAILURE = -1,
    NODE_DOES_NOT_EXIST = -2,
    UNABLE_TO_GET_ACTIVE_SELECTION = -3,
    UNABLE_TO_SET_ACTIVE_SELECTION = -4,
    UNABLE_TO_MERGE_SELECTION_LISTS = -5,
    SUCCESS = 0
};

// Here's how we'll expose members of this Maya plug-in to the Python module
// This is a (preferable) alternative to passing `/export <member>` to the linker
//
// We'll need extern "C" to avoid name mangling
// See dumpbin.exe /EXPORTS maya_python_c_ext.mll
#ifdef _WIN32
#   ifdef PLUGIN_EXPORTS
#       define DLLEXTERN extern "C" __declspec(dllexport)
#   else
#       define DLLEXTERN extern "C" __declspec(dllimport)
#   endif

// Linux doesn't use __declspec
#else
#   define DLLEXTERN extern "C"
#endif

namespace Plugin {
DLLEXTERN void                 displayInfo(const char* text);
DLLEXTERN void                 displayWarning(const char* text);
DLLEXTERN void                 displayError(const char* text);
DLLEXTERN void                 helloWorldMaya();
DLLEXTERN MayaPythonCExtStatus addToActiveSelectionList(const char* name);
} // Plugin