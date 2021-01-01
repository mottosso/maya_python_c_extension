/**
 * Original Maya plug-in from which to expose members to the Python binding
 *
 */

// Tell plugin_main to export members when this cpp is built
#define PLUGIN_EXPORTS

#include "plugin_main.h"

#include <maya/MGlobal.h>
#include <maya/MSelectionList.h>
#include <maya/MFnPlugin.h>

const char* kAUTHOR = "mottosso";
const char* kVERSION = "1.0.0";
const char* kREQUIRED_API_VERSION = "Any";
const char* kHELLOWORLD = "Original Hello world from the Maya Python C extension!";

// Make it obvious where calls are coming from to anyone external
namespace Plugin {


// Avoid external callers having to including anything from the Maya API
void displayInfo(const char* text) { return MGlobal::displayInfo(text); }
void displayWarning(const char* text) { return MGlobal::displayWarning(text); }
void displayError(const char* text) { return MGlobal::displayError(text); }


// A function we can modify from within the plug-in itself
void helloWorldMaya() {
    return displayInfo(kHELLOWORLD);
}


MayaPythonCExtStatus addToActiveSelectionList(const char* name) {
    MStatus stat;

    MSelectionList objList;
    stat = objList.add(name);
    if (!stat) {
        return MayaPythonCExtStatus::NODE_DOES_NOT_EXIST;
    }

    MSelectionList activeSelList;
    stat = MGlobal::getActiveSelectionList(activeSelList, true);
    if (!stat) {
        return MayaPythonCExtStatus::UNABLE_TO_GET_ACTIVE_SELECTION;
    }

    stat = activeSelList.merge(objList);
    if (!stat) {
        return MayaPythonCExtStatus::UNABLE_TO_MERGE_SELECTION_LISTS;
    }

    stat = MGlobal::setActiveSelectionList(activeSelList);
    if (!stat) {
        return MayaPythonCExtStatus::UNABLE_TO_SET_ACTIVE_SELECTION;
    }

    return MayaPythonCExtStatus::SUCCESS;
}

} // namespace "Plugin"


// These need to be in the ::root namespace for Maya to see
MStatus initializePlugin(MObject obj) {
    MFnPlugin plugin(obj, kAUTHOR, kVERSION, kREQUIRED_API_VERSION);

    // Let's change kHELLOWORLD locally, and have our Python bindings
    // reference it. Python should see the same modified string once
    // the plug-in has been loaded, but not until then.
    kHELLOWORLD = "Modified Hello world!";

    MStatus stat { MStatus::kSuccess };

    return stat;
}


MStatus uninitializePlugin(MObject obj) {
    MStatus status;

    return status;
}
