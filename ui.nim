
import ui/rawui

type
  Widget* = ref object of RootRef ## abstract Widget base class.
    internalImpl*: pointer

func impl*(w: Widget): ptr[Control] = cast[ptr Control](w.internalImpl)

proc init*() =
  var o: rawui.InitOptions
  var err: cstring
  err = rawui.init(addr(o))
  if err != nil:
    let msg = $err
    freeInitError(err)
    raise newException(ValueError, msg)

proc uninit*() =
  rawui.uninit()

proc quit*() = rawui.quit()

proc mainLoop*() =
  rawui.main()

export rawui.main
export rawui.mainSteps
export rawui.mainStep

proc pollingMainLoop*(poll: proc(timeout: int); timeout: int) {.deprecated: "Write your own loop please".} =
  ## Can be used to merge an async event loop with UI's event loop.
  ## Implemented using timeouts and polling because that's the only
  ## thing that truely composes.
  rawui.mainSteps()
  while true:
    poll(timeout)
    if rawui.mainStep(0) == 0: break

proc queueMain*(f: proc (): void {.cdecl.}) =
  rawui.queueMain(cast[proc (_:pointer): void {.cdecl.}](f), nil) # Not sure if this cast works or not

proc queueMain*[T](f: proc (_:T): void {.cdecl.}, p: T) =
  rawui.queueMain(cast[proc (_:pointer): void {.cdecl.}](f), cast[pointer](p))


# Not included due to bad implementation
# proc timer*(milliseconds: cint) =
#   rawui.timer(milliseconds)

proc onShouldQuit*(f: proc (): bool {.cdecl.}) =
  rawui.onShouldQuit(cast[proc (_:pointer): cint {.cdecl.}](f), nil) # Not sure if this cast works or not

proc onShouldQuit*[T](f: proc (_:T): bool {.cdecl.}, p: T) =
  rawui.onShouldQuit(cast[proc (_:pointer): cint {.cdecl.}](f), cast[pointer](p))


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
    
template genImplProcs(t: untyped) {.dirty.}=
  type `Raw t` = ptr[rawui.t]
  func impl*(b: t): `Raw t` = cast[`Raw t`](b.internalImpl)
  func `impl=`*(b: t, r: `Raw t`) = b.internalImpl = pointer(r)

# ------------------- Button --------------------------------------
type
  Button* = ref object of Widget
    onclick*: proc () {.closure.}

voidCallback(wrapOnClick, Button, Button, onclick)

genImplProcs(Button)

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
    onRadioButtonClick*: proc() {.closure.}

voidCallback(wrapOnRadioButtonClick, RadioButtons, RadioButtons, onRadioButtonClick)

genImplProcs(RadioButtons)

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
    onclosing*: proc (): bool
    child: Widget
    
genImplProcs(Window)

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

proc setChild*(w: Window; child: Widget) =
  windowSetChild(w.impl, child.impl)
  w.child = child

proc `child=`*(w: Window; c: Widget) =
  w.setChild(c)

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
    children*: seq[Widget]
    
genImplProcs(Box)

proc add*(b: Box; child: Widget; stretchy=false) =
  boxAppend(b.impl, child.impl, cint(stretchy))
  b.children.add child

proc delete*(b: Box; index: int) =
  boxDelete(b.impl, index.cint)
  b.children.delete(index)

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
    ontoggled*: proc ()
    
genImplProcs(Checkbox)

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
    onchanged*: proc ()

genImplProcs(Entry)

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

genImplProcs(Label)

proc text*(L: Label): string = $labelText(L.impl)
proc `text=`*(L: Label; text: string) = labelSetText(L.impl, text)
proc newLabel*(text: string): Label =
  newFinal(result)
  result.impl = rawui.newLabel(text)

# ---------------- Tab --------------------------------------------

type
  Tab* = ref object of Widget
    children*: seq[Widget]
    
genImplProcs(Tab)

proc add*(t: Tab; name: string; c: Widget) =
  tabAppend t.impl, name, c.impl
  t.children.add c

proc insertAt*(t: Tab; name: string; at: int; c: Widget) =
  tabInsertAt(t.impl, name, at.cint, c.impl)
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
    child: Widget
    
genImplProcs(Group)

proc title*(g: Group): string = $groupTitle(g.impl)
proc `title=`*(g: Group; title: string) =
  groupSetTitle(g.impl, title)
proc `child=`*(g: Group; c: Widget) =
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
    onchanged*: proc(newvalue: int)
    
genImplProcs(Spinbox)

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
    onchanged*: proc(newvalue: int)
    
genImplProcs(Slider)

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

genImplProcs(ProgressBar)

proc `value=`*(p: ProgressBar; n: int) =
  progressBarSetValue p.impl, n.cint

proc newProgressBar*(): ProgressBar =
  newFinal result
  result.impl = rawui.newProgressBar()

# ------------------------- Separator ----------------------------

type
  Separator* = ref object of Widget
  
genImplProcs(Separator)

