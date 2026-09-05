local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "值") .. "不匹配：期望 " .. tostring(expected) .. "，实际 " .. tostring(actual))
    end
end

local function acceptChoice()
    on.arrowKey("right")
    on.enterKey()
end

local function saveChoice()
    on.arrowKey("right")
    on.arrowKey("right")
    on.enterKey()
end

local function chooseIndex(index)
    for _ = 2, index do on.arrowKey("right") end
    on.enterKey()
end

local function findMenuAction(label)
    local function visit(node)
        if type(node) ~= "table" then return nil end
        if node[1] == label and type(node[2]) == "function" then return node[2] end
        for _, child in ipairs(node) do
            local found = visit(child)
            if found then return found end
        end
        return nil
    end
    return visit(registeredMenu)
end

local unpackValues = unpack or table.unpack


local function hasMenuLabel(node, label)
    if type(node) ~= "table" then return false end
    if node[1] == label then return true end
    for _, child in ipairs(node) do
        if hasMenuLabel(child, label) then return true end
    end
    return false
end

local function contains(actual, expected, label)
    if not string.find(tostring(actual), expected, 1, true) then
        error((label or "文本") .. "缺少：" .. expected .. "，实际 " .. tostring(actual))
    end
end

on.construction()
if not nMoon.app.input then error("未创建 D2Editor 输入控件") end
if type(registeredMenu) ~= "table" or registeredMenu[1][1] ~= "文件" then
    error("未注册中文工具菜单")
end
equal(nMoon.name, "nMoon", "程序名")
equal(nMoon.version, "Alpha", "版本")
if not hasMenuLabel(registeredMenu, "nMoon Alpha") then error("关于菜单标题缺失") end
equal(nMoon.app.settings.fontSize, 9, "默认编辑字号")
equal(nMoon.app:visibleRows(),
    math.max(1, math.floor((nMoon.app.height - 20 - 5) / nMoon.app.settings.lineHeight)),
    "编辑区顶部留白计入可见行数")
equal(nMoon.app.input.selectable, true, "原生输入选择启用")
equal(type(nMoon.app.input.filter), "table", "输入事件过滤器")
equal(timer.running, true, "输入导航轮询")
for name, handler in pairs(nMoon.app.input.filter) do
    nMoon.app.prompt = nil
    nMoon.app.help = false
    nMoon.app.fileBrowser = nil
    nMoon.app.buffer:clearSelection()
    local arguments = name == "arrowKey" and { "right" } or {}
    local ok, handled = pcall(handler, unpackValues(arguments))
    if not ok then error("D2过滤器 " .. name .. " 抛错：" .. tostring(handled)) end
    equal(handled, true, "D2过滤器 " .. name .. " 已处理返回值")

end
local allowedFontSizes = {
    [7] = true, [9] = true, [10] = true, [11] = true, [12] = true, [24] = true
}
local seenFontSizes = { [nMoon.app.settings.fontSize] = true }
for _ = 1, 6 do
    nMoon.app:cycleFontSize()
    local size = nMoon.app.settings.fontSize
    if not allowedFontSizes[size] then error("字号菜单产生非法字号：" .. tostring(size)) end
    seenFontSizes[size] = true
end
for size in pairs(allowedFontSizes) do
    if not seenFontSizes[size] then error("字号菜单未提供字号：" .. tostring(size)) end
end
equal(nMoon.app.settings.fontSize, 9, "字号循环回到默认值")
nMoon.app.prompt = nil
nMoon.app.buffer:setText("")
nMoon.app:resetHistory()

nMoon.app:newFile()
on.charIn("a")
on.charIn("b")
on.charIn("c")
equal(nMoon.app.buffer:text(), "abc", "快捷键测试输入")
nMoon.app:handleShortcut("z")
equal(nMoon.app.buffer:text(), "", "连续输入合并撤销")
nMoon.app:handleShortcut("y")
equal(nMoon.app.buffer:text(), "abc", "连续输入合并重做")
nMoon.app:handleTextInput(string.char(1))
equal(nMoon.app.buffer:selectedText(), "abc", "Ctrl+A全选")
nMoon.app:handleTextInput(string.char(3))
equal(clipboardText, "abc", "Ctrl+C复制")
nMoon.app:handleTextInput(string.char(24))
equal(nMoon.app.buffer:text(), "", "Ctrl+X剪切")
nMoon.app:handleTextInput(string.char(22))
equal(nMoon.app.buffer:text(), "abc", "Ctrl+V粘贴")
equal(nMoon.app:saveFile("quick"), true, "建立快捷键保存文件")
on.charIn("!")
nMoon.app:handleShortcut("s")
equal(variableStore.quick, "abc!", "Ctrl+S保存")
on.backspaceKey()
equal(nMoon.app.buffer:text(), "abc", "快捷键保存后继续编辑")
nMoon.app:handleShortcut("f")
equal(nMoon.app.prompt.label, "查找", "Ctrl+F查找")
on.escapeKey()
nMoon.app:handleShortcut("o")
equal(nMoon.app.prompt.label, "打开文件", "Ctrl+O打开")
on.escapeKey()
on.charIn("!")
nMoon.app:handleShortcut("n")
equal(nMoon.app.buffer:text(), "abc!", "未保存新建默认不丢弃")
on.escapeKey()
equal(nMoon.app.buffer:text(), "abc!", "取消未保存新建")
nMoon.app:handleShortcut("n")
saveChoice()
equal(variableStore.quick, "abc!", "未保存新建先保存当前文件")
equal(nMoon.app.buffer:text(), "", "保存确认后新建")
on.charIn("w")
on.charIn("x")
on.charIn("y")
on.charIn("z")
on.backspaceKey()
on.backspaceKey()
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "wxyz", "连续退格合并撤销")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "", "退格前连续输入仍为独立撤销组")
nMoon.app.buffer:setText("print(\"shortcut\")")
nMoon.app:handleShortcut("r")
equal(nMoon.app.consoleLines[1], "shortcut", "Ctrl+R运行")
on.escapeKey()
nMoon.app:newFile()


local longText = string.rep("0123456789", 1900)
nMoon.app.buffer:setText(longText)
nMoon.app.fileName = nil
nMoon.app.dirty = true
nMoon.app:saveFile("demo")
equal(variableStore.demo, longText, "分块保存")
equal(variableStore.nmt1whole, nil, "临时整块清理")
equal(variableStore.nmt1part, nil, "临时分块清理")
equal(nMoon.app.fileName, "demo", "保存后文件名")
equal(nMoon.app.dirty, false, "保存后修改标记")
local boundaryText = string.rep("a", 7999) .. "月" .. string.rep("b", 10)
local boundaryOk, boundaryError = nMoon.Storage.save("unicodefile", boundaryText)
equal(boundaryOk, true, boundaryError or "UTF-8边界保存")
equal(variableStore.unicodefile, boundaryText, "UTF-8边界回读")

local reservedOk, reservedError = nMoon.Storage.save("nmtmp1", "reserved destination")
equal(reservedOk, true, reservedError or "临时变量同名保存")
equal(variableStore.nmtmp1, "reserved destination", "临时变量同名目标保留")

variableStore.midfail = "old middle"
tiMock.resetFaults()
tiMock.inject("eval", "&", "error", "middle eval failed")
local middleCallOk, middleSaved, middleError =
    pcall(nMoon.Storage.save, "midfail", string.rep("M", 9000))
