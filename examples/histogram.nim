# 13 october 2015

import ui/rawui, random

var mainwin*: ptr Window

var histogram*: ptr Area

var handler*: AreaHandler

var datapoints*: array[10, ptr Spinbox]

var colorButton*: ptr ColorButton

var currentPoint*: cint = - 1

# some metrics

const
  xoffLeft* = 20
  yoffTop* = 20
  xoffRight* = 20
  yoffBottom* = 20
  pointRadius* = 5

# helper to quickly set a brush color


proc renderText(ctx: ptr DrawContext; txt: cstring) =
  let fontDesc = FontDescriptor(
    family: "Courier New",
    size: 12.0,
    weight: TextWeightNormal,
    italic: TextItalicNormal,
    stretch: TextStretchNormal
  )
  let textLayoutParams = DrawTextLayoutParams(
    str: newAttributedString(txt),
    defaultFont: unsafeAddr fontDesc,
    width: -1.0,
    align: DrawTextAlignCenter
  )
  let textLayout = drawNewTextLayout(unsafeAddr textLayoutParams)
  ctx.drawText(textLayout, 10.0.cdouble, 400.0.cdouble)
  drawFreeTextLayout(textLayout)

proc setSolidBrush*(brush: ptr DrawBrush; color: uint32; alpha: cdouble) {.cdecl.} =
  var component: uint8
  brush.`type` = DrawBrushTypeSolid
  component = (uint8)((color shr 16) and 0x000000FF)
  brush.r = (cdouble(component)) / 255.0
  component = (uint8)((color shr 8) and 0x000000FF)
  brush.g = (cdouble(component)) / 255.0
  component = (uint8)(color and 0x000000FF)
  brush.b = (cdouble(component)) / 255.0
  brush.a = alpha

# and some colors
# names and values from
# https://msdn.microsoft.com/en-us/library/windows/desktop/dd370907%28v=vs.85%29.aspx

const
  colorWhite* = 0x00FFFFFF
  colorBlack* = 0x00000000
  colorDodgerBlue* = 0x001E90FF

proc pointLocations*(width: cdouble; height: cdouble; xs, ys: var array[10, cdouble]) {.
    cdecl.} =
  var
    xincr: cdouble
    yincr: cdouble
  var
    i: cint
    n: cint
  xincr = width / 9
  # 10 - 1 to make the last point be at the end
  yincr = height / 100
  i = 0
  while i < 10:
    # get the value of the point
    n = cint spinboxValue(datapoints[i])
    # because y=0 is the top but n=0 is the bottom, we need to flip
    n = 100 - n
    xs[i] = xincr * cdouble i
    ys[i] = yincr * cdouble n
    inc(i)

proc constructGraph*(width: cdouble; height: cdouble; extend: bool): ptr DrawPath {.
    cdecl.} =
  var path: ptr DrawPath
  var
    xs: array[10, cdouble]
    ys: array[10, cdouble]
  pointLocations(width, height, xs, ys)
  path = drawNewPath(DrawFillModeWinding)
  drawPathNewFigure(path, xs[0], ys[0])
  for i in 1..<10:
    drawPathLineTo(path, xs[i], ys[i])
  if extend:
    drawPathLineTo(path, width, height)
    drawPathLineTo(path, 0, height)
    drawPathCloseFigure(path)
  drawPathEnd(path)
  return path

proc graphSize*(clientWidth: cdouble; clientHeight: cdouble; graphWidth: ptr cdouble;
               graphHeight: ptr cdouble) {.cdecl.} =
  graphWidth[] = clientWidth - xoffLeft - xoffRight
  graphHeight[] = clientHeight - yoffTop - yoffBottom

proc handlerDraw*(a: ptr AreaHandler; area: ptr Area; p: ptr AreaDrawParams) {.cdecl.} =
  var path: ptr DrawPath
  var brush: DrawBrush
  var sp: DrawStrokeParams
  var m: DrawMatrix
  var
    graphWidth: cdouble
    graphHeight: cdouble
  var
    graphR: cdouble
    graphG: cdouble
    graphB: cdouble
    graphA: cdouble
  # fill the area with white
  setSolidBrush(addr(brush), colorWhite, 1.0)
  path = drawNewPath(DrawFillModeWinding)
  drawPathAddRectangle(path, 0, 0, p.areaWidth, p.areaHeight)
  drawPathEnd(path)
  drawFill(p.context, path, addr(brush))
  drawFreePath(path)
  # figure out dimensions
  graphSize(p.areaWidth, p.areaHeight, addr(graphWidth), addr(graphHeight))
  # make a stroke for both the axes and the histogram line
  sp.cap = DrawLineCapFlat
  sp.join = DrawLineJoinMiter
  sp.thickness = 2
  sp.miterLimit = DrawDefaultMiterLimit
  # draw the axes
  setSolidBrush(addr(brush), colorBlack, 1.0)
  path = drawNewPath(DrawFillModeWinding)
  drawPathNewFigure(path, xoffLeft, yoffTop)
  drawPathLineTo(path, xoffLeft, yoffTop + graphHeight)
  drawPathLineTo(path, xoffLeft + graphWidth, yoffTop + graphHeight)
  drawPathEnd(path)
  drawStroke(p.context, path, addr(brush), addr(sp))
  drawFreePath(path)
  # now transform the coordinate space so (0, 0) is the top-left corner of the graph
  drawMatrixSetIdentity(addr(m))
  drawMatrixTranslate(addr(m), xoffLeft, yoffTop)
  drawTransform(p.context, addr(m))
  # now get the color for the graph itself and set up the brush
  colorButtonColor(colorButton, addr(graphR), addr(graphG), addr(graphB),
                     addr(graphA))
  brush.`type` = DrawBrushTypeSolid
  brush.r = graphR
  brush.g = graphG
  brush.b = graphB
  # we set brush->A below to different values for the fill and stroke
  # now create the fill for the graph below the graph line
  path = constructGraph(graphWidth, graphHeight, true)
  brush.a = graphA / 2
  drawFill(p.context, path, addr(brush))
  drawFreePath(path)
  # now draw the histogram line
  path = constructGraph(graphWidth, graphHeight, false)
  brush.a = graphA
  drawStroke(p.context, path, addr(brush), addr(sp))
  drawFreePath(path)
  renderText(p.context, "my example string")
  # now draw the point being hovered over
  if currentPoint != - 1:
    var
      xs: array[10, cdouble]
      ys: array[10, cdouble]
    pointLocations(graphWidth, graphHeight, xs, ys)
    path = drawNewPath(DrawFillModeWinding)
    drawPathNewFigureWithArc(path, xs[currentPoint], ys[currentPoint],
                               pointRadius, 0, 6.23, # TODO pi
                               0)
    drawPathEnd(path)
    # use the same brush as for the histogram lines
    drawFill(p.context, path, addr(brush))
    drawFreePath(path)

