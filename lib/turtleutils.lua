local filename = "lastmovements.dat"
local POSITION = {
    left = 'l',
    right = 'r',
    forward = 'f',
    back = 'b',
    up = 'u',
    down = 'd'
}
local turtleTurnLeft = turtle.turnLeft
local turtleTurnRight = turtle.turnRight
local turtleForward = turtle.forward
local turtleBack = turtle.back
local turtleUp = turtle.up
local turtleDown = turtle.down
local trackMovement = true
local turtleSlots = 16
local turtleWay = {}

local function tableContains(table, value)
    for _, tableValue in pairs(table) do
        if tableValue == value then
            return true
        end
    end

    return false
end

local function loadLastWay()
    if fs.exists(filename) then
        turtleWay = {}
        local file = fs.open(filename, "r")
        local str = file.read(fs.getSize(filename))
        for part in str:gmatch("[^;]+") do
            table.insert(turtleWay, part)
        end

        file.close()
    end
end

local function saveWay()
    if fs.exists(filename) then
        fs.delete(filename)

        if fs.exists(filename) then
            return false
        end
    end

    local file = fs.open(filename, "w")
    if not file then
        return false
    end

    local serialized = ""
    for i = 1, #turtleWay do
        serialized = serialized .. turtleWay[i] .. ";"
    end

    file.write(serialized)
    file.close()

    return true
end

-- new move function
local function move(position, amount)
    amount = amount or 1

    local moveAction = nil
    if position == POSITION.left then
        moveAction = turtleTurnLeft
    elseif position == POSITION.right then
        moveAction = turtleTurnRight
    elseif position == POSITION.forward then
        moveAction = turtleForward
    elseif position == POSITION.back then
        moveAction = turtleBack
    elseif position == POSITION.up then
        moveAction = turtleUp
    elseif position == POSITION.down then
        moveAction = turtleDown
    else
        return false
    end

    local success = true
    local moved = 0
    for i = 1, amount do
        if moveAction() then
            if trackMovement then
                table.insert(turtleWay, position)
            end
            moved = moved + 1
        else
            success = false
            break
        end
    end

    if moved > 0 then
        saveWay()
        return true
    end

    return false
end

local function undoSteps(amount)
    amount = amount or #turtleWay
    if amount > #turtleWay then
        amount = #turtleWay
    end

    if amount < #turtleWay then
        amount = #turtleWay
    end

    if #turtleWay == 0 then
        return true
    end

    if amount < 1 then
        print("Invalid amount parameter")
        return false
    end

    local stepsDone = 0
    while stepsDone < amount do
        local moveAction = nil
        local position = turtleWay[#turtleWay]

        if position == POSITION.left then
            moveAction = turtleTurnRight
        elseif position == POSITION.right then
            moveAction = turtleTurnLeft
        elseif position == POSITION.forward then
            moveAction = turtleBack
        elseif position == POSITION.back then
            moveAction = turtleForward
        elseif position == POSITION.up then
            moveAction = turtleDown
        elseif position == POSITION.down then
            moveAction = turtleUp
        else
            print("Invalid movement (" .. position .. ")")
            return false
        end

        if moveAction() then
            table.remove(turtleWay)
            stepsDone = stepsDone + 1
        else
            print("can't move")
            return false
        end
    end

    return true
end

turtle.addToWay = function(direction, amount)
    amount = amount or 1

    if amount < 1 then
        print("Invalid amount")
        return false
    end

    local add
    if direction == "left" then
        add = POSITION.left
    elseif direction == "right" then
        add = POSITION.right
    elseif direction == "down" then
        add = POSITION.down
    elseif direction == "up" then
        add = POSITION.up
    elseif direction == "forward" then
        add = POSITION.forward
    elseif direction == "back" then
        add = POSITION.back
    else
        print("Invalid direction")
        return false
    end

    for i = 1, amount do
        table.insert(turtleWay, add)
    end

    saveWay()

    return true
end

turtle.resetHome = function()
    turtleWay = {}

    if fs.exists(filename) then
        fs.delete(filename)
    end

    return not fs.exists(filename)
end

-- turtle.home can be used to move back to the start location
turtle.home = function()
    return undoSteps() and turtle.resetHome()
end

turtle.stopTracking = function()
    trackMovement = false
end

turtle.startTracking = function()
    trackMovement = true
end

turtle.undoSteps = function(amount)
    return undoSteps(amount or 1)
end

-- hook turtle.turnLeft
turtle.turnLeft = function(amount)
    return move(POSITION.left, amount)
end

-- hook turtle.turnRight
turtle.turnRight = function(amount)
    return move(POSITION.right, amount)
end

-- hook turtle.forward
turtle.forward = function(amount)
    return move(POSITION.forward, amount)
end

-- hook turtle.back
turtle.back = function(amount)
    return move(POSITION.back, amount)
end

-- hook turtle.up
turtle.up = function(amount)
    return move(POSITION.up, amount)
end

-- hook turtle.down
turtle.down = function(amount)
    return move(POSITION.down, amount)
end

turtle.digUntilVoid = function()
    while turtle.detect() do
        turtle.dig()
    end
end

turtle.digUpUntilVoid = function()
    while turtle.detectUp() do
        turtle.digUp()
    end
end

turtle.upWithDig = function()
    if turtle.getFuelLevel() < 1 then
        return false
    end

    while not turtle.up() do
        turtle.digUp()
    end

    return true
end

turtle.downWithDig = function()
    if turtle.getFuelLevel() < 1 then
        return false
    end

    while not turtle.down() do
        turtle.digDown()
    end

    return true
end

turtle.forwardWithDig = function()
    if turtle.getFuelLevel() < 1 then
        return false
    end

    while not turtle.forward() do
        turtle.dig()
    end

    return true
end

turtle.dropSlots = function(startSlot, endSlot, direction, ignoreSlots)
    startSlot = startSlot or 1
    endSlot = math.min(endSlot or turtleSlots, turtleSlots)

    local currentSlot = turtle.getSelectedSlot()
    for slot = startSlot, endSlot do
        if ignoreSlots == nil or not tableContains(ignoreSlots, slot) then
            turtle.select(slot)
            if direction == "up" then
                turtle.dropUp()
            elseif direction == "down" then
                turtle.dropDown()
            else
                turtle.drop()
            end
        end
    end

    turtle.select(currentSlot)
end

turtle.hasEmptySlots = function(emptySlots)
    emptySlots = emptySlots or 1

    local emptySlotsFound = 0
    for i = 1, turtleSlots do
        if turtle.getItemCount(i) == 0 then
            emptySlotsFound = emptySlotsFound + 1
            if emptySlotsFound >= emptySlots then
                return true
            end
        end
    end

    return false
end

loadLastWay()
