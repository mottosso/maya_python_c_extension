![image](https://user-images.githubusercontent.com/2152766/103206302-78733100-48f3-11eb-9b2c-d69d1f63ba98.png)

### Maya Python C++ Extension Example

An alternative verison of [sonictk's version](https://github.com/sonictk/maya_python_c_extension)..

| mottosso | sonictk
|:---------|:-------
| Builds with (and only with) Maya 2020[\*](#maya-2020) | Maya 2016-2018
| One `.cpp` per translation unit and short filenames | Lots of `.cpp` and long file names
| Regular build | [Unity build](https://en.wikipedia.org/wiki/Unity_build)
| 80-character width for `.bat` and `.sh` | Unlimited length
| Links to `libpython2.7.so` on Linux | Links to system-wide Python
| `.mll` includes Maya API, `.pyd` does not | Both include the Maya API
| `.pyd` links `.mll` | `.mll` links `.pyd`
| Bindings to plug-in, which calls Maya C++ API | Bindings to Maya C++ API, with optional plug-in

That last two bits are most important. The bindings from the upstream project are for the Maya API, with the (optional) Maya plug-in enabling `import maya_python_c_extension` *without* changes to the `PYTHONPATH`.

Thus, this fork consists of two independent dynamic libraries.

- `maya_python_c_extension.mll` implements functions in C++
- `maya_python_c_extension.pyd` exposes functions to Python

<br>

### Goal

Expose members of your C++ Maya plug-in to Python.

For example, your C++ plug-in implements a physics solver that you would like access from Python. Maybe you're adding or removing members to some internal datastructure. Maybe you want tests written in Python rather than C++.

Also, the Python library should not need to `#include <maya/>` in any way. All it needs is the plug-in `.h` and the `.mll` itself, which forwards any requests into the Maya API. This avoid the need to *link* your Python library against the Maya API, which will reduce the size and complexity. But most importantly it means you can create bindings for not just the Maya API but any-sized external library like Boost or USD without turning your `.pyd` into megabytes or gigabytes.

<br>

### Usage

You'll need `c:\Program Files\Autodesk\Maya2020` or `/usr/autodesk/maya2020`.

```bash
cd c:\github
git clone https://github.com/mottosso/maya_python_c_extension.git
cd maya_python_c_extension
.\build.bat  # or ./build.sh
.\test.bat   # or ./test.sh
```

- Optionally, use [`Dockerfile`](https://github.com/mottosso/maya_python_c_extension/blob/master/Dockerfile)

Then from the Maya Script Editor.

```py
import os, sys

# Change me maybe
builddir = r"c:\github\maya_python_c_ext\msbuild"

os.environ["MAYA_PLUG_IN_PATH"] = builddir  # Expose .mll
sys.path.insert(0, builddir)                # Expose .pyd

from maya import cmds

# Load your original plug-in as usual
cmds.loadPlugin("maya_python_c_ext")

# Then load the Python bindings, the order is not important*
import maya_python_c_ext as ext

cube, _ = cmds.polyCube()
cmds.select(deselect=True)
ext.add_to_active_selection_list(cube)
assert cmds.ls(selection=True)[0] == cube
```

About the order in which the `.mll` and `.pyd` are loaded, this is interesting! As dynamic libraries, they both (most likely) internally load via [`LoadLibrary`](https://docs.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibrarya) which has an interesting mechanic. Much like how Python recycles modules your `import`, `LoadLibrary` returns a reference to any previously loaded dynamic library.

In practice, it means that when the `.pyd` is loaded *after* the `.mll`, then it will be first to read it from disk. When Maya then `cmds.loadPlugin` it won't actually incur another file-read of the `.mll`. Instead, it will be given a reference to the already-loaded `.mll` that Python loaded via `import maya_plugin_c_extension`.

So you see, no matter the order, both libraries are loaded correctly regardless.

With *one* caveat!

```cpp
MStatus initializePlugin(MObject obj);
```

The Maya plug-in defines this, which is called automatically on `cmds.loadPlugin`. Thus, if you never call `cmds.loadPlugin` then this initialisation is never called which in this particular instance means this..

```cpp
const char* kHELLOWORLD = "Original Hello world from the Maya Python C extension!";

MStatus initializePlugin(MObject obj) {
    ...
    kHELLOWORLD = "Modified Hello world!";
    ...
}
```

..never happens. The result?

```py
import maya_python_c_ext as ext
ext.hello_world_maya("Success")
# Original Hello world from the Maya Python C extension!
# Success

from maya import cmds
cmds.loadPlugin("maya_python_c_ext")
ext.hello_world_maya("Success")
# Modified Hello world!
# Success
```

<br>

### Implementation

|      | `maya_python_c_extension.mll` | `maya_python_c_extension.pyd`
|:------------|:------------------------------|:-----------------------------
| **Doc** | Custom Maya plug-in for use by another dynamic library, such as a Python module | Python bindings for exported members of `maya_python_c_extension.mll`
| **Source** | `cpp/plugin_main.cpp`<br>`cpp/plugin_main.h` | `cpp/module_main.cpp`<br>`cpp/module_main.h`
| **Export** | `helloWorldMaya`<br>`addToActiveSelectionList` | `hello_world_maya`<br>`add_to_active_selection_list(name)`

A `.mll` is built (`.so` on Linux) and dynamically linked against a separate `.pyd`.

The `.pyd` exposes internal members of the `.mll` such that they can be accessed from Python. The `.mll` is only loaded once, and is merely referenced from the `.pyd` (rather than re-loaded) such that calls into the `.mll` from Python affect the same data as the `.mll` calling its own members.

Pretty much what you would expect.

##### Maya 2020

Two changes were made for the project to build on 2020 instead of Maya 2016-2019.

- `IMFbase.lib` was [renamed to `adskIMF.lib` in Maya 2020](https://around-the-corner.typepad.com/adn/2020/02/devkit-hotfix-for-maya-2020.html)
- The `/python2.7` directory was renamed `/Python` in Maya 2020

##### Key Takeaways

- On Windows, your `.mll` exports members to Python via `__declspec(dllexport)`
- On Linux, all members are automatically exported always, such is life
- Default C++ name-mangling is avoided via `extern "C"`
- The `.pyd` links against the generated `.lib` file from the `.mll`
- The `.lib` file contains function signatures from `.mll` to `.pyd`, e.g. `void helloWorldMaya()`

##### Example output

Here you can see how name mangling affects functions without `extern "C"`.

```bash
$ dumpbin /EXPORTS .\msbuild\maya_python_c_ext.mll
...
1    0 00001000 ?initializePlugin@@YA?AVMStatus@OpenMaya20200000@Maya@Autodesk@@VMObject@234@@Z
2    1 00001090 ?uninitializePlugin@@YA?AVMStatus@OpenMaya20200000@Maya@Autodesk@@VMObject@234@@Z
3    2 00004020 MApiVersion
4    3 000010D0 addToActiveSelectionList
5    4 000011D0 helloWorldMaya
```

<br>

### References

- [`__declspec(dllexport)`](https://docs.microsoft.com/en-us/cpp/build/exporting-from-a-dll-using-declspec-dllexport?view=msvc-160)
- [`LoadLibrary`](https://docs.microsoft.com/en-us/windows/win32/dlls/using-run-time-dynamic-linking)
- [maddouri/dynalo](https://github.com/maddouri/dynalo) Library for cross-platform `LoadLibrary`