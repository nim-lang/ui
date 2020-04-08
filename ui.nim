
import ui/rawui

export rawui.Align

type
  Widget* = ref object of RootRef ## abstract Widget base class.

proc init*() =
  var o: rawui.InitOptions
  var err: cstring
  err = rawui.init(addr(o))
  if err != nil:
    let msg = $err
    freeInitError(err)
    raise newException(ValueError, msg)

proc quit*() = rawui.quit()

proc mainLoop*() =
  rawui.main()
  rawui.uninit()

proc pollingMainLoop*(poll: proc(timeout: int); timeout: int) =
  ## Can be used to merge an async event loop with UI's event loop.
  ## Implemented using timeouts and polling because that's the only
  ## thing that truely composes.
  rawui.mainSteps()
  while true:
    poll(timeout)
    discard rawui.mainStep(0)# != 0: break
  rawui.uninit()

template newFinal(result) =
  #proc finalize(x: type(result)) {.nimcall.} =
  #  controlDestroy(x.impl)
  new(result) #, finalize)

template voidCallback(name, supertyp, basetyp, on) {.dirty.} =
  proc name(w: ptr rawui.supertyp; data: pointer) {.cdecl.} =
    let widget = cast[basetyp](data)
    if widget.on != nil: widget.on()

template intCallback(name, supertyp, basetyp, on) {.dirty.} =
  proc name(w: ptr rawui.supertyp; data: pointer) {.cdecl.} =
    let widget = cast[basetyp](data)
    if widget.on != nil: widget.on(widget.value)

# ------------------- Grid ------------------------
type
  Grid* = ref object of Widget
    impl*: ptr rawui.Grid

proc add*[SomeWidget: Widget](t: Grid; c: SomeWidget, left: cint, top: cint, xspan: cint, yspan: cint, hexpand: cint, halign: Align, vexpand: cint, valign: Align) =
  gridAppend t.impl, c.impl, left, top, xspan, yspan, hexpand, halign, vexpand, valign

proc newGrid*(padded = false): Grid =
  newFinal(result)
  result.impl = rawui.newGrid()
  result.impl.gridSetPadded(padded.cint)

# ------------------- Button --------------------------------------
type
  Button* = ref object of Widget
    impl*: ptr rawui.Button
    onclick*: proc () {.closure.}

voidCallback(wrapOnClick, Button, Button, onclick)

proc text*(b: Button): string =
  ## Gets the button's text.
  $buttonText(b.impl)

proc `text=`*(b: Button; text: string) =
  ## Sets the button's text.
  buttonSetText(b.impl, text)

proc newButton*(text: string; onclick: proc() = nil): Button =
  newFinal(result)
  result.impl = rawui.newButton(text)
  result.impl.buttonOnClicked(wrapOnClick, cast[pointer](result))
  result.onclick = onclick

# ------------------------ RadioButtons ----------------------------

type
  RadioButtons* = ref object of Widget
    impl*: ptr rawui.RadioButtons
    onRadioButtonClick*: proc() {.closure.}

voidCallback(wrapOnRadioButtonClick, RadioButtons, RadioButtons, onRadioButtonClick)

proc add*(r: RadioButtons; text: string) =
  radioButtonsAppend(r.impl, text)

proc radioButtonsSelected*(r: RadioButtons): int =
  radioButtonsSelected(r.impl)

proc newRadioButtons*(onclick: proc() = nil): RadioButtons =
  newFinal(result)
  result.impl = rawui.newRadioButtons()
  result.impl.radioButtonsOnSelected(wrapOnRadioButtonClick, cast[pointer](result))
  result.onRadioButtonClick = onclick

# ----------------- Window -------------------------------------------

type
  Window* = ref object of Widget
    impl*: ptr rawui.Window
    onclosing*: proc (): bool
    child: Widget

proc title*(w: Window): string =
  ## Gets the window's title.
  $windowTitle(w.impl)

proc `title=`*(w: Window; text: string) =
  ## Sets the window's title.
  windowSetTitle(w.impl, text)

proc destroy*(w: Window) =
  ## this needs to be called if the callback passed to addQuitItem returns
  ## true. Don't ask...
  controlDestroy(w.impl)

proc onclosingWrapper(rw: ptr rawui.Window; data: pointer): cint {.cdecl.} =
  let w = cast[Window](data)
  if w.onclosing != nil:
    if w.onclosing():
      controlDestroy(w.impl)
      rawui.quit()
      system.quit()

