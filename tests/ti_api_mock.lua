variableStore = {}
registeredMenu = nil
clipboardText = ""


tiMock = {
    calls = { store = {}, recall = {}, eval = {} },
    faults = { store = {}, recall = {}, eval = {} }
}
local mockUnpack = unpack or table.unpack

function tiMock.resetFaults()
    tiMock.calls = { store = {}, recall = {}, eval = {} }
    tiMock.faults = { store = {}, recall = {}, eval = {} }
end

function tiMock.inject(operation, matcher, mode, message)
    local faults = assert(tiMock.faults[operation], "未知 mock 操作：" .. tostring(operation))
    faults[#faults + 1] = {
        matcher = matcher,
        mode = mode or "error",
        message = message or ("injected " .. operation .. " failure")
    }
end

local function consumeFault(operation, ...)
    local arguments = { ... }
    local calls = tiMock.calls[operation]
    calls[#calls + 1] = arguments
    for _, fault in ipairs(tiMock.faults[operation]) do
        if not fault.used then
            local matches = fault.matcher == nil
            if type(fault.matcher) == "number" then
                matches = #calls == fault.matcher
            elseif type(fault.matcher) == "string" then
                matches = string.find(tostring(arguments[1]), fault.matcher, 1, true) ~= nil
            elseif type(fault.matcher) == "function" then
                matches = fault.matcher(mockUnpack(arguments))
            end
            if matches then
                fault.used = true
                if fault.mode == "raise" then error(fault.message) end
                return fault
            end
        end
    end
    return nil
end
if not loadstring then loadstring = load end
if not setfenv then
    function setfenv(fn, environment)
        local index = 1
        while true do
            local name = debug.getupvalue(fn, index)
            if not name then break end
            if name == "_ENV" then
                local function holder() return environment end
                debug.upvaluejoin(fn, index, holder, 1)
                break
            end
            index = index + 1
        end
        return fn
    end
end

platform = {
    window = {
        invalidations = 0,
        focused = false,
        invalidate = function(self) self.invalidations = self.invalidations + 1 end,
        width = function() return 320 end,
        height = function() return 217 end,
        setFocus = function(self, value) self.focused = value end
    }
}

document = {
    changes = 0,
    markChanged = function() document.changes = document.changes + 1 end
}

var = {}
function var.store(name, value)
    local fault = consumeFault("store", name, value)
    if fault then return fault.message end
    if type(value) == "string" and
        (name:match("^nmpart%d$") or name:match("^nmt%d+part$")) and
        utf8 and not utf8.len(value) then
        return "invalid utf8 chunk"
    end
    variableStore[name] = value
    return nil
end
function var.recall(name)
    local fault = consumeFault("recall", name)
    if fault then return fault.value end
    return variableStore[name]
end
function var.recallStr(name)
    return var.recall(name)
end
function var.list()
    local names = {}
    for name in pairs(variableStore) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function math.eval(expression)
    local fault = consumeFault("eval", expression)
    if fault then return nil, fault.message end
    local target, source = expression:match("^([A-Za-z][A-Za-z0-9_]*):=([A-Za-z][A-Za-z0-9_]*)$")
    if target then
        variableStore[target] = variableStore[source]
        return variableStore[target]
    end
    local left, first, second = expression:match("^([A-Za-z][A-Za-z0-9_]*):=([A-Za-z][A-Za-z0-9_]*)&([A-Za-z][A-Za-z0-9_]*)$")
    if left then
        variableStore[left] = (variableStore[first] or "") .. (variableStore[second] or "")
        return variableStore[left]
    end
    error("测试替身不支持表达式：" .. expression)
end

clipboard = {}
function clipboard.addText(text) clipboardText = text end
function clipboard.getText() return clipboardText end

toolpalette = {}
function toolpalette.register(menu) registeredMenu = menu end
function toolpalette.enableCopy() end
function toolpalette.enableCut() end
function toolpalette.enablePaste() end

timer = { running = false, interval = nil, starts = 0, stops = 0 }
function timer.start(interval)
    timer.running = true
    timer.interval = interval
    timer.starts = timer.starts + 1
end
function timer.stop()
    timer.running = false
    timer.stops = timer.stops + 1
end

D2Editor = {}
function D2Editor.newRichText()
    local editor = {
        text = "",
        cursor = -1,
        selection = -1,
        visible = true,
        focused = false,
        selectable = false
    }
    function editor:move() end
    function editor:resize() end
    function editor:setSelectable(value) self.selectable = value end
    function editor:setDisable2DinRT(value) self.disable2D = value end
    function editor:setVisible(value) self.visible = value end
    function editor:setFocus(value) self.focused = value end
    function editor:getText() return self.text end
    function editor:getExpressionSelection() return self.text, self.cursor, self.selection end
    function editor:setText(value, cursor, selection)
        self.text = value
        self.cursor = cursor or -1
        self.selection = selection or -1
    end
    function editor:setTextChangeListener(listener) self.listener = listener end
    function editor:registerFilter(filter) self.filter = filter end
    return editor
end