equal(middleCallOk, true, "中间math.eval失败不向外抛出")
equal(middleSaved, false, "中间math.eval失败")
contains(middleError, "middle eval failed", "中间math.eval错误")
equal(variableStore.midfail, "old middle", "中间math.eval失败保留旧文件")
equal(variableStore.nmt1owner, nil, "中间math.eval失败回收事务标记")
equal(variableStore.nmt1whole, nil, "中间math.eval失败回收临时整块")
equal(variableStore.nmt1part, nil, "中间math.eval失败回收临时分块")
equal(variableStore.nmt1backup, nil, "中间math.eval失败回收备份")

variableStore.finalfail = "old final"
tiMock.resetFaults()
tiMock.inject("eval", "finalfail:=", "error", "final eval failed")
local finalCallOk, finalSaved, finalError =
    pcall(nMoon.Storage.save, "finalfail", "new final")
equal(finalCallOk, true, "最终math.eval失败不向外抛出")
equal(finalSaved, false, "最终math.eval失败")
contains(finalError, "final eval failed", "最终math.eval错误")
equal(variableStore.finalfail, "old final", "最终math.eval失败回滚旧文件")
equal(variableStore.nmt1owner, nil, "最终math.eval失败回收事务标记")
equal(variableStore.nmt1whole, nil, "最终math.eval失败回收临时整块")
equal(variableStore.nmt1part, nil, "最终math.eval失败回收临时分块")
equal(variableStore.nmt1backup, nil, "最终math.eval失败回收备份")

variableStore.nmt1whole = "owned whole"
variableStore.nmt1part = "owned part"
variableStore.nmt1backup = "owned backup"
variableStore.nmt1owner = table.concat({
    "nMoonTxn1", "nmt1whole", "nmt1part", "nmt1backup"
}, "\n")
variableStore.nmt2whole = "user whole"
variableStore.nmt2part = "user part"
variableStore.nmt2backup = "user backup"
variableStore.nmt2owner = "foreign owner"
variableStore.nmt3whole = "ownerless whole"
variableStore.nmt3part = "ownerless part"
on.construction()
equal(variableStore.nmt1whole, nil, "启动回收自有事务整块")
equal(variableStore.nmt1part, nil, "启动回收自有事务分块")
equal(variableStore.nmt1backup, nil, "启动回收自有事务备份")
equal(variableStore.nmt1owner, nil, "启动回收自有事务标记")
equal(variableStore.nmt2whole, "user whole", "启动保留外部事务整块")
equal(variableStore.nmt2part, "user part", "启动保留外部事务分块")
equal(variableStore.nmt2backup, "user backup", "启动保留外部事务备份")
equal(variableStore.nmt2owner, "foreign owner", "启动保留外部事务标记")
equal(variableStore.nmt3whole, "ownerless whole", "启动保留无标记整块")
equal(variableStore.nmt3part, "ownerless part", "启动保留无标记分块")
for _, name in ipairs({
    "nmt2whole", "nmt2part", "nmt2backup", "nmt2owner",
    "nmt3whole", "nmt3part"
}) do
    variableStore[name] = nil
end



nMoon.app.buffer:selectAll()
on.charIn("changed")
nMoon.app:openFile("demo")
equal(nMoon.app.buffer:text(), "changed", "未保存打开默认不丢弃")
on.escapeKey()
equal(nMoon.app.buffer:text(), "changed", "取消未保存打开")
nMoon.app:openFile("demo")
acceptChoice()
equal(nMoon.app.buffer:text(), longText, "确认后重新打开")

nMoon.app.buffer:selectAll()
on.charIn("saved self edit")
nMoon.app:openFile("demo")
saveChoice()
equal(variableStore.demo, "saved self edit", "脏文件打开自身先保存当前文本")
equal(nMoon.app.buffer:text(), "saved self edit", "脏文件打开自身不回载保存前文本")

nMoon.app.buffer:setText("renamed text")
nMoon.app:renameFile("renamed")
equal(variableStore.renamed, "renamed text", "重命名目标")
equal(variableStore.demo, nil, "重命名删除原变量")
equal(nMoon.app.fileName, "renamed", "重命名后文件名")
nMoon.app.buffer:setCaret(1, 12, false)
on.charIn("!")

nMoon.app:deleteFile()
equal(variableStore.renamed, "renamed text", "删除确认默认保留文件")
on.escapeKey()
equal(variableStore.renamed, "renamed text", "取消删除保留文件")
equal(nMoon.app.buffer:text(), "renamed text!", "取消删除保留未保存修改")
nMoon.app:deleteFile()
acceptChoice()
equal(variableStore.renamed, nil, "确认删除文件")
equal(nMoon.app.buffer:text(), "", "删除后回到空白文档")

local occupiedOk, occupiedError = nMoon.Storage.save("occupied", "old text")
equal(occupiedOk, true, occupiedError or "预置覆盖目标")
on.charIn("replacement")
nMoon.app:saveFile("occupied")
equal(variableStore.occupied, "old text", "覆盖确认默认保留原文件")
on.escapeKey()
equal(variableStore.occupied, "old text", "取消覆盖保留原文件")
nMoon.app:saveFile("occupied")
acceptChoice()
equal(variableStore.occupied, "replacement", "确认后覆盖文件")

local conflictOk, conflictError = nMoon.Storage.save("conflicted", "base")
equal(conflictOk, true, conflictError or "预置外部冲突文件")
equal(nMoon.app:openFile("conflicted"), true, "打开外部冲突文件")
nMoon.app.buffer:selectAll()
on.charIn("local edit")
variableStore.conflicted = "external one"
equal(nMoon.app:saveFile(), false, "外部修改触发保存冲突")
variableStore.conflicted = "external two"
chooseIndex(1)
equal(nMoon.app.buffer:text(), "local edit", "取消冲突保留本地文本")
equal(variableStore.conflicted, "external two", "取消冲突保留最新外部文本")

equal(nMoon.app:saveFile(), false, "再次检测外部冲突")
variableStore.conflicted = "external three"
chooseIndex(2)
equal(nMoon.app.buffer:text(), "external three", "重新载入读取选择时的最新文本")
equal(nMoon.app.dirty, false, "重新载入后文档无修改")

nMoon.app.buffer:selectAll()
on.charIn("local overwrite")
variableStore.conflicted = "external four"
equal(nMoon.app:saveFile(), false, "覆盖前检测外部冲突")
variableStore.conflicted = "external five"
chooseIndex(3)
equal(variableStore.conflicted, "local overwrite", "覆盖使用当前本地文本")
equal(nMoon.app.buffer:text(), "local overwrite", "覆盖不回载陈旧外部快照")
equal(nMoon.app.dirty, false, "覆盖后文档无修改")


nMoon.app.buffer:setText("first recent")
nMoon.app:saveFile("recentone")
nMoon.app.buffer:setText("second recent")
nMoon.app:saveFile("recenttwo")
nMoon.app:openFile("recentone")
nMoon.app:newFile()
equal(nMoon.app:showFileList(), true, "打开文件列表")
on.enterKey()
equal(nMoon.app.fileName, "recentone", "文件列表优先打开最近文件")
equal(nMoon.app.buffer:text(), "first recent", "最近文件内容")

local ok = nMoon.Storage.save("bad-name", "x")
equal(ok, false, "拒绝非法文件名")

