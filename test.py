import os
import sys

from maya import standalone
standalone.initialize()

dirname = os.path.abspath(os.path.dirname(__file__))
builddir = os.path.join(dirname, "msbuild")

os.environ["MAYA_PLUG_IN_PATH"] = builddir  # Expose .mll
sys.path.insert(0, builddir)                # Expose .pyd

import maya_python_c_ext as ext
ext.hello_world_maya("Success")
# Original Hello world from the Maya Python C extension!
# Success

from maya import cmds
cmds.loadPlugin("maya_python_c_ext")
ext.hello_world_maya("Success")
# Modified Hello world!
# Success

# Note the different outputs, that's because the plug-in
# initialisation modifies the string printed by the function

#
# Now test the Maya API access
#

cube, _ = cmds.polyCube()
sphere, _ = cmds.polySphere()
cmds.select(deselect=True)
ext.add_to_active_selection_list(cube)
print("Selected: %s" % cmds.ls(sl=True))
# Selected: [u'polyCube1']

cmds.unloadPlugin("maya_python_c_ext")
cmds.loadPlugin("maya_python_c_ext")

ext.hello_world_maya("I was also able to unload and reload the module")

# Quit mayapy ourselves, as it'll otherwise segfault because it's a dick
os._exit(0)
