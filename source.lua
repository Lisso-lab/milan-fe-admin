--[[
    Made by: Thuxmwarn (Iss0)
    Contributions: Articlize
    Discord: utc_3 (Thuxmwarn)
    Project made in the span of months, probably deserver UI rewrite, and some sort of logic rewrites.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local _debug = false
local _safeMode = false

local teleportService = game:GetService("TeleportService")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")

local localPlayer = players.LocalPlayer

local defaultConfigData = {
    Username = "Iss0",
    Prefix = "/e ",
    UIKeybind = "Semicolon",
    Keybinds = {},
    EventBinds = {
        CharacterAdded = {},
        CharacterRemoving = {},
        OnSpawn = {},
        OnReset = {},
        PlayerAdded = {},
        PlayerRemoving = {},
        OnJoin = {},
        OnLeave = {}
    }
}
table.freeze(defaultConfigData)

local logsQueue = {}
local commandsArray = {}
local commandsValues = {}

-- //Function categories
local
    filesys,  get,
    rConsole, logs,
    chatLog,  redPing,
    config,   eventBinds,
    inputHandler, rbxConnections,
    UI

local httpRequest =
    (syn and syn.request) or
    (http and http.request) or
    (fluxus and fluxus.request) or
    http_request or request

-- //Functions

local function sanityCheck(data, isAOrType) -- //Returns true if thing isA or Typeof is the provided.
    if typeof(data) == isAOrType then
        return true
    elseif typeof(data) == "Instance" then
        if data:IsA(isAOrType) then
            return true
        else
            return false
        end
    else
        return false
    end
end

local function loadLog(tabl, pastLogInit) -- //Used for logging codebase tables loads.
    tabl.mt = {}

    setmetatable(tabl, tabl.mt)

    setmetatable(tabl, {
        __newindex = function(tablIndex, index, func)
            if func then
                rawset(tablIndex, index, func)

                if pastLogInit then
                    logs:Log("Loaded " .. tostring(index) .. ".")
                else
                    table.insert(logsQueue, "Loaded " .. tostring(index) .. ".")
                end
            end
        end
    })
end

local function sanitizePassTable(options, defaults) -- //Used for setting default values in table, with not providing all values.
    if typeof(options) ~= "table" then return defaults end

    for index in pairs(defaults) do
        if options[index] == nil or typeof(options[index]) ~= typeof(defaults[index]) then
            options[index] = defaults[index]
        end
    end

    return options
end

--[[
    addCommand(
        {"goto", "to"}, -- command
        "teleport to people" -- description
        function(args) -- arguments, unpacked from table
            print("Foo")
        end
    )
]]
local function addCommand(index, description, func, isInGroup) -- //Used to add commands, note mind isInGroup argument, internal.
    local startTime = tick()

    table.insert(commandsArray, {index, description, func})

    if not isInGroup then
        local endtime =  math.round((tick() - startTime) * 1e+9) / 1e+9

        logs:Log("Loaded " .. index[1] .. " Time elapsed: " .. tostring(endtime) .. "s.")
    end
end

local function addCommands(loadMessage, ...) -- //Adds table of commands, First provide string for Loading string(name of the group)
    local commands = {...}

    local startTime = tick()

    for _, command in pairs(commands) do
        table.insert(command, true)

        addCommand(table.unpack(command)) -- //If its in group then it doesnt log its respectable load.
    end

    if loadMessage then
        local endtime =  math.round((tick() - startTime) * 1e+9) / 1e+9

        logs:Log("Loaded " .. loadMessage .. " Time elapsed: " .. tostring(endtime) .. "s.")
    end
end

local function initCommand(commandFunc, args) -- //Last step of executing command, returns pcall.
    args = args or {}

    if not commandFunc then
        return
    end

    local _, err = pcall(function()
        commandFunc(table.unpack(args))
    end)

    return err
end

local function findCommand(index) -- //Returns command in commandsArray table with provided index
    for _, command in pairs(commandsArray) do
        if table.find(command[1], index) then
            return command
        end
    end

    logs:Log("Didn't find command: " .. index .. ".")
end

local function parseCommands(...) -- //Used for processing commands, extracting index of command, and executing it(also handles errors.)
    local args = typeof(...) == "table" and ... or {...}
    local commandIndex = args[1]

    table.remove(args, 1)

    local command = findCommand(commandIndex)

    if not command then
        return
    end

    local commandFunc = command[3]

    local err = initCommand(commandFunc, args)

    if err then -- //TODO handler func
        err = string.split(err, ":")

        if err[2] and err[3] then -- //TODO Fix
            logs:Log(commandIndex ..": "..err[2] ..err[3], 2)
        else
            logs:Log(commandIndex ..": " ..table.concat(err), 2)
        end
    else
        logs:Log("Successfully initialized command: " ..commandIndex ..".")
    end
end

local function processCommandString(message) -- //Used for chat message to run command.
    message = string.gsub(message, "%s+", " ") -- //Example: "<prefix>      command    arg" = "<prefix> command arg"

    local messageSplitArgs = string.split(message, " ")

    parseCommands(table.unpack(messageSplitArgs))
end

local function playerChatted(message)
    local prefix = config.Data.Prefix

    if string.sub(message, 1, #prefix) == prefix then
        message = string.sub(message, #prefix + 1)

        processCommandString(message)
    end
end

--[[
    filesys = {
        verifyIntegrity()
    }
]]
local function initializeFileSystem()
    do
        table.insert(logsQueue, {"Initializing Filesystem...", 3})

        filesys = {}

        loadLog(filesys, false)
    end

    local fileIntegrity = {
        ["Milan Admin"] = {
            ["Admin logs"] = {},
            ["config.cfg"] = httpService:JSONEncode(defaultConfigData),
            ["Chat logs"] = {}
        }
    }

    local function fileSysBuild(filesysPath, tabl) -- //Function which builds filesystem from provided table.
        filesysPath = filesysPath .."/"

        for index, value in pairs(tabl) do
            if typeof(value) == "string" then
                if isfile(filesysPath ..index) then
                    continue
                end

                writefile(filesysPath .. index, value)
            elseif typeof(value) == "table" then
                if not isfolder(filesysPath .. index) then
                    makefolder(filesysPath .. index)
                end

                fileSysBuild(filesysPath .. index, value)
            else
                if isfile(index .. index) then
                    continue
                end

                writefile(index, "")
            end
        end
    end

    function filesys:verifyIntegrity() -- //just runs fileSysBuild Function
        fileSysBuild("", fileIntegrity)
    end

    -- //Post-initialization
    do
        filesys:verifyIntegrity()

        table.insert(logsQueue, {"Initialized filesystem.", 3})
    end
end

--[[
    get = {
        Player()
        Character()
        Humanoid()
        Root()
    }
]]
local function initializeEnvironment()
    do
        table.insert(logsQueue, {"Initializing get environment...", 3})

        get = {}

        loadLog(get, false)
    end

    local stats = game:GetService("Stats")
    local performanceStats = stats.PerformanceStats
    local frameRateManager = stats.FrameRateManager
    local statsWorkspace = stats.Workspace
    local serverStatsItems = stats.Network.ServerStatsItem

    -- // CLIENT STUFF

    function get:DateTime(token) -- //Get date/time by DateTime. See roblox docs, for refference.
        local dateTime = DateTime.now()
        -- //Maybe make admin get country (en-us) but for now I will just use it as default
        return dateTime:FormatLocalTime(token, "en-us")
    end

    function get:FPS() -- //Returns render fps.
        return statsWorkspace.FPS:GetValue()
    end

    function get:GameEnvSpeedPercent() -- //Get Environment(game) speed in %.
        return statsWorkspace["Environment Speed %"]:GetValue()
    end

    function get:AvgFPS() -- //Get average render FPS.
        return frameRateManager["AverageFps"]:GetValue()
    end

    function get:GPUMs() -- //Get GPU ms delay.
        return performanceStats["GPU"]:GetValue()
    end

    function get:CPUMs() -- //Get CPU ms delay.
        return performanceStats["CPU"]:GetValue()
    end

    function get:NetworkRecieved() -- //Get Recieve(network).
        return performanceStats["NetworkReceived"]:GetValue()
    end

    function get:NetworkSent() -- //Get Sent(network).
        return performanceStats["NetworkSent"]:GetValue()
    end

    function get:Ping() -- //Get ping (not average).
        return serverStatsItems["Data Ping"]:GetValue()
    end

    function get:HeadShot(userId, size) -- //Get roblox avatar headshot photo.
        return players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            size
        )
    end

    function get:Mouse() -- //player:GetMouse()
        return localPlayer:GetMouse()
    end

    function get:LPlayer() -- //Returns local player.
        return localPlayer
    end

    function get:LCharacter() -- //Returns localPlayer character.
        return localPlayer.Character or workspace[localPlayer.Name]
    end

    function get:LHumanoid() -- //Returns localplayer character humanoid.
        local character = get:LCharacter()

        if character then
            return character:FindFirstChild("Humanoid") or character:FindFirstChildWhichIsA("Humanoid")
        end
    end

    function get:LRoot() -- //Returns localplayer character root. Tries to return HumanoidRootPart, if it doesn't exists, returns .PrimaryPart
        local character = get:LCharacter()

        if character then
            return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        end
    end

    -- // NOT CLIENT STUFF

    function get:StringLength(string)
        return utf8.len(string)
    end

    function get:Player(playerName) -- //Get player from name | displayname. For getting local player use:LPlayer()
        if not playerName or #playerName < 4 then
            return
        end

        playerName = string.lower(playerName)

        local playersTabl = players:GetChildren()
        table.remove(playersTabl, table.find(playersTabl, localPlayer))

        if playerName == "random" then
            return playersTabl[math.random(1, #playersTabl)]
        else
            for _, player in pairs(playersTabl) do
                local lowerName = string.lower(player.Name)
                local lowerDisName = string.lower(player.DisplayName)

                if string.sub(lowerName, 1, #playerName) == playerName or string.sub(lowerDisName, 1, #playerName) == playerName then
                    logs:Log("Found player: " .. player.Name)

                    return player
                end
            end
        end
    end

    function get:Character(target) -- //Get character from player. For getting local player use:LCharacter()
        if sanityCheck(target, "Player") then
            return target.Character or workspace:FindFirstChild(target.Name)
        elseif sanityCheck(target, "string") then
            local player = get:Player(target)

            if player then
                return player.Character
            end
        end
    end

    function get:Humanoid(target) -- //Get humanoid from character. For getting local player use:LHumanoid()
        if sanityCheck(target, "Model") then
            return target:FindFirstChild("Humanoid") or target:FindFirstChildWhichIsA("Humanoid")
        elseif sanityCheck(target, "Player") then
            local character = get:Character(target)

            if character then
                return character:FindFirstChild("Humanoid") or character:FindFirstChildWhichIsA("Humanoid")
            end
        elseif sanityCheck(target, "string") then
            local player = get:Player(target)

            if not player then
                return
            end

            local character = get:Character(player)

            if character then
                return character:FindFirstChild("Humanoid") or character:FindFirstChildWhichIsA("Humanoid")
            end
        end
    end

    function get:Root(target) -- //Get Root from character. Tries to return HumanoidRootPart, if it doesn't exists, returns .PrimaryPart. For getting local player use:LRoot() 
        if sanityCheck(target, "Model") then
            return target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        elseif sanityCheck(target, "Player") then
            local character = get:Character(target)

            if character then
                return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
            end
        elseif sanityCheck(target, "string") then
            local player = get:Player(target)

            if not player then
                return
            end

            local character = get:Character(player)

            if character then
                return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
            end
        end
    end

    function get:EnumName(enum) -- //Returns Enum name, if string is provided, returns that.
        return type(enum) == "string" and enum or enum.Name
    end

    function get:TupletsTable(...) -- //Used to convert tuplets to table, if table is provided, returns that.
        return type(...) == "table" and ... or {...}
    end

    -- //Post-initialization
    do
        table.freeze(get)

        table.insert(logsQueue, {"Initialized get environment.", 3})
    end
end

--[[
    rConsole = {
        Rename(),
        Print()
    }
]]
local function initializeRConsole() -- //TODO FIX ITS SHIT AND SHIT AND SHIT AND IDK DOESNT WORK
    do
        table.insert(logsQueue, {"Initializing rconsole...", 3})

        rConsole = {}

        loadLog(rConsole, false)
    end

    local defaultColor = "@@WHITE@@"

    if not rconsoleprint then
        function rConsole:Rename() end
        function rConsole:Print() end
        -- //If other exploits which don't support it.

        return
    end

    if typeof(getexecutorname) == "function" and string.find(getexecutorname(), "ScriptWare") then
        local colorConvertions = {
            ["@@BLACK@@"] = "black",
            ["@@BLUE@@"] = "blue",
            ["@@GREEN@@"] = "green",
            ["@@CYAN@@"] = "cyan",
            ["@@RED@@"] = "red",
            ["@@MAGENTA@@"] = "magenta",
            ["@@BROWN@@"] = "brown",
            ["@@LIGHT_GRAY@@"] = "white",
            ["@@DARK_GRAY@@"] = "white",
            ["@@LIGHT_BLUE@@"] = "blue",
            ["@@LIGHT_GREEN@@"] = "green",
            ["@@LIGHT_CYAN@@"] = "cyan",
            ["@@LIGHT_RED@@"] = "red",
            ["@@LIGHT_MAGENTA@@"] = "magenta",
            ["@@YELLOW@@"] = "yellow",
            ["@@WHITE@@"] = "white"
        }

        function rConsole:Rename(title) -- //Renames console window name.
            rconsolename(title or "ScriptWare console")
        end

        function rConsole:Print(str, color) -- //Prints Message in console (no breakline), defaults to defaultcolor after printing.
            consoleprint(str, colorConvertions[color])
        end
    elseif not getexecutorname then
        local colorConvertions = {
            ["@@BLACK@@"] = "black",
            ["@@BLUE@@"] = "blue",
            ["@@GREEN@@"] = "green",
            ["@@CYAN@@"] = "cyan",
            ["@@RED@@"] = "red",
            ["@@MAGENTA@@"] = "magenta",
            ["@@BROWN@@"] = "brown",
            ["@@LIGHT_GRAY@@"] = "white",
            ["@@DARK_GRAY@@"] = "white",
            ["@@LIGHT_BLUE@@"] = "blue",
            ["@@LIGHT_GREEN@@"] = "green",
            ["@@LIGHT_CYAN@@"] = "cyan",
            ["@@LIGHT_RED@@"] = "red",
            ["@@LIGHT_MAGENTA@@"] = "magenta",
            ["@@YELLOW@@"] = "yellow",
            ["@@WHITE@@"] = "white"
        }

        function rConsole:Rename(title) -- //Renames console window name.
            rconsolename(title or "ScriptWare console")
        end

        function rConsole:Print(str, color) -- //Prints Message in console (no breakline), defaults to defaultcolor after printing.
            color = color or defaultColor

            rconsoleprint(colorConvertions[color] .. str)
        end
    else
        function rConsole:Rename(str) -- //Renames console window name.
            rconsolename(str or "Synapse X console")
        end

        function rConsole:Print(str, color) -- //Prints Message in console (no breakline), defaults to defaultcolor after printing.
            color = color or defaultColor

            rconsoleprint(colorConvertions[color] .. str)
        end
    end

    do
        if _debug then
            rConsole:Rename("Debugging Milan admin.")

            rConsole:Print("\nStart of debugging at: " .. get:DateTime("LT L") .. ".\n-----------------\n")
        end

        table.freeze(rConsole)

        table.insert(logsQueue, {"Initialized rConsole.", 3})
    end
end

--[[
    logs = {
        Log(),
        CountRunTimes()
    }
]]
local function initializeLogs()
    do
        table.insert(logsQueue, {"Initializing chat logs...", 3})

        logs = {}

        loadLog(logs, false)
    end

    local filesysPath = "Milan admin/Admin logs/"
    local startLogsText = string.format("Logs of: %s, starting at: %s.\n------\n", get:DateTime("LT"), get:DateTime("L"))
    local runTimeCount -- //Will be stored in string, because there is no need for it to be stored otherwise.

    local levelStrings = {
        "[%s] ",
        "[%s] [Error!] ",
        "[Milan admin] "
    }

    local levelConsoleColor = {
        {"@@DARK_GRAY@@", "@@YELLOW@@"},
        {"@@RED@@", "@@LIGHT_RED@@"},
        {"@@DARK_GRAY@@", "@@YELLOW@@"}
    }

    function logs:CountRunTimes()
        filesys:verifyIntegrity()

        local filesAmount = #listfiles(filesysPath)

        return tostring(filesAmount + 1)
    end

    function logs:Log(str, level) -- //Logs message in file, and syn x console, has 4 levels of prefixes, internal use intended.
        -- //Currently 3 levels //level 1 execution, actions of user. non-error logs.
        -- //level 2 errors, errors inside code (mostly, all errors pcalled)
        -- //level 3 reserved level. Only used when initiliazing it.
        -- //level 4 rConsole and just no prefix stuff...
        level = level or 1

        filesys:verifyIntegrity()

        if not isfile(filesysPath .. runTimeCount .. ".txt") then
            writefile(filesysPath .. runTimeCount .. ".txt", startLogsText)
        end

        local logPrefix = levelStrings[level]
        logPrefix = string.format(logPrefix, get:DateTime("LTS"))

        appendfile(filesysPath .. runTimeCount .. ".txt", logPrefix .. str .. "\n")

        if _debug then
            local colorTable = levelConsoleColor[level]

            rConsole:Print(string.format(logPrefix, get:DateTime("LTS")), colorTable[1])
            rConsole:Print(str .. "\n", colorTable[2])
        end
    end

    -- //Post-initialization
    do
        runTimeCount = logs:CountRunTimes()

        writefile(filesysPath .. runTimeCount .. ".txt", startLogsText)

        if _debug then
            logs:Log("Debugging admin with console.", 3)
        end

        for _, message in pairs(logsQueue) do
            if typeof(message) == "table" then
                logs:Log(table.unpack(message))
            else
                logs:Log(message)
            end
        end

        table.remove(logsQueue)
        table.freeze(levelConsoleColor)

        logs:Log("Logs initialized.", 3)
    end
end

local function initializeChatLogs()
    do
        logs:Log("Initializing chat logs...", 3)

        chatLog = {}

        loadLog(chatLog, true)
    end

    local filesysPath = "Milan Admin/Chat logs/"

    local minInternalParsedStrLength = 110

    local startLogsText = "Chat logs of: " .. get:DateTime("L") .. "game id: " .. game.GameId .. "jobid: " .. game.JobId

    local prevMessageInfo = {
        ["Name"] = "",
        ["Message"] = "",
        ["MessageRepCounter"] = 1,
        ["Time"] = ""
    } -- //Used to count as how many times player chatted same message, and also stores previous message time.

    local dateFilePath

    local function getStringLength(message)
        local actualLength = get:StringLength(message)

        return actualLength <= minInternalParsedStrLength and minInternalParsedStrLength or actualLength
    end

    local function processInternalOutlines(message) -- //Creates box around message, with scalable size depending on the message size.
        local textLength = getStringLength(message)
        local messageOutline = string.rep("-", textLength + 1) .."|"

        return string.format("%s\n%s\n%s",
            messageOutline,
            (message .. string.rep(" ", (textLength + 1 - utf8.len(message))) .. "|\n"),
            messageOutline
        ),
        textLength -- //Used to determine final size of internallog thingy.
    end

    function chatLog:FileExists() -- //Returns if file exists in which logs are stored.
        return isfile(filesysPath .. dateFilePath .. ".txt")
    end

    function chatLog:formatLogMessage(time, name, message, repeatCount) -- //Used for formatting chat messaged to pleasable format.
        return string.format("%s[%s]: %s" .. (repeatCount and " (%sx)" or ""),
            time,
            name,
            message,
            repeatCount
        )
    end

    function chatLog:InternalLog(message, forceOutlines) -- //Used for player joined, player left and all sorts of chatLogs notifications.
        filesys:verifyIntegrity()

        if not chatLog:FileExists() then
            chatLog:GenerateFile()
        end

        dateFilePath = get:DateTime("L")
        dateFilePath = string.gsub(dateFilePath, "/", ".")

        local parsedMessage, messageLength = processInternalOutlines(message)
        local parsedMessageSplit = string.split(parsedMessage, "\n")

        local fileContents = readfile(filesysPath .. dateFilePath .. ".txt")
        local fileContentsSplit = string.split(fileContents, "\n")

        -- // + 2 cuz idk? But + 1 would make sense...
        if not forceOutlines and messageLength + 2 == #fileContentsSplit[#fileContentsSplit] then
            fileContentsSplit[#fileContentsSplit] = string.rep(" ", messageLength + 1) .. "|"

            table.remove(parsedMessageSplit, 1)

            table.insert(fileContentsSplit, parsedMessageSplit[1])
            table.insert(fileContentsSplit, parsedMessageSplit[2])

            writefile(filesysPath .. dateFilePath .. ".txt", table.concat(fileContentsSplit, "\n"))
        else
            appendfile(filesysPath .. dateFilePath .. ".txt", "\n" .. parsedMessage)
            -- //I could prolly add pcall and do some checks if the string is too big, but I dont think it will error.
            -- //Famous last words.
        end
    end

    function chatLog:GenerateFile() -- //Generates the file with ... FUCK
        writefile(filesysPath .. dateFilePath .. ".txt", "")

        chatLog:InternalLog(startLogsText, true)
    end

    function chatLog:GetPreNameTimeDisplay() -- //Returns space before message with/without time if it changed before
        local currTime = get:DateTime("LT")  -- //Previous message.

        if prevMessageInfo["Time"] ~= currTime then
            prevMessageInfo["Time"] = currTime

            return currTime .. " "
        else
            return string.rep(" ", 8)
        end
    end

    function chatLog:ParseMessage(name, message) -- //Returns formatted message, and if it was repeated.
        local currTime = chatLog:GetPreNameTimeDisplay()

        if not chatLog:FileExists() then
            chatLog:GenerateFile()
        end -- //I'unno if I should put it here or somewhere outside :shrug

        if prevMessageInfo["Name"] == name and prevMessageInfo["Message"] == message then
            prevMessageInfo["MessageRepCounter"] += 1

            local repeatCount = tostring(prevMessageInfo["MessageRepCounter"])

            return chatLog:formatLogMessage(currTime, name, message, repeatCount), true -- //Is repeated.
        else
            prevMessageInfo["MessageRepCounter"] = 1

            prevMessageInfo["Name"] = name
            prevMessageInfo["Message"] = message

            return chatLog:formatLogMessage(currTime, name, message), false -- //Is NOT repeated.
        end
    end

    function chatLog:Log(name, message)
        filesys:verifyIntegrity()

        dateFilePath = get:DateTime("L")
        dateFilePath = string.gsub(dateFilePath, "/", "_")

        local prefix = config.Data.Prefix

        local parsedMessage, isRepeating

        if string.sub(string.lower(message), 1, #prefix) == prefix then
            return
        elseif string.sub(message, 1, 3) == "/w " then
            local wordsArray = string.split(message, " ")
            local whisperTarget = wordsArray[2]

            if players:FindFirstChild(whisperTarget) then
                local _, afterNameMessage = string.find(message, whisperTarget)

                name = string.format("%s {%s}", name, whisperTarget)
                message = string.sub(message, afterNameMessage + 2)
            end

            parsedMessage, isRepeating = chatLog:ParseMessage(name, message)
        else
            parsedMessage, isRepeating = chatLog:ParseMessage(name, message)
        end

        if isRepeating then
            local fileContents = readfile(filesysPath .. dateFilePath .. ".txt")
            local fileContentsSplit = string.split(fileContents, "\n")

            fileContentsSplit[#fileContentsSplit] = parsedMessage

            writefile(filesysPath .. dateFilePath .. ".txt", table.concat(fileContentsSplit, "\n"))
        else
            appendfile(filesysPath .. dateFilePath .. ".txt", "\n" ..  parsedMessage)
        end
        -- //I could prolly add pcall and do some checks if the string is too big, but I dont think it will error.
        -- //Famous last words.
    end

    function chatLog.OnMessageDoneFiltering(args) -- //First Main connection function.
        local name, message = args.FromSpeaker, args.Message
        name = name == localPlayer.Name and config.Data.Username or name

        if prevMessageInfo["Name"] == name and prevMessageInfo["Message"] == message then
            return
        end

        chatLog:Log(name, message)
    end

    function chatLog.OnPlayerChatted(_, player, message) -- //Second main connection function.
        local name = player.Name
        name = name == localPlayer.Name and config.Data.Username or player.Name

        chatLog:Log(name, message)
    end

    -- //Post-initialization
    do
        coroutine.wrap(function()
            local _
            _, chatLog.MessageDoneFiltering = pcall(function()
                local chatEvents = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents")

                return chatEvents:WaitForChild("OnMessageDoneFiltering")
            end)
        end)()

        dateFilePath = get:DateTime("L")
        dateFilePath = string.gsub(dateFilePath, "/", "_")

        if chatLog:FileExists() then
            chatLog:InternalLog(startLogsText, true)
        end

        logs:Log("Chat log initialized.", 3)
    end
end

--[[
    redPing = {
        CalculatePredictionSineWave()
    }
]]
local function initializeRedPing()
    do
        logs:Log("Initializing redPing...", 3)

        redPing = {}

        loadLog(redPing, true)
    end

    function redPing:CalculatePredictionSineWave(moveDir, velocity, options) -- //Does sine wave movement prediction, while taking ping/fps into account.
        options = sanitizePassTable(options, {
            cosSpeed = 3.5
        })

        velocity = Vector3.new(velocity.X, 0, velocity.Z)

        local ping = get:Ping()
        ping = ping / get:FPS() -- //Weird but works..

        local sinWave =  math.abs(math.sin(tick() * options.cosSpeed) / 2)

        return CFrame.new(moveDir * ping * (velocity.Magnitude / ping) * sinWave)
    end

    -- //Post-initialization
    do
        logs:Log("RedPing initialized.", 3)
    end
end

--[[
    keybind.binds = {
        {{"f", "F1", "MouseButton1}, "ws"} -- bro that too much
        {{"ctrl", "z"}, "teleport"},
        {{"MouseButton1", "z"}, "teleport"}
    }
]]
local function initializeInputHandler()
    -- //Promptly provided to me by Articlize, :( ), SHIT I ACCIDENTALY REWROTEIT-ISH
    do
        logs:Log("Initializing inputHandler...", 3)

        inputHandler = {}
        inputHandler.inputHistory = {}

        loadLog(inputHandler, true)
    end

    local inputConnection = {}
    inputConnection.__index = inputConnection
    inputConnection.objects = {}

    do -- //!!!inputConnection!!!// --
        function inputConnection:New()
            local self = setmetatable(
                {
                    listener = true,
                    enumCombination = nil,
                    status = false,
                },
                inputConnection
            )

            table.insert(inputConnection.objects, self)

            return self
        end

        function inputConnection:Update(newStatus, ...)
            if self.status ~= newStatus then
                self.status = newStatus
                self.listener(newStatus, {...})
            end
        end

        function inputConnection:Disconnect()
            table.remove(inputConnection.objects, table.find(inputConnection.objects, self))
        end
    end -- //!!!inputConnection END!!!// --

    function inputHandler:IsPressed(...)
        local lastTick = 0

        for _, enum in ipairs(get:TupletsTable(...)) do
            local currentTick = inputHandler.inputHistory[get:EnumName(enum)] or -1

            if currentTick < lastTick then
                return false
            end

            lastTick = currentTick
        end

        return true
    end

    function inputHandler:IdentifyEnum(inputObject)
        return inputObject.KeyCode ~= Enum.KeyCode.Unknown and inputObject.KeyCode or
            inputObject.UserInputType ~= Enum.UserInputType.None and inputObject.UserInputType
    end

    function inputHandler:ConnectBind(enumCombination, listenerFunc)
        local inputConnectionOOP = inputConnection:New()
        inputConnectionOOP.enumCombination = enumCombination

        inputConnectionOOP.listener = listenerFunc
    end

    function inputHandler:UpdateConnections(inputBegan, actualEnum)
        for _, connection in ipairs(inputConnection.objects) do
            if connection.enumCombination then
                connection:Update(inputHandler:IsPressed(connection.enumCombination))
            else
                connection:Update(inputBegan, actualEnum)
            end
        end
    end

    function inputHandler.InputChanged(inputObject)
        local actualEnum = inputHandler:IdentifyEnum(inputObject)
        local enumName = actualEnum.Name

        local inputBegan = inputObject.UserInputState == Enum.UserInputState.Begin

        inputHandler.inputHistory[enumName] = inputBegan and tick() or nil
        inputHandler:UpdateConnections(inputBegan, actualEnum)
    end

    -- //Post-initialization
    do
        table.freeze(inputHandler)

        logs:Log("InputHandler initialized.", 3)
    end
end
-- //TODO THIS SHIT I HATE IT MAKE NEW IDK OR BEG ARTI TO GIVE BETTER VERSION :)

--[[
    config = {
        Check()
        Load()
        Save()

        !Config Data inbetween functions!!
        Data = {
            Prefix = "/e ",
            UIKeybind = "Semicolon",
            Keybinds = {},
            Username = "Iss0"
        }
    }
]]
local function initializeConfig()
    do
        logs:Log("Initializing config...", 3)

        config = {}

        loadLog(config, true)
    end

    local configPath = "Milan admin/config.cfg"

    function config:Save(data) -- //Saves data into config file, or creates new config file with default data.
        filesys:verifyIntegrity()

        data = data or defaultConfigData

        config.Data = data

        writefile(configPath, httpService:JSONEncode(data))
    end

    function config:LoadKeybinds() -- //Loads keybinds which are binded.
        local keybinds = config.Data.Keybinds

        for _, keybind in pairs(keybinds) do
            local enumCombination, cmdIndex, onPressedDown = keybind[1], keybind[2], keybind[3]

            inputHandler:ConnectBind(enumCombination, function(isPressed)
                if isPressed == onPressedDown then
                    for i=1, #cmdIndex do
                        parseCommands(cmdIndex[i])
                    end
                end
            end)
        end
    end

    function config:Load() -- //Loads config file, does one sanity check and simply 
        local _, data = pcall(function()
            return httpService:JSONDecode(readfile(configPath))
        end)

        if typeof(data) == "table" then
            config.Data = data

            logs:Log("Loaded config.")
        else
            config:Save() -- //Creates raw config

            logs:Log("Broken config, reloaded default config.")
        end

        config:LoadKeybinds()
    end

    -- //Post-initialization
    do
        config:Load()

        -- //Can't freeze

        logs:Log("Config initialized.", 3)
    end
end

local function initializeUI()
    do
        UI = {
            Data = {}
        }

        loadLog(UI, true)
    end

    local screenGUI
    local mainUI
    local inputBox

    function UI:Load()
        local UIElements = {}

        UIElements["1"] = Instance.new("ScreenGui")
        UIElements["1"]["Name"] = [[Milan UI]]

        -- StarterGui.Milan UI.MainFrame
        UIElements["2"] = Instance.new("Frame", UIElements["1"])
        UIElements["2"]["ZIndex"] = 2
        UIElements["2"]["BackgroundColor3"] = Color3.fromRGB(45, 48, 52)
        UIElements["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
        UIElements["2"]["Size"] = UDim2.new(0.08000000596046448, 0, 0.034999999701976776, 0)
        UIElements["2"]["Position"] = UDim2.new(0.5, 0, -.2, 0)
        UIElements["2"]["Name"] = [[MainFrame]]

        -- StarterGui.Milan UI.MainUICorner
        UIElements["3"] = Instance.new("UICorner", UIElements["2"])
        UIElements["3"]["Name"] = [[MainUICorner]]

        -- StarterGui.Milan UI.MainFrame.TopBar
        UIElements["4"] = Instance.new("Frame", UIElements["2"])
        UIElements["4"]["ZIndex"] = 3
        UIElements["4"]["BackgroundColor3"] = Color3.fromRGB(36, 40, 43)
        UIElements["4"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
        UIElements["4"]["Size"] = UDim2.new(1, 0, 0.30000001192092896, 0)
        UIElements["4"]["Position"] = UDim2.new(0.5, 0, -0.15000000596046448, 0)
        UIElements["4"]["Name"] = [[TopBar]]

        -- StarterGui.Milan UI.MainFrame.TopBar.TopBarUiCorner
        UIElements["5"] = Instance.new("UICorner", UIElements["4"])
        UIElements["5"]["Name"] = [[TopBarUiCorner]]

        -- StarterGui.Milan UI.MainFrame.TopBar.TopBarFix
        UIElements["6"] = Instance.new("Frame", UIElements["4"])
        UIElements["6"]["ZIndex"] = 3
        UIElements["6"]["BorderSizePixel"] = 0
        UIElements["6"]["BackgroundColor3"] = Color3.fromRGB(36, 40, 43)
        UIElements["6"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
        UIElements["6"]["Size"] = UDim2.new(1, 0, 0, 12)
        UIElements["6"]["Position"] = UDim2.new(0.5, 0, 1, 0)
        UIElements["6"]["Name"] = [[TopBarFix]]

        -- StarterGui.Milan UI.MainFrame.TopBar.TopBarFix.WhiteLine
        UIElements["7"] = Instance.new("Frame", UIElements["6"])
        UIElements["7"]["ZIndex"] = 3
        UIElements["7"]["BorderSizePixel"] = 0
        UIElements["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["7"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
        UIElements["7"]["Size"] = UDim2.new(1, 0, 0, 1)
        UIElements["7"]["Position"] = UDim2.new(0.5, 0, 1, 0)
        UIElements["7"]["Name"] = [[WhiteLine]]

        -- StarterGui.Milan UI.MainFrame.TopBar.TopBarFix.WhiteLine.WhiteLineGradient\
        UIElements["8"] = Instance.new("UIGradient", UIElements["7"])
        UIElements["8"]["Name"] = [[WhiteLineGradient\]]
        UIElements["8"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(133, 133, 133)),ColorSequenceKeypoint.new(0.083, Color3.fromRGB(184, 184, 184)),ColorSequenceKeypoint.new(0.200, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(0.800, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(133, 133, 133))}

        -- StarterGui.Milan UI.MainFrame.TopBar.TitleText
        UIElements["9"] = Instance.new("TextLabel", UIElements["4"])
        UIElements["9"]["ZIndex"] = 3
        UIElements["9"]["TextXAlignment"] = Enum.TextXAlignment.Left
        UIElements["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["9"]["TextSize"] = 20
        UIElements["9"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["9"]["AnchorPoint"] = Vector2.new(0, 0.5)
        UIElements["9"]["Size"] = UDim2.new(0.5, 0, 1.100000023841858, 0)
        UIElements["9"]["Text"] = [[Milan admin]]
        UIElements["9"]["Name"] = [[TitleText]]
        UIElements["9"]["Font"] = Enum.Font.TitilliumWeb
        UIElements["9"]["BackgroundTransparency"] = 1
        UIElements["9"]["Position"] = UDim2.new(0, 0, 0.6499999761581421, 0)

        -- StarterGui.Milan UI.MainFrame.TopBar.TitleText.TitleUiPadding
        UIElements["a"] = Instance.new("UIPadding", UIElements["9"])
        UIElements["a"]["Name"] = [[TitleUiPadding]]
        UIElements["a"]["PaddingLeft"] = UDim.new(0, 6)

        -- StarterGui.Milan UI.MainFrame.InputBox
        UIElements["b"] = Instance.new("TextBox", UIElements["2"])
        UIElements["b"]["CursorPosition"] = -1
        UIElements["b"]["ZIndex"] = 2
        UIElements["b"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["b"]["TextSize"] = 20
        UIElements["b"]["BackgroundColor3"] = Color3.fromRGB(42, 44, 48)
        UIElements["b"]["AnchorPoint"] = Vector2.new(.5, 0.5)
        UIElements["b"]["PlaceholderText"] = "Hello!, " .. config.Data.Username
        UIElements["b"]["Size"] = UDim2.new(0.800000011920929, 0, 0.5, 0)
        UIElements["b"]["Text"] = [[]]
        UIElements["b"]["Position"] = UDim2.new(.5, 0, 0.550000011920929, 0)
        UIElements["b"]["Font"] = Enum.Font.TitilliumWeb
        UIElements["b"]["Name"] = [[InputBox]]

        -- StarterGui.Milan UI.MainFrame.InputBox.UICorner
        UIElements["d"] = Instance.new("UICorner", UIElements["b"])
        UIElements["d"]["CornerRadius"] = UDim.new(0, 6)

        -- StarterGui.Milan UI.MainFrame.InputBox.UIStroke
        UIElements["e"] = Instance.new("UIStroke", UIElements["b"])
        UIElements["e"]["Color"] = Color3.fromRGB(255, 255, 255)
        UIElements["e"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border

        -- StarterGui.Milan UI.MainFrame.InputBox.UIStroke.UIGradient
        UIElements["f"] = Instance.new("UIGradient", UIElements["e"])
        UIElements["f"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(184, 184, 184)),ColorSequenceKeypoint.new(0.303, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(0.800, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))}

        -- StarterGui.Milan UI.MainFrame.DropShadowHolder
        UIElements["10"] = Instance.new("Frame", UIElements["2"])
        UIElements["10"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["10"]["BackgroundTransparency"] = 1
        UIElements["10"]["Size"] = UDim2.new(1, 0, 1.2999999523162842, 0)
        UIElements["10"]["Position"] = UDim2.new(0, 0, -0.30000001192092896, 0)
        UIElements["10"]["Name"] = [[DropShadowHolder]]

        -- StarterGui.Milan UI.MainFrame.DropShadowHolder.DropShadow
        UIElements["11"] = Instance.new("ImageLabel", UIElements["11"])
        UIElements["11"]["SliceCenter"] = Rect.new(49, 49, 450, 450)
        UIElements["11"]["ScaleType"] = Enum.ScaleType.Slice
        UIElements["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
        UIElements["11"]["ImageColor3"] = Color3.fromRGB(0, 0, 0)
        UIElements["11"]["ImageTransparency"] = 0.5
        UIElements["11"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
        UIElements["11"]["Image"] = [[rbxassetid://6014261993]]
        UIElements["11"]["Size"] = UDim2.new(1, 40, 1, 40)
        UIElements["11"]["Active"] = true
        UIElements["11"]["Name"] = [[DropShadow]]
        UIElements["11"]["BackgroundTransparency"] = 1
        UIElements["11"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)

        return UIElements["1"], UIElements["2"], UIElements["b"]
    end

    function UI:GetInputBox()
        return inputBox
    end

    function UI:GetScreenGui()
        return screenGUI
    end

    function UI:GetMainUI()
        return mainUI
    end

    function UI:Open()
        inputBox:CaptureFocus()

        mainUI.Size = UDim2.new(0, mainUI.Size.X.Offset - 40, mainUI.Size.Y.Scale, mainUI.Size.Y.Offset)

        UI.TextChanged()
        mainUI:TweenPosition(
            UDim2.new(0.5, 0, 0.1, 0),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quint,
            .4,
            true
        )
    end

    function UI:Close()
        if inputBox:IsFocused() then
            inputBox:ReleaseFocus()
        end

        mainUI:TweenSizeAndPosition(
            UDim2.new(0, mainUI.Size.X.Offset - 40, mainUI.Size.Y.Scale, mainUI.Size.Y.Offset),
            UDim2.new(.5, 0, -0.1, 0),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quint,
            .1,
            true
        )
    end

    function UI.KeybindTriggered(isPressed)
        if isPressed then
            return
        end

        if not inputBox:IsFocused() and not userInputService:GetFocusedTextBox() then
            UI:Open()
        end
    end

    function UI.FocusLost()
        local UIKeybind = userInputService:GetStringForKeyCode(config.Data.UIKeybind)
        local text = inputBox.Text

        UI:Close()

        if text ~= "" then
            text = string.lower(text)

            if string.sub(text, 1, #UIKeybind) == UIKeybind then
                text = string.sub(text, #UIKeybind + 1)
            end

            processCommandString(text)
        end
    end

    function UI.TextChanged()
        local textBoxUDim2 = inputBox.Size

        mainUI:TweenSize(
            UDim2.new(0, math.clamp(inputBox.TextBounds.X + 30, 100, 9e99), 0.034999999701976776, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            .1,
            true
        )

        inputBox:TweenSize(
            UDim2.new(0, inputBox.TextBounds.X + 13, textBoxUDim2.Y.Scale, textBoxUDim2.Y.Offset),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            .1,
            true
        )
    end

    -- //Post-initialize
    do
        screenGUI, mainUI, inputBox = UI:Load()

        if gethui then
            screenGUI.Parent = gethui()
        elseif (syn and syn.protect_gui) then
            syn.protect_gui(screenGUI)

            screenGUI.Parent = coreGui
        elseif get_hidden_gui then
            screenGUI.Parent = get_hidden_gui()
        end

        PARENT = screenGUI.Parent -- //Needs to be global because of third party scripts using this if its foudn.

        UI.TextChanged()

        inputHandler:ConnectBind({config.Data.UIKeybind}, UI.KeybindTriggered)
    end
end

local function initializeEventBinds()
    do
        logs:Log("Initializing EventBinds...", 3)

        eventBinds = {}

        loadLog(eventBinds, true)
    end

    local rejoinDebounce = {}
    local internalBinds = {
        CharacterAdded = {},
        CharacterRemoving = {},
        OnSpawn = {},
        OnReset = {},
        PlayerAdded = {
            function(player)
                local currTime = get:DateTime("LT")

                if rejoinDebounce[player.Name] then
                    rejoinDebounce[player.Name] = nil

                    chatLog:InternalLog(string.format("%s Player: %s | %s rejoined.", currTime, player.Name, player.DisplayName))
                else
                    if player.FollowUserId ~= 0 then
                        local followedPlayer = players:GetPlayerByUserId(player.FollowUserId)

                        if followedPlayer == localPlayer then
                            chatLog:InternalLog(
                                string.format(
                                    "%s Player: %s | %s joined from your profile.",
                                    currTime,
                                    player.Name,
                                    player.DisplayName
                                )
                            )
                        elseif followedPlayer then
                            chatLog:InternalLog(
                                string.format(
                                    "%s Player: %s | %s joined from player: %s | %s.",
                                    currTime,
                                    player.Name,
                                    player.DisplayName,
                                    followedPlayer.Name,
                                    followedPlayer.DisplayName
                                )
                            )
                        end
                    else
                        chatLog:InternalLog(
                            string.format(
                                "%s Player: %s | %s joined.",
                                currTime,
                                player.Name,
                                player.DisplayName
                            )
                        )
                    end
                end
            end
        },
        PlayerRemoving = {
            function(player)
                rejoinDebounce[player.Name] = true

                task.wait(5) -- // Prolly better way of doing something like this tbh... WELL DUH this is shit

                if rejoinDebounce[player.Name] then
                    rejoinDebounce[player.Name] = nil

                    local currTime = get:DateTime("LT")

                    chatLog:InternalLog(string.format("%s Player: %s | %s left.", currTime, player.Name, player.DisplayName))
                end
            end
        },
        OnJoin = {},
        OnLeave = {
            function()
                logs:Log("You are leaving. Time/Date: " .. get:DateTime("LT L"))
            end
        }
    }
    -- //Don't need to add already connected players before loading the admin, because, no point.

    function eventBinds:GetEventBinds(event) -- //Returns table[event] in EventBinds
        return config.Data.EventBinds[event]
    end

    function eventBinds:GetInternalBinds(event) -- //Returns internalBinds[event].
        return internalBinds[event]
    end

    function eventBinds:ProcessBind(event, player) -- //Processes internalBinds and EventBinds.
        local commands = eventBinds:GetEventBinds(event)
        local internalEvents = eventBinds:GetInternalBinds(event)

        for index = 1, #internalEvents do
            internalEvents[index](player)
        end

        for index = 1, #commands do
            parseCommands(commands[index])
        end
    end

    -- //Not gonna name alldis, self explanatory, fuck this.
    function eventBinds.CharacterAdded(character)
        eventBinds:ProcessBind("CharacterAdded", character)
    end

    function eventBinds.CharacterRemoving(character)
        eventBinds:ProcessBind("CharacterRemoving", character)
    end

    function eventBinds.OnSpawn(character)
        eventBinds:ProcessBind("OnSpawn", character)
    end

    function eventBinds.OnReset(character)
        eventBinds:ProcessBind("OnReset", character)
    end

    function eventBinds.PlayerAdded(player)
        eventBinds:ProcessBind("PlayerAdded", player)

        player.CharacterAdded:Connect(eventBinds.CharacterAdded)
        player.CharacterAdded:Connect(eventBinds.CharacterRemoving)
    end

    function eventBinds.OnJoin(player) -- //LocalPlayer Connection
        eventBinds:ProcessBind("OnJoin", player)

        player.CharacterAdded:Connect(eventBinds.OnSpawn)
        player.CharacterAdded:Connect(eventBinds.OnReset)
    end

    function eventBinds.PlayerRemoving(player)
        if player == localPlayer then
            eventBinds:ProcessBind("OnLeave", player)
        else
            eventBinds:ProcessBind("PlayerRemoving", player)
        end
    end

    -- //Post-initializition.
    do
        table.freeze(logs)

        logs:Log("EventBinds initialized.", 3)

        eventBinds.OnJoin(localPlayer)
    end
end

-- //Default Commands!!!!!!!!!!!!!!!!!!!!!!

local function initializeConnections()
    do
        rbxConnections = {
            Events = {},
            Keybinds = {},
            ChatLogs = {},
            Chatted = {},
            Gui = {}
        }
    end

    function rbxConnections:Add(index, func) -- //Adds connection into rbxConnections category.
        local tabl = rbxConnections[index]

        if tabl then
            table.insert(tabl, func)
        end
    end

    function rbxConnections:Disconnect(index) -- //Maybe future use? If I wanna make it reloadable.
        local tabl = rbxConnections[index]

        if tabl then
            for i=1, #tabl do
                tabl[i]:Disconnect()

                tabl[i] = nil
            end
        end
    end

    -- //Post-initialization
    do
        --UI.TextChanged()
        rbxConnections:Add("Events", players.PlayerAdded:Connect(eventBinds.PlayerAdded))
        rbxConnections:Add("Events", players.PlayerRemoving:Connect(eventBinds.PlayerRemoving))
        rbxConnections:Add("Keybinds", userInputService["InputBegan"]:Connect(inputHandler.InputChanged))
        rbxConnections:Add("Keybinds", userInputService["InputEnded"]:Connect(inputHandler.InputChanged))
        rbxConnections:Add("Chatted", localPlayer.Chatted:Connect(playerChatted))
        rbxConnections:Add("Gui", UI:GetInputBox().FocusLost:Connect(UI.FocusLost))
        rbxConnections:Add("Gui", UI:GetInputBox():GetPropertyChangedSignal("Text"):Connect(UI.TextChanged))
        rbxConnections:Add("Gui", UI:GetInputBox():GetPropertyChangedSignal("PlaceholderText"):Connect(UI.TextChanged))

        rbxConnections:Add("ChatLogs", players.PlayerChatted:Connect(chatLog.OnPlayerChatted))
        if chatLog.MessageDoneFiltering then
            rbxConnections:Add("ChatLogs", chatLog.MessageDoneFiltering.OnClientEvent:Connect(chatLog.OnMessageDoneFiltering))
        end
    end
end

local function initializeDefaultCommand()
    do
        logs:Log("Initializing default commands...", 3)
    end

    addCommands(
        "teleportation commands.",
        {
            {"tjid", "tpjobid", "tpjid"},
            "Teleports you to job id",
            function(jobId)
                if not sanityCheck(jobId, "string") then
                    return
                end

                local match1 = string.match(jobId, '[%d]+')
                local match2 = string.gsub(string.match(jobId, '["]+[%a%d-]+'), '"', '')
            end
        },{
            {"goto", "to", "tp", "teleport"},
            "Teleports you to player.",
            function(target)
                if not sanityCheck(target, "string") then
                    return
                end

                local root, targetRoot = get:LRoot(), get:Root(target)

                if root and targetRoot then
                    root.CFrame = targetRoot.CFrame * CFrame.new(0,0,2)
                end
            end
        },{
            {"rj", "rejoin"},
            "Rejoins you.",
            function()
                local player = get:LPlayer()

                if #players:GetChildren() <= 1 then
                    player:Kick("Empty server, Server might kick you...")

                    task.wait()

                    teleportService:Teleport(game.PlaceId. player)
                else
                    teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
                end
            end
        },{
            {"shop", "servehop"},
            "Teleports you to different server.",
            function()
                local player = get:LPlayer()

                local jsonServerList = httpRequest({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"})
                local success, serverList = pcall(httpService.JSONDecode, httpService, jsonServerList.Body)
                local serverListData = success and serverList.data

                if not serverListData then
                    logs:Log("No availible servers found. #1")

                    return
                end

                local availableServers = {}

                for _, v in pairs(serverListData) do
                    if typeof(v) ~= "table" or not (tonumber(v.playing) and tonumber(v.maxPlayers)) then
                        continue
                    end

                    if v.playing < v.maxPlayers and game.JobId ~= v.id then
                        table.insert(availableServers, v.id)
                    end
                end

                if #availableServers > 0 then
                    teleportService:TeleportToPlaceInstance(game.PlaceId, availableServers[math.random(1, #availableServers)], player)
                else
                    logs:Log("No availible servers found. #2")
                end
            end
        }
    )

    addCommands( -- //Character functions
        "camera commands.",
        {
            {"camdistance", "camdist"},
            "Change camera's max zoomout.",
            function(maxDist)
                local player = get:LPlayer()

                if not commandsValues.camDefDist then
                    commandsValues.camDefDist = player.CameraMaxZoomDistance
                end

                player.CameraMaxZoomDistance = tonumber(maxDist) or player.CameraMaxZoomDistance
            end
        },{
            {"infcamera", "infcam", "infcamerazoom"},
            "Change camera's max zoomout.",
            function()
                local player = get:LPlayer()

                if not commandsValues.camDefDist then
                    commandsValues.camDefDist = player.CameraMaxZoomDistance
                end

                player.CameraMaxZoomDistance = 9e99
            end
        },{
            {"defcamdistance", "defcamdist"},
            "Changes max zoomout to default.",
            function()
                local player = get:LPlayer()

                if commandsValues.camDefDist then
                    commandsValues.camDefDist = player.CameraMaxZoomDistance
                end
            end
        },{
            {"noclipcam", "nclipcam"},
            "Makes camera clip through object.",
            function()
                local setConst = (debug and debug.setconstant) or setconstant
                local getConst = (debug and debug.getconstants) or getconstants

                local playerModule = get:LPlayer():WaitForChild("PlayerModule")
                local popperScript = playerModule:WaitForChild("CameraModule"):WaitForChild("ZoomController"):WaitForChild("Popper")

                for _, popperScriptGC in pairs(getgc()) do
                    if type(popperScriptGC) == "function" and getfenv(popperScriptGC).script == popperScript then
                    else
                        continue
                    end

                    for index, constant in pairs(getConst(popperScriptGC)) do
                        local numValue = tonumber(constant)

                        if numValue == .25 then
                            setConst(constant, index, 0)
                        elseif numValue == 0 then
                            setConst(constant, index, .25)
                        end
                    end
                end
            end
        },{
            {"freecam", "fc"},
            "Enables freecam",
            function()
                local cam = workspace.CurrentCamera

                if commandsValues.Freecam then
                    runService:UnbindFromRenderStep("Freecam")

                    contextActionService:UnbindAction("FreecamKeyboard")
                    contextActionService:UnbindAction("FreecamMousePan")

                    cam.CameraType = commandsValues.Freecam

                    commandsValues.Freecam = nil

                    return
                end

                local enumCASPriority = Enum.ContextActionPriority.High.Value
                local enumRSPriority = Enum.RenderPriority.Camera.Value

                local keyboardNavSpeed = Vector3.one

                local panMouseSpeed = Vector2.one * (math.pi/64)
                local mouseDelta = Vector2.zero

                local adjustNavSpeed = 0.75
                local shiftNavMul = 0.25

                local inputKeys = {
                    W = 0,
                    A = 0,
                    S = 0,
                    D = 0,
                    E = 0,
                    Q = 0,
                    Up = 0,
                    Down = 0
                }

                local navSpeed = 1

                local spring = {} do
                    spring.__index = spring

                    function spring:New(freq, pos)
                        local self = setmetatable({}, spring)
                        self.frequency = freq
                        self.pos = pos
                        self.posZero = pos * 0

                        return self
                    end

                    function spring:Update(deltaTime, goal)
                        local freq = self.frequency * (2 * math.pi)
                        local pos = self.pos
                        local posZero = self.posZero

                        local offset = goal - pos
                        local decay = math.exp(-freq * deltaTime)

                        local newPos = goal + (posZero * deltaTime - offset*(freq*deltaTime + 1)) * decay
                        local newPosZero = ((freq * deltaTime) * (offset * freq - posZero) + posZero) * decay

                        self.pos = newPos
                        self.posZero = newPosZero

                        return newPos
                    end

                    function spring:Reset(pos)
                        self.pos = pos
                        self.posZero = pos*0
                    end
                end

                local cameraPos = Vector3.zero
                local cameraRot = Vector2.zero

                local velSpring = spring:New(5, Vector3.zero)
                local panSpring = spring:New(5, Vector2.zero)

                local function getVelocity(deltaTime)
                    navSpeed = math.clamp(navSpeed + deltaTime * (inputKeys.Up - inputKeys.Down)* adjustNavSpeed, 0.01, 4)

                    local moveDirection = Vector3.new(
                        inputKeys.D - inputKeys.A,
                        inputKeys.E - inputKeys.Q,
                        inputKeys.S - inputKeys.W
                    ) * keyboardNavSpeed

                    local isShiftDown = userInputService:IsKeyDown(Enum.KeyCode.LeftShift)

                    return moveDirection * (navSpeed * (isShiftDown and shiftNavMul or 1))
                end

                local function calcPan()
                    local kMouse = mouseDelta * panMouseSpeed

                    mouseDelta = Vector2.zero

                    return kMouse
                end

                local function keypress(_, state, inputObject)
                    inputKeys[inputObject.KeyCode.Name] = (state == Enum.UserInputState.Begin and 1 or 0)

                    return Enum.ContextActionResult.Sink
                end

                local function mousePan(_, _, inputObject)
                    local delta = inputObject.Delta

                    mouseDelta = Vector2.new(-delta.Y, -delta.X)

                    return Enum.ContextActionResult.Sink
                end

                local function getFoucesDistance(cameraFrame, cameraFov, viewPort)
                    local projy = 2 * math.tan(cameraFov / 2)
                    local projx = viewPort.X / viewPort.Y * projy

                    local rightVec = cameraFrame.RightVector
                    local upVec = cameraFrame.UpVector
                    local lookVec = cameraFrame.LookVector

                    local minVect = Vector3.zero
                    local minDist = 512

                    for x = 0, 1, 0.5 do
                        for y = 0, 1, 0.5 do
                            local cx = (x - 0.5) * projx
                            local cy = (y - 0.5) * projy
                            local offset = (rightVec * cx) - (upVec * cy) + lookVec
                            local origin = cameraFrame.Position + offset * 0.1

                            local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.Unit * minDist))
                            local dist = (hit - origin).Magnitude

                            if minDist > dist then
                                minDist = dist
                                minVect = offset.Unit
                            end
                        end
                    end

                    return lookVec:Dot(minVect) * minDist
                end

                local function stepFreecam(deltaTime)
                    local cameraFov = cam.FieldOfView

                    local vel = velSpring:Update(deltaTime, getVelocity(deltaTime))
                    local pan = panSpring:Update(deltaTime, calcPan(deltaTime))

                    local zoomFactor = math.sqrt(math.tan(math.rad(35)) / math.tan(math.rad(cameraFov / 2)))

                    cameraRot = cameraRot + pan * Vector2.new(0.75, 1) * 8 * (deltaTime / zoomFactor)
                    cameraRot = Vector2.new(math.clamp(cameraRot.X, -math.rad(90), math.rad(90)), cameraRot.Y % (2 * math.pi))

                    local cameraCFrame = CFrame.new(cameraPos) *
                        CFrame.fromOrientation(cameraRot.X, cameraRot.Y, 0) * CFrame.new((vel * Vector3.one * 64) * deltaTime)
                    cameraPos = cameraCFrame.Position

                    cam.CFrame = cameraCFrame
                    cam.Focus = cameraCFrame * CFrame.new(0, 0, -getFoucesDistance(cameraCFrame, cameraFov, cam.ViewportSize))
                    cam.FieldOfView = cam.FieldOfView
                end

                local function bindCAS()
                    contextActionService:BindActionAtPriority("FreecamKeyboard", keypress, false, enumCASPriority,
                        Enum.KeyCode.W,
                        Enum.KeyCode.A,
                        Enum.KeyCode.S,
                        Enum.KeyCode.D,
                        Enum.KeyCode.E,
                        Enum.KeyCode.Q,
                        Enum.KeyCode.Up,
                        Enum.KeyCode.Down
                    )
                    contextActionService:BindActionAtPriority("FreecamMousePan", mousePan, false, enumCASPriority, Enum.UserInputType.MouseMovement)
                end

                local camCFrame = cam.CFrame
                cameraPos = camCFrame.Position

                commandsValues.Freecam = cam.CameraType

                runService:BindToRenderStep("Freecam", enumRSPriority, stepFreecam)
                cam.CameraType = Enum.CameraType.Custom

                bindCAS()
            end
        },{
            {"spectate", "view"},
            "View Someones pov: ",
            function(target)
                target = get:Player(target)

                local cam = workspace.CurrentCamera

                local function disableSpectateValues()
                    commandsValues.spectate[1]:Disconnect()
                    commandsValues.spectate[2]:Disconnect()
                    commandsValues.spectate[3]:Disconnect()
                    commandsValues.spectate = nil
                end

                local function setDefaultCam()
                    local character = get:LCharacter()

                    if not character then
                        get:LPlayer().CharacterAdded:Wait()

                        task.wait(.05)
                    end

                    local hum = get:LHumanoid()

                    cam.CameraSubject = hum
                end

                if commandsValues.spectate then
                    disableSpectateValues()

                    if not target then
                        setDefaultCam()

                        return
                    end
                end

                local targChar = get:Character(target)
                local targHum = get:Humanoid(targChar)

                if not targChar or not targHum then
                    return
                end

                local function onLeave(playerLeaving)
                    if playerLeaving == target then
                        disableSpectateValues()

                        setDefaultCam()
                    end
                end

                local function onDied()
                    if not target then
                        disableSpectateValues()

                        setDefaultCam()
                    end

                    target.CharacterAdded:Wait()

                    task.wait(.05)

                    targChar = get:Character(target)
                    targHum = get:Humanoid(targChar)

                    cam.CameraSubject = targHum
                end

                local function onChanged()
                    if not targChar then
                        return
                    end

                    cam.CameraSubject = targChar
                end

                commandsValues.spectate = {
                    cam:GetPropertyChangedSignal("CameraSubject"):Connect(onChanged),
                    players.PlayerRemoving:Connect(onLeave),
                    target.CharacterRemoving:Connect(onDied)
                }

                cam.CameraSubject = targHum
            end
        },{
            {"unspectate", "unview"},
            "Unviews",
            function()
                local cam = workspace.CurrentCamera

                local function setDefaultCam()
                    local character = get:LCharacter()

                    if not character then
                        get:LPlayer().CharacterAdded:Wait()

                        task.wait(.05)
                    end

                    local hum = get:LHumanoid()

                    cam.CameraSubject = hum
                end

                if commandsValues.spectate then
                    commandsValues.spectate[1]:Disconnect()
                    commandsValues.spectate[2]:Disconnect()
                    commandsValues.spectate[3]:Disconnect()
                    commandsValues.spectate = nil

                    setDefaultCam()
                end
            end
        }
    )

    addCommands(
        "player commands",
        {
            {"enableshiftlock", "esl"},
            "Enables shift-lock",
            function()
                local player = get:LPlayer()

                player.DevEnableMouseLock = true
            end
        }
    )

    addCommands(
        "game settings commands",
        {
            {"vol", "volume"},
            "Set volume of your game.",
            function(volume)
                local userGameSettings = UserSettings():GetService("UserGameSettings")
                volume = tonumber(volume) or 5

                userGameSettings.MasterVolume = math.clamp(volume, 0, 10) / 10
            end
        }
    )

    addCommands(
        "character commands.",
        {
            {"ws", "walkspeed"},
            "Changes your walkspeed.",
            function(number)
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                if not commandsValues.DefWalksSpeed then
                    commandsValues.DefWalksSpeed = hum.WalkSpeed
                end

                hum.WalkSpeed = tonumber(number) or commandsValues.DefWalksSpeed
            end
        },{
            {"hh", "hipheight"},
            "Changes your hipheight.",
            function(number)
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                if not commandsValues.DefHipHeight then
                    commandsValues.DefHipHeight = hum.HipHeight
                end

                hum.HipHeight = tonumber(number) or commandsValues.DefHipHeight
            end
        },{
            {"jp", "jumppower"},
            "Changes your jumpheight.",
            function(number)
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                if not commandsValues.JumpPower then
                    commandsValues.JumpPower = hum.JumpPower
                end

                hum.JumpPower = tonumber(number) or commandsValues.JumpPower
            end
        },{
            {"sit"},
            "Makes you sit.",
            function()
                local hum = get:LHumanoid()

                if hum then
                    hum.Sit = true
                end
            end
        },{
            {"nosit", "nsit"},
            "Makes you NOT sit",
            function()
                local hum = get:LHumanoid()

                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    hum.Sit = false
                end
            end
        },{
            {"noclip", "nclip"},
            "Makes you not collide.",
            function()
                if commandsValues.noclip then
                    commandsValues.noclip:Disconnect()
                    commandsValues.noclip = nil

                    return
                end

                local character = get:LCharacter()

                commandsValues.noclip = runService["PreSimulation"]:Connect(function()
                    if not character or character.Parent == nil then
                        character = get:LCharacter()

                        return
                    end

                    for _, inst in pairs(character:GetChildren()) do
                        if inst:IsA("BasePart") then
                            inst.CanCollide = false
                        end
                    end
                end)
            end
        },{
            {"unnoclip", "nnclip"},
            "Makes you not collide.",
            function()
                if commandsValues.noclip then
                    commandsValues.noclip:Disconnect()
                    commandsValues.noclip = nil

                    return
                end
            end
        },{
            {"antifling", "afling"},
            "Makes you unflingable",
            function()
                local character = get:LCharacter()

                if not character then
                    return
                end

                for _, inst in pairs(character:GetChildren()) do
                    if inst:IsA("BasePart") then
                        inst.CustomPhysicalProperties = PhysicalProperties.new(9e99, 0.3, 0.5)
                    end
                end
            end
        },{
            {"clicktp", "tpclick"},
            "Teleports you where your mouse is pointing.",
            function()
                local mouse = get:Mouse()

                local hum = get:LHumanoid()
                local root = get:LRoot()

                if not hum or not root then
                    return
                end

                if hum.Sit then
                    hum.Sit = false
                end

                if mouse.Target then
                    root.CFrame = mouse.Hit + (Vector3.yAxis * 5)
                end
            end
        },{
            {"invisfling"},
            "Uses root to fling players!",
            function(speed)
                speed = tonumber(speed) or 50

                local cam = workspace.CurrentCamera

                local player = get:LPlayer()
                local character = get:LCharacter()
                local hum = get:LHumanoid()
                local root = get:LRoot()

                if commandsValues.InvisFling then
                    commandsValues.InvisFling[1]:Disconnect()
                    commandsValues.InvisFling[2]:Disconnect()

                    commandsValues.InvisFling = nil

                    return
                end

                if not character or not hum or not root or root.Name ~= "HumanoidRootPart" then
                    return
                end

                local cframePos = root.CFrame -- //Its here so the movment starts at respawn position.

                local function setVelocity()
                    root:ApplyImpulse(Vector3.new(1, 1, 0) * 10000)
                    root.AssemblyLinearVelocity = Vector3.new(1, 1, 0) * 10000

                    root.RotVelocity = Vector3.one * 10000
                end

                local function processVelocity()
                    root.CustomPhysicalProperties = PhysicalProperties.new(100 ,0 ,0 ,0 ,0)

                    commandsValues.InvisFling[1] = runService["Heartbeat"]:Connect(setVelocity)
                end

                local function initializeMovement()
                    local keyDirections = {
                        [Enum.KeyCode.W] = -Vector3.zAxis,
                        [Enum.KeyCode.A] = -Vector3.xAxis,
                        [Enum.KeyCode.S] =  Vector3.zAxis,
                        [Enum.KeyCode.D] =  Vector3.xAxis,
                        [Enum.KeyCode.Q] = -Vector3.yAxis,
                        [Enum.KeyCode.E] =  Vector3.yAxis,
                    }

                    local function getDirection()
                        local direction = Vector3.zero

                        for key, directionValue in pairs(keyDirections) do
                            if userInputService:IsKeyDown(key) then
                                direction += directionValue
                            end
                        end

                        return direction.Magnitude == 0 and Vector3.zero or direction.Unit
                    end

                    local function updateCFrame(deltaTime)
                        local direction = CFrame.new((getDirection() * deltaTime) * commandsValues.InvisFling[3])

                        cframePos = (cam.CFrame.Rotation + cframePos.Position) * direction
                    end

                    local function main(deltaTime)
                        if not root or not character then
                            root = get:LRoot()

                            if not root then
                                commandsValues.Fly:Disconnect()
                                commandsValues.Fly = nil

                                return
                            end
                        end

                        updateCFrame(deltaTime)

                        root.Position = cframePos.Position
                    end

                    commandsValues.InvisFling[2] = runService["Heartbeat"]:Connect(main)
                end

                local function processCharacter()
                    player.Character = nil

                    for _, inst in pairs(character:GetDescendants()) do
                        if inst ~= root then
                            inst:Destroy()
                        end
                    end

                    task.wait(players.RespawnTime + .3)

                    player.Character = character

                    processVelocity()

                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(62, 16, 85)
                    highlight.OutlineColor = Color3.fromRGB(18, 0, 27)
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Adornee = root
                    highlight.Parent = root

                    root.Transparency = 0
                end

                local function initialize()
                    local oldCF = root.CFrame
                    root.CFrame *= CFrame.new(0, 100, 0)

                    task.wait(.3)
                    root.Anchored = true

                    commandsValues.InvisFling = {}

                    processCharacter()
                    processVelocity()
                    initializeMovement()

                    cam.CameraSubject = root

                    commandsValues.InvisFling[3] = speed

                    root.Anchored = false
                    root.CFrame = oldCF
                end

                initialize()
            end
        },{
            {"fly"},
            "Makes you fly!",
            function(speed)
                speed = tonumber(speed) or 50

                if commandsValues.Fly then
                    commandsValues.Fly[1]:Disconnect()
                    commandsValues.Fly[2]:Disconnect()

                    commandsValues.Fly = nil

                    return
                end

                local cam = workspace.CurrentCamera

                local character = get:LCharacter()
                local root = get:LRoot()

                if not character or not root then
                    return
                end

                local keyDirections = {
                    [Enum.KeyCode.W] = -Vector3.zAxis,
                    [Enum.KeyCode.A] = -Vector3.xAxis,
                    [Enum.KeyCode.S] =  Vector3.zAxis,
                    [Enum.KeyCode.D] =  Vector3.xAxis,
                    [Enum.KeyCode.Q] = -Vector3.yAxis,
                    [Enum.KeyCode.E] =  Vector3.yAxis,
                }

                local function getDirection()
                    local direction = Vector3.zero

                    if userInputService:GetFocusedTextBox() then
                        return direction
                    end

                    for key, directionValue in pairs(keyDirections) do
                        if userInputService:IsKeyDown(key) then
                            direction += directionValue
                        end
                    end

                    return direction.Magnitude == 0 and Vector3.zero or direction.Unit
                end

                local function updateCFrame(deltaTime)
                    local direction = CFrame.new((getDirection() * deltaTime) * commandsValues.Fly[4])

                    commandsValues.Fly[3] = (cam.CFrame.Rotation + commandsValues.Fly[3].Position) * direction
                end

                local function setVelocity()
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                        end
                    end
                end

                local function main(deltaTime)
                    if not root or not character or character.Parent == nil then
                        commandsValues.Fly[1]:Disconnect()
                        commandsValues.Fly[2]:Disconnect()

                        commandsValues.Fly = nil

                        return
                    end

                    setVelocity()
                    updateCFrame(deltaTime)

                    root.CFrame = commandsValues.Fly[3]
                end

                local function onCFrameChanged()
                    commandsValues.Fly[3] = (cam.CFrame.Rotation + root.CFrame.Position)
                    -- //Shitty, but hacky way to apply any CFrames being set by scripts (goto, clicktp)
                end

                commandsValues.Fly = {
                    runService["Heartbeat"]:Connect(main),
                    root:GetPropertyChangedSignal("CFrame"):Connect(onCFrameChanged),
                    root.CFrame,
                    speed,
                }
            end
        },{
            {"flyspeed", "fspeed"},
            "Changes fly speed.",
            function(speed)
                speed = tonumber(speed)

                if speed then
                    commandsValues.Fly[4] = speed
                end
            end
        },{
            {"unfly", "ufly"},
            "Makes you stop flying.",
            function(speed)
                if commandsValues.Fly then
                    commandsValues.Fly[1]:Disconnect()
                    commandsValues.Fly[2]:Disconnect()

                    commandsValues.Fly = nil
                end
            end
        },{
            {"re", "reset"},
            "Resets your avatar.",
            function()
                local player = get:LPlayer()
                local character = get:LCharacter()
                local root = get:LRoot()

                local preCFrame do
                    if root then
                        preCFrame = root.CFrame
                    elseif not character then
                        return
                    else
                        local part = character:FindFirstChildWhichIsA("BasePart")

                        if part then
                            preCFrame = part.CFrame
                        end
                    end
                end

                character:BreakJoints()

                player.CharacterAdded:Wait()

                task.wait(.1)

                get:LRoot().CFrame = preCFrame
            end
        },{
            {"noroot"},
            "Removes root.",
            function()
                local character = get:LCharacter()

                if character then
                    local root = character:FindFirstChild("Root")

                    if root then
                        root:Destroy()
                    end
                end
            end
        }
    )

    addCommands( -- //Tool stuff
        "tool commands.",
        {
            {"looptoolgrab", "ltgrab"},
            "Grabs all tools dropped.",
            function()
                if commandsValues.toolGrab then
                    commandsValues.toolGrab:Disconnect()
                    commandsValues.toolGrab = nil

                    logs:Log("Disconnected")

                    return
                end

                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                commandsValues.toolGrab = workspace.ChildAdded:Connect(function(inst)
                    if inst:IsA("Tool") then
                        if not hum then
                            hum = get:LHumanoid()

                            if not hum then
                                commandsValues.toolGrab:Disconnect()

                                commandsValues.toolGrab = nil
                            end
                        end

                        hum:EquipTool(inst)

                        task.wait(.8)
                    end
                end)

                for _,inst in pairs(workspace:GetChildren()) do
                    if inst:IsA("Tool") then
                        hum:EquipTool(inst)
                    end
                end
            end
        },{
            {"unlooptoolgrab", "nltgrab"},
            "Grabs all tools dropped.",
            function()
                if commandsValues.toolGrab then
                    commandsValues.toolGrab:Disconnect()
                    commandsValues.toolGrab = nil

                    logs:Log("Disconnected")

                    return
                end
            end
        },{
            {"toolgrab", "tgrab"},
            "Grabs all tools dropped.",
            function()
                local hum = get:LHumanoid()

                if hum then
                    for _,inst in pairs(workspace:GetChildren()) do
                        if inst:IsA("Tool") then
                            hum:EquipTool(inst)
                        end
                    end
                end
            end
        },{
            {"toolspam", "spamtools"},
            "Spams all tools",
            function(delay)
                if commandsValues.ToolSpam then
                    commandsValues.ToolSpam = false

                    return
                end

                local character = get:LCharacter()
                local hum = get:LHumanoid()

                local backPack = get:LPlayer().Backpack

                local tools = {}

                if not character or not hum then
                    return
                end

                for _, tool in pairs(backPack:GetChildren()) do
                    table.insert(tools, tool)

                    tool.Parent = character
                end

                commandsValues.ToolSpam = true

                while hum.Health >= 1 and commandsArray.ToolSpam and task.wait(tonumber(delay) or .1) do
                    for i=1, #tools do
                        local tool = tools[i]

                       if tool.Parent ~= character then
                            tool.Parent = character

                            task.wait()
                       end

                       tool:Activate()
                    end
                end
            end
        },{
            {"anticlaim", "aclaim"},
            "Makes you unclaimable by tools.",
            function()
                local hum = get:Humanoid()

                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    hum.Sit = true
                end
            end
        },{
            {"toolfling", "tfling"},
            "Uses tools for flinging.",
            function()
                if commandsValues.toolfling then
                    commandsValues.toolfling[1]:Disconnect()
                    commandsValues.toolfling[2]:Disconnect()

                    commandsValues.toolfling = nil
                end

                local LPlayer = get:LPlayer()

                local backpack = LPlayer.Backpack
                local mouse = get:Mouse()

                local character = get:LCharacter()
                local hum = get:LHumanoid()

                local sine = 0
                local target = LPlayer

                local tools = {}

                local function onMouseButton1Down()
                    if not mouse.Target then
                        return
                    end

                    local isModel = mouse.Target:FindFirstAncestorOfClass("Model")

                    if not isModel or isModel.Name == "Workspace" then
                        return
                    end

                    if isModel and players:FindFirstChild(isModel.Name) then
                        target = isModel

                        task.wait(1)

                        if target == isModel then
                            target = LPlayer
                        end
                    end
                end

                local function applyVelocity()
                    for _, tool in pairs(tools) do
                        tool.AssemblyLinearVelocity = Vector3.new(0, 0, 50)
                        tool.RotVelocity = Vector3.new(10000,10000,10000)
                    end
                end

                for _, tool in pairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = character
                    end
                end

                for _, tool in pairs(character:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = backpack
                        task.wait()
                        tool.Parent = character

                        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")

                        if handle then
                            handle.CustomPhysicalProperties = PhysicalProperties.new(math.huge, math.huge, 0, 0, math.huge)

                            table.insert(tools, handle)
                        end
                    end
                end

                if hum.RigType == Enum.HumanoidRigType.R15 then
                    character["RightHand"]:Destroy()
                else
                    character["Right Arm"]:Destroy()
                end

                commandsValues.toolfling = {
                    runService["Heartbeat"]:Connect(applyVelocity),
                    mouse.Button1Down:Connect(onMouseButton1Down)
                }

                while get:LRoot() and hum and hum.Health >= 1 and task.wait() do
                    sine += 1

                    local targetRoot = get:Root(target)
                    local targetHum = get:Humanoid(target)

                    if target.Name == character.Name then
                        for i, tool in pairs(tools) do
                            if not tool then
                                return
                            end

                            local circlePosition = math.rad(sine + ( i * (360 / #tools)))

                            tool.CFrame = CFrame.new(
                                (CFrame.new(targetRoot.Position) * CFrame.Angles(0, circlePosition, 0) * CFrame.new(0, 0, 8+1 * math.cos(sine/30))).Position
                            ) * CFrame.Angles(sine/20, sine/20, 0)
                        end
                    else
                        for _, tool in pairs(tools) do
                            if not targetRoot or not targetHum or not tool then
                                return
                            end

                            local predictionCFrame = redPing:CalculatePredictionSineWave(targetHum.MoveDirection, targetRoot.AssemblyLinearVelocity):Inverse()
                            tool.CFrame = predictionCFrame:ToObjectSpace(targetRoot.CFrame) * CFrame.Angles(sine/20, sine/20, 0)
                        end
                    end
                end

                commandsValues.toolfling[1]:Disconnect()
                commandsValues.toolfling[2]:Disconnect()

                commandsValues.toolfling = nil
            end
        },{
            {"equiptools", "eqtools"},
            "Equips all tools",
            function()
                local character = get:LCharacter()

                local backPack = get:LPlayer().Backpack

                if not character then
                    return
                end

                for _, tool in pairs(backPack:GetChildren()) do
                    tool.Parent = character
                end
            end
        }
    )

    if not _safeMode then
        addCommands( -- //Third party scripts
            "third-party commands.",
            {
                {"dex", "explorer"},
                "Opens dex explorer, exploiting version of roblox service browser.",
                function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
                end
            },{
                {"rspy", "remotespy"},
                "Opens Hydroxide remote spy.",
                function()
                    local function webImport(file)
                        return loadstring(game:HttpGetAsync(string.format("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/%s.lua", file), file ..".lua"))()
                    end

                    webImport("init")
                    webImport("ui/main")
                end
            },{
                {"unnamedesp", "nnesp"},
                "Opens Unnamed ESP.",
                function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua"))()
                end
            }
        )
    end

    addCommands(
        "trolling commands.",
        {
            {"lookat", "stareat"},
            "Stares at target...",
            function(target)
                target = get:Player(target)

                if commandsValues.Staring then
                    commandsValues.Staring = nil

                    task.wait()

                    if not target then
                        return
                    end
                end

                local root = get:LRoot()
                local hum = get:LHumanoid()

                target = get:Root(target)

                if not target or not root or not hum then
                    return
                end

                commandsValues.Staring = true

                coroutine.wrap(function()
                    while hum.Health >= 1 and commandsValues.Staring and target and task.wait() do -- //TODO FOR FUNNY TROLOLOLO
                        root.CFrame = CFrame.lookAt(root.Position, target.Position * Vector3.new(1,0,1) + (Vector3.yAxis * root.Position.Y))
                    end

                    commandsValues.Staring = nil
                end)()
            end
        },{
            {"orbit", "spinaround"},
            "Orbits around target",
            function(target, speed, distance)
                distance = tonumber(distance) or 5
                speed = (tonumber(speed) or 1) / 100

                target = get:Player(target)

                if commandsValues.Orbit then
                    commandsValues.Orbit = nil

                    task.wait(.2)

                    if not target then
                        return
                    end
                end

                local root = get:LRoot()
                local hum = get:LHumanoid()

                local targHum = get:Humanoid(target)

                if not target or not root or not hum or not targHum then
                    return
                end

                commandsValues.Orbit = true

                coroutine.wrap(function()
                    local sine = 0

                    local targRoot = get:Root(target)

                    while hum.Health >= 1 and commandsValues.Orbit and target and targHum.Health >= 1 do
                        sine += speed

                        root.CFrame = CFrame.new(
                            ((CFrame.new(targRoot.Position) * CFrame.Angles(0, sine, 0)) * CFrame.new(0, 0, distance)).Position,
                            targRoot.Position
                        )

                        targRoot = get:Root(target)

                        runService["Heartbeat"]:Wait()
                    end

                    commandsValues.Staring = nil
                end)()
            end
        },{
            {"unorbit", "noorbit"},
            "Disables orbiting.",
            function(target, speed, distance)
                if commandsValues.Orbit then
                    commandsValues.Orbit = nil
                end
            end
        }
    )

    addCommands( -- //Hat functions
        "hat commands.",
        {
            {"hatresize"},
            "Resizes your hats (r15 only).",
            function(number)
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                for index = 1, tonumber(number) or 20 do
                    for _,hat in pairs(hum:GetAccessories()) do
                        local handle = hat:FindFirstChild("Handle") or hat:FindFirstChildWhichIsA("BasePart")

                        if handle then
                            local vec3Value = handle:FindFirstChildWhichIsA("Vector3Value")

                            if vec3Value then
                                vec3Value:Destroy()
                            end
                        end
                    end

                    local numValue = hum:FindFirstChildWhichIsA("NumberValue")

                    if numValue then
                        numValue:Destroy()

                        task.wait(1)
                    else
                        break
                    end
                end
            end
        },{
            {"blockhats"},
            "Makes hats blocks.",
            function()
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                for _, accessory in pairs(hum:GetAccessories()) do
                    local handle = accessory:FindFirstChild("Handle") or accessory:FindFirstChildWhichIsA("BasePart")

                    if handle then
                        local specialMesh = handle:FindFirstChildWhichIsA("SpecialMesh")

                        if specialMesh then
                            specialMesh:Destroy()
                        end
                    end
                end
            end
        },{
            {"nohats", "removehats"},
            "Removes all accessories",
            function()
                local hum = get:LHumanoid()

                if not hum then
                    return
                end

                for _, accessory in pairs(hum:GetAccessories()) do
                    accessory:Destroy()
                end
            end
        }
    )

    -- //Post-initialization
    do
        logs:Log(tostring(#commandsArray) .. " commands initialized.", 3)
    end
end

local function initialize()
    table.insert(logsQueue, {"----------LOADING ADMIN----------", 3})

    initializeFileSystem()
    initializeEnvironment()
    initializeRConsole()
    initializeLogs()
    initializeChatLogs()
    initializeRedPing()
    initializeInputHandler()
    initializeConfig()
    initializeUI()
    initializeDefaultCommand()
    initializeEventBinds()

    initializeConnections()

    logs:Log("----------ADMIN LOADED----------", 3)
end

initialize()

--[[
    I believe in making code public for the purpose of helping people with finding new coding styles, and other stuff.
    If you rip this shit without even knowing how it works you are cheating yourself.
]]
