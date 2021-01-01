#pragma once

#include <Python.h>

#ifdef _DEBUG
#   undef Py_InitModule4
#   if PY_VERSION_HEX >= 0x02050000 && SIZEOF_SIZE_T != SIZEOF_INT
#       ifdef _DEBUG
#           define Py_InitModule4 Py_InitModule4TraceRefs_64
#       else
#           define Py_InitModule4 Py_InitModule4_64
#       endif
#   endif
#endif

static const char DOCSTRING_HELLO_WORLD_MAYA[] = "Says hello world!";
static const char DOCSTRING_ADD_TO_ACTIVE_SELECTION_LIST[] = "Adds the specified object with the given name to the active selection list.";
static const char DOCSTRING_MAYA_PYTHON_C_EXT[] = "An example Python C extension that makes use of Maya functionality.";

static PyObject* pyHelloWorldMaya(PyObject* module, PyObject* args);
static PyObject* pyAddToActiveSelectionList(PyObject* self, PyObject* args);

// NOTE: Declare the available methods for the module
static PyMethodDef mayaPythonCExtMethods[] = {
    {"hello_world_maya", pyHelloWorldMaya, METH_VARARGS, DOCSTRING_HELLO_WORLD_MAYA},
    {"add_to_active_selection_list", pyAddToActiveSelectionList, METH_VARARGS, DOCSTRING_ADD_TO_ACTIVE_SELECTION_LIST},
    {NULL, NULL, 0, NULL}   // NOTE: Sentinel value for Python
};