proc newWindow*(title: string; width, height: int; hasMenubar: bool): Window =
  newFinal(result)
  result.impl = rawui.newWindow(title, cint width, cint height,
                                cint hasMenubar)
  windowOnClosing(result.impl, onClosingWrapper, cast[pointer](result))

proc margined*(w: Window): bool = windowMargined(w.impl) != 0
proc `margined=`*(w: Window; x: bool) = windowSetMargined(w.impl, cint(x))

proc setChild*[SomeWidget: Widget](w: Window; child: SomeWidget) =
  windowSetChild(w.impl, child.impl)
  w.child = child

proc openFile*(parent: Window): string =
  let x = openFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc saveFile*(parent: Window): string =
  let x = saveFile(parent.impl)
  result = $x
  if x != nil: freeText(x)

proc msgBox*(parent: Window; title, desc: string) =
  msgBox(parent.impl, title, desc)
proc msgBoxError*(parent: Window; title, desc: string) =
  msgBoxError(parent.impl, title, desc)

# ------------------------- Box ------------------------------------------

type
  Box* = ref object of Widget
    impl*: ptr rawui.Box
    children*: seq[Widget]

proc add*[SomeWidget: Widget](b: Box; child: SomeWidget; stretchy=false) =
  boxAppend(b.impl, child.impl, cint(stretchy))
  b.children.add child

proc delete*(b: Box; index: int) = boxDelete(b.impl, index.cint)
proc padded*(b: Box): bool = boxPadded(b.impl) != 0
proc `padded=`*(b: Box; x: bool) = boxSetPadded(b.impl, x.cint)

proc newHorizontalBox*(padded = false): Box =
  newFinal(result)
  result.impl = rawui.newHorizontalBox()
  result.children = @[]
  boxSetPadded(result.impl, padded.cint)

proc newVerticalBox*(padded = false): Box =
  newFinal(result)
  result.impl = rawui.newVerticalBox()
  result.children = @[]
  boxSetPadded(result.impl, padded.cint)

# -------------------- Checkbox ----------------------------------

type
  Checkbox* = ref object of Widget
    impl*: ptr rawui.Checkbox
    ontoggled*: proc ()

proc text*(c: Checkbox): string = $checkboxText(c.impl)
proc `text=`*(c: Checkbox; text: string) = checkboxSetText(c.impl, text)

voidCallback(wrapOntoggled, Checkbox, Checkbox, ontoggled)

proc checked*(c: Checkbox): bool = checkboxChecked(c.impl) != 0

proc `checked=`*(c: Checkbox; x: bool) =
  checkboxSetChecked(c.impl, cint(x))

proc newCheckbox*(text: string; ontoggled: proc() = nil): Checkbox =
  newFinal(result)
  result.impl = rawui.newCheckbox(text)
  result.ontoggled = ontoggled
  checkboxOnToggled(result.impl, wrapOntoggled, cast[pointer](result))

# ------------------ Entry ---------------------------------------

type
  Entry* = ref object of Widget
    impl*: ptr rawui.Entry
    onchanged*: proc ()

proc text*(e: Entry): string = $entryText(e.impl)
proc `text=`*(e: Entry; text: string) = entrySetText(e.impl, text)

voidCallback(wrapOnchanged, Entry, Entry, onchanged)

proc readOnly*(e: Entry): bool = entryReadOnly(e.impl) != 0

proc `readOnly=`*(e: Entry; x: bool) =
  entrySetReadOnly(e.impl, cint(x))

proc newEntry*(text: string; onchanged: proc() = nil): Entry =
  newFinal(result)
  result.impl = rawui.newEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged
  entrySetText(result.impl, text)

# ----------------- Label ----------------------------------------

type
  Label* = ref object of Widget
    impl*: ptr rawui.Label

proc text*(L: Label): string = $labelText(L.impl)
proc `text=`*(L: Label; text: string) = labelSetText(L.impl, text)
proc newLabel*(text: string): Label =
  newFinal(result)
  result.impl = rawui.newLabel(text)

# ---------------- Tab --------------------------------------------

type
  Tab* = ref object of Widget
    impl*: ptr rawui.Tab
    children*: seq[Widget]

proc add*[SomeWidget: Widget](t: Tab; name: string; c: SomeWidget) =
  tabAppend t.impl, name, c.impl
  t.children.add c

proc insertAt*[SomeWidget: Widget](t: Tab; name: string; at: int; c: SomeWidget) =
  tabInsertAt(t.impl, name, at.uint64, c.impl)
  t.children.insert(c, at)

