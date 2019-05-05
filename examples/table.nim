import ui, random


const
  NUM_COLUMNS = 7
  NUM_ROWS = 10

  COLUMN_ID = 0
  COLUMN_FIRST_NAME = 1
  COLUMN_LAST_NAME = 2
  COLUMN_ADRESS = 3
  COLUMN_PROCESS = 4
  COLUMN_PASSED = 5
  COLUMN_ACTION = 6

var
  progress: array[NUM_ROWS, array[NUM_COLUMNS, int]]

proc modelNumColumns(mh: ptr TableModelHandler, m: TableModel): int {.cdecl.} = NUM_COLUMNS
proc modelNumRows(mh: ptr TableModelHandler, m: TableModel): int {.cdecl.} = NUM_ROWS

proc modelColumnType(mh: ptr TableModelHandler, m: TableModel, col: int): TableValueType {.noconv.} =
  echo "type"
  if col in [COLUMN_ID, COLUMN_PROCESS, COLUMN_PASSED]:
    result = TableValueTypeInt
  else:
    result = TableValueTypeString

proc modelCellValue(mh: ptr TableModelHandler, m: TableModel, row, col: int): ptr TableValue {.noconv.} =
  if col == COLUMN_ID:
    result = newTableValueString($(row+1))
  elif col == COLUMN_PROCESS:
    if progress[row][col] == 0:
      progress[row][col] = random(100)
    result = newTableValueInt(progress[row][col])
  #elif col == COLUMN_PASSED:
  #  if progress[row][col] > 60:
  #    result = newTableValueInt(1)
  #  else:
  #    result = newTableValueInt(0)
  elif col == COLUMN_ACTION:
    result = newTableValueString("Apply")
  else:
    result = newTableValueString("row " & $row & " x col " & $col)


proc modelSetCellValue(mh: ptr TableModelHandler, m: TableModel, row, col: int, val: ptr TableValue) {.cdecl.} =
  echo "setCellValue"
  if col == COLUMN_PASSED:
    echo tableValueInt(val)
  elif col == COLUMN_ACTION:
    m.rowChanged(row)


var
  mh: TableModelHandler
  p: TableParams
  tp: TableTextColumnOptionalParams

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

  mh.numColumns = modelNumColumns
  mh.columnType = modelColumnType
  mh.numRows = modelNumRows
  mh.cellValue  = modelCellValue
  mh.setCellValue = modelSetCellValue

  p.model = newTableModel(addr mh)
  p.rowBackgroundColorModelColumn = 4
 
  let table = newTable(addr p)
  table.appendTextColumn("ID", COLUMN_ID, TableModelColumnNeverEditable, nil)
  table.appendTextColumn("First Name", COLUMN_FIRST_NAME, TableModelColumnAlwaysEditable, nil)
  table.appendTextColumn("Last Name", COLUMN_LAST_NAME, TableModelColumnAlwaysEditable, nil)
  table.appendTextColumn("Address", COLUMN_ADRESS, TableModelColumnAlwaysEditable, nil)
  table.appendProgressBarColumn("Progress", COLUMN_PROCESS)
  table.appendCheckboxColumn("Passed", COLUMN_PASSED, TableModelColumnAlwaysEditable)
  table.appendButtonColumn("Action", COLUMN_ACTION, TableModelColumnAlwaysEditable)

  box.add(table, true)
  show(mainwin)

init()
main()
mainLoop()
