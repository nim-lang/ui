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

import
  ui

proc main() =
  var mainwin = newWindow("libui Control Gallery", 640, 480, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  let box = newVerticalBox(true)
  mainwin.setChild(box)

  var group = newGroup("Basic Controls", true)
  box.add(group, false)

  var inner = newVerticalBox(true)
  group.child = inner

  inner.add newButton("Button", proc() = msgBox(mainwin, "Info", "button clicked!"))

  show(mainwin)
  mainLoop()

init()
main()
```
