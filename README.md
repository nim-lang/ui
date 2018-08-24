# UI

This package wraps the [libui](https://github.com/andlabs/libui) C library. It
also provides a high-level Nim binding for it.

To get started, install using Nimble:

```bash
nimble install ui
```

or add it to your project's Nimble file:

```nim
requires "ui"
```

### Dependencies
- `gtk+-3.0`

Linux: `$ sudo apt-get install libgtk-3-dev`

OSX: `$ brew install gtk+3`

Windows:
- Install: http://www.msys2.org/
- `$ pacman -Ss gtk3`
- `$ pacman -S mingw-w64-x86_64-gtk3 --force` for `x64`
- `$ pacman -S mingw-w64-i686-gtk3 --force` for `x32`
- Add `C:\msys64\mingw64\bin` and `\lib` in the path variable.


You should then be able to compile the sample code in the
[``examples/``](https://github.com/nim-lang/ui/tree/master/examples)
directory successfully.

## Static vs. dynamic linking

This library installs the C sources for libui and statically compiles them
into your application.

Static compilation is the default behaviour, but if you would prefer to depend
on a DLL instead, pass the ``-d:useLibUiDll`` to the Nim compiler. You will
then need to bundle your application with a libui.dll, libui.dylib, or libui.so
for Windows, macOS, and Linux respectively.