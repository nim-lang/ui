
import ui

proc main*() =
  var mainwin: Window

  var menu = newMenu("File")
  menu.addQuitItem(proc(): bool {.closure.} =
    mainwin.destroy()
    return true)

  mainwin = newWindow("uiTable", 640, 480, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  let box = newVerticalBox(true)
  mainwin.setChild(box)

  let table = newTable(@[TableValueTypeString, TableValueTypeInt])
  table.appendTextColumn("text 1", 1, 1, nil)
  table.appendTextColumn("text 2", 2, 0, nil)
  table.appendTextColumn("text 3", 3, 0, nil)
  table.appendTextColumn("text 4", 4, 0, nil)
  table.appendTextColumn("text 5", 5, 0, nil)

  box.add(table, true)

  show(mainwin)


init()
main()
mainLoop()