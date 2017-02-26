import "../ui", "../ui/genui"

proc getRadioBox():RadioButtons =
  genui:
    result%RadioButtons:
      "Radio Button 1"
      "Radio Button 2"
      "Radio Button 3"

proc main*() =
  var mainwin: Window
  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar
  var rb = getRadioBox()
  rb.onselected= proc()=
    echo rb.selected

  proc update(value: int) =
    spinbox.value = value
    slider.value = value
    progressBar.value = value

  mainwin = newWindow("libui Control Gallery", 640, 480, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  genui:
    box%VerticalBox(padded = true):
      HorizontalBox(padded = true)[stretchy = true]:
        Group(title = "Basic Controls"):
          VerticalBox(padded = true):
            Button("Button")
            Checkbox("Checkbox")
            Entry("Entry")
            HorizontalSeparator
        VerticalBox(padded = true)[stretchy = true]:
          Group(title = "Numbers", margined = true):
            VerticalBox(padded = true):
              spinbox%Spinbox(min = 0, max = 100, onchanged = update)
              slider%Slider(min = 0, max = 100, onchanged = update)
              progressbar%ProgressBar
          Group(title = "Lists", margined = true):
            VerticalBox(padded = true):
              Combobox:
                "Combobox Item 1"
                "Combobox Item 2"
                "Combobox Item 3"
              EditableCombobox:
                "Editable Item 1"
                "Editable Item 2"
                "Editable Item 3"
              %rb
          Tab[stretchy = true]:
            HorizontalBox[name = "Page 1"]
            HorizontalBox[name = "Page 2"]
            HorizontalBox[name = "Page 3"]

  mainwin.setChild(box)
  show(mainwin)
  mainLoop()

init()
main()