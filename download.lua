local httpPrefix = ""

if fs.exists("http_prefix") then
    local httpPrefixFile = fs.open("http_prefix", 'r')
    httpPrefix = httpPrefixFile.readAll()
    httpPrefixFile.close()
end

local function downloadJsonLib()
    local jsonfile = fs.open('lib/json.lua', 'w')
    fs.makeDir("lib")
    jsonfile.write(
            http.get(httpPrefix .. 'https://raw.githubusercontent.com/LuaDist/dkjson/master/dkjson.lua').readAll()
    )
    jsonfile.close()
end

local downloadStepPercent = nil
local downloadStatus = {
    "Alte startup Datei löschen",
    "Programm herunterladen",
    "Libraries herunterladen",
    "Startup erstellen",
    "Reboot",
}
local function printDownloadStatus(downloadStep)
    for i = 1, #downloadStatus do
        term.setCursorPos(1, i)
        term.clearLine()
        local symbol = (downloadStep >= i and "x" or " ")
        local percent = downloadStep == i - 1 and downloadStepPercent ~= nil and ((downloadStepPercent*100).."%") or ""
        print("["..symbol.."] " .. downloadStatus[i], percent)
    end
end

if type(textutils.unserializeJSON) == "nil" and not fs.exists("lib/json.lua") then
    print("textutils.unserializeJSON not supported in your version, downloading JSON library as fallback....")
    downloadJsonLib()
end

local deserializeJson = textutils.unserializeJSON
if not deserializeJson then
    local json = require and require("lib/json") or loadfile("lib/json.lua")()
    deserializeJson = json.decode
end

local files = deserializeJson(http.get(httpPrefix .. 'https://api.github.com/repos/derpierre65/computercraft-scripts/contents/programs').readAll())
local selected = 1

local function downloadLuaScript(filename, url, script)
    if url ~= nil then
        script = http.get(httpPrefix .. url).readAll()
    end

    local osFile = fs.open(filename, "w")
    osFile.write(script)
    osFile.close()
end

local function downloadFile(file)
    term.clear()
    term.setCursorPos(1, 1)

    downloadStepPercent = nil
    printDownloadStatus(0)

    -- delete old startup file if exists
    if fs.exists("startup") then
        shell.run("rm startup")
        os.sleep(1)
        printDownloadStatus(1)
    end

    -- download script
    local script = http.get(httpPrefix .. file.download_url).readAll()
    os.sleep(1)
    printDownloadStatus(2)

    local libraries = {}
    for name in script:gmatch("%-%-%s*@lib%s+([%w_]+)") do
        table.insert(libraries, name)
    end

    downloadStepPercent = 0
    for index, library in ipairs(libraries) do
        if not fs.exists("lib/".. library ..".lua") then
            downloadLuaScript(
                "lib/".. library ..".lua",
                "https://raw.githubusercontent.com/derpierre65/computercraft-scripts/refs/heads/main/lib/".. library ..".lua"
            )
            printDownloadStatus(2)
            downloadStepPercent = index / #libraries
            os.sleep(1)
        end
    end
    downloadStepPercent = 1
    printDownloadStatus(2)
    downloadStepPercent = nil

    -- create startup file
    downloadLuaScript("startup", nil, script)
    os.sleep(1)
    printDownloadStatus(4)

    -- reboot
    os.sleep(1)
    printDownloadStatus(5)
    shell.run("reboot")
end

local function drawSelectMenu()
    local _, maxLines = term.getSize()
    maxLines = maxLines - 3

    term.clear()
    term.setCursorPos(1, 1)

    local from = selected
    local to = math.min(selected + maxLines, #files)

    if from > #files - maxLines then
        from = #files - maxLines
    end

    from = math.max(from, 1)

    print("Welches Programm möchtest du herunterladen?")
    for i = from, to do
        if i == selected then
            if term.setTextColor then
                term.setTextColor(colors.green)
            end
            print("[x] " .. files[i].name)
            if term.setTextColor then
                term.setTextColor(colors.white)
            end
        else
            print("[ ] " .. files[i].name)
        end
    end
end

drawSelectMenu()

local keyUp = keys and keys.up or 200
local keyDown = keys and keys.down or 208
local keyEnter = keys and keys.down or 28

while true do
    local _, key = os.pullEvent("key")
    print(key)
    if key == keyUp then
        selected = selected - 1
        if selected < 1 then
            selected = #files
        end
        drawSelectMenu()
    elseif key == keyDown then
        selected = selected + 1
        if selected > #files then
            selected = 1
        end
        drawSelectMenu()
    elseif key == keyEnter then
        term.clear()
        term.setCursorPos(1, 1)
        print("Download für " .. files[selected].name .. " wird vorbereitet...")

        local download = true
        if fs.exists("startup") then
            print("")
            print("Dieser Computer hat bereits eine startup Datei, soll diese wirklich überschrieben werden? [Y/n]")
            while true do
                local _, confirmKey = os.pullEvent("key")
                if confirmKey == keys.n then
                    print("Download wird abgebrochen...")
                    download = false
                    os.sleep(3)
                    drawSelectMenu()
                else
                    print("")
                end

                break
            end
        end

        if download then
            downloadFile(files[selected])
            break
        end
    end
end