variableStore.statefile = "state text"
variableStore.otheruser = "not a companion"
variableStore.nmt9whole = "internal text"
nMoon.app.buffer:setText("state text")
nMoon.app.fileName = "statefile"
nMoon.app.savedText = "state text"
nMoon.app.recentFiles = {
    "recenttwo", "statefile", "missing", "bad-name",
    "nmt9whole", "nmoon_recent"
}
nMoon.app.settings.theme = 3
local state = on.save()
nMoon.app:newFile()
nMoon.app.settings.theme = 1
tiMock.resetFaults()
local changesBeforeRestore = document.changes
on.restore(state)
equal(document.changes, changesBeforeRestore, "restore不调用markChanged")
equal(#tiMock.calls.store, 0, "restore不写最近文件变量")
equal(nMoon.app.buffer:text(), "state text", "文档状态文本恢复")
equal(nMoon.app.fileName, "statefile", "文档状态文件名恢复")
equal(nMoon.app.settings.theme, 3, "文档状态设置恢复")
equal(type(on.getSymbolList), "function", "官方伴随变量事件")
local symbolList = on.getSymbolList()
equal(#symbolList, 2, "伴随变量列表仅含关联文本变量")
equal(symbolList[1], "statefile", "伴随变量列表当前文件优先")
equal(symbolList[2], "recenttwo", "伴随变量列表保持最近文件顺序")

on.resize(640, 360)
equal(nMoon.app.width, 640, "动态宽度")
equal(nMoon.app.height, 360, "动态高度")
local gc = { strings = {}, rectangles = {}, lines = {}, clipRects = {}, fonts = {} }
function gc:setColorRGB(color) self.color = color end
function gc:fillRect(x, y, width, height)
    self.rectangles[#self.rectangles + 1] = { x = x, y = y, width = width, height = height }
end
function gc:setFont(font, mode, size)
    self.fonts[#self.fonts + 1] = { font = font, mode = mode, size = size }
end
function gc:drawString(text, x, y, anchor)
    local clip
    if self.activeClip then
        clip = {
            x = self.activeClip.x, y = self.activeClip.y,
            width = self.activeClip.width, height = self.activeClip.height
        }
    end
    self.strings[#self.strings + 1] = {
        text = text, x = x, y = y, color = self.color, anchor = anchor, clip = clip
    }
end
function gc:drawLine(x1, y1, x2, y2)
    self.lines[#self.lines + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end
function gc:clipRect(operation, x, y, width, height)
    self.clipRects[#self.clipRects + 1] = {
        operation, x, y, width, height
    }
    if operation == "set" or operation == "intersect" then
        self.activeClip = { x = x, y = y, width = width, height = height }
    elseif operation == "reset" or operation == "null" then
        self.activeClip = nil
    end
end
function gc:getStringWidth(text)
    local width, position = 0, 1
    while position <= #text do
        local byte = string.byte(text, position)
        local length = byte < 0x80 and 1 or
            (byte < 0xE0 and 2 or (byte < 0xF0 and 3 or 4))
        if byte == 0xCC and string.byte(text, position + 1) == 0x81 then
            width = width
        elseif length >= 3 then
            width = width + 12
        else
            width = width + 6
        end
        position = position + length
    end
    return width
end

local function findDraw(text)
    for _, draw in ipairs(gc.strings) do
        if draw.text == text then return draw end
    end
    return nil
end
local function findCodeDraw(text)
    for _, draw in ipairs(gc.strings) do
        if draw.text == text and draw.x >= 24 and draw.y < nMoon.app.height - 20 then
            return draw
        end
    end
    return nil
end
local function findRectangle(x, y, width, height)
    for _, rectangle in ipairs(gc.rectangles) do
        if rectangle.x == x and rectangle.y == y and
            rectangle.width == width and rectangle.height == height then
            return rectangle
        end
    end
    return nil
end
local function findLine(x1, y1, x2, y2)
    for _, line in ipairs(gc.lines) do
        if line.x1 == x1 and line.y1 == y1 and
            line.x2 == x2 and line.y2 == y2 then
            return line
        end
    end
    return nil
end

local function resetGc()
    gc.strings = {}
    gc.rectangles = {}
    gc.lines = {}
    gc.clipRects = {}
    gc.fonts = {}
    gc.activeClip = nil
end

on.resize(320, 212)
nMoon.app:showHelp()
resetGc()
on.paint(gc)
local narrowHelp = nMoon.app.helpLayout
if not narrowHelp then error("窄屏帮助未生成实测布局") end
local bodyDraws = 0
for _, draw in ipairs(gc.strings) do
    if draw.clip then
        if draw.x < draw.clip.x or
            draw.x + gc:getStringWidth(draw.text) > draw.clip.x + draw.clip.width then
            error("窄屏帮助绘制片段横向越过内容区：" .. draw.text)
        end
        if draw.y > draw.clip.y + draw.clip.height then
            error("窄屏帮助绘制片段纵向越过内容区：" .. draw.text)
        end
        if draw.clip.y == narrowHelp.contentTop then bodyDraws = bodyDraws + 1 end
    end
end
equal(bodyDraws, math.min(narrowHelp.visibleRows, #narrowHelp.lines),
    "窄屏帮助仅绘制可见正文")
local helpFooter
for _, draw in ipairs(gc.strings) do
    if not draw.clip and string.find(draw.text, "Esc", 1, true) then
        helpFooter = draw
        break
    end
end
if not helpFooter then error("窄屏帮助缺少滚动与关闭提示") end
if helpFooter.x + gc:getStringWidth(helpFooter.text) > 320 or helpFooter.y > 212 then
    error("窄屏帮助底部提示越界")
end
local narrowLineCount = #narrowHelp.lines
for _ = 1, 100 do on.pageDownKey() end
local narrowMaximum = nMoon.app:helpMaximumTop()
equal(nMoon.app.helpTop, narrowMaximum, "帮助PageDown滚至底部")
local helpPageRows = nMoon.app:helpPageRows()
on.pageUpKey()
equal(nMoon.app.helpTop, math.max(1, narrowMaximum - helpPageRows),
    "帮助PageUp向上翻页")
on.pageDownKey()
equal(nMoon.app.helpTop, narrowMaximum, "帮助PageDown向下翻页")
on.arrowKey("up")
equal(nMoon.app.helpTop, narrowMaximum - 1, "帮助方向键向上滚动")
on.mouseWheel("down")
equal(nMoon.app.helpTop, narrowMaximum, "帮助鼠标滚轮向下滚动")
resetGc()
on.paint(gc)
local finalHelpLine = nMoon.app.helpLayout.lines[#nMoon.app.helpLayout.lines]
local finalLineDraw
for _, draw in ipairs(gc.strings) do
    if draw.clip and draw.clip.y == nMoon.app.helpLayout.contentTop and
        draw.text == finalHelpLine then
        finalLineDraw = draw
    end
end
if not finalLineDraw then error("帮助滚到底部后未绘制最后一行") end
if finalLineDraw.y > nMoon.app.helpLayout.contentBottom then
    error("帮助最后一行越过底部")
end

on.resize(640, 360)
resetGc()
on.paint(gc)
if #nMoon.app.helpLayout.lines >= narrowLineCount then
    error("帮助宽度变化后未按实测宽度重新排版")
end
if nMoon.app.helpTop > nMoon.app:helpMaximumTop() then
    error("帮助重排后滚动范围未夹紧")
end

on.resize(816, 612)
resetGc()
on.paint(gc)
if not nMoon.app.helpLayout then error("大屏帮助未生成实测布局") end
local visibleHelp = table.concat(nMoon.app.helpLayout.lines, "")
local expectedHelpContent = {
    "按键：方向键移动，Shift+方向键选择",
    "按键：Home/End移至行首/行尾，PageUp/PageDown翻页",
    "按键：Tab/Shift+Tab增加/减少缩进",
    "按键：Enter智能缩进并自动配对括号和引号",
    "按键：Esc取消提示、关闭列表或返回编辑器",
    "组合键：Ctrl+A/C/X/V全选、复制、剪切、粘贴",
    "组合键：Ctrl+Z/Y撤销、重做",
    "组合键：Ctrl+S/F保存、查找",
    "组合键：Ctrl+N/O/R新建、打开、运行",
    "功能：文件列表 / 最近可浏览并打开 TI-Nspire 文本变量",
    "功能：查找支持上/下一处和循环查找",
    "功能：运行代码后显示预览，Tab切换图形/控制台",
    "功能：运行输出支持滚动、复制、清空",
    "功能：未保存修改和覆盖已有变量时提供确认",
    "警告：请勿使用中文文件名",
    "警告：请使用英文字母开头、最长16字符的文件名"
}
for _, expected in ipairs(expectedHelpContent) do
    contains(visibleHelp, expected, "帮助页可见内容")
end
for _, implementationDetail in ipairs({
    "debug.sethook", "安全副本", "标准库", "platform",
    "document", "D2Editor", "语法检查"
}) do
    if string.find(visibleHelp, implementationDetail, 1, true) then
        error("帮助页显示实现细节：" .. implementationDetail)
    end
end
on.escapeKey()
equal(nMoon.app.help, false, "Esc关闭帮助")
on.resize(640, 360)
resetGc()


local editorLineHeight = nMoon.app.settings.lineHeight
local firstBaseline = 5 + editorLineHeight
local secondBaseline = 5 + editorLineHeight * 2
nMoon.app.buffer:setText("abcdef\nsecond")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
nMoon.app.fileName = nil
nMoon.app.dirty = false
nMoon.app.status = ""
on.mouseDown(24 + 3 + 18, 5 + math.floor(editorLineHeight / 2))
on.paint(gc)
equal(nMoon.app.buffer.row, 1, "顶部留白内点击定位首行")
equal(nMoon.app.buffer.col, 3, "鼠标像素定位")
equal(findDraw("abcdef").x, 27, "编辑区左边距")
equal(findDraw("abcdef").y, firstBaseline, "首行代码基线")
equal(findDraw("second").y, secondBaseline, "第二行代码基线")
equal(findDraw("1").x, 13, "右对齐行号")
equal(findDraw("1").y, firstBaseline, "首行行号基线")
equal(findDraw("2").y, secondBaseline, "第二行行号基线")
equal(findDraw("未命名").x, 6, "状态栏文件名分栏")
equal(findDraw("1:3").x, 615, "状态栏光标位置右对齐")
if not findRectangle(24, 5, 616, editorLineHeight) then
    error("首行当前行背景未整体下移")
end
if not findRectangle(24, 5, 2, editorLineHeight) then
    error("当前行缺少下移后的强调色标记")
end
if not findRectangle(0, 340, 640, 20) then error("状态栏尺寸不正确") end
local caretDraw = findLine(45, 8, 45, 5 + editorLineHeight - 1)
if not caretDraw then error("光标未与文字位置对齐") end
if caretDraw.y2 >= 5 + nMoon.app.settings.lineHeight then
    error("光标底部进入下一行")
end
gc.strings = {}
nMoon.app.buffer:setText("")
nMoon.app.dirty = false
on.paint(gc)
local placeholderDraw = findDraw("输入 Lua 代码…")
if not placeholderDraw then error("空白编辑器缺少输入提示") end
equal(placeholderDraw.x, 27, "空白提示左边距")
equal(placeholderDraw.y, firstBaseline, "空白提示基线")
gc.strings = {}
gc.rectangles = {}
nMoon.app.buffer:setText("local value = 42 -- note\nprint(\"hello\")")
nMoon.app.buffer:setCaret(1, 0, false)
on.paint(gc)
local keywordDraw = findDraw("local")
local textDraw = findDraw(" value = ")
local numberDraw = findDraw("42")
local commentDraw = findDraw("-- note")
local builtinDraw = findDraw("print")
local stringDraw = findDraw("\"hello\"")
if not keywordDraw or not textDraw or not numberDraw or not commentDraw or
    not builtinDraw or not stringDraw then
    error("Lua语法着色分段不完整")
end
equal(keywordDraw.x, 27, "着色代码起点")
equal(keywordDraw.y, firstBaseline, "首行着色代码基线")
equal(textDraw.y, keywordDraw.y, "分段代码基线一致")
equal(numberDraw.y, keywordDraw.y, "数字分段基线一致")
equal(commentDraw.y, keywordDraw.y, "注释分段基线一致")
equal(builtinDraw.x, 27, "第二行着色代码起点")
equal(builtinDraw.y, secondBaseline, "第二行着色代码基线")
equal(builtinDraw.y - keywordDraw.y, nMoon.app.settings.lineHeight,
    "相邻行文字基线间距")
equal(stringDraw.y, builtinDraw.y, "第二行分段基线一致")
if keywordDraw.color == textDraw.color or numberDraw.color == textDraw.color or
    commentDraw.color == textDraw.color or builtinDraw.color == textDraw.color or
    stringDraw.color == textDraw.color then
    error("Lua语法着色未使用独立颜色")
end

local keywordColor = keywordDraw.color
local plainTextColor = textDraw.color
local numberColor = numberDraw.color
local longCommentColor = commentDraw.color
local longStringColor = stringDraw.color

gc.strings = {}
nMoon.app.buffer:setText(
    "--[[ comment begins\nfunction hidden()\n]]\n" ..
    "local long = [=[\nthen hidden\n]=]\nfunction visible() end")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
on.paint(gc)
local commentMiddle = findCodeDraw("function hidden()")
if not commentMiddle then error("跨行 --[[ ]] 注释被拆成代码着色") end
equal(commentMiddle.color, longCommentColor, "跨行 --[[ ]] 注释着色")
local stringMiddle = findCodeDraw("then hidden")
if not stringMiddle then error("跨行 [=[ ]=] 字符串被拆成代码着色") end
equal(stringMiddle.color, longStringColor, "跨行 [=[ ]=] 字符串着色")
equal(findCodeDraw("function").color, keywordColor, "long bracket结束后恢复关键字着色")

gc.strings = {}
nMoon.app.buffer:setText("--[[ open\nfunction downstream()\n]]")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
on.paint(gc)
local cachedDownstream = findCodeDraw("function downstream()")
if not cachedDownstream then error("下游行未继承上游long comment状态") end
equal(cachedDownstream.color, longCommentColor, "下游行初始注释着色")
nMoon.app.buffer:replaceRange(1, 0, 1, 9, "-- plain", "replace")
gc.strings = {}
on.paint(gc)
local invalidatedDownstream = findCodeDraw("function")
if not invalidatedDownstream then error("上游修改后下游语法缓存未失效") end
equal(invalidatedDownstream.color, keywordColor, "上游修改后下游恢复代码着色")

gc.strings = {}
nMoon.app.buffer:setText("0x1F\n1e3\n.5\n1..2\n123abc\n0xGG")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
on.paint(gc)
local function equalCodeColor(text, color, label)
    local draw = findCodeDraw(text)
    if not draw then error(label .. "：未找到独立分段 " .. text) end
    equal(draw.color, color, label)
end
equalCodeColor("0x1F", numberColor, "十六进制数字边界")
equalCodeColor("1e3", numberColor, "指数数字边界")
equalCodeColor(".5", numberColor, "小数数字边界")
equalCodeColor("1", numberColor, "连接运算左侧数字")
local concatDots = 0
local concatBaseline = 5 + editorLineHeight * 4
for _, draw in ipairs(gc.strings) do
    if draw.y == concatBaseline and draw.color == plainTextColor then
        if draw.text == ".." then
            concatDots = concatDots + 2
        elseif draw.text == "." then
            concatDots = concatDots + 1
        end
    end
end
equal(concatDots, 2, "连接运算符不属于数字")
equalCodeColor("2", numberColor, "连接运算右侧数字")
equalCodeColor("123abc", plainTextColor, "标识符相邻数字不误着色")
equalCodeColor("0xGG", plainTextColor, "非法十六进制不部分着色")

nMoon.app:wakeCaret()
for _ = 1, 12 do on.timer() end
equal(nMoon.app.caretVisible, false, "光标定时隐藏")
on.arrowKey("right")
equal(nMoon.app.caretVisible, true, "移动后恢复光标")
on.loseFocus()
equal(nMoon.app.caretVisible, false, "失焦隐藏光标")
on.getFocus()
equal(nMoon.app.caretVisible, true, "聚焦恢复光标")
nMoon.app.buffer:setText("abcd")
nMoon.app.buffer:setCaret(1, 1, false)
local shadowCursor = nMoon.app.input.cursor
nMoon.app.input.cursor = shadowCursor + 1
nMoon.app.input.selection = shadowCursor
on.timer()
equal(nMoon.app.buffer:selectedText(), "b", "Shift+右方向键选择")
equal(nMoon.app.buffer.col, 2, "Shift选择后光标")

nMoon.app.input.cursor = shadowCursor + 1
nMoon.app.input.selection = -1
on.timer()
equal(nMoon.app.buffer.anchor, nil, "普通方向键取消Shift选择")
equal(nMoon.app.buffer.col, 3, "普通方向键继续移动")

nMoon.app.input.text = string.sub(nMoon.app.input.text, 1, shadowCursor - 1) ..
    "月" .. string.sub(nMoon.app.input.text, shadowCursor)
nMoon.app.input.listener(nMoon.app.input)
equal(nMoon.app.buffer:text(), "abc月d", "原生输入差分")
nMoon.app.input.text = string.sub(nMoon.app.input.text, 1, shadowCursor - 1) ..
    "Z" .. string.sub(nMoon.app.input.text, shadowCursor + 1)
nMoon.app.input.listener(nMoon.app.input)
equal(nMoon.app.buffer:text(), "abc月Zd", "等长原生输入差分")
nMoon.app.buffer:setText("select all")
nMoon.app.buffer:setCaret(1, 4, false)
nMoon.app.input.cursor = #nMoon.app.input.text + 1
nMoon.app.input.selection = 1
on.timer()
equal(nMoon.app.buffer:selectedText(), "select all", "原生Ctrl+A全选")
on.escapeKey()

nMoon.app.buffer:setText("if ready then")
nMoon.app.buffer:setCaret(1, 13, false)
on.enterKey()
equal(nMoon.app.buffer:text(), "if ready then\n    ", "回车智能增加块缩进")
on.charIn("e")
on.charIn("n")
on.charIn("d")
equal(nMoon.app.buffer:text(), "if ready then\nend", "闭合关键字智能减少缩进")

nMoon.app.buffer:setText("")
nMoon.app.buffer:setCaret(1, 0, false)
on.charIn("(")
equal(nMoon.app.buffer:text(), "()", "自动补全括号")
equal(nMoon.app.buffer.col, 1, "自动配对后光标位于括号内")
on.charIn(")")
equal(nMoon.app.buffer:text(), "()", "跳过已有闭合括号")
equal(nMoon.app.buffer.col, 2, "跳过闭合括号后移动光标")
nMoon.app.buffer:setText("")

nMoon.app:resetHistory()
on.charIn("a")
nMoon.app:handleTextInput(string.rep("b", 100000))
equal(nMoon.app.buffer:text(), "a", "超大编辑确认前不修改文档")
equal(nMoon.app.prompt.kind, "choice", "超大编辑显示确认")
contains(nMoon.app.prompt.label, "无法撤销", "超大编辑警告")
chooseIndex(1)
equal(nMoon.app.buffer:text(), "a", "取消超大编辑保留文档")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "", "取消超大编辑保留既有撤销历史")
nMoon.app.buffer:setText("")
nMoon.app:resetHistory()


nMoon.app.buffer:setCaret(1, 0, false)
on.charIn("[")
on.backspaceKey()
equal(nMoon.app.buffer:text(), "", "退格同时删除空配对")
nMoon.app.buffer:setText("value")
nMoon.app.buffer:selectAll()
on.charIn("\"")
equal(nMoon.app.buffer:text(), "\"value\"", "引号包裹选择")
equal(nMoon.app.buffer:selectedText(), "value", "包裹后保留内部选择")

local stringIndentLine = "    print(\"function then\")"
nMoon.app.buffer:setText(stringIndentLine)
nMoon.app.buffer:setCaret(1, #stringIndentLine, false)
nMoon.app:resetHistory()
on.enterKey()
equal(nMoon.app.buffer:text(), stringIndentLine .. "\n    ",
    "字符串中的function和then不增加缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), stringIndentLine, "字符串行换行单次undo")

local commentIndentLine = "    -- function then"
nMoon.app.buffer:setText(commentIndentLine)
nMoon.app.buffer:setCaret(1, #commentIndentLine, false)
nMoon.app:resetHistory()
on.enterKey()
equal(nMoon.app.buffer:text(), commentIndentLine .. "\n    ",
    "注释中的function和then不增加缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), commentIndentLine, "注释行换行单次undo")

nMoon.app.buffer:setText("    els")
nMoon.app.buffer:setCaret(1, 7, false)
nMoon.app:resetHistory()
on.charIn("e")
equal(nMoon.app.buffer:text(), "else", "else自动退缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "    els", "else退缩进单次undo")

nMoon.app.buffer:setText("else")
nMoon.app.buffer:setCaret(1, 4, false)
nMoon.app:resetHistory()
on.enterKey()
equal(nMoon.app.buffer:text(), "else\n    ", "else后正确增加块缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "else", "else换行单次undo")

nMoon.app.buffer:setText("    elsei")
nMoon.app.buffer:setCaret(1, 9, false)
nMoon.app:resetHistory()
on.charIn("f")
equal(nMoon.app.buffer:text(), "elseif", "elseif自动退缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "    elsei", "elseif退缩进单次undo")

local elseifLine = "elseif ready then"
nMoon.app.buffer:setText(elseifLine)
nMoon.app.buffer:setCaret(1, #elseifLine, false)
nMoon.app:resetHistory()
on.enterKey()
equal(nMoon.app.buffer:text(), elseifLine .. "\n    ", "elseif后正确增加块缩进")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), elseifLine, "elseif换行单次undo")

nMoon.app.buffer:setText("")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app:resetHistory()
on.charIn("(")
equal(nMoon.app.buffer:text(), "()", "自动配对产生完整括号")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "", "自动配对单次undo")

nMoon.app.buffer:setText("")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app:resetHistory()
on.charIn("{")
on.enterKey()
equal(nMoon.app.buffer:text(), "{\n    \n}", "花括号换行自动编辑")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "{}", "花括号换行单次undo")
nMoon.app:undo()
equal(nMoon.app.buffer:text(), "", "花括号配对保持独立undo")

nMoon.app.buffer:setText("alpha  beta.中文")
nMoon.app.buffer:setCaret(1, 0, false)
on.arrowKey("right", "ctrl")
equal(nMoon.app.buffer.col, 7, "Ctrl+右按词前进")
on.arrowKey("right", "ctrl")
equal(nMoon.app.buffer.col, 11, "Ctrl+右停在标点")
on.arrowKey("left", "ctrl")
equal(nMoon.app.buffer.col, 7, "Ctrl+左按词后退")

local navigationLines = {}
for index = 1, 40 do navigationLines[index] = "line" .. index end
nMoon.app.buffer:setText(table.concat(navigationLines, "\n"))
nMoon.app.buffer:setCaret(30, 3, false)
on.homeKey()
equal(nMoon.app.buffer.col, 0, "Home到行首")
on.endKey()
equal(nMoon.app.buffer.col, 6, "End到行尾")
local pageDistance = nMoon.app:visibleRows() - 1
on.pageUpKey()
equal(nMoon.app.buffer.row, 30 - pageDistance, "PageUp翻页")
on.pageDownKey()
equal(nMoon.app.buffer.row, 30, "PageDown翻页")

nMoon.app.buffer:setText("abcdef\nuvwxyz")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
local firstRowMouseY = 5 + math.floor(editorLineHeight / 2)
on.mouseDown(27 + 6, firstRowMouseY)
on.mouseMove(27 + 30, firstRowMouseY)
on.mouseUp(27 + 30, firstRowMouseY)
gc.rectangles = {}
on.paint(gc)
equal(nMoon.app.buffer.row, 1, "拖选末端保持首行")
equal(nMoon.app.buffer:selectedText(), "bcde", "鼠标拖动选择文本")
if not findRectangle(33, 5, 24, editorLineHeight) then
    error("拖选高亮未与下移后的代码行对齐")
end

gc.rectangles = {}
gc.lines = {}
local secondRowY = 5 + editorLineHeight + 1
on.mouseDown(27 + 12, secondRowY)
on.mouseUp(27 + 12, secondRowY)
on.paint(gc)
equal(nMoon.app.buffer.row, 2, "第二行顶部点击定位")
equal(nMoon.app.buffer.col, 2, "第二行点击列定位")
if not findRectangle(24, 5 + editorLineHeight, 616, editorLineHeight) then
    error("第二行当前行背景未整体下移")
end


nMoon.app.buffer:setText("中Ａx")
nMoon.app.buffer:setCaret(1, 0, false)
nMoon.app.top = 1
on.mouseDown(27 + 5, firstRowMouseY)
on.mouseUp(27 + 5, firstRowMouseY)
on.paint(gc)
equal(nMoon.app.buffer.col, 0, "宽字符中点左侧命中前一插入位")
on.mouseDown(27 + 7, firstRowMouseY)
on.mouseUp(27 + 7, firstRowMouseY)
on.paint(gc)
equal(nMoon.app.buffer.col, 1, "宽字符中点右侧命中后一插入位")
on.mouseDown(27 + 12 + 7, firstRowMouseY)
on.mouseUp(27 + 12 + 7, firstRowMouseY)
on.paint(gc)
equal(nMoon.app.buffer.col, 2, "连续宽字符按实测宽度命中")

local clippedCode = string.rep("a", 200)
nMoon.app.buffer:setText(clippedCode)
nMoon.app.buffer:setCaret(1, 200, false)
nMoon.app.top = 1
nMoon.app.horizontal = 600
gc.strings = {}
gc.clipRects = {}
gc.activeClip = nil
on.paint(gc)
local clippedDraw = findDraw(clippedCode)
if not clippedDraw or not clippedDraw.clip then
    error("横向滚动代码未在clipRect内绘制")
end
if clippedDraw.clip.x < 24 then error("代码clipRect未保护gutter") end
equal(gc.activeClip, nil, "代码绘制后重置clipRect")
local resetClip = false
for _, call in ipairs(gc.clipRects) do
    if call[1] == "reset" then resetClip = true break end
end
equal(resetClip, true, "代码绘制重置clipRect")

local clipRectMethod = gc.clipRect
gc.clipRect = nil
local paintWithoutClip, paintWithoutClipError = pcall(on.paint, gc)
gc.clipRect = clipRectMethod
equal(paintWithoutClip, true,
    "缺失clipRect API仍可绘制：" .. tostring(paintWithoutClipError))
nMoon.app.horizontal = 0

local boundaryLines = {}
for index = 1, 14 do boundaryLines[index] = "line" .. index end
nMoon.app.buffer:setText(table.concat(boundaryLines, "\n"))
nMoon.app.buffer:setCaret(14, 0, false)
nMoon.app.top = 1
on.resize(320, 216)
gc.lines = {}
gc.rectangles = {}
on.paint(gc)
local boundaryRows = nMoon.app:visibleRows()
local boundaryCaretY = 5 + (boundaryRows - 1) * editorLineHeight
local lastRowCaret = findLine(27, boundaryCaretY + 3, 27,
    boundaryCaretY + editorLineHeight - 1)
if not lastRowCaret then error("末行光标位置不正确") end
local statusY = nMoon.app.height - 20
if lastRowCaret.y2 >= statusY then error("末行光标进入状态栏") end
if not findRectangle(0, statusY, 320, 20) then
    error("边界场景状态栏尺寸不正确")
end
on.resize(640, 360)

local scrollLines = {}
for index = 1, 40 do scrollLines[index] = string.format("row%02d", index) end
nMoon.app.buffer:setText(table.concat(scrollLines, "\n"))
nMoon.app.buffer:setCaret(1, 0, false)
on.resize(640, 90)
on.mouseDown(639, 1)
on.mouseMove(639, 69)
on.mouseUp(639, 70)
gc.strings = {}
on.paint(gc)
if not findDraw("row37") or not findDraw("row40") then
    error("滚动条拖动未到达文档末页")
end
on.resize(640, 360)




local hostStringByte = string.byte
local hostTableInsert = table.insert
local hostWindowWidth = platform.window.width
nMoon.app.buffer:setText(
    "local values = {}\n" ..
    "table.insert(values, string.upper('moon'))\n" ..
    "local caught = pcall(function() error('expected') end)\n" ..
    "assert(caught == false)\n" ..
    "apiResult = table.concat(values, ',') .. ':' .. math.floor(2.9) .. ':' .. platform.window:width()\n" ..
    "var.store('runtime_api', apiResult)\n" ..
    "clipboard.addText('runtime clipboard')\n" ..
    "string.byte = function() return 999 end\n" ..
    "table.insert = function() error('mutated') end\n" ..
    "platform.window.width = function() return 999 end\n" ..
    "painted = 0\n" ..
    "function on.paint(...) painted = painted + 1; paintArgs = select('#', ...); paintGc, paintX, paintY, paintWidth, paintHeight = ... end")
equal(nMoon.app:startRun(), true, "启动常用API隔离程序")
equal(variableStore.runtime_api, "MOON:2:320", "运行环境允许常用API")
equal(clipboardText, "runtime clipboard", "运行环境允许剪贴板API")
equal(string.byte, hostStringByte, "运行环境不污染宿主string")
equal(table.insert, hostTableInsert, "运行环境不污染宿主table")
equal(platform.window.width, hostWindowWidth, "运行环境不污染宿主platform")
equal(platform.window:width(), 320, "宿主platform行为保持不变")
on.paint(gc, 11, 12, 13, 14)
equal(nMoon.app.runEnvironment.painted, 1, "运行时paint事件")
equal(nMoon.app.runEnvironment.paintArgs, 5, "paint完整参数数量")
equal(nMoon.app.runEnvironment.paintGc, gc, "paint收到原始gc")
equal(nMoon.app.runEnvironment.paintX, 11, "paint收到x")
equal(nMoon.app.runEnvironment.paintY, 12, "paint收到y")
equal(nMoon.app.runEnvironment.paintWidth, 13, "paint收到width")
equal(nMoon.app.runEnvironment.paintHeight, 14, "paint收到height")
on.escapeKey()

nMoon.app.buffer:setText(
    "print('Hello world')\npainted = 0\n" ..
    "function on.paint(...) painted = painted + 1; paintArgs = select('#', ...); paintGc = (...) end")
equal(nMoon.app:startRun(), true, "启动输出与图形程序")
equal(nMoon.app.consoleLines[1], "Hello world", "print输出被保留")
equal(nMoon.app.consoleVisible, false, "有paint时优先显示用户图形")
on.paint(gc)
equal(nMoon.app.runEnvironment.painted, 1, "print后用户paint继续")
on.tabKey()
equal(nMoon.app.consoleVisible, true, "Tab切换到运行控制台")
on.paint(gc)
equal(nMoon.app.runEnvironment.painted, 1, "控制台显示时暂停用户paint")
local copyRunOutput = findMenuAction("复制运行输出")
if not copyRunOutput then error("运行菜单缺少复制输出操作") end
copyRunOutput()
equal(clipboardText, "Hello world", "复制运行输出")
on.tabKey()
equal(nMoon.app.consoleVisible, false, "Tab切换回用户图形")
on.paint(gc)
equal(nMoon.app.runEnvironment.painted, 2, "切回图形后paint继续")
local clearRunOutput = findMenuAction("清空运行输出")
if not clearRunOutput then error("运行菜单缺少清空输出操作") end
clearRunOutput()
equal(#nMoon.app.consoleLines, 0, "清空运行输出")
on.escapeKey()
equal(nMoon.app.input.focused, true, "返回编辑器恢复输入焦点")
equal(timer.running, true, "返回编辑器恢复输入轮询")


local function assertBudgetCannotBeCaught(source, label)
    nMoon.app.buffer:setText(source)
    local started = nMoon.app:startRun()
    local status = nMoon.app.status
    if nMoon.app.running then nMoon.app:stopRun() end
    equal(started, false, label .. "不能吞掉预算终止")
    contains(status, "指令预算", label .. "预算状态")
    equal(timer.running, true, label .. "预算后恢复输入轮询")
end

assertBudgetCannotBeCaught(
    "pcall(function() while true do end end)\nprint('pcall swallowed')",
    "用户pcall")

assertBudgetCannotBeCaught(
    "xpcall(function() for i = 1, 1000000 do end end, function() return 'caught' end)",
    "用户xpcall")
assertBudgetCannotBeCaught(
    "pcall(function() coroutine.resume(coroutine.create(function() for i = 1, 1000000 do end end)) end)",
    "用户coroutine.resume")
assertBudgetCannotBeCaught(
    "pcall(coroutine.wrap(function() for i = 1, 1000000 do end end))",
    "用户coroutine.wrap")

nMoon.app.buffer:setText("while true do end")
equal(nMoon.app:startRun(), false, "顶层死循环被中断")
equal(nMoon.app.running, false, "顶层watchdog后返回编辑器")
equal(timer.running, true, "顶层watchdog后恢复输入轮询")
contains(nMoon.app.status, "指令预算", "顶层watchdog状态")
nMoon.app.buffer:setText("print(\"recovered top\")")
equal(nMoon.app:startRun(), true, "顶层watchdog后仍可运行")
equal(nMoon.app.consoleLines[1], "recovered top", "顶层watchdog恢复后的输出")
on.escapeKey()

nMoon.app.buffer:setText("function on.timer() while true do end end")
equal(nMoon.app:startRun(), true, "启动事件watchdog程序")
on.timer()
equal(nMoon.app.running, false, "事件死循环被中断")
equal(timer.running, true, "事件watchdog后恢复输入轮询")
contains(nMoon.app.status, "指令预算", "事件watchdog状态")
nMoon.app.buffer:setText("print(\"recovered event\")")
equal(nMoon.app:startRun(), true, "事件watchdog后仍可运行")
equal(nMoon.app.consoleLines[1], "recovered event", "事件watchdog恢复后的输出")
on.escapeKey()

nMoon.app.buffer:setText(
    "for index = 1, 40 do print('trace line ' .. index) end\n" ..
    "function on.timer()\n" ..
    "  local function inner() error('boom from timer') end\n" ..
    "  inner()\n" ..
    "end")
equal(nMoon.app:startRun(), true, "启动错误traceback程序")
on.timer()
equal(nMoon.app.running, false, "运行错误退出预览")
equal(nMoon.app.consoleVisible, true, "运行错误保留控制台")
local tracebackText = table.concat(nMoon.app.consoleLines, "\n")
contains(tracebackText, "boom from timer", "错误控制台消息")
contains(tracebackText, "stack traceback", "错误控制台traceback")
local tracebackTop = nMoon.app.consoleTop
on.arrowKey("up")
equal(nMoon.app.consoleTop, math.max(1, tracebackTop - 1), "退出预览后错误控制台可滚动")
local copyErrorOutput = findMenuAction("复制运行输出")
if not copyErrorOutput then error("编辑菜单缺少复制错误输出操作") end
copyErrorOutput()
equal(clipboardText, tracebackText, "复制完整错误traceback")
local clearErrorOutput = findMenuAction("清空运行输出")
if not clearErrorOutput then error("编辑菜单缺少清空错误输出操作") end
clearErrorOutput()
equal(#nMoon.app.consoleLines, 0, "清空错误traceback")
equal(nMoon.app.consoleVisible, false, "清空错误traceback关闭控制台")

nMoon.app.buffer:setText(
    "events = { activate = 0, deactivate = 0, destroy = 0 }\n" ..
    "function on.activate() events.activate = events.activate + 1 end\n" ..
    "function on.deactivate() events.deactivate = events.deactivate + 1 end\n" ..
    "function on.destroy() events.destroy = events.destroy + 1 end")
equal(nMoon.app:startRun(), true, "启动Esc生命周期程序")
local escapeLifecycle = nMoon.app.runEnvironment
on.escapeKey()
equal(escapeLifecycle.events.activate, 1, "启动预览调用activate")
equal(escapeLifecycle.events.deactivate, 1, "Esc退出调用deactivate一次")
equal(escapeLifecycle.events.destroy, 1, "Esc退出调用destroy一次")

nMoon.app.buffer:setText(
    "events = { activate = 0, deactivate = 0, destroy = 0 }\n" ..
    "function on.construction() timer.start(0.25) end\n" ..
    "function on.activate() events.activate = events.activate + 1 end\n" ..
    "function on.deactivate() events.deactivate = events.deactivate + 1 end\n" ..
    "function on.destroy() events.destroy = events.destroy + 1 end")
equal(nMoon.app:startRun(), true, "启动宿主生命周期程序")
local hostLifecycle = nMoon.app.runEnvironment
equal(hostLifecycle.events.activate, 1, "启动时activate一次")
equal(timer.running, true, "用户计时器启动")
on.deactivate()
equal(nMoon.app.running, true, "宿主deactivate不销毁预览")
equal(hostLifecycle.events.deactivate, 1, "宿主deactivate转发一次")
equal(hostLifecycle.events.destroy, 0, "宿主deactivate不调用destroy")
equal(timer.running, false, "宿主deactivate暂停用户计时器")
equal(type(on.activate), "function", "宿主activate事件存在")
on.activate()
equal(hostLifecycle.events.activate, 2, "宿主activate转发一次")
equal(timer.running, true, "宿主activate恢复用户计时器")
equal(timer.interval, 0.25, "宿主activate恢复原计时间隔")
on.destroy()
equal(hostLifecycle.events.deactivate, 1, "宿主destroy不重复deactivate")
equal(hostLifecycle.events.destroy, 1, "宿主destroy转发一次")
equal(nMoon.app.running, false, "宿主destroy销毁预览")
equal(timer.running, false, "宿主destroy停止用户计时器")


do
    local hostDebug = debug
    local function assertNativePreview(debugApi, label)
        debug = debugApi
        dofile("tests/ti_api_mock.lua")
        on = {}
        dofile("src/nMoon.lua")
        on.construction()
        local app = nMoon.app
        app.fileName = "native_preview"
        app.buffer:setText(
            "local total = 0; for i = 1, 5 do total = total + i end\n" ..
            "print('native preview ' .. total)\n" ..
            "var.store('nativepreview', tostring(total))\n" ..
            "events = { activate = 0, deactivate = 0, destroy = 0, timer = 0 }\n" ..
            "co = coroutine.create(function(value)\n" ..
            "  local nextValue = coroutine.yield(value + 1, nil, 'yielded')\n" ..
            "  return nextValue * 2, nil, 'done'\n" ..
            "end)\n" ..
            "local ok, value, gap, state = coroutine.resume(co, 14)\n" ..
            "assert(ok and value == 15 and gap == nil and state == 'yielded')\n" ..
            "wrapped = coroutine.wrap(function() coroutine.yield('wrapped', nil, 7); return 'finished' end)\n" ..
            "local text, gap, number = wrapped(); assert(text == 'wrapped' and gap == nil and number == 7)\n" ..
            "function on.construction() timer.start(0.25) end\n" ..
            "function on.activate() events.activate = events.activate + 1 end\n" ..
            "function on.deactivate() events.deactivate = events.deactivate + 1 end\n" ..
            "function on.destroy() events.destroy = events.destroy + 1 end\n" ..
            "function on.paint(gc, x, y, width, height) paintArgs = { gc, x, y, width, height }; gc:drawString('native paint', x, y, 'top') end\n" ..
            "function on.timer()\n" ..
            "  local ok, value, gap, state = coroutine.resume(co, 9)\n" ..
            "  assert(ok and value == 18 and gap == nil and state == 'done')\n" ..
            "  clipboard.addText(wrapped() .. ':' .. value)\n" ..
            "  events.timer = events.timer + 1\n" ..
            "end")
        equal(app:startRun(), true, label .. "启动原生预览")
        local runner = app.runEnvironment
        equal(app.consoleLines[1], "native preview 15", label .. "有限循环和print")
        equal(variableStore.nativepreview, "15", label .. "var存储")
        equal(app.consoleVisible, false, label .. "图形优先")
        on.paint(gc, 11, 12, 13, 14)
        equal(runner.paintArgs[1], gc, label .. "paint收到gc")
        equal(runner.paintArgs[2], 11, label .. "paint收到x")
        equal(runner.paintArgs[3], 12, label .. "paint收到y")
        equal(runner.paintArgs[4], 13, label .. "paint收到width")
        equal(runner.paintArgs[5], 14, label .. "paint收到height")
        if not findDraw("native paint") then error(label .. "未绘制用户图形") end
        equal(runner.events.activate, 1, label .. "启动activate")
        equal(timer.interval, 0.25, label .. "construction启动timer")
        on.deactivate()
        equal(timer.running, false, label .. "deactivate暂停timer")
        on.timer()
        equal(runner.events.timer, 0, label .. "停用时不调用timer")
        on.activate()
        equal(runner.events.activate, 2, label .. "恢复activate")
        equal(timer.running, true, label .. "activate恢复timer")
        equal(timer.interval, 0.25, label .. "恢复计时间隔")
        on.timer()
        equal(runner.events.timer, 1, label .. "timer继续协程")
        equal(clipboardText, "finished:18", label .. "协程返回值和clipboard")
        on.escapeKey()
        equal(runner.events.deactivate, 2, label .. "Esc调用deactivate")
        equal(runner.events.destroy, 1, label .. "Esc调用destroy")
        equal(app.running, false, label .. "Esc返回编辑器")
        equal(app.runEnvironment, nil, label .. "Esc释放运行环境")
        equal(app.userTimerActive, false, label .. "Esc停止用户timer")
        equal(app.input.focused, true, label .. "Esc恢复输入焦点")
        equal(timer.running, true, label .. "Esc恢复输入轮询")
        equal(timer.interval, 0.04, label .. "Esc恢复轮询间隔")

        app.buffer:setText("function on.paint(")
        equal(app:startRun(), false, label .. "报告语法错误")
        contains(app.status, "语法错误", label .. "语法错误状态")
        equal(app.running, false, label .. "语法错误留在编辑器")
        app.buffer:setText("error('native top failure')")
        equal(app:startRun(), false, label .. "捕获顶层错误")
        contains(table.concat(app.consoleLines, "\n"), "native top failure",
            label .. "顶层错误输出")
        equal(app.runEnvironment, nil, label .. "顶层错误清理")
        equal(timer.interval, 0.04, label .. "顶层错误恢复轮询")
        app.buffer:setText("function on.timer() error('native timer failure') end")
        equal(app:startRun(), true, label .. "错误后重新启动")
        on.timer()
        equal(app.running, false, label .. "事件错误退出预览")
        local errorOutput = table.concat(app.consoleLines, "\n")
        contains(errorOutput, "native timer failure", label .. "事件错误输出")
        contains(errorOutput, "nMoon/native_preview:1:", label .. "原生错误位置")
        if debugApi and debugApi.traceback then
            contains(errorOutput, "stack traceback", label .. "可用的traceback")
        end
        equal(app.consoleVisible, true, label .. "事件错误显示控制台")
        equal(app.input.focused, true, label .. "事件错误恢复焦点")
        equal(timer.interval, 0.04, label .. "事件错误恢复轮询")
        app.buffer:setText("print('recovered native')")
        equal(app:startRun(), true, label .. "事件错误后仍可运行")
        equal(app.consoleLines[1], "recovered native", label .. "恢复后的输出")
        on.escapeKey()
        debug = hostDebug
    end
    assertNativePreview(nil, "debug=nil：")
    assertNativePreview({ traceback = hostDebug.traceback }, "无sethook：")
    assertNativePreview({
        traceback = hostDebug.traceback,
        sethook = function() error("host refuses hooks") end
    }, "sethook安装失败：")
end


print("nMoon app tests: OK")
