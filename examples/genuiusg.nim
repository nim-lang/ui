import "../ui", "../ui/genui"

# The macro is a fairly simple substitution
# It follows one of three patterns:
# <Widget name>(arguments, for, widget, creator)[arguments, for, add, function]:
#   <Children>
# <Identifier>%<Widget name>(arguments, for, widget, creator)[arguments, for, add, function]:
#   <Children>
# %<Identifier>[arguments, for, add, function]:
#   <Children>
# "String"
#
# Both ()-arguments and []-arguments can be omitted
# If the widget has no children the : must be omitted
# Identifiers create a var statement assigning the widget to the identifier, or assign the widget to the identifier if it already exists
# Using %<identifier> you can add widget created previously, it takes the same add options and children as any other widget
# The string pattern is used for widgets which have an add function for string values, such as radio-, and comboboxes.

# This is an example of a simple function which creates a piece of UI
# You will notice it uses result% to bind the RadioButtons widget created to the result
proc getRadioBox():RadioButtons =
  genui:
    result%RadioButtons:
      "Radio Button 1"
      "Radio Button 2"
      "Radio Button 3"
# This is a longer example which creates the same UI as in the controllgallery2 example
proc main*() =
  var mainwin: Window
  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  # This gets the widget from the previously defined function and adds callback to it
  var radioBox = getRadioBox()
  radioBox.onselected= proc()=
    echo radioBox.selected

  # This is another way to create a callback, it will be assigned to the widgets later
  proc update(value: int) =
    spinbox.value = value
    slider.value = value
    progressBar.value = value

  # Since Window uses setChild instead of add it can't be put inside the genui macro.
  # NOTE: Group uses "child=" to set it's child but has a template to make it work.
  # Adding more children to a Group widget would result in only the last being shown
  mainwin = newWindow("libui Control Gallery", 640, 480, true)
  mainwin.margined = true
  mainwin.onClosing = (proc (): bool = return true)

  # This is where the magic happens. Note that most of the parameter names are included,
  # this is a stylistic choice which I find makes the code easier to read. The notable
  # exception to this is for widgets which take only a string as it's fairly obvious what it's used for
  genui:
    # This vertical box is attached to the box variable which is later used to add it to the mainWin
    box%VerticalBox(padded = true):
      HorizontalBox(padded = true)[stretchy = true]:
        Group("Basic Controls"):
          VerticalBox(padded = true):
            Button("Button")
            Checkbox("Checkbox")
            Entry("Entry")
            HorizontalSeparator
        VerticalBox(padded = true)[stretchy = true]:
          Group("Numbers", margined = true):
            VerticalBox(padded = true):
              # These are the three widgets which variables was declared earlier and used in the callback
              spinbox%Spinbox(min = 0, max = 100, onchanged = update)
              slider%Slider(min = 0, max = 100, onchanged = update)
              progressbar%ProgressBar
          Group("Lists", margined = true):
            VerticalBox(padded = true):
              Combobox:
                "Combobox Item 1"
                "Combobox Item 2"
                "Combobox Item 3"
              EditableCombobox:
                "Editable Item 1"
                "Editable Item 2"
                "Editable Item 3"
              # This does not create a new widget but adds in the radio box created earlier
              %radioBox
          # Tabs are a bit strange as their add function has two required arguments
          # Here the name parameter must be included fully qualified in order to be properly added
          Tab(margined = true)[stretchy = true]:
            HorizontalBox[name = "Page 1"]:
              Label("Welcome to page 1")
            HorizontalBox[name = "Page 2"]:
              Label("Welcome to page 2")
            HorizontalBox[name = "Page 3"]:
              Label("Welcome to page 3")

  mainwin.setChild(box)
  show(mainwin)
  mainLoop()

init()
main()