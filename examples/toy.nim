
# Test & show the new high level wrapper

import ui

proc main*() =
  var mainwin: Window

  var menu = newMenu("File")
  menu.addItem("Open", proc() =
    let filename = ui.openFile(mainwin)
    if filename.len == 0:
      msgBoxError(mainwin, "No file selected", "Don't be alarmed!")
    else:
      msgBox(mainwin, "File selected", filename)
  )
  menu.addItem("Save", proc() =
    let filename = ui.saveFile(mainwin)
    if filename.len == 0:
      msgBoxError(mainwin, "No file selected", "Don't be alarmed!")
    else:
      msgBox(mainwin, "File selected (don't worry, it's still there)", filename)
  )
  menu.addQuitItem(proc(): bool {.closure.} =
    mainwin.destroy()
    return true)

  menu = newMenu("Edit")
  menu.addCheckItem("Checkable Item", proc() = discard)
  menu.addSeparator()
  let item = menu.addItem("Disabled Item", proc() = discard)
  item.disable()
  menu.addPreferencesItem(proc() = discard)
  menu = newMenu("Help")
  menu.addItem("Help", proc () = discard)
  menu.addAboutItem(proc () = discard)

  mainwin = newWindow("libui Control Gallery", 640, 480, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  let box = newVerticalBox(true)
  mainwin.setChild(box)

  var group = newGroup("Basic Controls", true)
  box.add(group, false)

  var inner = newVerticalBox(true)
  group.child = inner

  inner.add newButton("Button", proc() = msgBoxError(mainwin, "Error", "Rotec"))

  show(mainwin)
  mainLoop()

init()
main()
