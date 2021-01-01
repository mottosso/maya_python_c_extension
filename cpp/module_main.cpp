#include "module_main.h"
#include "plugin_main.h"


static PyObject* pyHelloWorldMaya(PyObject* module, PyObject* args) {
    const char* inputString;
    if (!PyArg_ParseTuple(args, "s", &inputString)) {
        return nullptr;
    }

    PyGILState_STATE pyGILState = PyGILState_Ensure();

    Plugin::helloWorldMaya();

    Plugin::displayInfo(inputString);

    PyObject* result = Py_BuildValue("s", inputString);

    PyGILState_Release(pyGILState);

    return result;
}


static PyObject* pyAddToActiveSelectionList(PyObject* self, PyObject* args) {
    const char* nodeName;
    if (!PyArg_ParseTuple(args, "s", &nodeName)) {
        return nullptr;
    }

    PyGILState_STATE pyGILState = PyGILState_Ensure();

    Plugin::displayInfo(nodeName);

    MayaPythonCExtStatus status = Plugin::addToActiveSelectionList(nodeName);

    if (status != MayaPythonCExtStatus::SUCCESS) {
        Plugin::displayError("An error occurred!");
    }

    // NOTE: Convert enum (short) to a Python int
    PyObject* result = Py_BuildValue("h", status);

    PyGILState_Release(pyGILState);

    return result;
}


PyMODINIT_FUNC initmaya_python_c_ext() {
    PyObject* module = Py_InitModule3("maya_python_c_ext",
                                      mayaPythonCExtMethods,
                                      DOCSTRING_MAYA_PYTHON_C_EXT);
    if (module == nullptr) {
        return;
    }
}
