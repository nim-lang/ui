
import rawui

type
  Widget* = ref object of RootRef ## abstract Widget base class.

# ------------------- Button --------------------------------------

template newFinal(result) =
  proc finalize(x: type(result)) {.nimcall.} =
    controlDestroy(x.impl)
  new(result, finalize)

template voidCallback(name, supertyp, basetyp, on) {.dirty.} =
  proc name(w: ptr rawui.supertyp; data: pointer) {.cdecl.} =
    let widget = cast[basetyp](data)
    if widget.on != nil: widget.on()

type
  Button* = ref object of Widget
    impl*: ptr rawui.Button
    onclick*: proc () {.closure.}

voidCallback(wrapOnClick, Button, Button, onclick)

proc text*(b: Button): string =
  ## Gets the button's text.
  $buttonText(b.impl)

proc `text=`(b: Button; text: string) =
  ## Sets the button's text.
  buttonSetText(b.impl, text)

proc newButton*(text: string; onclick: proc() = nil): Button =
  newFinal(result)
  result.impl = rawui.newButton(text)
  result.impl.buttonOnClicked(wrapOnClick, cast[pointer](result))

# ----------------- Window -------------------------------------------

type
  Window* = ref object of Widget
    impl*: ptr rawui.Window
    onclosing*: proc ()
    child*: Widget

proc title*(w: Window): string =
  ## Gets the window's title.
  $windowTitle(w.impl)

proc `title=`(w: Window; text: string) =
  ## Sets the window's title.
  windowSetTitle(w.impl, text)

proc onclosingWrapper(w: ptr rawui.Window; data: pointer): cint {.cdecl.} =
  let w = cast[Window](data)
  if w.onclosing != nil: w.onclosing()

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

proc openFile*(parent: Window): cstring = $openFile(parent.impl)
proc saveFile*(parent: Window): cstring = $saveFile(parent.impl)
proc msgBox*(parent: Window; title, desc: string) =
  msgBox(parent.impl, title, desc)
proc msgBoxError*(parent: Window; title, desc: string) =
  msgBoxError(parent.impl, title, desc)

# ------------------------- Box ------------------------------------------

type
  Box* = ref object of Widget
    impl*: ptr rawui.Box
    children*: seq[Widget]

proc add*[SomeWidget: Widget](b: Box; child: SomeWidget; stretchy: bool) =
  boxAppend(b.impl, child.impl, cint(stretchy))
  b.children.add child

proc delete*(b: Box; index: int) = boxDelete(b.impl, index.uint64)
proc padded*(b: Box): bool = boxPadded(b.impl) != 0
proc `padded=`*(b: Box; x: bool) = boxSetPadded(b.impl, x.cint)

proc newHorizontalBox*(): Box =
  newFinal(result)
  result.impl = rawui.newHorizontalBox()
  result.children = @[]

proc newVerticalBox*(): Box =
  newFinal(result)
  result.impl = rawui.newVerticalBox()
  result.children = @[]

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

proc newEntry*(onchanged: proc() = nil): Entry =
  newFinal(result)
  result.impl = rawui.newEntry()
  result.impl.entryOnChanged(wrapOnchanged, cast[pointer](result))
  result.onchanged = onchanged

# ----------------- Label ----------------------------------------

type
  Label* = ref object of Widget
    impl*: ptr rawui.Label

proc text*(l: Label): string = $labelText(l.impl)
proc `text=`*(l: Label; text: string) = labelSetText(l.impl, text)
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
  tabDelete(t.impl, index.uint64)
  t.children.delete(index)

proc numPages*(t: Tab): int = tabNumPages(t.impl).int
proc margined*(t: Tab; page: int): bool =
  tabMargined(t.impl, page.uint64) != 0
proc `margined=`*(t: Tab; page: int; x: bool) =
  tabSetMargined(t.impl, page.uint64, cint(x))
proc newTab*(): Tab =
  newFinal result
  result.impl = rawui.newTab()
  result.children = @[]

# ------------- Group --------------------------------------------------

type
  Group* = ref object of Widget
    impl*: ptr rawui.Group
    child*: Widget

proc title*(g: Group): string = $groupTitle(g.impl)
proc `title=`*(g: Group; title: string) =
  groupSetTitle(g.impl, title)
proc `child=`*[SomeWidget: Widget](g: Group; c: SomeWidget) =
  groupSetChild(g.impl, c.impl)
  g.child = c
proc margined*(g: Group): bool = groupMargined(g.impl) != 0
proc `margined=`*(g: Group; x: bool) =
  groupSetMargined(g.impl, x.cint)

proc newGroup*(title: string): Group =
  newFinal result
  result.impl = rawui.newGroup(title)

# ----------------------- Spinbox ---------------------------------------

type
  Spinbox* = ref object of Widget
    impl*: ptr rawui.Spinbox
    onchanged*: proc()

proc value*(s: Spinbox): int64 = spinboxValue(s.impl)
proc `value=`*(s: Spinbox; value: int64) = spinboxSetValue(s.impl, value)

voidCallback wrapsbOnChanged, Spinbox, Spinbox, onchanged

proc newSpinbox*(min: int64; max: int64; onchanged: proc () = nil): Spinbox =
  newFinal result
  result.impl = rawui.newSpinbox(min, max)
  spinboxOnChanged result.impl, wrapsbOnChanged, cast[pointer](result)
  result.onchanged = onchanged

# ---------------------- Slider ---------------------------------------

type
  Slider* = ref object of Widget
    impl*: ptr rawui.Slider
    onchanged*: proc()

proc value*(s: Slider): int64 = sliderValue(s.impl)
proc `value=`*(s: Slider; value: int64) = sliderSetValue(s.impl, value)

voidCallback wrapslOnChanged, Slider, Slider, onchanged

proc newSlider*(min: int64; max: int64; onchanged: proc () = nil): Slider =
  newFinal result
  result.impl = rawui.newSlider(min, max)
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
proc selected*(c: Combobox): int64 = comboboxSelected(c.impl)
proc `selected=`*(c: Combobox; n: int64) =
  comboboxSetSelected c.impl, n

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

# ------------------------ RadioButtons ----------------------------

type
  RadioButtons* = ref object of Widget
    impl*: ptr rawui.RadioButtons

proc add*(r: RadioButtons; text: string) =
  radioButtonsAppend(r.impl, text)
proc newRadioButtons*(): RadioButtons =
  newFinal result
  result.impl = rawui.newRadioButtons()

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

proc addItem*(m: Menu; name: string): MenuItem =
  addMenuItemImpl(menuAppendItem(m.impl, name))

proc addCheckItem*(m: Menu; name: string): MenuItem =
  addMenuItemImpl(menuAppendCheckItem(m.impl, name))

proc addQuitItem*(m: Menu): MenuItem =
  addMenuItemImpl(menuAppendQuitItem(m.impl))
proc addPreferencesItem*(m: Menu): MenuItem =
  addMenuItemImpl(menuAppendPreferencesItem(m.impl))
proc addAboutItem*(m: Menu): MenuItem =
  addMenuItemImpl(menuAppendAboutItem(m.impl))

proc addSeparator*(m: Menu) =
  menuAppendSeparator m.impl

proc newMenu*(name: string): Menu =
  newFinal result
  result.impl = rawui.newMenu(name)
  result.children = @[]
