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