proc newHorizontalSeparator*(): Separator =
  newFinal result
  result.impl = rawui.newHorizontalSeparator()

# ------------------------ Combobox ------------------------------

type
  Combobox* = ref object of Widget
    onselected*: proc ()
    
genImplProcs(Combobox)

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
    onchanged*: proc ()
    
genImplProcs(EditableCombobox)

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
    onchanged*: proc ()
    
genImplProcs(MultilineEntry)

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
    onclicked*: proc ()
    
genImplProcs(MenuItem)

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
    children*: seq[MenuItem]
    
genImplProcs(Menu)

template addMenuItemImpl(ex; skip_click=false) =
  newFinal result
  result.impl = ex
  when not skip_click:
    menuItemOnClicked(result.impl, wrapmeOnclicked, cast[pointer](result))
  m.children.add result

proc addItem*(m: Menu; name: string, onclicked: proc() = nil): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendItem(m.impl, name))
  result.onclicked = onclicked

proc addCheckItem*(m: Menu; name: string, onclicked: proc() = nil): MenuItem {.discardable.} =
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

proc addQuitItem*(m: Menu): MenuItem {.discardable.} =
  addMenuItemImpl(menuAppendQuitItem(m.impl), skip_click=true)

proc addQuitItem*(m: Menu, shouldQuit: proc(): bool): MenuItem {.discardable, deprecated:"Register menu action yourself".} =
  result = addQuitItem(m)
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

genImplProcs(Image)
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

genImplProcs(Table)


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

# -------------------- Area ----------------------------------------

type
  AreaObj = object of Widget
    handler: AreaHandler
    onDraw*: proc (drawParams: ptr AreaDrawParams)
    onMouseEvent*: proc (event: ptr AreaMouseEvent)
    onMouseCrossed*: proc (left: cint)
    onDragBroken*: proc ()
    onKeyEvent*: proc (event: ptr AreaKeyEvent): cint
  Area* = ref AreaObj

genImplProcs(Area)

# template void2Callback(name, param0typ, supertyp, basetyp; on: untyped; param2typ:typedesc=void) =
#   proc name(handler: ptr param0typ, w: ptr rawui.supertyp; data: param2typ) {.cdecl.} =
#     let widget = cast[basetyp](w)
#     if widget.on != nil: widget.on(param2typ)

# let wrapOnDraw = void2Callback(AreaHandler, Area, Area, onDraw, ptr rawui.AreaDrawParams)
# void2Callback(wrapOnMouseEvent, AreaHandler, Area, Area, onMouseEvent, ptr rawui.AreaMouseEvent)
# void2Callback(wrapOnMouseCrossed, AreaHandler, Area, Area, onMouseCrossed, cint)
# void2Callback(wrapOnDragBroken, AreaHandler, Area, Area, onDragBroken)
# void2Callback(wrapOnKeyEvent, AreaHandler, Area, Area, onKeyEvent, ptr rawui.AreaKeyEvent)

template wrapAreaCallback(on; param2typ:typedesc=void, rettyp: typedesc = void): untyped =
  when param2typ is void:
    block:
      proc generated_handler(phandler: ptr AreaHandler, _: ptr rawui.Area): rettyp {.cdecl.} =
        let widget = cast[ptr Area](cast[int](phandler) - offsetOf(AreaObj, handler))
        if widget.on != nil: widget.on()
        else: default(rettyp)
      generated_handler
  else:
    block:
      proc generated_handler(phandler: ptr AreaHandler, _: ptr rawui.Area, params: param2typ): rettyp {.cdecl.} =
        let widget = cast[ptr Area](cast[int](phandler) - offsetOf(AreaObj, handler))
        if widget.on != nil: widget.on(params)
        else: default(rettyp)
      generated_handler

proc initHandler(a: Area) =
  var handler: AreaHandler
  handler.draw = wrapAreaCallback(onDraw, ptr AreaDrawParams)
  handler.mouseEvent = wrapAreaCallback(onMouseEvent, ptr AreaMouseEvent)
  handler.mouseCrossed = wrapAreaCallback(onMouseCrossed, cint)
  handler.dragBroken = wrapAreaCallback(onDragBroken)
  handler.keyEvent = wrapAreaCallback(onKeyEvent, ptr AreaKeyEvent, cint)

  a.handler = handler

proc newArea*(): Area =
  newFinal result
  result.initHandler()
  result.impl = rawui.newArea(result.handler.addr)

proc newScrollingArea*(width: cint, height: cint): Area =
  newFinal result
  result.initHandler()
  result.impl = rawui.newScrollingArea(result.handler.addr, width, height)

proc `size=`*(a: Area, width: cint, height: cint) =
  a.impl.areaSetSize(width, height)

proc queueRedrawAll*(a: Area) =
  rawui.areaQueueRedrawAll(a.impl)

proc scrollTo*(a: Area; x: cdouble; y: cdouble; width: cdouble; height: cdouble) =
  rawui.areaScrollTo(a.impl, x, y, width, height)

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

  genImplProcs(DateTimePicker)

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
