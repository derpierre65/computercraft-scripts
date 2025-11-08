-- @version 1.0.0
-- @lib turtleutils
-- Simple tunnel builder to build a 3x3 tunnel

require("lib/turtleutils")

local width = 3
local height = 3
local maxDepth = 0
local maxPossibleDepth = 0

local function requestInput(text, default)
    print(text)
    local value = read()

    return value ~= "" and value or default
end

local function calculateRequiredFuelPerDepth()
    local fuel = 1
    for y = 1, height do
        if y < height then
            fuel = fuel + 1
        end
    end

    fuel = fuel + 2

    return fuel
end

local function calculateMaxLength(withoutThisFuelValue)
    local perDepth = calculateRequiredFuelPerDepth()
    local fuel = math.floor(turtle.getFuelLevel()) - (withoutThisFuelValue or 0)
    local requiredTotalFuel = 0
    local depth = 0

    while true do
        -- add +1, the turtle must be come back to home
        requiredTotalFuel = requiredTotalFuel + perDepth + 1
        if requiredTotalFuel > fuel then
            break
        end
        depth = depth + 1
    end

    return depth
end

local function digRow()
    turtle.forwardWithDig()
    turtle.stopTracking()
    turtle.turnLeft()
    for y = 1, height do
        turtle.digUntilVoid()
        turtle.turnRight(2)
        turtle.digUntilVoid()

        if y < height then
            turtle.digUpUntilVoid()
            turtle.up()
        end
    end

    turtle.down(2)
    turtle.turnLeft()
    turtle.startTracking()

    -- WIP code for dynamic sizes
    --[[    turtle.forwardWithDig()

        local actions = width - 2

        if width > 1 then
            turtle.turnLeft()
        end

        for i = 1, (width - 2) / 2 do
            turtle.forwardWithDig()
        end

        local isUp = false;
        for i = 1, width - 2 do
            if i % 3 == 1 then
                for y = 1, height do
                    turtle.digUntilVoid()
                    turtle.turnRight(2)
                    turtle.digUntilVoid()

                    if y < height then
                        turtle.digUpUntilVoid()
                        turtle.up()
                    end
                    isUp = true
                end
            elseif i % 3 == 0 then
                turtle.forwardWithDig()
                for y = 1, height do
                    turtle.digUntilVoid()
                    turtle.turnRight(2)
                    turtle.digUntilVoid()

                    if y < height then
                        turtle.digDown()
                        turtle.down()
                    end

                    isUp = false
                end
            else
                turtle.forwardWithDig()
            end
        end

        if isUp then
            for y = 1, height - 1 do
                turtle.down()
            end

            turtle.turnLeft()
        else
            turtle.turnRight()
        end]]
end

term.clear()
term.setCursorPos(1,1)
print("Der Tunnel Builder baut einen 3x3 Tunnel.")

--while width == nil or width < 1 do
--    width = tonumber(requestInput("Breite? (leer = 3)", 3))
--end
--while height == nil or height < 1 do
--    height = tonumber(requestInput("Höhe? (leer = 3)", 3))
--end

maxPossibleDepth = calculateMaxLength()

if maxPossibleDepth < 5 then
    print("Die Turtle hat nicht genug Fuel um einen Tunnel von einer Mindestgröße von 5 bauen zu können. Fülle den 1. Slot mit einem Fuel um zu starten.")
    local _, cursorLine = term.getCursorPos()
    while maxPossibleDepth < 5 do
        if turtle.refuel() then
            maxPossibleDepth = calculateMaxLength()
        end

        term.setCursorPos(1, cursorLine)
        print("Aktuelle Tiefe:", maxPossibleDepth)
        sleep(1)
    end
end

print("Fuel pro Tiefe:", calculateRequiredFuelPerDepth())
print("Fuel:", turtle.getFuelLevel())
print("Mögliche Tiefe:", maxPossibleDepth)
print("")
turtle.turnRight(2)

local sent = false

local checkChest = os.startTimer(1)

while true do
    local event, data = os.pullEvent()
    if event == "timer" and data == checkChest then
        local hasBlock, details = turtle.inspect()
        if hasBlock then
            if string.find(details.name, "chest") or string.find(details.name, "ender_storage") then
                print("Kiste gefunden.")
                break
            end
        end
        if not sent then
            sent = true
            print("Ich habe keine Kiste gefunden, platziere eine Kiste oder drücke Enter um es zu überspringen. Achtung: Items werden einfach rausgeworfen. Es ist sicherer eine Kiste zu platzieren.")
        end

        checkChest = os.startTimer(1)
    end

    if event == "key" and data == keys.enter then
        print("")
        print("Okay, ich werfe die Items dann einfach raus. No risk, no fun oder was?")
        break
    end
end

turtle.turnRight(2)

while maxDepth == nil or maxDepth < 1 do
    maxDepth = tonumber(requestInput("Maximale Tiefe? (leer = "..maxPossibleDepth..")", maxPossibleDepth))
end


local currentDepth = 0

turtle.resetHome()

while currentDepth < maxDepth do
    turtle.forward(currentDepth)

    local remaining = maxDepth - currentDepth
    local sentError = false
    while calculateMaxLength(currentDepth) < remaining do
        if not sentError then
            print("Nicht genug Fuel um die gewünschte Tiefe zu erreichen.")
        end

        if peripheral.getType( "left" ) == "chat_box" then
            peripheral.wrap("left").say("Nicht genug Fuel um die gewünschte Tiefe zu erreichen. ("..(os.getComputerLabel() or os.getComputerID())..")")
        end

        turtle.refuel()
        os.sleep(3)
    end

    for i = currentDepth, maxDepth do
        -- turtle requires 3 empty slots, otherwise the turtle goes back and will empty the inventory
        if not turtle.hasEmptySlots(3) then
            break
        end
        digRow()
        currentDepth = currentDepth + 1
    end

    turtle.home()
    turtle.stopTracking()
    turtle.turnRight(2)
    turtle.dropSlots()
    turtle.turnRight(2)
    turtle.startTracking()
end

if peripheral.getType( "left" ) == "chat_box" then
    peripheral.wrap("left").say("Tunnel Builder "..(os.getComputerLabel() or os.getComputerID()).." ist fertig.")
end