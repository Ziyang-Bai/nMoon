local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "值") .. "不匹配：期望 " .. tostring(expected) .. "，实际 " .. tostring(actual))
    end
end

local changes = 0
local buffer = nMoon.Buffer.new("alpha\nbeta", function() changes = changes + 1 end)
buffer:setCaret(1, 5, false)
buffer:insert("\nX")
equal(buffer:text(), "alpha\nX\nbeta", "多行插入")
equal(buffer.row, 2, "插入后行号")
equal(buffer.col, 1, "插入后列号")

buffer:setText("one\ntwo\nthree")
buffer.anchor = { row = 1, col = 1 }
buffer.row = 3
buffer.col = 2
equal(buffer:selectedText(), "ne\ntwo\nth", "跨行选择")
buffer:deleteSelection()
equal(buffer:text(), "oree", "跨行删除")
equal(buffer.row, 1, "删除后行号")
equal(buffer.col, 1, "删除后列号")

buffer:setText("    value")
buffer:setCaret(1, 9, false)
buffer:newline()
equal(buffer:text(), "    value\n    ", "自动缩进")
buffer:backspace()
equal(buffer:text(), "    value\n   ", "退格")

buffer:setText("first\nsecond")
buffer:setCaret(2, 0, false)
buffer:backspace()
equal(buffer:text(), "firstsecond", "跨行退格")
equal(buffer.col, 5, "合并行后的列号")

buffer:setText("abcd")
buffer:setCaret(1, 2, false)
buffer:toggleSelection()
buffer:moveHorizontal(1, true)
equal(buffer:selectedText(), "c", "选择移动")
buffer:insert("X")
equal(buffer:text(), "abXd", "替换选择")
equal(buffer.anchor, nil, "输入后清除选择")

buffer:setText("if ready then")
buffer:setCaret(1, 13, false)
buffer:newline(4, true)
equal(buffer:text(), "if ready then\n    ", "块起始行智能缩进")

buffer:setText("alpha  beta.中文")
buffer:setCaret(1, 0, false)
buffer:moveWord(1, false)
equal(buffer.col, 7, "按词前进跳过空白")
buffer:moveWord(1, false)
equal(buffer.col, 11, "按词前进停在标点前")
buffer:moveWord(-1, false)
equal(buffer.col, 7, "按词后退到单词开头")

local replaced, count = nMoon.replaceAllLiteral("a.b.a", ".", "X")
equal(replaced, "aXbXa", "纯文本全部替换")
equal(count, 2, "替换数量")

nMoon.app.buffer:setText("abc abc\nabc")
nMoon.app.buffer:setCaret(1, 0, false)
equal(nMoon.app:findLiteral("abc", true), true, "首次查找")
equal(nMoon.app.buffer.anchor.col, 0, "首次匹配起点")
equal(nMoon.app.buffer.col, 3, "首次匹配终点")
equal(nMoon.app:findLiteral("abc", true), true, "继续查找")
equal(nMoon.app.buffer.anchor.col, 4, "第二次匹配起点")
equal(nMoon.app.buffer.col, 7, "第二次匹配终点")

-- UTF-8 字节偏移不能泄漏为编辑器字符列。
nMoon.app.buffer:setText("中文前缀 target；再次中文查询")
nMoon.app.buffer:setCaret(1, 0, false)
equal(nMoon.app:findLiteral("target", true), true, "中文前缀后的查找")
equal(nMoon.app.buffer:selectedText(), "target", "中文前缀后的字符选区")
nMoon.app.buffer:setCaret(1, 0, false)
equal(nMoon.app:findLiteral("中文查询", true), true, "中文查询查找")
equal(nMoon.app.buffer:selectedText(), "中文查询", "中文查询字符选区")

buffer:setText("")
buffer:setCaret(0, -20, false)
equal(buffer.row, 1, "行号下界")
equal(buffer.col, 0, "列号下界")
buffer:setCaret(99, 99, false)
equal(buffer.row, 1, "行号上界")
equal(buffer.col, 0, "列号上界")

local function bytes(...)
    return string.char(...)
end

local graphemeCases = {
    { "e" .. bytes(0xCC, 0x81), "组合标记" },
    { bytes(0xE2, 0x9D, 0xA4) .. bytes(0xEF, 0xB8, 0x8F), "变体选择符" },
    { bytes(0xF0, 0x9F, 0x91, 0x8D) ..
        bytes(0xF0, 0x9F, 0x8F, 0xBD), "Emoji肤色修饰符" },
    { bytes(0xF0, 0x9F, 0x91, 0xA9) ..
        bytes(0xE2, 0x80, 0x8D) ..
        bytes(0xF0, 0x9F, 0x92, 0xBB), "ZWJ序列" }
}

for _, case in ipairs(graphemeCases) do
    local cluster, label = case[1], case[2]
    buffer:setText("A" .. cluster .. "B")
    buffer:setCaret(1, 1, false)
    buffer:moveHorizontal(1, true)
    equal(buffer:selectedText(), cluster, label .. "向右整体选择")
    buffer:moveHorizontal(-1, false)
    equal(buffer.col, 1, label .. "向左不进入序列")

    buffer:setCaret(1, 2, false)
    buffer:backspace()
    equal(buffer:text(), "AB", label .. "退格整体删除")

    buffer:setText("A" .. cluster .. "B")
    buffer:setCaret(1, 1, false)
    buffer:deleteForward()
    equal(buffer:text(), "AB", label .. "Delete整体删除")
end


if changes < 6 then error("变更回调次数不足") end
print("nMoon core tests: OK")