proc delete*(t: Tab; index: int) =
  tabDelete(t.impl, index.cint)
  t.children.delete(index)

proc numPages*(t: Tab): int = tabNumPages(t.impl).int
proc margined*(t: Tab; page: int): bool =
  tabMargined(t.impl, page.cint) != 0
proc `margined=`*(t: Tab; page: int; x: bool) =
  tabSetMargined(t.impl, page.cint, cint(x))
proc newTab*(): Tab =
  newFinal result
  result.impl = rawui.newTab()
  result.children = @[]

# ------------- Group --------------------------------------------------

type
  Group* = ref object of Widget
    impl*: ptr rawui.Group
    child: Widget

proc title*(g: Group): string = $groupTitle(g.impl)
proc `title=`*(g: Group; title: string) =
  groupSetTitle(g.impl, title)
proc `child=`*[SomeWidget: Widget](g: Group; c: SomeWidget) =
  groupSetChild(g.impl, c.impl)
  g.child = c
proc margined*(g: Group): bool = groupMargined(g.impl) != 0
proc `margined=`*(g: Group; x: bool) =
  groupSetMargined(g.impl, x.cint)

proc newGroup*(title: string; margined=false): Group =
  newFinal result
  result.impl = rawui.newGroup(title)
  groupSetMargined(result.impl, margined.cint)

# ----------------------- Spinbox ---------------------------------------

type
  Spinbox* = ref object of Widget
    impl*: ptr rawui.Spinbox
    onchanged*: proc(newvalue: int)

proc value*(s: Spinbox): int = spinboxValue(s.impl)
proc `value=`*(s: Spinbox; value: int) = spinboxSetValue(s.impl, value.cint)

intCallback wrapsbOnChanged, Spinbox, Spinbox, onchanged

proc newSpinbox*(min, max: int; onchanged: proc (newvalue: int) = nil): Spinbox =
  newFinal result
  result.impl = rawui.newSpinbox(cint min, cint max)
  spinboxOnChanged result.impl, wrapsbOnChanged, cast[pointer](result)
  result.onchanged = onchanged

# ---------------------- Slider ---------------------------------------

type
  Slider* = ref object of Widget
    impl*: ptr rawui.Slider
    onchanged*: proc(newvalue: int)

proc value*(s: Slider): int = sliderValue(s.impl)
proc `value=`*(s: Slider; value: int) = sliderSetValue(s.impl, cint value)

intCallback wrapslOnChanged, Slider, Slider, onchanged

proc newSlider*(min, max: int; onchanged: proc (newvalue: int) = nil): Slider =
  newFinal result
  result.impl = rawui.newSlider(cint min, cint max)
  sliderOnChanged result.impl, wrapslOnChanged, cast[pointer](result)
  result.onchanged = onchanged

# ------------------- Progressbar ---------------------------------

type
  ProgressBar* = ref object of Widget
    impl*: ptr rawui.ProgressBar

proc `value=`*(p: ProgressBar; n: int) =
  progressBarSetValue p.impl, n.cint

proc newProgressBar*(): ProgressBar =
  newFinal result
  result.impl = rawui.newProgressBar()

# ------------------------- Separator ----------------------------

type
  Separator* = ref object of Widget
    impl*: ptr rawui.Separator

proc newHorizontalSeparator*(): Separator =
  newFinal result
  result.impl = rawui.newHorizontalSeparator()

# ------------------------ Combobox ------------------------------

type
  Combobox* = ref object of Widget
    impl*: ptr rawui.Combobox
    onselected*: proc ()

proc add*(c: Combobox; text: string) =
  c.impl.comboboxAppend text
proc selected*(c: Combobox): int = comboboxSelected(c.impl)
proc `selected=`*(c: Combobox; n: int) =
  comboboxSetSelected c.impl, cint n

voidCallback wrapbbOnSelected, Combobox, Combobox, onselected

proc newCombobox*(onSelected: proc() = nil): Combobox =
  newFinal result
  result.impl = rawui.newCombobox()
  result.onSelected = onSelected
  comboboxOnSelected(result.impl, wrapbbOnSelected, cast[pointer](result))

# ----------------------- EditableCombobox ----------------------

type
  EditableCombobox* = ref object of Widget
    impl*: ptr rawui.EditableCombobox
    onchanged*: proc ()

proc add*(c: EditableCombobox; text: string) =
  editableComboboxAppend(c.impl, text)

proc text*(c: EditableCombobox): string =
  $editableComboboxText(c.impl)

