# UI

This package wraps the [libui](https://github.com/andlabs/libui) C library.

In order to make use of it you will need to build the C library first.
Instructions for doing so can be found
[here](https://github.com/andlabs/libui#building).

## Using the wrapper

Start by installing this wrapper using Nimble:

    nimble install ui

Then test that everything works by using this code sample:

```nim
import ui

var mainWin*: ptr Window

proc onClosing*(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainWin)
  ui.quit()
  return 0

proc main*() =
  var o: ui.InitOptions

  var err = ui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return

  mainWin = newWindow("libui in Nim", 200, 100, 1)
  windowSetMargined(mainWin, 1)
  windowOnClosing(mainWin, onClosing, nil)

  windowSetChild(mainWin, newLabel("Hello, World!"))

  controlShow(mainWin)
  ui.main()
  ui.uninit()

main()
```
