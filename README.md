# UI

This package wraps the [libui](https://github.com/andlabs/libui) C library.

In order to make use of it you will need to do:

```
cd ui
cd .. # ensure libui is a sibling of your ui directory
git clone https://github.com/araq/libui
cd ui
nim c -r examples/controllgallery2.nim
```

On Windows currently Visual Studio is required, so you need to use:

```
nim c -r --cc:vcc examples/controllgallery2.nim
```


## Using the wrapper

Test that everything works by using this code sample:

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