proc inPoint*(x: cdouble; y: cdouble; xtest: cdouble; ytest: cdouble): bool {.cdecl.} =
  # TODO switch to using a matrix
  let x = x - xoffLeft
  let y = y - yoffTop
  return (x >= xtest - pointRadius) and (x <= xtest + pointRadius) and
      (y >= ytest - pointRadius) and (y <= ytest + pointRadius)

proc handlerMouseEvent*(a: ptr AreaHandler; area: ptr Area; e: ptr AreaMouseEvent) {.
    cdecl.} =
  var
    graphWidth: cdouble
    graphHeight: cdouble
  var
    xs: array[10, cdouble]
    ys: array[10, cdouble]
  graphSize(e.areaWidth, e.areaHeight, addr(graphWidth), addr(graphHeight))
  pointLocations(graphWidth, graphHeight, xs, ys)
  var i = 0.cint
  while i < 10:
    if inPoint(e.x, e.y, xs[i], ys[i]): break
    inc(i)
  if i == 10:
    i = - 1
  currentPoint = i
  # TODO only redraw the relevant area
  areaQueueRedrawAll(histogram)

proc handlerMouseCrossed*(ah: ptr AreaHandler; a: ptr Area; left: cint) {.cdecl.} =
  # do nothing
  discard

proc handlerDragBroken*(ah: ptr AreaHandler; a: ptr Area) {.cdecl.} =
  # do nothing
  discard

proc handlerKeyEvent*(ah: ptr AreaHandler; a: ptr Area; e: ptr AreaKeyEvent): cint {.
    cdecl.} =
  # reject all keys
  return 0

proc onDatapointChanged*(s: ptr Spinbox; data: pointer) {.cdecl.} =
  areaQueueRedrawAll(histogram)

proc onColorChanged*(b: ptr ColorButton; data: pointer) {.cdecl.} =
  areaQueueRedrawAll(histogram)

proc onClosing*(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  rawui.quit()
  return 0

proc shouldQuit*(data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  return 1

proc main*() {.cdecl.} =
  var o: InitOptions
  var err: cstring
  var
    hbox: ptr Box
    vbox: ptr Box
  var i: cint
  var brush: DrawBrush
  handler.draw = handlerDraw
  handler.mouseEvent = handlerMouseEvent
  handler.mouseCrossed = handlerMouseCrossed
  handler.dragBroken = handlerDragBroken
  handler.keyEvent = handlerKeyEvent
  err = rawui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return
  onShouldQuit(shouldQuit, nil)
  mainwin = newWindow("libui Histogram Example", 640, 480, 1)
  windowSetMargined(mainwin, 1)
  windowOnClosing(mainwin, onClosing, nil)
  hbox = newHorizontalBox()
  boxSetPadded(hbox, 1)
  windowSetChild(mainwin, hbox)
  vbox = newVerticalBox()
  boxSetPadded(vbox, 1)
  boxAppend(hbox, vbox, 0)
  randomize()
  i = 0
  while i < 10:
    datapoints[i] = newSpinbox(0, 100)
    spinboxSetValue(datapoints[i], rand(101).cint)
    spinboxOnChanged(datapoints[i], onDatapointChanged, nil)
    boxAppend(vbox, datapoints[i], 0)
    inc(i)
  colorButton = newColorButton()
  # TODO inline these
  setSolidBrush(addr(brush), colorDodgerBlue, 1.0)
  colorButtonSetColor(colorButton, brush.r, brush.g, brush.b, brush.a)
  colorButtonOnChanged(colorButton, onColorChanged, nil)
  boxAppend(vbox, colorButton, 0)
  histogram = newArea(addr(handler))
  boxAppend(hbox, histogram, 1)
  controlShow(mainwin)
  rawui.main()
  rawui.uninit()

main()