proc `text=`*(c: EditableCombobox; text: string) =
  editableComboboxSetText(c.impl, text)

voidCallback wrapecbOnchanged, EditableCombobox, EditableCombobox, onchanged

proc newEditableCombobox*(onchanged: proc () = nil): EditableCombobox =
  newFinal result
  result.impl = rawui.newEditableCombobox()
  result.onchanged = onchanged
  editableComboboxOnChanged result.impl, wrapecbOnchanged, cast[pointer](result)

# ------------------------ MultilineEntry ------------------------------

type
  MultilineEntry* = ref object of Widget
    impl*: ptr rawui.MultilineEntry
    onchanged*: proc ()

proc text*(e: MultilineEntry): string =
  $multilineEntryText(e.impl)
proc `text=`*(e: MultilineEntry; text: string) =
  multilineEntrySetText(e.impl, text)
proc add*(e: MultilineEntry; text: string) =
  multilineEntryAppend(e.impl, text)

voidCallback wrapmeOnchanged, MultilineEntry, MultilineEntry, onchanged

proc readonly*(e: MultilineEntry): bool =
  multilineEntryReadOnly(e.impl) != 0
proc `readonly=`*(e: MultilineEntry; x: bool) =
  multilineEntrySetReadOnly(e.impl, cint(x))

proc newMultilineEntry*(): MultilineEntry =
  newFinal result
  result.impl = rawui.newMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

proc newNonWrappingMultilineEntry*(): MultilineEntry =
  newFinal result
  result.impl = rawui.newNonWrappingMultilineEntry()
  multilineEntryOnChanged(result.impl, wrapmeOnchanged, cast[pointer](result))

# ---------------------- MenuItem ---------------------------------------

type
  MenuItem* = ref object of Widget
    impl*: ptr rawui.MenuItem
    onclicked*: proc ()

proc enable*(m: MenuItem) = menuItemEnable(m.impl)
proc disable*(m: MenuItem) = menuItemDisable(m.impl)

proc wrapmeOnclicked(sender: ptr rawui.MenuItem;
                     window: ptr rawui.Window; data: pointer) {.cdecl.} =
  let m = cast[MenuItem](data)
  if m.onclicked != nil: m.onclicked()

proc checked*(m: MenuItem): bool = menuItemChecked(m.impl) != 0
proc `checked=`*(m: MenuItem; x: bool) = menuItemSetChecked(m.impl, cint(x))

# -------------------- Menu ---------------------------------------------

type
  Menu* = ref object of Widget
    impl*: ptr rawui.Menu
    children*: seq[MenuItem]

template addMenuItemImpl(ex) =
  newFinal result
  result.impl = ex
  menuItemOnClicked(result.impl, wrapmeOnclicked, cast[pointer](result))
  m.children.add result

proc addItem*(m: Menu; name: string, onclicked: proc()): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendItem(m.impl, name))
  result.onclicked = onclicked

proc addCheckItem*(m: Menu; name: string, onclicked: proc()): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendCheckItem(m.impl, name))
  result.onclicked = onclicked

type
  ShouldQuitClosure = ref object
    fn: proc(): bool

proc wrapOnShouldQuit(data: pointer): cint {.cdecl.} =
  let c = cast[ShouldQuitClosure](data)
  result = cint(c.fn())
  if result == 1:
    GC_unref c

proc addQuitItem*(m: Menu, shouldQuit: proc(): bool): MenuItem {.discardable.} =
  newFinal result
  result.impl = menuAppendQuitItem(m.impl)
  m.children.add result
  var cl = ShouldQuitClosure(fn: shouldQuit)
  GC_ref cl
  onShouldQuit(wrapOnShouldQuit, cast[pointer](cl))

proc addPreferencesItem*(m: Menu, onclicked: proc()): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendPreferencesItem(m.impl))
  result.onclicked = onclicked

proc addAboutItem*(m: Menu, onclicked: proc()): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendAboutItem(m.impl))
  result.onclicked = onclicked

proc addSeparator*(m: Menu) =
  menuAppendSeparator m.impl

proc newMenu*(name: string): Menu =
  newFinal result
  result.impl = rawui.newMenu(name)
  result.children = @[]

# -------------------- Image --------------------------------------

type
  Image* = ref object of Widget
    impl*: ptr rawui.Image

proc newImage*(width, height: float): Image =
  newFinal result
  result.impl = rawui.newImage(width.cdouble, height.cdouble)

