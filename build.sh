#!/usr/bin/env bash

# This is the GCC build script for the Maya example Python C extension.
# usage: build.sh [debug|release]
echo "This is it"

StartTime=`date +%T`;
echo "Build script started executing at ${StartTime}...";

# Process command line arguments
BuildType=$1;

if [ "$BuildType" == "" ]; then
    BuildType="release";
fi;


# Define colours to be used for terminal output messages
RED='\033[0;31m';
GREEN='\033[0;32m';
NC='\033[0m'; # No Color

# Create a build directory to store artifacts
BuildDir="${PWD}/linuxbuild";
echo "Building in directory: $BuildDir";
if [ ! -d "$BuildDir" ]; then
   mkdir -p "$BuildDir";
fi;

# Set up globals
MayaRootDir="/usr/autodesk/maya2020";
MayaIncludeDir="$MayaRootDir/include";
MayaLibraryDir="$MayaRootDir/lib";

ProjectName="maya_python_c_ext";

MayaPluginEntryPoint="${PWD}/cpp/plugin_main.cpp";
PythonModuleEntryPoint="${PWD}/cpp/module_main.cpp";

MayaPluginExtension="so";
PythonModuleExtension="${MayaPluginExtension}";

# Setup all the compiler flags
CommonCompilerFlags="-DBits64_ \
                     -m64 \
                     -DUNIX \
                     -D_BOOL \
                     -DLINUX \
                     -DFUNCPROTO \
                     -D_GNU_SOURCE \
                     -DLINUX_64 \
                     -fPIC \
                     -fno-strict-aliasing \
                     -DREQUIRE_IOSTREAM \
                     -Wall \
                     -std=c++11 \
                     -Wno-multichar \
                     -Wno-comment \
                     -Wno-sign-compare \
                     -funsigned-char \
                     -pthread \
                     -Wno-deprecated \
                     -Wno-reorder \
                     -ftemplate-depth-25 \
                     -fno-gnu-keywords \
                     -I${MayaIncludeDir} \
                     -I${MayaIncludeDir}/Python";

CommonCompilerFlagsDebug="-ggdb -O0 ${CommonCompilerFlags}";
CommonCompilerFlagsRelease="-O3 ${CommonCompilerFlags}";

MayaPluginIntermediateObject="${BuildDir}/${ProjectName}_plugin_main.o";
PythonModuleIntermediateObject="${BuildDir}/${ProjectName}_py_mod_main.o";

# As per the Maya official Makefile:
# -Bsymbolic binds references to global symbols within the library.
# This avoids symbol clashes in other shared libraries but forces
# the linking of all required libraries.
CommonLinkerFlags="-Bsymbolic \
                   -shared \
                   -lm \
                   -ldl \
                   -lstdc++ \
                   ${MayaLibraryDir}/libOpenMaya.so \
                   ${MayaLibraryDir}/libFoundation.so \
                   ${MayaLibraryDir}/libclew.so \
                   ${MayaLibraryDir}/libImage.so \
                   ${MayaLibraryDir}/libadskIMF.so";

MayaPluginLinkerFlags="-o ${BuildDir}/${ProjectName}_plugin.${MayaPluginExtension} \
                       ${MayaPluginIntermediateObject}";
PythonModuleLinkerFlags="${MayaLibraryDir}/libpython2.7.so \
                         -o ${BuildDir}/${ProjectName}.${PythonModuleExtension} \
                         ${PythonModuleIntermediateObject}";

#
# Here's where the MAGIC happens
#
PythonModuleLinkerFlags="${PythonModuleLinkerFlags} \
                         ${BuildDir}/${ProjectName}_plugin.${MayaPluginExtension}";

# Namely, the plug-in is linked to the Python module, so as to expose exported members

if [ "$BuildType" == "debug" ]; then
    echo "Building in debug mode...";

    MayaPluginCompilerFlags="${CommonCompilerFlagsDebug} \
                             -c ${MayaPluginEntryPoint} \
                             -o ${MayaPluginIntermediateObject}";
    MayaPluginLinkerFlags="${CommonLinkerFlags} -ggdb -O0 \
                           ${MayaPluginLinkerFlags}";

    PythonModuleCompilerFlags="${CommonCompilerFlagsDebug} \
                               -c ${PythonModuleEntryPoint} \
                               -o ${PythonModuleIntermediateObject}";
    PythonModuleLinkerFlags="${CommonLinkerFlags} -ggdb -O0 \
                             ${PythonModuleLinkerFlags}";
else
    echo "Building in release mode...";

    MayaPluginCompilerFlags="${CommonCompilerFlagsRelease} \
                             -c ${MayaPluginEntryPoint} \
                             -o ${MayaPluginIntermediateObject}";
    MayaPluginLinkerFlags="${CommonLinkerFlags} -O3 \
                           ${MayaPluginLinkerFlags}";

    PythonModuleCompilerFlags="${CommonCompilerFlagsRelease} \
                               -c ${PythonModuleEntryPoint} \
                               -o ${PythonModuleIntermediateObject}";
    PythonModuleLinkerFlags="${CommonLinkerFlags} -O3 \
                             ${PythonModuleLinkerFlags}";
fi;

function error() {
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*                                     *${NC}";
    echo -e "${RED}*      !!! An error occurred !!!      *${NC}";
    echo -e "${RED}*                                     *${NC}";
    echo -e "${RED}***************************************${NC}";
}

echo "Compiling Maya plugin (command follows)...";
echo "g++ ${MayaPluginCompilerFlags}";
echo "";

g++ ${MayaPluginCompilerFlags};

if [ $? -ne 0 ]; then
    error;
    exit 1;
fi;

echo "Linking (command follows)...";
echo "g++ ${MayaPluginLinkerFlags}";
echo "";

g++ -v ${MayaPluginLinkerFlags};

if [ $? -ne 0 ]; then
    error;
    exit 2;
fi;

echo "Compiling Python module (command follows)...";
echo "g++ ${PythonModuleCompilerFlags}";
echo "";

g++ ${PythonModuleCompilerFlags};

if [ $? -ne 0 ]; then
    error;
    exit 3;
fi;

echo "Linking Python module (command follows)...";
echo "g++ ${PythonModuleLinkerFlags}";
echo "";

g++ -v ${PythonModuleLinkerFlags};

if [ $? -ne 0 ]; then
    error;
    exit 4;
fi;

EndTime=`date +%T`;

echo -e "${GREEN}***************************************${NC}";
echo -e "${GREEN}*                                     *${NC}";
echo -e "${GREEN}*    Build completed successfully!    *${NC}";
echo -e "${GREEN}*                                     *${NC}";
echo -e "${GREEN}***************************************${NC}";

echo "Build script finished execution at ${EndTime}.";

exit 0;
