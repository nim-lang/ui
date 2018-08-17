    when defined(useLibUiDll):
  when defined(windows):
    const
      dllName* = "libui.dll"
  elif defined(macosx):
    const
      dllName* = "libui.dylib"
  else:
    const
      dllName* = "libui.so"
  {.pragma: mylib, dynlib: dllName.}
else:
  {.pragma: mylib.}
  when defined(linux):
    # thanks to 'import math' missing linking flags are added
    import math
    from strutils import replace
    const cflags = (staticExec"pkg-config --cflags gtk+-3.0").replace('\L', ' ')
    const lflags = (staticExec"pkg-config --libs gtk+-3.0").replace('\L', ' ')
    {.passC: cflags.}
    {.passL: lflags.}

  {.compile: ("./libui/common/*.c", "common_$#.obj").}
  when defined(windows):
    {.compile: ("./libui/windows/*.cpp", "win_$#.obj").}
  elif defined(macosx):
    {.compile: ("./libui/darwin/*.m", "osx_$#.obj").}

    {.passL: "-framework OpenGL".}
    {.passL: "-framework CoreAudio".}
    {.passL: "-framework AudioToolbox".}
    {.passL: "-framework AudioUnit".}
    {.passL: "-framework Carbon".}
    {.passL: "-framework IOKit".}
    {.passL: "-framework Cocoa".}
  else:
    {.compile: ("./libui/unix/*.c", "unix_$#.obj").}
  when defined(gcc) and defined(windows):
    #{.passL: r"C:\Users\rumpf\projects\mingw64\x86_64-w64-mingw32\lib\liboleaut32.a".}
    {.passL: r"-lwinspool".}
    {.passL: r"-lcomdlg32".}
    {.passL: r"-ladvapi32".}
    {.passL: r"-lshell32".}
    {.passL: r"-lole32".}
    {.passL: r"-loleaut32".}

    {.passL: r"-luuid".}
    {.passL: r"-lcomctl32".}
    {.passL: r"-ld2d1".}
    {.passL: r"-ldwrite".}
    {.passL: r"-lUxTheme".}
    {.passL: r"-lUsp10".}
    {.passL: r"-lgdi32".}
    {.passL: r"-luser32".}
    {.passL: r"-lkernel32".}
    {.link: r"..\res\resources.o".}

  when defined(vcc):
    {.passC: "/EHsc".}
    when false:
      const arch = when defined(cpu32): "x86" else: "x64"
      {.link: r"C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\" & arch & r"\d2d1.lib".}
      {.link: r"C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\" & arch & r"\dwrite.lib".}
      {.link: r"C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\" & arch & r"\UxTheme.lib".}
      {.link: r"C:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\" & arch & r"\Usp10.lib".}

    {.link: r"kernel32.lib".}
    {.link: r"user32.lib".}
    {.link: r"gdi32.lib".}
    {.link: r"winspool.lib".}
    {.link: r"comdlg32.lib".}
    {.link: r"advapi32.lib".}
    {.link: r"shell32.lib".}
    {.link: r"ole32.lib".}
    {.link: r"oleaut32.lib".}
    {.link: r"uuid.lib".}
    {.link: r"comctl32.lib".}

    {.link: r"d2d1.lib".}
    {.link: r"dwrite.lib".}
    {.link: r"UxTheme.lib".}
    {.link: r"Usp10.lib".}
    {.link: r"..\res\resources.res".}

import times

type
  ForEach* {.size: sizeof(cint).} = enum
    ForEachContinue,
    ForEachStop,

  InitOptions* = object
    size*: csize

{.deadCodeElim: on.}

proc init*(options: ptr InitOptions): cstring {.cdecl, importc: "uiInit",
    mylib.}
proc uninit*() {.cdecl, importc: "uiUninit", mylib.}
proc freeInitError*(err: cstring) {.cdecl, importc: "uiFreeInitError", mylib.}
proc main*() {.cdecl, importc: "uiMain", mylib.}
proc mainSteps*() {.cdecl, importc: "uiMainSteps", mylib.}
proc mainStep*(wait: cint): cint {.cdecl, importc: "uiMainStep", mylib.}
proc quit*() {.cdecl, importc: "uiQuit", mylib.}
proc queueMain*(f: proc (data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiQueueMain", mylib.}

proc timer*(milliseconds: cint, f: proc (data: pointer): cint {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiTimer", mylib.}

proc onShouldQuit*(f: proc (data: pointer): cint {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiOnShouldQuit", mylib.}
proc freeText*(text: cstring) {.cdecl, importc: "uiFreeText", mylib.}
type
  Control* {.inheritable, pure.} = object
    signature*: uint32
    oSSignature*: uint32
    typeSignature*: uint32
    destroy*: proc (a2: ptr Control) {.cdecl.}
    handle*: proc (a2: ptr Control): int {.cdecl.}
    parent*: proc (a2: ptr Control): ptr Control {.cdecl.}
    setParent*: proc (a2: ptr Control; a3: ptr Control) {.cdecl.}
    toplevel*: proc (a2: ptr Control): cint {.cdecl.}
    visible*: proc (a2: ptr Control): cint {.cdecl.}
    show*: proc (a2: ptr Control) {.cdecl.}
    hide*: proc (a2: ptr Control) {.cdecl.}
    enabled*: proc (a2: ptr Control): cint {.cdecl.}
    enable*: proc (a2: ptr Control) {.cdecl.}
    disable*: proc (a2: ptr Control) {.cdecl.}



template toUiControl*(this: untyped): untyped =
  (cast[ptr Control]((this)))

proc controlDestroy*(a2: ptr Control) {.cdecl, importc: "uiControlDestroy",
                                    mylib.}
proc controlHandle*(a2: ptr Control): int {.cdecl, importc: "uiControlHandle",
                                       mylib.}
proc controlParent*(a2: ptr Control): ptr Control {.cdecl, importc: "uiControlParent",
    mylib.}
proc controlSetParent*(a2: ptr Control; a3: ptr Control) {.cdecl,
    importc: "uiControlSetParent", mylib.}
proc controlToplevel*(a2: ptr Control): cint {.cdecl, importc: "uiControlToplevel",
    mylib.}
proc controlVisible*(a2: ptr Control): cint {.cdecl, importc: "uiControlVisible",
    mylib.}
proc controlShow*(a2: ptr Control) {.cdecl, importc: "uiControlShow", mylib.}
proc controlHide*(a2: ptr Control) {.cdecl, importc: "uiControlHide", mylib.}
proc controlEnabled*(a2: ptr Control): cint {.cdecl, importc: "uiControlEnabled",
    mylib.}
proc controlEnable*(a2: ptr Control) {.cdecl, importc: "uiControlEnable",
                                   mylib.}
proc controlDisable*(a2: ptr Control) {.cdecl, importc: "uiControlDisable",
                                    mylib.}
proc allocControl*(n: csize; oSsig: uint32; typesig: uint32; typenamestr: cstring): ptr Control {.
    cdecl, importc: "uiAllocControl", mylib.}
proc freeControl*(a2: ptr Control) {.cdecl, importc: "uiFreeControl", mylib.}

proc controlVerifySetParent*(a2: ptr Control; a3: ptr Control) {.cdecl,
    importc: "uiControlVerifySetParent", mylib.}
proc controlEnabledToUser*(a2: ptr Control): cint {.cdecl,
    importc: "uiControlEnabledToUser", mylib.}
proc userBugCannotSetParentOnToplevel*(`type`: cstring) {.cdecl,
    importc: "uiUserBugCannotSetParentOnToplevel", mylib.}
type
  Window* = object of Control


template toUiWindow*(this: untyped): untyped =
  (cast[ptr Window]((this)))

proc windowTitle*(w: ptr Window): cstring {.cdecl, importc: "uiWindowTitle",
                                       mylib.}
proc windowSetTitle*(w: ptr Window; title: cstring) {.cdecl,
    importc: "uiWindowSetTitle", mylib.}
proc windowContentSize*(w: ptr Window; width: ptr cint; height: ptr cint) {.cdecl,
    importc: "uiWindowContentSize", mylib.}
proc windowSetContentSize*(w: ptr Window; width: cint; height: cint) {.cdecl,
    importc: "uiWindowSetContentSize", mylib.}
proc windowFullscreen*(w: ptr Window): cint {.cdecl, importc: "uiWindowFullscreen",
    mylib.}
proc windowSetFullscreen*(w: ptr Window; fullscreen: cint) {.cdecl,
    importc: "uiWindowSetFullscreen", mylib.}
proc windowOnContentSizeChanged*(w: ptr Window;
                                f: proc (a2: ptr Window; a3: pointer) {.cdecl.};
                                data: pointer) {.cdecl,
    importc: "uiWindowOnContentSizeChanged", mylib.}
proc windowOnClosing*(w: ptr Window;
                     f: proc (w: ptr Window; data: pointer): cint {.cdecl.};
                     data: pointer) {.cdecl, importc: "uiWindowOnClosing",
                                    mylib.}
proc windowBorderless*(w: ptr Window): cint {.cdecl, importc: "uiWindowBorderless",
    mylib.}
proc windowSetBorderless*(w: ptr Window; borderless: cint) {.cdecl,
    importc: "uiWindowSetBorderless", mylib.}
proc windowSetChild*(w: ptr Window; child: ptr Control) {.cdecl,
    importc: "uiWindowSetChild", mylib.}
proc windowMargined*(w: ptr Window): cint {.cdecl, importc: "uiWindowMargined",
                                       mylib.}
proc windowSetMargined*(w: ptr Window; margined: cint) {.cdecl,
    importc: "uiWindowSetMargined", mylib.}
proc newWindow*(title: cstring; width: cint; height: cint; hasMenubar: cint): ptr Window {.
    cdecl, importc: "uiNewWindow", mylib.}
type
  Button* = object of Control


template toUiButton*(this: untyped): untyped =
  (cast[ptr Button]((this)))

proc buttonText*(b: ptr Button): cstring {.cdecl, importc: "uiButtonText",
                                      mylib.}
proc buttonSetText*(b: ptr Button; text: cstring) {.cdecl, importc: "uiButtonSetText",
    mylib.}
proc buttonOnClicked*(b: ptr Button;
                     f: proc (b: ptr Button; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiButtonOnClicked", mylib.}
proc newButton*(text: cstring): ptr Button {.cdecl, importc: "uiNewButton",
                                        mylib.}
type
  Box* = object of Control


template toUiBox*(this: untyped): untyped =
  (cast[ptr Box]((this)))

proc boxAppend*(b: ptr Box; child: ptr Control; stretchy: cint) {.cdecl,
    importc: "uiBoxAppend", mylib.}
proc boxDelete*(b: ptr Box; index: cint) {.cdecl, importc: "uiBoxDelete", mylib.}
proc boxPadded*(b: ptr Box): cint {.cdecl, importc: "uiBoxPadded", mylib.}
proc boxSetPadded*(b: ptr Box; padded: cint) {.cdecl, importc: "uiBoxSetPadded",
    mylib.}
proc newHorizontalBox*(): ptr Box {.cdecl, importc: "uiNewHorizontalBox",
                                mylib.}
proc newVerticalBox*(): ptr Box {.cdecl, importc: "uiNewVerticalBox", mylib.}
type
  Checkbox* = object of Control


template toUiCheckbox*(this: untyped): untyped =
  (cast[ptr Checkbox]((this)))

proc checkboxText*(c: ptr Checkbox): cstring {.cdecl, importc: "uiCheckboxText",
    mylib.}
proc checkboxSetText*(c: ptr Checkbox; text: cstring) {.cdecl,
    importc: "uiCheckboxSetText", mylib.}
proc checkboxOnToggled*(c: ptr Checkbox;
                       f: proc (c: ptr Checkbox; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiCheckboxOnToggled", mylib.}
proc checkboxChecked*(c: ptr Checkbox): cint {.cdecl, importc: "uiCheckboxChecked",
    mylib.}
proc checkboxSetChecked*(c: ptr Checkbox; checked: cint) {.cdecl,
    importc: "uiCheckboxSetChecked", mylib.}
proc newCheckbox*(text: cstring): ptr Checkbox {.cdecl, importc: "uiNewCheckbox",
    mylib.}
type
  Entry* = object of Control


template toUiEntry*(this: untyped): untyped =
  (cast[ptr Entry]((this)))

proc entryText*(e: ptr Entry): cstring {.cdecl, importc: "uiEntryText", mylib.}
proc entrySetText*(e: ptr Entry; text: cstring) {.cdecl, importc: "uiEntrySetText",
    mylib.}
proc entryOnChanged*(e: ptr Entry; f: proc (e: ptr Entry; data: pointer) {.cdecl.};
                    data: pointer) {.cdecl, importc: "uiEntryOnChanged",
                                   mylib.}
proc entryReadOnly*(e: ptr Entry): cint {.cdecl, importc: "uiEntryReadOnly",
                                     mylib.}
proc entrySetReadOnly*(e: ptr Entry; readonly: cint) {.cdecl,
    importc: "uiEntrySetReadOnly", mylib.}
proc newEntry*(): ptr Entry {.cdecl, importc: "uiNewEntry", mylib.}
proc newPasswordEntry*(): ptr Entry {.cdecl, importc: "uiNewPasswordEntry",
                                  mylib.}
proc newSearchEntry*(): ptr Entry {.cdecl, importc: "uiNewSearchEntry", mylib.}
type
  Label* = object of Control


template toUiLabel*(this: untyped): untyped =
  (cast[ptr Label]((this)))

proc labelText*(label: ptr Label): cstring {.cdecl, importc: "uiLabelText",
                                        mylib.}
proc labelSetText*(label: ptr Label; text: cstring) {.cdecl, importc: "uiLabelSetText",
    mylib.}
proc newLabel*(text: cstring): ptr Label {.cdecl, importc: "uiNewLabel", mylib.}
type
  Tab* = object of Control


template toUiTab*(this: untyped): untyped =
  (cast[ptr Tab]((this)))

proc tabAppend*(t: ptr Tab; name: cstring; c: ptr Control) {.cdecl,
    importc: "uiTabAppend", mylib.}
proc tabInsertAt*(t: ptr Tab; name: cstring; before: cint; c: ptr Control) {.cdecl,
    importc: "uiTabInsertAt", mylib.}
proc tabDelete*(t: ptr Tab; index: cint) {.cdecl, importc: "uiTabDelete", mylib.}
proc tabNumPages*(t: ptr Tab): cint {.cdecl, importc: "uiTabNumPages", mylib.}
proc tabMargined*(t: ptr Tab; page: cint): cint {.cdecl, importc: "uiTabMargined",
    mylib.}
proc tabSetMargined*(t: ptr Tab; page: cint; margined: cint) {.cdecl,
    importc: "uiTabSetMargined", mylib.}
proc newTab*(): ptr Tab {.cdecl, importc: "uiNewTab", mylib.}
type
  Group* = object of Control


template toUiGroup*(this: untyped): untyped =
  (cast[ptr Group]((this)))

proc groupTitle*(g: ptr Group): cstring {.cdecl, importc: "uiGroupTitle",
                                     mylib.}
proc groupSetTitle*(g: ptr Group; title: cstring) {.cdecl, importc: "uiGroupSetTitle",
    mylib.}
proc groupSetChild*(g: ptr Group; c: ptr Control) {.cdecl, importc: "uiGroupSetChild",
    mylib.}
proc groupMargined*(g: ptr Group): cint {.cdecl, importc: "uiGroupMargined",
                                     mylib.}
proc groupSetMargined*(g: ptr Group; margined: cint) {.cdecl,
    importc: "uiGroupSetMargined", mylib.}
proc newGroup*(title: cstring): ptr Group {.cdecl, importc: "uiNewGroup",
                                       mylib.}

type
  Spinbox* = object of Control


template toUiSpinbox*(this: untyped): untyped =
  (cast[ptr Spinbox]((this)))

proc spinboxValue*(s: ptr Spinbox): cint {.cdecl, importc: "uiSpinboxValue",
                                      mylib.}
proc spinboxSetValue*(s: ptr Spinbox; value: cint) {.cdecl,
    importc: "uiSpinboxSetValue", mylib.}
proc spinboxOnChanged*(s: ptr Spinbox;
                      f: proc (s: ptr Spinbox; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiSpinboxOnChanged", mylib.}
proc newSpinbox*(min: cint; max: cint): ptr Spinbox {.cdecl, importc: "uiNewSpinbox",
    mylib.}
type
  Slider* = object of Control


template toUiSlider*(this: untyped): untyped =
  (cast[ptr Slider]((this)))

proc sliderValue*(s: ptr Slider): cint {.cdecl, importc: "uiSliderValue",
                                    mylib.}
proc sliderSetValue*(s: ptr Slider; value: cint) {.cdecl, importc: "uiSliderSetValue",
    mylib.}
proc sliderOnChanged*(s: ptr Slider;
                     f: proc (s: ptr Slider; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiSliderOnChanged", mylib.}
proc newSlider*(min: cint; max: cint): ptr Slider {.cdecl, importc: "uiNewSlider",
    mylib.}
type
  ProgressBar* = object of Control


template toUiProgressBar*(this: untyped): untyped =
  (cast[ptr ProgressBar]((this)))

proc progressBarValue*(p: ptr ProgressBar): cint {.cdecl,
    importc: "uiProgressBarValue", mylib.}
proc progressBarSetValue*(p: ptr ProgressBar; n: cint) {.cdecl,
    importc: "uiProgressBarSetValue", mylib.}
proc newProgressBar*(): ptr ProgressBar {.cdecl, importc: "uiNewProgressBar",
                                      mylib.}
type
  Separator* = object of Control


template toUiSeparator*(this: untyped): untyped =
  (cast[ptr Separator]((this)))

proc newHorizontalSeparator*(): ptr Separator {.cdecl,
    importc: "uiNewHorizontalSeparator", mylib.}
proc newVerticalSeparator*(): ptr Separator {.cdecl,
    importc: "uiNewVerticalSeparator", mylib.}
type
  Combobox* = object of Control


template toUiCombobox*(this: untyped): untyped =
  (cast[ptr Combobox]((this)))

proc comboboxAppend*(c: ptr Combobox; text: cstring) {.cdecl,
    importc: "uiComboboxAppend", mylib.}
proc comboboxSelected*(c: ptr Combobox): cint {.cdecl, importc: "uiComboboxSelected",
    mylib.}
proc comboboxSetSelected*(c: ptr Combobox; n: cint) {.cdecl,
    importc: "uiComboboxSetSelected", mylib.}
proc comboboxOnSelected*(c: ptr Combobox;
                        f: proc (c: ptr Combobox; data: pointer) {.cdecl.};
                        data: pointer) {.cdecl, importc: "uiComboboxOnSelected",
                                       mylib.}
proc newCombobox*(): ptr Combobox {.cdecl, importc: "uiNewCombobox", mylib.}
type
  EditableCombobox* = object of Control


template toUiEditableCombobox*(this: untyped): untyped =
  (cast[ptr EditableCombobox]((this)))

proc editableComboboxAppend*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxAppend", mylib.}
proc editableComboboxText*(c: ptr EditableCombobox): cstring {.cdecl,
    importc: "uiEditableComboboxText", mylib.}
proc editableComboboxSetText*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxSetText", mylib.}

proc editableComboboxOnChanged*(c: ptr EditableCombobox; f: proc (
    c: ptr EditableCombobox; data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiEditableComboboxOnChanged", mylib.}
proc newEditableCombobox*(): ptr EditableCombobox {.cdecl,
    importc: "uiNewEditableCombobox", mylib.}
type
  RadioButtons* = object of Control


template toUiRadioButtons*(this: untyped): untyped =
  (cast[ptr RadioButtons]((this)))

proc radioButtonsAppend*(r: ptr RadioButtons; text: cstring) {.cdecl,
    importc: "uiRadioButtonsAppend", mylib.}
proc radioButtonsSelected*(r: ptr RadioButtons): cint {.cdecl,
    importc: "uiRadioButtonsSelected", mylib.}
proc radioButtonsSetSelected*(r: ptr RadioButtons; n: cint) {.cdecl,
    importc: "uiRadioButtonsSetSelected", mylib.}
proc radioButtonsOnSelected*(r: ptr RadioButtons; f: proc (a2: ptr RadioButtons;
    a3: pointer) {.cdecl.}; data: pointer) {.cdecl,
                                        importc: "uiRadioButtonsOnSelected",
                                        mylib.}
proc newRadioButtons*(): ptr RadioButtons {.cdecl, importc: "uiNewRadioButtons",
                                        mylib.}
type
  StructTm* = object
  DateTimePicker* = object of Control


template toUiDateTimePicker*(this: untyped): untyped =
  (cast[ptr DateTimePicker]((this)))

proc dateTimePickerTime*(d: ptr DateTimePicker,
                        time: ptr StructTm){.cdecl, importc: "uiDateTimePickerTime",
                        mylib.}
proc dateTimePickerSetTime*(d: ptr DateTimePicker,
                        time: ptr StructTm){.cdecl, importc: "uiDateTimePickerSetTime",
                        mylib.}
proc dateTimePickerOnChanged*(d: ptr DateTimePicker,
                        f: proc (a1: ptr DateTimePicker; a2: pointer),
                        data: pointer){.cdecl, importc: "uiDateTimePickerOnChanged",
                        mylib.}
proc newDateTimePicker*(): ptr DateTimePicker {.cdecl,
    importc: "uiNewDateTimePicker", mylib.}
proc newDatePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewDatePicker",
                                        mylib.}
proc newTimePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewTimePicker",
                                        mylib.}

type
  MultilineEntry* = object of Control


template toUiMultilineEntry*(this: untyped): untyped =
  (cast[ptr MultilineEntry]((this)))

proc multilineEntryText*(e: ptr MultilineEntry): cstring {.cdecl,
    importc: "uiMultilineEntryText", mylib.}
proc multilineEntrySetText*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntrySetText", mylib.}
proc multilineEntryAppend*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntryAppend", mylib.}
proc multilineEntryOnChanged*(e: ptr MultilineEntry; f: proc (e: ptr MultilineEntry;
    data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMultilineEntryOnChanged", mylib.}
proc multilineEntryReadOnly*(e: ptr MultilineEntry): cint {.cdecl,
    importc: "uiMultilineEntryReadOnly", mylib.}
proc multilineEntrySetReadOnly*(e: ptr MultilineEntry; readonly: cint) {.cdecl,
    importc: "uiMultilineEntrySetReadOnly", mylib.}
proc newMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewMultilineEntry", mylib.}
proc newNonWrappingMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewNonWrappingMultilineEntry", mylib.}
type
  MenuItem* = object of Control


template toUiMenuItem*(this: untyped): untyped =
  (cast[ptr MenuItem]((this)))

proc menuItemEnable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemEnable",
                                    mylib.}
proc menuItemDisable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemDisable",
                                     mylib.}
proc menuItemOnClicked*(m: ptr MenuItem; f: proc (sender: ptr MenuItem;
    window: ptr Window; data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMenuItemOnClicked", mylib.}
proc menuItemChecked*(m: ptr MenuItem): cint {.cdecl, importc: "uiMenuItemChecked",
    mylib.}
proc menuItemSetChecked*(m: ptr MenuItem; checked: cint) {.cdecl,
    importc: "uiMenuItemSetChecked", mylib.}
type
  Menu* = object of Control


template toUiMenu*(this: untyped): untyped =
  (cast[ptr Menu]((this)))

proc menuAppendItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendItem", mylib.}
proc menuAppendCheckItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendCheckItem", mylib.}
proc menuAppendQuitItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendQuitItem", mylib.}
proc menuAppendPreferencesItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendPreferencesItem", mylib.}
proc menuAppendAboutItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendAboutItem", mylib.}
proc menuAppendSeparator*(m: ptr Menu) {.cdecl, importc: "uiMenuAppendSeparator",
                                     mylib.}
proc newMenu*(name: cstring): ptr Menu {.cdecl, importc: "uiNewMenu", mylib.}
proc openFile*(parent: ptr Window): cstring {.cdecl, importc: "uiOpenFile",
    mylib.}
proc saveFile*(parent: ptr Window): cstring {.cdecl, importc: "uiSaveFile",
    mylib.}
proc msgBox*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBox", mylib.}
proc msgBoxError*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBoxError", mylib.}
type
  Area* = object of Control

  Modifiers* {.size: sizeof(cint).} = enum
    ModifierCtrl = 1 shl 0, ModifierAlt = 1 shl 1, ModifierShift = 1 shl 2,
    ModifierSuper = 1 shl 3



type
  AreaMouseEvent* = object
    x*: cdouble
    y*: cdouble
    areaWidth*: cdouble
    areaHeight*: cdouble
    down*: cint
    up*: cint
    count*: cint
    modifiers*: Modifiers
    held1To64*: uint64

  ExtKey* {.size: sizeof(cint).} = enum
    ExtKeyEscape = 1, ExtKeyInsert, ExtKeyDelete, ExtKeyHome, ExtKeyEnd, ExtKeyPageUp,
    ExtKeyPageDown, ExtKeyUp, ExtKeyDown, ExtKeyLeft, ExtKeyRight, ExtKeyF1, ExtKeyF2,
    ExtKeyF3, ExtKeyF4, ExtKeyF5, ExtKeyF6, ExtKeyF7, ExtKeyF8, ExtKeyF9, ExtKeyF10,
    ExtKeyF11, ExtKeyF12, ExtKeyN0, ExtKeyN1, ExtKeyN2, ExtKeyN3, ExtKeyN4, ExtKeyN5,
    ExtKeyN6, ExtKeyN7, ExtKeyN8, ExtKeyN9, ExtKeyNDot, ExtKeyNEnter, ExtKeyNAdd,
    ExtKeyNSubtract, ExtKeyNMultiply, ExtKeyNDivide


type
  AreaKeyEvent* = object
    key*: char
    extKey*: ExtKey
    modifier*: Modifiers
    modifiers*: Modifiers
    up*: cint

  DrawContext* = object

  AreaDrawParams* = object
    context*: ptr DrawContext
    areaWidth*: cdouble
    areaHeight*: cdouble
    clipX*: cdouble
    clipY*: cdouble
    clipWidth*: cdouble
    clipHeight*: cdouble

  AreaHandler* = object
    draw*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaDrawParams) {.cdecl.}
    mouseEvent*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaMouseEvent) {.cdecl.}
    mouseCrossed*: proc (a2: ptr AreaHandler; a3: ptr Area; left: cint) {.cdecl.}
    dragBroken*: proc (a2: ptr AreaHandler; a3: ptr Area) {.cdecl.}
    keyEvent*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaKeyEvent): cint {.cdecl.}


template toUiArea*(this: untyped): untyped =
  (cast[ptr Area]((this)))


proc areaSetSize*(a: ptr Area; width: cint; height: cint) {.cdecl,
    importc: "uiAreaSetSize", mylib.}

proc areaQueueRedrawAll*(a: ptr Area) {.cdecl, importc: "uiAreaQueueRedrawAll",
                                    mylib.}
proc areaScrollTo*(a: ptr Area; x: cdouble; y: cdouble; width: cdouble; height: cdouble) {.
    cdecl, importc: "uiAreaScrollTo", mylib.}
proc newArea*(ah: ptr AreaHandler): ptr Area {.cdecl, importc: "uiNewArea",
    mylib.}
proc newScrollingArea*(ah: ptr AreaHandler; width: cint; height: cint): ptr Area {.cdecl,
    importc: "uiNewScrollingArea", mylib.}
type
  DrawPath* = object

  DrawBrushType* {.size: sizeof(cint).} = enum
    DrawBrushTypeSolid, DrawBrushTypeLinearGradient, DrawBrushTypeRadialGradient,
    DrawBrushTypeImage


type
  DrawLineCap* {.size: sizeof(cint).} = enum
    DrawLineCapFlat, DrawLineCapRound, DrawLineCapSquare


type
  DrawLineJoin* {.size: sizeof(cint).} = enum
    DrawLineJoinMiter, DrawLineJoinRound, DrawLineJoinBevel



const
  DrawDefaultMiterLimit* = 10.0

type
  DrawFillMode* {.size: sizeof(cint).} = enum
    DrawFillModeWinding, DrawFillModeAlternate


type
  DrawMatrix* = object
    m11*: cdouble
    m12*: cdouble
    m21*: cdouble
    m22*: cdouble
    m31*: cdouble
    m32*: cdouble

  DrawBrush* = object
    `type`*: DrawBrushType
    r*: cdouble
    g*: cdouble
    b*: cdouble
    a*: cdouble
    x0*: cdouble
    y0*: cdouble
    x1*: cdouble
    y1*: cdouble
    outerRadius*: cdouble
    stops*: ptr DrawBrushGradientStop
    numStops*: csize

  DrawBrushGradientStop* = object
    pos*: cdouble
    r*: cdouble
    g*: cdouble
    b*: cdouble
    a*: cdouble

  DrawStrokeParams* = object
    cap*: DrawLineCap
    join*: DrawLineJoin
    thickness*: cdouble
    miterLimit*: cdouble
    dashes*: ptr cdouble
    numDashes*: csize
    dashPhase*: cdouble


proc drawNewPath*(fillMode: DrawFillMode): ptr DrawPath {.cdecl,
    importc: "uiDrawNewPath", mylib.}
proc drawFreePath*(p: ptr DrawPath) {.cdecl, importc: "uiDrawFreePath", mylib.}
proc drawPathNewFigure*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathNewFigure", mylib.}
proc drawPathNewFigureWithArc*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                              radius: cdouble; startAngle: cdouble; sweep: cdouble;
                              negative: cint) {.cdecl,
    importc: "uiDrawPathNewFigureWithArc", mylib.}
proc drawPathLineTo*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathLineTo", mylib.}

proc drawPathArcTo*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                   radius: cdouble; startAngle: cdouble; sweep: cdouble;
                   negative: cint) {.cdecl, importc: "uiDrawPathArcTo",
                                   mylib.}
proc drawPathBezierTo*(p: ptr DrawPath; c1x: cdouble; c1y: cdouble; c2x: cdouble;
                      c2y: cdouble; endX: cdouble; endY: cdouble) {.cdecl,
    importc: "uiDrawPathBezierTo", mylib.}

proc drawPathCloseFigure*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathCloseFigure",
    mylib.}

proc drawPathAddRectangle*(p: ptr DrawPath; x: cdouble; y: cdouble; width: cdouble;
                          height: cdouble) {.cdecl,
    importc: "uiDrawPathAddRectangle", mylib.}
proc drawPathEnd*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathEnd", mylib.}
proc drawStroke*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush;
                p: ptr DrawStrokeParams) {.cdecl, importc: "uiDrawStroke",
                                        mylib.}
proc drawFill*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush) {.cdecl,
    importc: "uiDrawFill", mylib.}

proc drawMatrixSetIdentity*(m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixSetIdentity", mylib.}
proc drawMatrixTranslate*(m: ptr DrawMatrix; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawMatrixTranslate", mylib.}
proc drawMatrixScale*(m: ptr DrawMatrix; xCenter: cdouble; yCenter: cdouble; x: cdouble;
                     y: cdouble) {.cdecl, importc: "uiDrawMatrixScale",
                                 mylib.}
proc drawMatrixRotate*(m: ptr DrawMatrix; x: cdouble; y: cdouble; amount: cdouble) {.
    cdecl, importc: "uiDrawMatrixRotate", mylib.}
proc drawMatrixSkew*(m: ptr DrawMatrix; x: cdouble; y: cdouble; xamount: cdouble;
                    yamount: cdouble) {.cdecl, importc: "uiDrawMatrixSkew",
                                      mylib.}
proc drawMatrixMultiply*(dest: ptr DrawMatrix; src: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixMultiply", mylib.}
proc drawMatrixInvertible*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvertible", mylib.}
proc drawMatrixInvert*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvert", mylib.}
proc drawMatrixTransformPoint*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformPoint", mylib.}
proc drawMatrixTransformSize*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformSize", mylib.}
proc drawTransform*(c: ptr DrawContext; m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawTransform", mylib.}

proc drawClip*(c: ptr DrawContext; path: ptr DrawPath) {.cdecl, importc: "uiDrawClip",
    mylib.}
proc drawSave*(c: ptr DrawContext) {.cdecl, importc: "uiDrawSave", mylib.}
proc drawRestore*(c: ptr DrawContext) {.cdecl, importc: "uiDrawRestore",
                                    mylib.}

type
  Attribute* = object
  AttributedString* = object


proc freeAttribute*(a1: ptr Attribute): cstring {.cdecl,
    importc: "uiFreeAttribute", mylib.}

type
    AttributeType* {.size: sizeof(cint).} = enum
        AttributeTypeFamily, AttributeTypeSize, AttributeTypeWeight,
        AttributeTypeItalic, AttributeTypeStretch, AttributeTypeColor,
        AttributeTypeBackground, AttributeTypeUnderline, AttributeTypeUnderlineColor,
        AttributeTypeFeatures

proc AttributeGetType*(a: ptr Attribute): AttributeType {.cdecl,
    importc: "uiAttributeGetType", mylib.}

proc newFamilyAttribute*(family: cstring): ptr Attribute {.cdecl,
importc: "uiNewFamilyAttribute", mylib.}

proc attributeFamily*(a: ptr Attribute): cstring {.cdecl,
importc: "uiAttributeFamily", mylib.}

proc newSizeAttribute*(size: cdouble): ptr Attribute {.cdecl,
importc: "uiNewSizeAttribute", mylib.}

proc attributeSize*(a: ptr Attribute): cdouble {.cdecl,
importc: "uiAttributeSize", mylib.}

type
  DrawTextFont* = object

  TextWeight* {.size: sizeof(cint).} = enum
    TextWeightMinimum = 0
    TextWeightThin = 100
    TextWeightUltraLight = 200
    TextWeightLight = 300
    TextWeightBook = 350
    TextWeightNormal = 400
    TextWeightMedium = 500
    TextWeightSemiBold = 600
    TextWeightBold = 700
    TextWeightUltraBold = 800
    TextWeightHeavy = 900
    TextWeightUltraHeavy = 950
    TextWeightMaximum = 1000

proc newWeightAttribute*(weight: TextWeight): ptr Attribute {.cdecl,
    importc: "uiNewWeightAttribute", mylib.}
proc attributeWeight*(a: ptr Attribute): TextWeight {.cdecl,
    importc: "uiAttributeWeight", mylib.}

type
  TextItalic* {.size: sizeof(cint).} = enum
    TextItalicNormal, TextItalicOblique, TextItalicItalic

proc newItalicAttribute*(italic: TextItalic): ptr Attribute {.cdecl,
    importc: "uiNewItalicAttribute", mylib.}
proc attributeItalic*(a: ptr Attribute): TextItalic {.cdecl,
    importc: "uiAttributeItalic", mylib.}

type
  TextStretch* {.size: sizeof(cint).} = enum
    TextStretchUltraCondensed, TextStretchExtraCondensed,
    TextStretchCondensed, TextStretchSemiCondensed, TextStretchNormal,
    TextStretchSemiExpanded, TextStretchExpanded,
    TextStretchExtraExpanded, TextStretchUltraExpanded

proc newStretchAttribute*(stretch: TextStretch): ptr Attribute {.cdecl,
    importc: "uiNewStretchAttribute", mylib.}
proc attributeStretch*(a: ptr Attribute): TextStretch {.cdecl,
    importc: "uiAttributeStretch", mylib.}
proc newColorAttribute*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): ptr Attribute {.cdecl,
    importc: "uiNewColorAttribute", mylib.}
proc attributeColor*(a: ptr Attribute; r: ptr cdouble; g: ptr cdouble; b: ptr cdouble;
                    alpha: ptr cdouble) {.cdecl,
                    importc: "uiAttributeColor", mylib.}
proc newBackgroundAttribute*(r: cdouble; g: cdouble; b: cdouble; a: cdouble): ptr Attribute {.cdecl,
    importc: "uiNewBackgroundAttribute", mylib.}

type
    Underline* {.size: sizeof(cint).} = enum
        UnderlineNone, UnderlineSingle,
        UnderlineDouble, UnderlineSuggestion

proc newUnderlineAttribute*(u: Underline): ptr Attribute {.cdecl, importc: "uiNewUnderlineAttribute", mylib.}
proc attributeUnderline*(a: ptr Attribute): Underline {.cdecl, importc: "uiAttributeUnderline", mylib.}

type
    UnderlineColor* {.size: sizeof(cint).} = enum
        UnderlineColorCustom, UnderlineColorSpelling,
        UnderlineColorGrammar, UnderlineColorAuxiliary

proc newUnderlineColorAttribute*(u: UnderlineColor; r: cdouble; g: cdouble;
                                    b: cdouble; a: cdouble): ptr Attribute {.cdecl, importc: "uiNewUnderlineColorAttribute", mylib.}
proc attributeUnderlineColor*(a: ptr Attribute; u: ptr UnderlineColor;
                                r: ptr cdouble; g: ptr cdouble; b: ptr cdouble;
                                alpha: ptr cdouble) {.cdecl, importc: "uiAttributeUnderlineColor", mylib.}
type
    OpenTypeFeatures* = object
    OpenTypeFeaturesForEachFunc* = proc (otf: ptr OpenTypeFeatures; a: char; b: char;
                                        c: char; d: char; value: uint32; data: pointer): ForEach

proc newOpenTypeFeatures*(): ptr OpenTypeFeatures {.cdecl, importc: "uiNewOpenTypeFeatures", mylib.}
proc freeOpenTypeFeatures*(otf: ptr OpenTypeFeatures) {.cdecl, importc: "uiFreeOpenTypeFeatures", mylib.}
proc openTypeFeaturesClone*(otf: ptr OpenTypeFeatures): ptr OpenTypeFeatures {.cdecl, importc: "uiOpenTypeFeaturesClone", mylib.}
proc openTypeFeaturesAdd*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char;
                            d: char; value: uint32) {.cdecl, importc: "uiOpenTypeFeaturesAdd", mylib.}
proc openTypeFeaturesRemove*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char;
                                d: char) {.cdecl, importc: "uiOpenTypeFeaturesRemove", mylib.}
proc openTypeFeaturesGet*(otf: ptr OpenTypeFeatures; a: char; b: char; c: char;
                            d: char; value: ptr uint32): cint {.cdecl, importc: "uiOpenTypeFeaturesGet", mylib.}
proc openTypeFeaturesForEach*(otf: ptr OpenTypeFeatures;
                                f: OpenTypeFeaturesForEachFunc; data: pointer) {.cdecl, importc: "uiOpenTypeFeaturesForEach", mylib.}
proc newFeaturesAttribute*(otf: ptr OpenTypeFeatures): ptr Attribute {.cdecl, importc: "uiNewFeaturesAttribute", mylib.}
proc attributeFeatures*(a: ptr Attribute): ptr OpenTypeFeatures {.cdecl, importc: "uiAttributeFeatures", mylib.}

type
    AttributedStringForEachAttributeFunc* = proc (s: ptr AttributedString;
        a: ptr Attribute; start: csize; `end`: csize; data: pointer): ForEach

proc newAttributedString*(initialString: cstring): ptr AttributedString {.cdecl, importc: "uiNewAttributedString", mylib.}
proc freeAttributedString*(s: ptr AttributedString) {.cdecl, importc: "uiFreeAttributedString", mylib.}
proc attributedStringString*(s: ptr AttributedString): cstring {.cdecl, importc: "uiAttributedStringString", mylib.}
proc attributedStringLen*(s: ptr AttributedString): csize {.cdecl, importc: "uiAttributedStringLen", mylib.}
proc attributedStringAppendUnattributed*(s: ptr AttributedString; str: cstring) {.cdecl, importc: "uiAttributedStringAppendUnattributed", mylib.}
proc attributedStringInsertAtUnattributed*(s: ptr AttributedString;
    str: cstring; at: csize) {.cdecl, importc: "uiAttributedStringInsertAtUnattributed", mylib.}
proc attributedStringDelete*(s: ptr AttributedString; start: csize; `end`: csize) {.cdecl, importc: "uiAttributedStringDelete", mylib.}
proc attributedStringSetAttribute*(s: ptr AttributedString; a: ptr Attribute;
                                    start: csize; `end`: csize) {.cdecl, importc: "uiAttributedStringSetAttribute", mylib.}
proc attributedStringForEachAttribute*(s: ptr AttributedString; f: AttributedStringForEachAttributeFunc;
                                        data: pointer) {.cdecl, importc: "uiDruiAttributedStringForEachAttributeawSave", mylib.}
proc attributedStringNumGraphemes*(s: ptr AttributedString): csize {.cdecl, importc: "uiAttributedStringNumGraphemes", mylib.}
proc attributedStringByteIndexToGrapheme*(s: ptr AttributedString; pos: csize): csize {.cdecl, importc: "uiAttributedStringByteIndexToGrapheme", mylib.}
proc attributedStringGraphemeToByteIndex*(s: ptr AttributedString; pos: csize): csize {.cdecl, importc: "uiAttributedStringGraphemeToByteIndex", mylib.}

type
  FontDescriptor* = object
    family*: cstring
    size*: cdouble
    weight*: TextWeight
    italic*: TextItalic
    stretch*: TextStretch

type
    DrawTextLayout* = object
    DrawTextAlign* {.size: sizeof(cint).} = enum
        DrawTextAlignLeft,
        DrawTextAlignCenter
        DrawTextAlignRight

    DrawTextLayoutParams* {.bycopy.} = object
        str*: ptr AttributedString
        defaultFont*: ptr FontDescriptor
        width*: cdouble
        align*: DrawTextAlign

proc drawNewTextLayout*(params: ptr DrawTextLayoutParams): ptr DrawTextLayout {.
    cdecl, importc: "uiDrawNewTextLayout", mylib.}

proc drawFreeTextLayout*(tl: ptr DrawTextLayout) {.cdecl, importc: "uiDrawFreeTextLayout", mylib.}
proc drawText*(c: ptr DrawContext; tl: ptr DrawTextLayout; x: cdouble; y: cdouble) {.cdecl, importc: "uiDrawText", mylib.}
proc drawTextLayoutExtents*(tl: ptr DrawTextLayout; width: ptr cdouble;
                                height: ptr cdouble) {.cdecl, importc: "uiDrawTextLayoutExtents", mylib.}

type
    FontButton* = object of Control

template toUiFontButton*(this: untyped): untyped =
    (cast[ptr FontButton]((this)))

proc fontButtonFont*(b: ptr FontButton; desc: ptr FontDescriptor) {.cdecl, importc: "uiFontButtonFont", mylib.}
proc fontButtonOnChanged*(b: ptr FontButton,
                            f: proc (a1: ptr FontButton; a2: pointer); data: pointer) {.cdecl, importc: "uiFontButtonOnChanged", mylib.}
proc newFontButton*(): ptr FontButton {.cdecl, importc: "uiNewFontButton", mylib.}
proc freeFontButtonFont*(desc: ptr FontDescriptor) {.cdecl, importc: "uiFreeFontButtonFont", mylib.}

type
  ColorButton* = object of Control


template toUiColorButton*(this: untyped): untyped =
  (cast[ptr ColorButton]((this)))

proc colorButtonColor*(b: ptr ColorButton; r: ptr cdouble; g: ptr cdouble;
                      bl: ptr cdouble; a: ptr cdouble) {.cdecl,
    importc: "uiColorButtonColor", mylib.}
proc colorButtonSetColor*(b: ptr ColorButton; r: cdouble; g: cdouble; bl: cdouble;
                         a: cdouble) {.cdecl, importc: "uiColorButtonSetColor",
                                     mylib.}
proc colorButtonOnChanged*(b: ptr ColorButton;
                          f: proc (a2: ptr ColorButton; a3: pointer) {.cdecl.};
                          data: pointer) {.cdecl,
    importc: "uiColorButtonOnChanged", mylib.}
proc newColorButton*(): ptr ColorButton {.cdecl, importc: "uiNewColorButton",
                                      mylib.}
type
  Form* = object of Control


template toUiForm*(this: untyped): untyped =
  (cast[ptr Form]((this)))

proc formAppend*(f: ptr Form; label: cstring; c: ptr Control; stretchy: cint) {.cdecl,
    importc: "uiFormAppend", mylib.}
proc formDelete*(f: ptr Form; index: cint) {.cdecl, importc: "uiFormDelete",
                                       mylib.}
proc formPadded*(f: ptr Form): cint {.cdecl, importc: "uiFormPadded", mylib.}
proc formSetPadded*(f: ptr Form; padded: cint) {.cdecl, importc: "uiFormSetPadded",
    mylib.}
proc newForm*(): ptr Form {.cdecl, importc: "uiNewForm", mylib.}
type
  Align* {.size: sizeof(cint).} = enum
    AlignFill, AlignStart, AlignCenter, AlignEnd


type
  At* {.size: sizeof(cint).} = enum
    AtLeading, AtTop, AtTrailing, AtBottom


type
  Grid* = object of Control


template toUiGrid*(this: untyped): untyped =
  (cast[ptr Grid]((this)))

proc gridAppend*(g: ptr Grid; c: ptr Control; left: cint; top: cint; xspan: cint;
                yspan: cint; hexpand: cint; halign: Align; vexpand: cint; valign: Align) {.
    cdecl, importc: "uiGridAppend", mylib.}
proc gridInsertAt*(g: ptr Grid; c: ptr Control; existing: ptr Control; at: At; xspan: cint;
                  yspan: cint; hexpand: cint; halign: Align; vexpand: cint;
                  valign: Align) {.cdecl, importc: "uiGridInsertAt", mylib.}
proc gridPadded*(g: ptr Grid): cint {.cdecl, importc: "uiGridPadded", mylib.}
proc gridSetPadded*(g: ptr Grid; padded: cint) {.cdecl, importc: "uiGridSetPadded",
    mylib.}
proc newGrid*(): ptr Grid {.cdecl, importc: "uiNewGrid", mylib.}

type
    Image* = object

proc newImage*(width: cdouble; height: cdouble): ptr Image {.cdecl, importc: "uiNewImage", mylib.}
proc freeImage*(i: ptr Image) {.cdecl, importc: "uiFreeImage", mylib.}
proc imageAppend*(i: ptr Image; pixels: pointer; pixelWidth: cint;
                   pixelHeight: cint; byteStride: cint) {.cdecl, importc: "uiImageAppend", mylib.}

type
    Table* = object of Control
    TableValueType* {.size: sizeof(cint).} = enum
        TableValueTypeString,
        TableValueTypeImage,
        TableValueTypeInt,
        TableValueTypeColor

    Color* {.bycopy.} = object
        r*: cdouble
        g*: cdouble
        b*: cdouble
        a*: cdouble

    TableValueInner* {.bycopy.} = object {.union.}
        str*: cstring
        img*: ptr Image
        i*: cint
        color*: Color

    TableValue* {.bycopy.} = object
        kind*: TableValueType
        u*: TableValueInner
    TableModel* = object

proc freeTableValue*(v: ptr TableValue) {.cdecl, importc: "uiFreeTableValue", mylib.}

proc tableValueGetType*(v: ptr TableValue): TableValueType {.cdecl, importc: "uiTableValueGetType", mylib.}
proc newTableValueString*(str: cstring): ptr TableValue {.cdecl, importc: "uiNewTableValueString", mylib.}
proc tableValueString*(v: ptr TableValue): cstring {.cdecl, importc: "uiTableValueString", mylib.}
proc newTableValueImage*(img: ptr Image): ptr TableValue {.cdecl, importc: "uiNewTableValueImage", mylib.}
proc tableValueImage*(v: ptr TableValue): ptr Image {.cdecl, importc: "uiTableValueImage", mylib.}
proc newTableValueInt*(i: cint): ptr TableValue {.cdecl, importc: "uiNewTableValueInt", mylib.}
proc tableValueInt*(v: ptr TableValue): int {.cdecl, importc: "uiTableValueInt", mylib.}
proc newTableValueColor*(r: float; g: float; b: float; a: float): ptr TableValue {.cdecl, importc: "uiNewTableValueColor", mylib.}
proc tableValueColor*(v: ptr TableValue; r: ptr float; g: ptr float;
                       b: ptr float; a: ptr float) {.cdecl, importc: "uiTableValueColor", mylib.}
type
  TableNumColumns* = proc (a1: ptr TableModelHandler, a2: ptr rawui.TableModel): cint {.cdecl.}
  TableColumnType* = proc (a1: ptr TableModelHandler, a2: ptr TableModel, a3: cint): TableValueType {.cdecl.}
  TableNumRows* = proc (a1: ptr TableModelHandler, a2: ptr TableModel): cint {.cdecl.}
  TableCellValue* = proc (mh: ptr TableModelHandler, m: ptr TableModel, row: int, column: int): ptr TableValue {.cdecl.}
  TableSetCellValue* = proc (a1: ptr TableModelHandler, a2: ptr TableModel, a3: cint, a4: cint, a5: ptr TableValue) {.cdecl.}

  TableModelHandler* = object
    numColumns*: TableNumColumns
    columnType*: TableColumnType
    numRows*: TableNumRows
    cellValue*: TableCellValue
    setCellValue*: TableSetCellValue


proc newTableModel*(mh: ptr TableModelHandler): ptr TableModel {.cdecl, importc: "uiNewTableModel", mylib.}
proc freeTableModel*(m: ptr TableModel) {.cdecl, importc: "uiFreeTableModel", mylib.}
proc tableModelRowInserted*(m: ptr TableModel; newIndex: cint) {.cdecl, importc: "uiTableModelRowInserted", mylib.}
proc tableModelRowChanged*(m: ptr TableModel; index: cint) {.cdecl, importc: "uiTableModelRowChanged", mylib.}
proc tableModelRowDeleted*(m: ptr TableModel; oldIndex: cint) {.cdecl, importc: "uiTableModelRowDeleted", mylib.}

const
  TableModelColumnNeverEditable* = (-1)
  TableModelColumnAlwaysEditable* = (-2)

type
  TableTextColumnOptionalParams* {.bycopy.} = object
    ColorModelColumn*: cint

  TableParams* = object
    model*: ptr TableModel
    rowBackgroundColorModelColumn*: cint


template toUiTable*(this: untyped): untyped =
  (cast[ptr Table]((this)))

proc tableAppendTextColumn*(t: ptr Table; name: cstring; textModelColumn: cint;
                             textEditableModelColumn: cint;
                             textParams: ptr TableTextColumnOptionalParams) {.cdecl, importc: "uiTableAppendTextColumn", mylib.}
proc tableAppendImageColumn*(t: ptr Table; name: cstring; imageModelColumn: cint) {.cdecl, importc: "uiTableAppendImageColumn", mylib.}
proc tableAppendImageTextColumn*(t: ptr Table; name: cstring;
                                  imageModelColumn: cint; textModelColumn: cint;
                                  textEditableModelColumn: cint; textParams: ptr TableTextColumnOptionalParams) {.cdecl, importc: "uiTableAppendImageTextColumn", mylib.}
proc tableAppendCheckboxColumn*(t: ptr Table; name: cstring;
                                 checkboxModelColumn: cint;
                                 checkboxEditableModelColumn: cint) {.cdecl, importc: "uiTableAppendCheckboxColumn", mylib.}
proc tableAppendCheckboxTextColumn*(t: ptr Table; name: cstring; checkboxModelColumn: cint; checkboxEditableModelColumn: cint;
                                     textModelColumn: cint; textEditableModelColumn: cint; textParams: ptr TableTextColumnOptionalParams) {.cdecl,  importc: "uiTableAppendCheckboxTextColumn", mylib.}
proc tableAppendProgressBarColumn*(t: ptr Table; name: cstring; progressModelColumn: cint) {.cdecl, importc: "uiTableAppendProgressBarColumn", mylib.}
proc tableAppendButtonColumn*(t: ptr Table; name: cstring; buttonModelColumn: cint; buttonClickableModelColumn: cint) {.cdecl, importc: "uiTableAppendButtonColumn", mylib.}
proc newTable*(params: ptr TableParams): ptr Table {.cdecl, importc: "uiNewTable", mylib.}