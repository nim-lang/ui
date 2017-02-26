import macros, typetraits, tables, unicode, "../ui"

proc `[]`(s: NimNode, x: Slice[int]): seq[NimNode] =
  ## slice operation for NimNodes.
  var a = x.a
  var L = x.b - a + 1
  newSeq(result, L)
  for i in 0.. <L: result[i] = s[i + a]

proc high(s: NimNode):int =
  s.len-1

template add*[SomeWidget: Widget](g:Group, child:SomeWidget) =
  g.`child=`child

macro genui*(args: varargs[untyped]): untyped =
  type WidgetArguments = object
    identifier:NimNode
    name: string
    addArguments: seq[NimNode]
    arguments: seq[NimNode]
    children: seq[WidgetArguments]
    isStr:bool
    isIdentified:bool

  proc parseNode(node:NimNode):WidgetArguments
  proc parseBracketExpr(bracketExpr:NimNode):WidgetArguments
  proc parseChildren(stmtList:NimNode): seq[WidgetArguments] =
    result = @[]
    for child in stmtList:
      result.add parseNode(child)

  proc parseCall(call:NimNode):WidgetArguments =
    let hasAddArguments = call[0].kind == nnkBracketExpr
    let hasChildren = call[call.high].kind == nnkStmtList
    if hasAddArguments:
      result = parseBracketExpr(call[0])
    else:
      result.name = $call[0].ident
    if result.arguments == nil:
      result.arguments = if hasChildren: call[1..<call.high] else: call[1..call.high]
    #else:
    #  for arg in if hasChildren: call[1..<call.high] else: call[1..call.high]:
    #    result.arguments.add arg
    result.children = if hasChildren: parseChildren(call[call.high]) else: nil

  proc parseBracketExpr(bracketExpr:NimNode):WidgetArguments =
    let hasArguments = bracketExpr[0].kind == nnkCall
    let hasChildren = bracketExpr[bracketExpr.high].kind == nnkStmtList
    if hasArguments:
      result = parseCall(bracketExpr[0])
    else:
      result.name = $bracketExpr[0].ident
    result.addArguments = if hasChildren: bracketExpr[1..<bracketExpr.high] else: bracketExpr[1..bracketExpr.high]
    result.children = if hasChildren: parseChildren(bracketExpr[bracketExpr.high]) else: nil

  proc parseInfix(infix:NimNode):WidgetArguments=
    result = parseNode(infix[2])
    result.identifier = infix[1]
    if infix[infix.high].kind == nnkStmtList:
      result.children = parseChildren(infix[infix.high])

  proc parseIdent(ident:NimNode):WidgetArguments=
    result = WidgetArguments(
      identifier: nil,
      name: $ident.ident,
      addArguments: nil,
      arguments: nil,
      children: nil,
    )

  proc parsePrefix(prefix:NimNode):WidgetArguments=
    #assert prefix[0] == !"%", "Use % to identify"
    result = parseNode(prefix[1])
    result.isIdentified = true

  proc parseString(str:NimNode):WidgetArguments=
    result = WidgetArguments(
      name: str.strVal,
      isStr: true
    )

  proc parseNode(node:NimNode):WidgetArguments =
    case node.kind:
    of nnkCall:
      result = parseCall(node)
    of nnkBracketExpr:
      result = parseBracketExpr(node)
    of nnkInfix:
      result = parseInfix(node)
    of nnkPrefix:
      result = parsePrefix(node)
    of nnkIdent:
      result = parseIdent(node)
    of nnkStrLit:
      result = parseString(node)
    else:
      discard

  template updateOrCreate(ident: untyped, value: untyped)=
    when not declared(ident):
      var ident = value
    else:
      ident = value

  proc createWidget(widget: var WidgetArguments):NimNode =
    result = newStmtList()
    var call:NimNode
    if widget.isIdentified:
      call = newIdentNode(widget.name)
    else:
      call = newCall("new" & widget.name)
      if widget.arguments!=nil:
        for arg in widget.arguments:
          call.add arg
    if widget.identifier==nil:
      widget.identifier = genSym(nskLet)
      result.add nnkLetSection.newTree(
        nnkIdentDefs.newTree(
            widget.identifier,
            newEmptyNode(),
            call
          )
      )
    else:
      result.add getAst(updateOrCreate(widget.identifier, call))

    for child in widget.children:
      if child.isStr:
        result.add newCall("add", widget.identifier, newStrLitNode(child.name))
      else:
        var c = child
        let childCode = createWidget(c)
        for node in childCode:
          result.add node
        var addCall = newCall("add",widget.identifier, nnkExprEqExpr.newTree(
            ident"child",
            c.identifier
          )
        )
        for addArg in c.addArguments:
          addCall.add addArg
        result.add addCall

  echo treeRepr args[0]
  let parsed = parseChildren(args[0])
  result = newStmtList()
  for widget in parsed:
    var w = widget
    let widgetCode = createWidget(w)
    for node in widgetCode:
      result.add(node)
  echo result.toStrLit