# -------------------- Table --------------------------------------

export TableModelHandler, TableModel, TableParams, TableTextColumnOptionalParams, TableColumnType, TableValueType, TableValue
export newTableModel, freeTableModel

const
  TableModelColumnNeverEditable* = (-1)
  TableModelColumnAlwaysEditable* = (-2)


type
  Table* = ref object of Widget
    impl*: ptr rawui.Table


proc tableValueGetType*(v: ptr TableValue): TableValueType {.inline.} = rawui.tableValueGetType(v)

proc newTableValueString*(s: string): ptr TableValue {.inline.} = rawui.newTableValueString(s.cstring)
proc tableValueString*(v: ptr TableValue): string {.inline.} = $rawui.tableValueString(v)

proc newTableValueImage*(img: Image): ptr TableValue = rawui.newTableValueImage(img.impl)
proc tableValueImage*(v: ptr TableValue): Image =
  newFinal result
  result.impl = rawui.tableValueImage(v)

proc newTableValueInt*(i: int): ptr TableValue {.inline.} = rawui.newTableValueInt(i.cint)
proc tableValueInt*(v: ptr TableValue): int {.inline.} = rawui.tableValueInt(v)

proc newTableValueColor*(r: float; g: float; b: float; a: float): ptr TableValue {.inline.} = rawui.newTableValueColor(r, g, b, a)
proc tableValueColor*(v: ptr TableValue; r: ptr float; g: ptr float;
                      b: ptr float; a: ptr float) {.inline.} = rawui.tableValueColor(v, r, g, b, a)


proc rowInserted*(m: TableModel; newIndex: int) {.inline.} = rawui.tableModelRowInserted(m, newIndex.cint)
proc rowChanged*(m: TableModel; index: int) {.inline.} = rawui.tableModelRowChanged(m, index.cint)
proc rowDeleted*(m: TableModel; oldIndex: int) {.inline.} = rawui.tableModelRowDeleted(m, oldIndex.cint)


proc appendTextColumn*(table: Table, title: string, index, editableMode: int, textParams: ptr TableTextColumnOptionalParams) =
  table.impl.tableAppendTextColumn(title, index.cint, editableMode.cint, textParams)

proc appendImageColumn*(table: Table, title: string, index: int) =
  table.impl.tableAppendImageColumn(title, index.cint)

proc appendImageTextColumn*(table: Table, title: string, imageIndex, textIndex, editableMode: int, textParams: ptr TableTextColumnOptionalParams) =
  table.impl.tableAppendImageTextColumn(title, imageIndex.cint, textIndex.cint, editableMode.cint, textParams)

proc appendCheckboxColumn*(table: Table, title: string, index, editableMode: int) =
  table.impl.tableAppendCheckboxColumn(title, index.cint, editableMode.cint)

proc appendProgressBarColumn*(table: Table, title: string, index: int) =
  table.impl.tableAppendProgressBarColumn(title, index.cint)

proc appendButtonColumn*(table: Table, title: string, index, clickableMode: int) =
  table.impl.tableAppendButtonColumn(title, index.cint, clickableMode.cint)

proc newTable*(params: ptr TableParams): Table =
  newFinal result
  result.impl = rawui.newTable(params)


# -------------------- Generics ------------------------------------

proc show*[W: Widget](w: W) =
  rawui.controlShow(w.impl)

proc hide*[W: Widget](w: W) =
  rawui.controlHide(w.impl)

proc enable*[W: Widget](w: W) =
  rawui.controlEnable(w.impl)

proc disable*[W: Widget](w: W) =
  rawui.controlDisable(w.impl)

# -------------------- DateTimePicker ------------------------------

when false:
  # XXX no way yet to get the date out of this?
  type
    DateTimePicker* = ref object of Widget
      impl*: ptr rawui.DateTimePicker

  proc dateTimePickerTime*(p: DateTimePicker)

  proc newDateTimePicker*(): DateTimePicker =
    newFinal result
    result.impl = rawui.newDateTimePicker()

  proc newDatePicker*(): DateTimePicker =
    newFinal result
    result.impl = rawui.newDatePicker()

  proc newTimePicker*(): DateTimePicker =
    newFinal result
    result.impl = rawui.newTimePicker()

  proc time*(P: DateTimePicker): StructTm = dateTimePickerTime(P.impl, addr result)
  proc `time=`*(P: DateTimePicker, time: ptr StructTm) = dateTimePickerSetTime(P.impl, time)
  #proc onchanged*(P: DateTimePicker)
