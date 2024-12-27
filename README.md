# FlareLang

**Project is in very early development and not usable in any sort of way**

A general purpose programming language. In reality it will probably mainly be used to build desktop UI apps.

## Features
- Implicit contex system (similar to odin/jai)
- Different allocators (GC, arena, etc.)
- C style syntax


**Implementation**:
The compiler/interpreter is implemented in odin (for now, goal is self hosted).

There is a interpreter that is supposed to be used for development and a compiler for production.
The interpreter should have all the nice developer features (0 build time, hot reload, debugging, etc.) and the compiler should purely focus on speed.

**Interpreter**:
Should use a byte code vm to execute the code semi fast. 
During runtime you should be able to run user suplied code with the interpreter (e.g. plugins), in a isolated and safe environment.

**Compiler**:
Should use XYZ as the backend, and produce stand alone native executables. The compiler should also be able to output wasm.


CLI:

`flare run main.fl` 
runs the application in interpreted mode

`flare check main.fl`
check the application for any syntax/type errors (`run` also includes these checks)

`flare compile main.fl`
compiles the application to a native executable

`flare watch main.fl`
runs the application in interpreted mode and then watches for file system changes and reloads the app (statefull hot reload if available)

`flare reload`
hot reloads the last instance of `flare run`

Debugger:
The debugger uses a custom protocol and is only available for when the app runs in interpreted mode.
While debugging, you should be able to execute arbitrary code, inspect the state of the app.
GOAL: time traveling debugger, I should be able to step back in time. But not an unlimited amount of time.

There should be an Editor/IDE/Debugger for this language.