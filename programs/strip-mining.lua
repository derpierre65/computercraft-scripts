-- @version 1.0.0
-- @lib turtleutils
-- @lib termutils
-- Simple strip mining turtle

require("lib/turtleutils")
require("lib/termutils")

local enderChestSlot = -1
local torchSlot = -1
local depthPerCorridor = -1
local maxCorridors = -1
local requiredFuel = 0
local fuelSlot = 1
local userWasAlreadyStupid = false
local started = false
local startedTime = 0
local lastCorridor = 1
local lastCorridorDuration = 0
local lastCorridorRealStart = 0
local direction = ""
local corridorTimes = {}
local finished = false
local terminalMaxCharacters, terminalMaxLines = term.getSize()

term.clear()
term.setCursorPos(1, 1)
turtle.resetHome()

local function sendChatMessage(message)
    if peripheral.getType("left") == "chat_box" then
        peripheral.wrap("left").say(message)
    end
end

local function requestInput(text, default)
    print(text)
    local value = read()

    return value ~= "" and value or default
end

local function hasEnderChest()
    if enderChestSlot == nil or enderChestSlot < 1 or enderChestSlot > 16 then
        return false
    end

    local info = turtle.getItemDetail(enderChestSlot)
    if info == nil then
        return false
    end

    if info.name == "enderstorage:ender_storage" then
        return true
    elseif info.name == "minecraft:ender_chest" then
        return true
    end

    return false
end

local function calculateRequiredFuelForCorridors(corridors)
    return depthPerCorridor * 2 * corridors + (corridors - 1) * 3
end

local function printConfiguration(key, value)
    key = tostring(key)
    value = tostring(value)

    local characters, _ = term.getSize()

    key = key .. string.rep(" ", characters - string.len(value) - string.len(key) - 1)
    print(key, value)
end

local function showCurrentConfiguration()
    term.clear()
    term.setCursorPos(1, 1)

    if enderChestSlot ~= -1 then
        printConfiguration("Ender Chest", enderChestSlot ~= nil and ("Slot " .. enderChestSlot) or "Deaktiviert")
    end

    if torchSlot ~= -1 then
        printConfiguration("Fackeln", torchSlot ~= nil and ("Slot " .. torchSlot) or "Deaktiviert")
    end

    if depthPerCorridor ~= -1 then
        printConfiguration("Tiefe pro Gang", depthPerCorridor)
    end

    if maxCorridors ~= -1 then
        local fuel = turtle.getFuelLevel()
        printConfiguration("Anzahl an Gänge", maxCorridors)
        printConfiguration("Brennstoff", fuel .. "/" .. requiredFuel)
        if fuel < requiredFuel then
            printConfiguration("Fehlender Brennstoff", requiredFuel - fuel)
            print("")
            print("Bitte Brennstoff in Slot " .. fuelSlot .. " einlegen.")

            showProgressBar(terminalMaxLines, fuel / requiredFuel * 100)
        end
    end

    if string.len(direction) > 0 then
        printConfiguration("Richtung", direction == "right" and "Rechts" or "Links")
    end

    print("")

    if not started then
        return
    end

    printConfiguration("Gang", lastCorridor .. "/" .. maxCorridors)

    if lastCorridorDuration > 0 then
        local bufferTimeForMovement = 1.5;
        local corridorsLeft = maxCorridors - lastCorridor + 1;
        local movementBack = maxCorridors * bufferTimeForMovement;
        printConfiguration("Benötigte Zeit pro Gang", (lastCorridorDuration + bufferTimeForMovement) .. "s")
        printConfiguration("Geschätzte Restzeit", (((lastCorridorDuration + bufferTimeForMovement) * corridorsLeft) + movementBack) .. "s")

        showProgressBar(terminalMaxLines, lastCorridor / maxCorridors * 100)
    end
end

local function getOppositeDirection()
    if direction == "right" then
        return "left"
    end

    return "right"
end

local function simpleTurn(turnDirection)
    if turnDirection == "right" then
        return turtle.turnRight()
    end

    return turtle.turnLeft()
end

local function storeItems(targetCorridor)
    if targetCorridor ~= 0 and turtle.hasEmptySlots(2) then
        return false
    end

    if targetCorridor ~= 0 and enderChestSlot ~= nil then
        turtle.digUpUntilVoid()
        turtle.select(enderChestSlot)
        turtle.placeUp()
        turtle.dropSlots(1, 16, "up", { enderChestSlot, torchSlot })
        turtle.digUpUntilVoid()

        return false
    end

    turtle.home()
    turtle.stopTracking()
    turtle.turnRight(2)
    turtle.dropSlots(1, 16, nil, { enderChestSlot, torchSlot })

    if targetCorridor > 1 then
        simpleTurn(getOppositeDirection())
    else
        turtle.turnRight(2)
    end

    -- TODO CHECK FUEL HERE

    turtle.startTracking()

    if targetCorridor > 1 then
        local forward = (targetCorridor - 1) * 3
        for i = 1, forward do
            turtle.forwardWithDig()
        end

        simpleTurn(getOppositeDirection())
    end

    return true
end

