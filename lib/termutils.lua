function showProgressBar(line, progress, textRight, textPadding, emptyChar, completedChar)
    emptyChar = emptyChar or "|"
    completedChar = completedChar or "\143"
    textRight = (type(textRight) == "string" and textRight) or (textRight == nil or textRight == true and true) or false
    textPadding = textRight and 5 or 0 -- if empty text is expected to be "x%"

    if textRight == true then
        textRight = string.format("%.0f%%", progress)
    end

    local termWidth, _ = term.getSize()
    local barWidth = textRight and math.floor(termWidth - textPadding) or termWidth

    term.setCursorPos(1, line)
    term.clearLine()

    for i = 1, barWidth do
        local thisPercent = i / barWidth * 100
        term.write(thisPercent <= progress and completedChar or emptyChar)
    end

    if textRight then
        term.setCursorPos(termWidth - string.len(textRight), line)
        term.write(" " .. textRight)
    end
end
