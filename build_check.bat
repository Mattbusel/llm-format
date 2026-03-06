@echo off
setlocal EnableDelayedExpansion

REM Locate cl.exe using vswhere (works for Community, Professional, Enterprise, BuildTools)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo ERROR: vswhere.exe not found. Install Visual Studio or Build Tools.
    exit /b 1
)

for /f "usebackq tokens=*" %%i in (
    `"%VSWHERE%" -latest -products * -requires Microsoft.VisualCpp.Tools.HostX64.TargetX64 -find VC\Tools\MSVC\**\bin\Hostx64\x64\cl.exe`
) do set "CL_EXE=%%i"

if not defined CL_EXE (
    echo ERROR: Could not locate cl.exe. Install the MSVC C++ toolset.
    exit /b 1
)

REM Derive MSVC root from cl.exe path  (strip \bin\Hostx64\x64\cl.exe)
set "MSVC_BIN_DIR=%CL_EXE%"
for %%i in ("%CL_EXE%") do set "MSVC_BIN_DIR=%%~dpi"
set "MSVC_BIN_DIR=%MSVC_BIN_DIR:~0,-1%"
REM Go up 3 levels: Hostx64\x64 -> bin -> MSVC version root
for %%i in ("%MSVC_BIN_DIR%") do set "UP1=%%~dpi"
set "UP1=%UP1:~0,-1%"
for %%i in ("%UP1%") do set "UP2=%%~dpi"
set "UP2=%UP2:~0,-1%"
for %%i in ("%UP2%") do set "MSVC_ROOT=%%~dpi"
set "MSVC_ROOT=%MSVC_ROOT:~0,-1%"

set "MSVC_INC=%MSVC_ROOT%\include"
set "MSVC_LIB=%MSVC_ROOT%\lib\x64"

set "SDK_BASE=%ProgramFiles(x86)%\Windows Kits\10"
REM Pick the newest SDK include dir
for /f "tokens=*" %%i in ('dir /b /ad "%SDK_BASE%\Include" 2^>nul') do set "SDK_VER=%%i"
set "SDK_INC=%SDK_BASE%\Include\%SDK_VER%"
set "SDK_LIB=%SDK_BASE%\Lib\%SDK_VER%"

set "PROJ_INC=C:\Users\Matthew\llm-format\include"

if not exist C:\Temp mkdir C:\Temp

echo === Compiling basic_format.cpp ===
"%CL_EXE%" /std:c++17 /W4 /WX /EHsc /I"%MSVC_INC%" /I"%SDK_INC%\ucrt" /I"%SDK_INC%\shared" /I"%SDK_INC%\um" /I"%PROJ_INC%" /Fe:C:\Temp\basic_format.exe "C:\Users\Matthew\llm-format\examples\basic_format.cpp" /link /LIBPATH:"%MSVC_LIB%" /LIBPATH:"%SDK_LIB%\ucrt\x64" /LIBPATH:"%SDK_LIB%\um\x64"
if %ERRORLEVEL% NEQ 0 ( echo FAILED basic_format & exit /b 1 )
echo OK

echo === Compiling nested_schema.cpp ===
"%CL_EXE%" /std:c++17 /W4 /WX /EHsc /I"%MSVC_INC%" /I"%SDK_INC%\ucrt" /I"%SDK_INC%\shared" /I"%SDK_INC%\um" /I"%PROJ_INC%" /Fe:C:\Temp\nested_schema.exe "C:\Users\Matthew\llm-format\examples\nested_schema.cpp" /link /LIBPATH:"%MSVC_LIB%" /LIBPATH:"%SDK_LIB%\ucrt\x64" /LIBPATH:"%SDK_LIB%\um\x64"
if %ERRORLEVEL% NEQ 0 ( echo FAILED nested_schema & exit /b 1 )
echo OK

echo === Compiling validate_only.cpp ===
"%CL_EXE%" /std:c++17 /W4 /WX /EHsc /I"%MSVC_INC%" /I"%SDK_INC%\ucrt" /I"%SDK_INC%\shared" /I"%SDK_INC%\um" /I"%PROJ_INC%" /Fe:C:\Temp\validate_only.exe "C:\Users\Matthew\llm-format\examples\validate_only.cpp" /link /LIBPATH:"%MSVC_LIB%" /LIBPATH:"%SDK_LIB%\ucrt\x64" /LIBPATH:"%SDK_LIB%\um\x64"
if %ERRORLEVEL% NEQ 0 ( echo FAILED validate_only & exit /b 1 )
echo OK

echo === Running examples ===
echo --- basic_format ---
C:\Temp\basic_format.exe
echo --- nested_schema ---
C:\Temp\nested_schema.exe
echo --- validate_only ---
C:\Temp\validate_only.exe

echo === All done ===