local function digCorridor()
    local start = os.clock()

    if lastCorridorRealStart == 0 then
        lastCorridorRealStart = os.clock()
    end

    turtle.startTracking()
    for i = 1, depthPerCorridor do
        turtle.forwardWithDig()
        turtle.digUpUntilVoid()

        if i ~= depthPerCorridor and storeItems(lastCorridor) then
            return false
        end
    end

    turtle.stopTracking()
    for i = 1, depthPerCorridor do
        turtle.back()
    end

    lastCorridorDuration = math.max(lastCorridorDuration, os.clock() - start)

    table.insert(corridorTimes, {
        tostring(lastCorridor),
        tostring(os.clock() - lastCorridorRealStart) .. "s"
    })
    lastCorridorRealStart = 0

    return true
end

-- ender chest mode
enderChestSlot = tonumber(requestInput("Slot für Ender Chest (leer = deaktiviert)", 0))
if enderChestSlot == nil or enderChestSlot < 1 then
    enderChestSlot = nil
    print("Ender Chest Modus deaktiviert")
elseif hasEnderChest() then
    print("Ender Chest Modus aktiviert und gefunden")
else
    print("Ender Chest Modus aktiviert, bitte Ender Chest in Slot " .. enderChestSlot .. " legen.")
end
print("")

while enderChestSlot ~= nil and not hasEnderChest() do
    sleep(0.5)
end

showCurrentConfiguration()

-- torch mode
torchSlot = tonumber(requestInput("Slot für Fackeln (leer = deaktiviert)", 0))
if torchSlot == nil or torchSlot < 1 then
    torchSlot = nil
    print("Fackel Modus deaktiviert")
else
    print("Fackel Modus aktiviert, bitte Fackeln in Slot " .. torchSlot .. " legen.")
end
print("")

while torchSlot ~= nil and turtle.getItemCount(torchSlot) == 0 do
    sleep(0.5)
end

for slot = 1, 9 do
    if slot ~= enderChestSlot and slot ~= torchSlot then
        fuelSlot = slot
        break
    end
end

-- fuel calculation and refuel turtle
while requiredFuel == 0 do
    depthPerCorridor = -1
    maxCorridors = -1

    while depthPerCorridor == -1 do
        showCurrentConfiguration()
        depthPerCorridor = tonumber(requestInput("Wie tief soll ein Gang gehen? (leer = 32)", 32))
        if depthPerCorridor == nil or depthPerCorridor < 1 then
            depthPerCorridor = -1
        end
    end

    while maxCorridors == -1 do
        showCurrentConfiguration()
        maxCorridors = tonumber(requestInput("Wie viele Gänge sollen entshteen? (leer = 10)", 10))
        if maxCorridors == nil or maxCorridors < 1 then
            maxCorridors = -1
        end
    end

    requiredFuel = calculateRequiredFuelForCorridors(maxCorridors)
    showCurrentConfiguration()

    local limit = turtle.getFuelLimit()
    if requiredFuel > limit then
        print("Die Konfiguration überschreitet das maximale Brennstoff Level von " .. limit)
        print("Bitte gebe eine neue Distanz ein.")
        os.sleep(userWasAlreadyStupid and 3 or 10)

        userWasAlreadyStupid = true
        requiredFuel = 0
    end
end

while turtle.getFuelLevel() < requiredFuel do
    turtle.select(fuelSlot)
    turtle.refuel()
    showCurrentConfiguration()
    os.sleep(0.5)
end

-- set the direction
while string.len(direction) == 0 do
    showCurrentConfiguration()
    direction = string.lower(requestInput("In welche Richtung sollen die Gänge gehen? (R)echts, (L)inks", ""))
    if direction == "r" or direction == "right" then
        direction = "right"
    elseif direction == "l" or direction == "left" then
        direction = "left"
    else
        direction = ""
    end
end

showCurrentConfiguration()
local text = "Drücke Enter um die Turtle zu starten."
term.setCursorPos(1, terminalMaxLines - (string.len(text) > terminalMaxCharacters and 2 or 1))
print(text)

while true do
    local _, key = os.pullEvent("key")
    if key == keys.enter then
        break
    end
end

-- start program
started = true
startedTime = os.clock()

while lastCorridor <= maxCorridors do
    for corridor = lastCorridor, maxCorridors do
        lastCorridor = corridor
        showCurrentConfiguration()

        if not digCorridor() then
            break
        end

        turtle.resetHome()
        local forward = (corridor == maxCorridors and corridor - 1 or corridor) * 3
        turtle.addToWay(direction)
        turtle.addToWay("forward", forward)
        turtle.addToWay(getOppositeDirection())

        if corridor == maxCorridors then
            storeItems(0)
            finished = true
            break
        end

        if not storeItems(corridor + 1) then
            turtle.stopTracking()
            if corridor ~= maxCorridors then
                simpleTurn(direction)
                for i = 1, 3 do
                    turtle.forwardWithDig()
                end
                simpleTurn(getOppositeDirection())
            end
        end
    end

    if finished then
        break
    end
end

-- program finished, go back to home
turtle.home()

term.clear()
term.setCursorPos(1, 1)

local completedIn = (os.clock() - startedTime)
print("Abgeschlossen in "..completedIn.."s Benötigte Zeit pro Gang:")
textutils.pagedTabulate(colors.white, { "Gang", "Zeit" }, colors.lightBlue, table.unpack(corridorTimes))
sendChatMessage("Strip Mining Turtle (" .. (os.getComputerLabel() or os.getComputerID()) .. ") nach " .. completedIn .. "s abgeschlossen.")