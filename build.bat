@echo off
:: This is the Windows build script for the Maya example Python C extension.
:: usage: build.bat [debug|release]
:: e.g. build.bat
::      build.bat debug

echo ***************************************
echo *
echo * Build script started at %time%

:: Process command line arguments
set BuildType=%1
if "%BuildType%"=="" (set BuildType=release)

:: Make a build directory to store artifacts; remember, %~dp0 is just a special
:: FOR variable reference in Windows that specifies the current directory the
:: batch script is being run in
set BuildDir=%~dp0msbuild
echo * Build directory: %BuildDir%

if not exist %BuildDir% mkdir %BuildDir%
pushd %BuildDir%

:: Set up globals
set MayaRootDir=C:\Program Files\Autodesk\Maya2020
set MayaIncludeDir=%MayaRootDir%\include
set MayaLibraryDir=%MayaRootDir%\lib

set ProjectName=maya_python_c_ext
set MayaPluginExtension=mll
set PythonModuleExtension=pyd

set MayaPluginEntryPoint=%~dp0cpp/plugin_main.cpp
set PythonModuleEntryPoint=%~dp0cpp/module_main.cpp

:: We pipe errors to null, since we don't care if it fails
del *.pdb > NUL 2> NUL

:: Setup compiler flags
:: /nologo                     Cosmetics, less chatter in the terminal
:: /c                          Compile-only, we'll do linking ourselves
:: /W3                         Warning level 3 out of 4, for posterity
:: /WX                         Treat warnings as errors, for posterity
:: /GS                         Additional security checks, for posterity
set CommonCompilerFlags=^
    /nologo ^
    /c ^
    /W3 ^
    /WX ^
    /GS ^
    /Fo"%BuildDir%\%ProjectName%.obj" ^
    /I "%MayaRootDir%\include" ^
    /I "%MayaRootDir%\include\Python"

:: Setup linker flags
:: /nologo                     Cosmetics
:: /incremental:no             Reduce size of final dll
:: /machine:x64                We'll need this
:: /dll                        The .mll and .pyd are .dll's in disguise
set CommonLinkerFlags=^
    /nologo ^
    /incremental:no ^
    /machine:x64 ^
    /dll ^
    "%BuildDir%\%ProjectName%.obj"

set MayaPluginLinkerFlags=^
    %CommonLinkerFlags% ^
    "%MayaLibraryDir%\OpenMaya.lib" ^
    "%MayaLibraryDir%\Foundation.lib" ^
    "%MayaLibraryDir%\clew.lib" ^
    "%MayaLibraryDir%\Image.lib" ^
    /pdb:"%BuildDir%\%ProjectName%_mll.pdb" ^
    /implib:"%BuildDir%\%ProjectName%_mll.lib"

:: Expose exported members of the .mll to the .pyd
:: NOTE: The added link to _mll.lib, we'll need that
set PythonModuleLinkerFlags=^
    %CommonLinkerFlags% ^
    "%MayaLibraryDir%\python27.lib" ^
    "%BuildDir%\%ProjectName%_mll.lib" ^
    /pdb:"%BuildDir%\%ProjectName%_pyd.pdb" ^
    /implib:"%BuildDir%\%ProjectName%_pyd.lib"

set PythonModuleLinkerFlagsCommon=^
    /out:"%BuildDir%\%ProjectName%.%PythonModuleExtension%"

set MayaPluginLinkerFlagsCommon=^
    /out:"%BuildDir%\%ProjectName%.%MayaPluginExtension%"

if "%BuildType%"=="debug" (
    echo * Building in DEBUG mode...

    set PythonModuleCompilerFlags=%CommonCompilerFlags% ^
        /D _DEBUG ^
        /Zi ^
        /Od ^
        %PythonModuleEntryPoint%
    set PythonModuleLinkerFlags=%PythonModuleLinkerFlags% /debug /opt:noref %PythonModuleLinkerFlagsCommon%

    set MayaPluginCompilerFlags=%CommonCompilerFlags% /Zi /Od %MayaPluginEntryPoint%
    set MayaPluginLinkerFlags=%MayaPluginLinkerFlags% /debug /opt:noref %MayaPluginLinkerFlagsCommon%

) else (
    echo * Building in RELEASE mode...

    set PythonModuleCompilerFlags=%CommonCompilerFlags% ^
        /D NDEBUG ^
        /O2 ^
        %PythonModuleEntryPoint%
    set PythonModuleLinkerFlags=%PythonModuleLinkerFlags% /opt:ref %PythonModuleLinkerFlagsCommon%

    set MayaPluginCompilerFlags=%CommonCompilerFlags% /O2 %MayaPluginEntryPoint%
    set MayaPluginLinkerFlags=%MayaPluginLinkerFlags% /opt:ref %MayaPluginLinkerFlagsCommon%
)

echo *
echo ***************************************

:: Build Maya plugin
echo -> Compiling Maya plugin (command follows)...
echo -> cl %MayaPluginCompilerFlags%
cl %MayaPluginCompilerFlags%
if %errorlevel% neq 0 goto error


:link
echo -- Linking (command follows)...
echo -- link %MayaPluginLinkerFlags%
link %MayaPluginLinkerFlags%
if %errorlevel% neq 0 goto error


:: Build standalone Python module
echo -- Compiling Python module (command follows)...
echo -- cl %PythonModuleCompilerFlags%
cl %PythonModuleCompilerFlags%
if %errorlevel% neq 0 goto error


:link
echo -- Linking Python module (command follows)...
echo -- link %PythonModuleLinkerFlags%
link %PythonModuleLinkerFlags%
if %errorlevel% neq 0 goto error
if %errorlevel% == 0 goto success


:error
echo ***************************************
echo *                                     *
echo *      !!! An error occurred !!!      *
echo *                                     *
echo ***************************************
goto end


:success
echo ***************************************
echo *                                     *
echo *    Build completed successfully!    *
echo *                                     *
echo ***************************************
goto end


:end
echo Build script finished execution at %time%.
popd
exit /b %errorlevel%
