for i = 1,3 do
if _G.OCTOHUBALREADYLOADED then
    return
end
_G.OCTOHUBALREADYLOADED = true

local _executor = identifyexecutor()
local _fileDivider = [[\]]
local _isDelta = string.find(_executor, "Delta")
if _isDelta then
    _fileDivider = "/"
end
 
if _G.Octohub then _G.Library:Notify("Hub already executed") end
_G.Octohub = {}

if not isfolder("OctoHub") then makefolder("OctoHub") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards") then makefolder("OctoHub"..[[/]].."Anime Vanguards") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro") then makefolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Config") then makefolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Config") end

local repo = "https://raw.githubusercontent.com/r1sIngisgood/octohub/main/"
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/r1sIngisgood/octohub/main/UILib/Linoria.lua"))()

--// IG SERVICES \\--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local StarterPlayer = game:GetService("StarterPlayer")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

--// GAME MODULES \\--
local ReplicatedModulesFolder = ReplicatedStorage.Modules
local StarterPlayerModulesFolder = StarterPlayer.Modules

local EntityIDHandler = require(ReplicatedModulesFolder.Data.Entities.EntityIDHandler)
local UnitsModule = require(ReplicatedModulesFolder.Data.Entities.Units)
local ClientUnitHandler = require(StarterPlayerModulesFolder.Gameplay.ClientUnitHandler)
local PlayerYenHandler = require(StarterPlayerModulesFolder.Gameplay.PlayerYenHandler)
local GameHandler = require(ReplicatedModulesFolder.Gameplay.GameHandler)
local UnitPlacementsHandler = require(StarterPlayerModulesFolder.Gameplay.UnitManager.UnitPlacementsHandler)
local StagesData = require(ReplicatedModulesFolder.Data.StagesData)

--// IG OBJECTS \\--
local NetworkingFolder = ReplicatedStorage:WaitForChild("Networking")

local SkipWaveEvent = NetworkingFolder.SkipWaveEvent
local UnitEvent = NetworkingFolder.UnitEvent
local VoteEvent = NetworkingFolder.EndScreen.VoteEvent
local ShowEndScreenEvent = NetworkingFolder.EndScreen.ShowEndScreenEvent
local GameRestartedEvent = NetworkingFolder.ClientListeners.GameRestartedEvent
local WaveInfoEvent = NetworkingFolder.WaveInfoEvent

local UnitsFolder = workspace.Units
local StagesDataFolder = ReplicatedModulesFolder.Data.StagesData
local StoryStages = StagesDataFolder.Story

local LocalPlayer = Players.LocalPlayer

--// Script Consts \\--
local lewisakura = "webhook.lewisakura.moe"
local headers = {["Content-Type"] = "application/json"}
local ScriptFilePath = "OctoHub"..[[/]].."Anime Vanguards"..[[/]]
local MacroPath = ScriptFilePath.."Macro"..[[/]]
local ConfigPath = ScriptFilePath.."Config"..[[/]]
local EmptyFunc = function() end

--// Script Runtime Values \\--
local Options = _G.Options

local Functions = {CreateMacro = EmptyFunc, DeleteMacro = EmptyFunc, ChooseMacro = EmptyFunc}
local Connections = {}
local Macros = {}
local CurrentRecordStep = 1
local CurrentRecordData = {}
local CurrentUnits = {}
local CurrentWave = 0

local CurrentMacroName = nil
local CurrentMacroData = nil
local RecordingMacro = false
local CurrentMacroStage = nil
local MacroPlaying = false

--// UTIL FUNCTIONS \\--
local function cfgbeautify(str) return string.gsub(string.gsub(str,MacroPath,""),".json","") end
local function isdotjson(file) return string.sub(file, -5) == ".json" end
local function string_to_vector3(str) return Vector3.new(table.unpack(str:gsub(" ",""):split(","))) end
local function checkJSON(str)
    local result = pcall(function()
        HttpService:JSONDecode(str)
    end)
    return result
end

Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

--// UI \\--
local Window = UILib:CreateWindow({
    Title = 'Octo Hub!!!',
    Center = true,
    AutoShow = true,
    TabPadding = 8
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Macro = Window:AddTab('Macro'),
    UISettings = Window:AddTab('UI Settings'),
    Config = Window:AddTab('Config'),
    Webhook = Window:AddTab('Webhook'),
}

local FarmSettingsBox = Tabs.Main:AddLeftGroupbox("Farm Settings")
local AutoRetryToggle = FarmSettingsBox:AddToggle("AutoRetryToggle", {Text = "Auto Retry", Default = false, Tooltip = "Auto press the retry button"})
local AutoNextStoryToggle = FarmSettingsBox:AddToggle("AutoNextStoryToggle", {Text = "Auto Next Story", Default = false, Tooltip = "Auto press the next story button"})
local AutoStartToggle = FarmSettingsBox:AddToggle("AutoStartToggle", {Text = "Auto Start Game", Default = true, Tooltip = "Auto votes for start at the start of a game"})

local UISettingsBox = Tabs.UISettings:AddLeftGroupbox("UI Settings")
local UnloadButton = UISettingsBox:AddButton("Unload", EmptyFunc)

local MacroSettingsBox = Tabs.Macro:AddLeftGroupbox('Macro Settings')
local MacroStageBox = Tabs.Macro:AddRightGroupbox('Macros')

local MacroStageDropdown = MacroStageBox:AddDropdown("StageDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Map", Tooltip = "Choose a map to manage macros for it"})
local MacroStageStoryDropdown = MacroStageBox:AddDropdown("MacroStageStoryDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Story"})
local MacroStageInfDropdown = MacroStageBox:AddDropdown("MacroStageInfDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Infinite"})
local MacroStageParagonDropdown = MacroStageBox:AddDropdown("MacroStageParagonDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Paragon"})
local MacroStageLegendDropdown = MacroStageBox:AddDropdown("MacroStageLegendDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Legend"})

local CurrentMacroDropdown = MacroSettingsBox:AddDropdown("CurrentMacroDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Current Macro", Tooltip = "Choose a macro here", Callback = Functions.ChooseMacro})
local MacroPlayToggle = MacroSettingsBox:AddToggle("MacroPlayToggle", {Text = "Play Macro", Default = false, Tooltip = "Play Selected Macro"})
local MacroStatusLabel = MacroSettingsBox:AddLabel("Macro Status Here!", true)
local MacroDiv1 = MacroSettingsBox:AddDivider()
local function ChangeMacroName(NewName)
    CurrentMacroName = NewName
end
local MacroNameInput = MacroSettingsBox:AddInput("MacroNameInput", {Default = "", Numeric = false, Finished = false, Text = "Create Macro", Tooltip = "Input a name to create a macro", Placeholder = "Name here (32 char max)", MaxLength = 32, Callback = ChangeMacroName})
local CreateMacroButton = MacroSettingsBox:AddButton({Text = "Create Macro", Func = EmptyFunc})
local DeleteMacroConfirmToggle = MacroSettingsBox:AddToggle("DeleteMacroConfirmToggle", {Text = "I want to delete the macro", Tooltip = "Turn this on to see the macro delete button"})
local MacroDeleteDepBox = MacroSettingsBox:AddDependencyBox()
local MacroDeleteButton = MacroDeleteDepBox:AddButton({Text = "Delete Macro", Func = EmptyFunc})
local MacroDiv2 = MacroSettingsBox:AddDivider()
local MacroRecordToggle = MacroSettingsBox:AddToggle("MacroRecordToggle", {Text = "Record Macro", Tooltip = "Starts a macro recording. Toggle off to end it."})
local RecordMacroDepBox = MacroSettingsBox:AddDependencyBox()
local MacroRecordStatusLabel = RecordMacroDepBox:AddLabel("Recording status here!")

local UnitGroupBox = Tabs.Macro:AddLeftGroupbox("Macro Units:")
local MacroUnitsLabel = UnitGroupBox:AddLabel("", true)

local ConfigBox = Tabs.Config:AddLeftGroupbox("Config Settings")
local ConfigLoadButton = ConfigBox:AddButton({Text = "Load Config", Func = EmptyFunc})
local ConfigSaveButton = ConfigBox:AddButton({Text = "Save Config", Func = EmptyFunc})

local WebhookBox = Tabs.Webhook:AddRightGroupbox("Webhook Settings")
local WebhookInput = WebhookBox:AddInput("WebhookInput", {Default = "", Numeric = false, Finished = false, Text = "Webhook Link", Tooltip = "Enter your discord webhook here"})
local WebhookResultToggle = WebhookBox:AddToggle("WebhookResultToggle", {Text = "Webhook Result", Default = false, Tooltip = "Send game results to webhook"})

MacroDeleteDepBox:SetupDependencies({
    {DeleteMacroConfirmToggle, true}
})
RecordMacroDepBox:SetupDependencies({
    {MacroRecordToggle, true}
})
local randomScreenGui = Instance.new("ScreenGui")
randomScreenGui.Parent = game.CoreGui
local HideShowButton = Instance.new("TextButton")
HideShowButton.Text = ""
HideShowButton.BackgroundColor3 = Color3.new(0.231372, 0.231372, 0.231372)
HideShowButton.BorderColor3 = Color3.new(0.086274, 0.086274, 0.086274)
HideShowButton.Position = UDim2.new(1,0,0.6,0)
HideShowButton.Size = UDim2.new(0,50,0,50)
HideShowButton.AnchorPoint = Vector2.new(1,0.5)
HideShowButton.Parent = randomScreenGui
HideShowButton.Activated:Connect(function()
    task.spawn(UILib.Toggle)
end)

local MacroDropdowns = {["CurrentMacroDropdown"] = CurrentMacroDropdown, ["MacroStageInfDropdown"] = MacroStageInfDropdown, ["MacroStageParagonDropdown"] = MacroStageParagonDropdown, ["MacroStageStoryDropdown"] = MacroStageStoryDropdown, ["MacroStageLegendDropdown"] = MacroStageLegendDropdown}
local idxtoact = {["MacroStageStoryDropdown"] = "Story", ["MacroStageInfDropdown"] = "Infinite", ["MacroStageParagonDropdown"] = "Paragon", ["MacroStageLegendDropdown"] = "LegendStage"}

local function UpdateMacroDropdowns()
    Macros = {}
    local MacroFileList = listfiles("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro")
    
    for _, file in pairs(MacroFileList) do
        if isdotjson(file) then
            local MacroName = cfgbeautify(file)
            table.insert(Macros, MacroName)
        end
    end
    for _, Dropdown in pairs(MacroDropdowns) do
        Dropdown.Values = Macros
        Dropdown:SetValues()
    end
end

local StageList = {}
local StageNumToName = {}

local MacroMaps = {}
for _, StoryFolder in pairs(StoryStages:GetChildren()) do
    local StageModuleObject = StoryFolder[StoryFolder.Name]
    local StageModule = require(StoryFolder[StoryFolder.Name])
    local StageName = StageModule["Name"]

    StageNumToName[StageModuleObject.Name] = StageName
    table.insert(StageList, StageName)
    MacroMaps[StageName] = {}
end
MacroStageDropdown.Values = StageList
MacroStageDropdown:SetValues()
UpdateMacroDropdowns()

MacroStageDropdown:OnChanged(function()
    CurrentMacroStage = MacroStageDropdown.Value
    for name,Dropdown in pairs(MacroDropdowns) do
        if Dropdown == CurrentMacroDropdown then continue end
        local macroStage = MacroMaps[CurrentMacroStage]
        if not macroStage then return end
        local dropvalue = MacroMaps[CurrentMacroStage][idxtoact[name]]
        if not dropvalue then dropvalue = false end
        Dropdown:SetValue(dropvalue)
    end
end)
local function setStageMacro(Dropdown, StageAct)
    if not CurrentMacroStage or not MacroMaps[CurrentMacroStage] then return end
    MacroMaps[CurrentMacroStage][StageAct] = Dropdown.Value or nil
end

MacroStageStoryDropdown:OnChanged(function()
    setStageMacro(MacroStageStoryDropdown, "Story")
end)
MacroStageInfDropdown:OnChanged(function()
    setStageMacro(MacroStageInfDropdown, "Infinite")
end)
MacroStageParagonDropdown:OnChanged(function()
    setStageMacro(MacroStageParagonDropdown, "Paragon")
end)

--// CONFIG \\--
local Filename = "AnimeVanguards_"..Players.LocalPlayer.Name..".json"
local DefaultCFG = {Toggles = {}, MacroDropdowns = {}, MacroMaps = {}}
local ConfigBlacklistNames = {"DeleteMacroConfirmToggle", "MacroRecordToggle", "MacroStageStoryDropdown", "MacroStageInfDropdown", "MacroStageParagonDropdown"}

local function LoadConfig()
    if not isfile(ConfigPath..Filename) then
        writefile(ConfigPath..Filename, HttpService:JSONEncode(DefaultCFG))
        return
    end
    local ConfigData = readfile(ConfigPath..Filename)
    if not checkJSON(ConfigData) then UILib:Notify("Unable to load config, invalid json format") return DefaultCFG end
    local DecodedConfig = HttpService:JSONDecode(ConfigData)
    return DecodedConfig
end
ConfigLoadButton.Func = LoadConfig

_G.Octohub.Config = LoadConfig() or DefaultCFG
writefile("r1singdebug.json", HttpService:JSONEncode(_G.Octohub.Config))
for Name, Value in DefaultCFG do
    local CurrentCFGVal = _G.Octohub.Config[Name]
    if not CurrentCFGVal then
        _G.Octohub.Config[Name] = Value
    end
end

local function SaveConfig()
    for ToggleName, ToggleProps in pairs(_G.Toggles) do
        if table.find(ConfigBlacklistNames, ToggleName) then continue end
        _G.Octohub.Config.Toggles[ToggleName] = ToggleProps.Value
    end
    for DropdownName, DropdownProps in pairs(MacroDropdowns) do
        if table.find(ConfigBlacklistNames, DropdownName) then continue end
        _G.Octohub.Config.MacroDropdowns[DropdownName] = DropdownProps.Value
    end
    _G.Octohub.Config.MacroMaps = MacroMaps
    _G.Octohub.Config.WebhookUrl = WebhookInput.Value or ""

    local ConfigData = HttpService:JSONEncode(_G.Octohub.Config)
    writefile(ConfigPath..Filename, ConfigData)
    return true
end
ConfigSaveButton.Func = SaveConfig
UnloadButton.Func = function()
    for _, Con in pairs(Connections) do
        Con:Disconnect()
    end

    randomScreenGui:Destroy()
    
    local a = SaveConfig()
    UILib:Unload()
    _G.Octohub = nil
end

Players.PlayerRemoving:Connect(function(plr)
    if plr == Players.LocalPlayer then
        SaveConfig()
    end
end)

task.wait(0.5)
for StageName, StageMacros in pairs(MacroMaps) do
    local curMacroList = _G.Octohub.Config.MacroMaps[StageName]
    if curMacroList then
        MacroMaps[StageName] = curMacroList
    end
end
local CurrentMacroDecide = nil
for DropdownName, DropdownValue in pairs(_G.Octohub.Config.MacroDropdowns) do
    if table.find(ConfigBlacklistNames, DropdownName) then return end
    local Dropdown = _G.Options[DropdownName]
    if not Dropdown then continue end
    if DropdownName == "CurrentMacroDropdown" then
        CurrentMacroDecide = DropdownValue
        continue
    end
    _G.Options[DropdownName]:SetValue(DropdownValue)
end
for StageName, StageMacros in pairs(MacroMaps) do
    if StageName == StageNumToName[GameHandler["GameData"]["Stage"]] then
        local MacroName = MacroMaps[StageName][GameHandler["GameData"]["StageType"]]
        CurrentMacroDecide = MacroName
    end
end
_G.Options["CurrentMacroDropdown"]:SetValue(CurrentMacroDecide)
for ToggleName, ToggleValue in pairs(_G.Octohub.Config.Toggles) do
    local Toggle = _G.Toggles[ToggleName]
    if not Toggle then continue end
    _G.Toggles[ToggleName]:SetValue(ToggleValue)
end
local webhookUrlVal = _G.Octohub.Config.WebhookUrl or ""
WebhookInput:SetValue(webhookUrlVal)

--// WEBHOOK \\--
local function convertUrl(url)
    if string.find(url, "webhook.lewisakura.moe") then return url end
    local lewiUrl = string.gsub(url, "discord.com", lewisakura)
    return lewiUrl.."/queue"
end

local function convertTimeToMins(Seconds)
    return math.floor(Seconds/60)..":"..math.floor(Seconds%60)
end

local function convertEndscreenData(EndScreenData)
    local resultData = {}
    resultData["Status"] = EndScreenData["Status"]
    local rewardsString = ""
    if resultData["Status"] ~= "Failed" then
        rewardsString = rewardsString.."Currency:\n    "
        for currencyName, currencyData in pairs(EndScreenData["Rewards"]["Currencies"]) do
            rewardsString = rewardsString..currencyName..": "..currencyData["Amount"].."\n    "
        end
        rewardsString = rewardsString.."Experience:\n    ".."Player: "..EndScreenData["Rewards"]["Experience"]["Amount"].."\n    ".."Units: "..EndScreenData["Rewards"]["UnitExperience"]["Amount"].."\n"
        rewardsString = rewardsString.."Items:\n    "
        for itemName, itemData in pairs(EndScreenData["Rewards"]["Items"]) do
            rewardsString = rewardsString..itemName..": "..itemData["Amount"].."\n    "
        end
        local UNITDROP = EndScreenData["Rewards"]["Units"][1]
        if UNITDROP then
            rewardsString = rewardsString.."***UNITS:***\n    "
            for unitName, unitData in pairs(EndScreenData["Rewards"]["Units"]) do
                rewardsString = rewardsString.."*"..unitName.."*\n    "
            end
        end
    end
    resultData["RewardsString"] = rewardsString
    
    local StatsString = "Damage: "..EndScreenData["DamageDealt"].."\n".."Waves Completed: "..EndScreenData["WavesCompleted"].."\n".."Time Taken: "..convertTimeToMins(EndScreenData["TimeTaken"])
    resultData["StatsString"] = StatsString

    return resultData
end

local function SendResultWebhook(resultData)
    local data = {}
    local decodedbody = {
        ["embeds"] = {
            {
                ["title"] = "*Octo Hub* :octopus:",
                ["type"] = "rich",
                ["description"] = "Game Results: "..resultData["Status"],
                ["color"] = tonumber(0x3D85C6),
                ["fields"] = {
                    {
                        name = "**Rewards:**",
                        value = resultData["RewardsString"],
                        inline = true
                    },
                    {
                        name = "**Stats:**",
                        value = resultData["StatsString"],
                        inline = true
                    }
                },
                ["footer"] = {
                    ["text"] = "Pyseph is a faggot"
                }
            }
        }
    }
    data.body = HttpService:JSONEncode(decodedbody)
    data.url = WebhookInput.Value

    local lewiUrl = convertUrl(data.url)
    local requestData = {Url = lewiUrl, Method = "POST", Headers = headers, Body = data.body}
    local response, err = pcall(function()
        return request(requestData)
    end)
    return response, err
end

--// GAME RELATED FUNCTIONS \\--
local function SkipWavesCall()
    SkipWaveEvent:FireServer("Skip")
end

local function RetryCall()
    VoteEvent:FireServer("Retry")
end

local function NextCall()
    VoteEvent:FireServer("Next")
end

local RetryAndNextStoryCon = ShowEndScreenEvent.OnClientEvent:Connect(function(...)
    local EndScreenData = ...
    local resultData = convertEndscreenData(EndScreenData)
    task.spawn(function()
        for _ = 1,3 do
            local webhookResult, err = SendResultWebhook(resultData)
            if typeof(err) == "table" then
                for i, v in pairs(err) do
                    warn(i,v)
                end
            end
        end
    end)
    if MacroRecordToggle.Value then return end
        task.wait(5)
        if AutoNextStoryToggle.Value and EndScreenData["StageType"] == "Story" and EndScreenData["Status"] ~= "Failed" then
            NextCall()
        elseif AutoRetryToggle.Value then
            RetryCall()
        end     
end)

local AutoMacroReplayCon = GameRestartedEvent.OnClientEvent:Connect(function(...)
    CurrentWave = 1
    if MacroPlayToggle.Value and not MacroRecordToggle.Value then
        MacroPlayToggle:SetValue(false)
        task.wait(0.3)
        MacroPlayToggle:SetValue(true)
    end
end)

local AutoStartGameCon = GameRestartedEvent.OnClientEvent:Connect(function(...)
    if AutoStartToggle.Value then
        task.wait(5)
        SkipWavesCall()
    end
end)

table.insert(Connections, RetryAndNextStoryCon)
table.insert(Connections, AutoMacroReplayCon)

local function GetUnitIDFromName(UnitName: string)
    if not UnitName then return end
    return EntityIDHandler.GetIDFromName(nil, "Unit", UnitName)
end

local function GetPlacedUnitDataFromGUID(UnitGUID: string)
    local PlacedUnitData
    local AllPlacedUnits
    repeat task.wait(0.1)
        if UILib.Unloaded then return end
        AllPlacedUnits = UnitPlacementsHandler:GetAllPlacedUnits()
        PlacedUnitData = AllPlacedUnits[UnitGUID]
    until PlacedUnitData ~= nil
    writefile("r1singdebug.json", HttpService:JSONEncode(AllPlacedUnits))
    return PlacedUnitData
end

local function GetUnitDataFromID(UnitID: number)
    if not UnitID then return end
    if string.find(UnitID,":Evolved") then
        UnitID = string.gsub(UnitID,":Evolved","")
    end
    return UnitsModule.GetUnitDataFromID(nil, UnitID, true)
end

local function GetUnitNameFromID(UnitID: number)
    if not UnitID then return end
    local UnitData = GetUnitDataFromID(UnitID)
    return UnitData["Name"]
end

local function Notify(message)
    UILib:Notify(message)
end

local function GetUnitModelFromGUID(UnitGUID: string)
    if not UnitGUID then return end
    return ClientUnitHandler.GetUnitModelFromGUID(nil, UnitGUID)
end

local function GetUnitGUIDFromPos(Pos: Vector3)
    if not Pos then return end
    local UnitData
    local repeatCount = 0
    repeat task.wait(0.1)
        if UILib.Unloaded or not MacroPlaying then return end
        for UnitPos, Data in pairs(CurrentUnits) do
            if (UnitPos - Pos).Magnitude <= 2 or (Vector3.new(UnitPos.X, 0, UnitPos.Z) - Vector3.new(Pos.X, 0, Pos.Z)).Magnitude <= 2 then
                UnitData = Data
            end
        end
        repeatCount += 1
        if repeatCount > 100 then return nil end
    until UnitData ~= nil
    local UnitGUID = UnitData["GUID"]
    return UnitGUID
end

local function PlaceUnit(UnitIDOrName: number|string, Pos: Vector3, Rotation: number)
    if not UnitIDOrName or not Pos then return end
    if not Rotation then Rotation = 90 end
    local UnitName, UnitID
    if typeof(UnitIDOrName) == "number" or string.find(UnitIDOrName, ":Evolved") then
        UnitID = UnitIDOrName
        UnitName = GetUnitNameFromID(UnitID)
    elseif typeof(UnitIDOrName) == "string" then
        UnitName = UnitIDOrName
        UnitID = GetUnitIDFromName(UnitName)
    end
    local Payload = {UnitName, UnitID, Pos, Rotation}

    UnitEvent:FireServer("Render", Payload)
end

local function SellUnit(UnitGUID: string)
    if not UnitGUID then return end
    UnitEvent:FireServer("Sell", UnitGUID)
end

local function UpgradeUnit(UnitGUID)
    if not UnitGUID then return end
    UnitEvent:FireServer("Upgrade", UnitGUID)
end

local lastWaveState = {"Show", {Wave = 0}}
local WaveInfoCon = WaveInfoEvent.OnClientEvent:Connect(function(State, Data)
    if State == "Show" then
        lastWaveState[2] = Data
    else
        CurrentWave = lastWaveState[2]["Wave"]
    end
    lastWaveState[1] = State
end)
table.insert(Connections, WaveInfoCon)

--// UNIT TRACKING \\--
local function PlayerCheck(UnitObject) if UnitObject["Player"] == LocalPlayer then return true else return false end end

local function UnitAdded(child)
    local PlacedUnitData = GetPlacedUnitDataFromGUID(child.Name)
    local PlacedUnitObject = PlacedUnitData["UnitObject"]
    if not PlayerCheck(PlacedUnitObject) then return end
    if PlacedUnitObject["Player"] == LocalPlayer then
        CurrentUnits[PlacedUnitObject["Position"]] = {["Name"] = PlacedUnitObject["Name"], ["GUID"] = PlacedUnitObject["UniqueIdentifier"], ["Model"] = child, ["Position"] = PlacedUnitObject["Position"]}
    end
end

local function UnitRemoved(child)
    for Pos, UnitProps in pairs(CurrentUnits) do
        if UnitProps["Model"] == child then
            CurrentUnits[Pos] = nil
        end
    end
end

local UnitAddedCon = UnitsFolder.ChildAdded:Connect(UnitAdded)
local UnitRemovedCon = UnitsFolder.ChildRemoved:Connect(UnitRemoved)
table.insert(Connections, UnitAddedCon)
table.insert(Connections, UnitRemovedCon)

local function GetTrackedUnitDataFromGUID(UnitGUID: string)
    local UnitData
    for UnitPos, Unit in pairs(CurrentUnits) do
        if Unit["GUID"] == UnitGUID then
            UnitData = Unit
        end
    end
    return UnitData
end

--// MACRO FILES MANIPULATIONS \\--

local function ReadMacroFile(MacroName: string)
    if not MacroName then return end
    if not isfile(MacroPath..MacroName..".json") then return end
    local EncodedMacroData = readfile(MacroPath..MacroName..".json")
    local DecodedMacroData = HttpService:JSONDecode(EncodedMacroData)

    return DecodedMacroData
end

local function WriteMacroFile(MacroName: string, MacroData)
    if not MacroName or not MacroData then return end
    local EncodedMacroData = HttpService:JSONEncode(MacroData)
    writefile("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro"..[[/]]..MacroName..".json", EncodedMacroData)
    UpdateMacroDropdowns()
    return true
end

local function CreateMacro(MacroName)
    if not MacroName or MacroName == "" or string.find(MacroName, '"') then return end
    local MacroFile = MacroPath..MacroName..".json"
    writefile(MacroPath..MacroName..".json", HttpService:JSONEncode({}))
    Notify("Macro "..tostring(MacroName).." created")
    UpdateMacroDropdowns()
    CurrentMacroDropdown:SetValue(MacroName)
end
Functions.CreateMacro = CreateMacro
CreateMacroButton.Func = function()
    CreateMacro(MacroNameInput.Value)
end

local function DeleteMacro(MacroName)
    if not MacroName then return end
    local MacroFile = MacroPath..MacroName..".json"
    if not isfile(MacroFile) then return end
    delfile(MacroPath..MacroName..".json")
    Notify("Macro "..tostring(MacroName).." deleted")
    UpdateMacroDropdowns()
    CurrentMacroDropdown:SetValue()
end
Functions.DeleteMacro = DeleteMacro
MacroDeleteButton.Func = function()
    DeleteMacro(CurrentMacroName)
end

local function ChooseMacro(ChosenMacroName)
    if not ChosenMacroName or type(ChosenMacroName) ~= "string" or ChosenMacroName == "" then return end
    if not isfile(MacroPath..ChosenMacroName..".json") then UpdateMacroDropdowns() return end
    CurrentMacroName = ChosenMacroName
    local tempMacroData = ReadMacroFile(CurrentMacroName)
    local macroSteps = tempMacroData["Steps"]
    if not macroSteps then
        tempMacroData = {["UnitsData"] = {"No units data"}, ["Steps"] = tempMacroData}
        WriteMacroFile(ChosenMacroName, tempMacroData)
    end
    CurrentMacroData = tempMacroData
    Notify("Macro "..CurrentMacroName.." was loaded.")
    local MentionedUnits = {}
    local unitsString = ""
    for _, unit in pairs(CurrentMacroData["UnitsData"]) do
        if not table.find(MentionedUnits, unit) then
            table.insert(MentionedUnits, unit)
            unitsString = unitsString..unit..", \n"
        end
    end
    MacroUnitsLabel:SetText(unitsString)
    UpdateMacroDropdowns()
end
Functions.ChooseMacro = ChooseMacro
CurrentMacroDropdown:OnChanged(ChooseMacro)

UpdateMacroDropdowns()

--// MACRO PLAY \\--
local function PlayMacro()
    if (not CurrentMacroName or not CurrentRecordData) and MacroPlaying then Notify("Invalid macro") return end
    MacroPlaying = MacroPlayToggle.Value
    if MacroPlaying then
        if not CurrentMacroData then return end
        local totalSteps = #CurrentMacroData["Steps"]
        for stepCount, stepData in pairs(CurrentMacroData["Steps"]) do
            if not MacroPlaying then break end
            if UILib.Unloaded then break end
            task.wait(0.5)
            local CurrentYen = PlayerYenHandler:GetYen()

            local stepName = stepData[1]
            if stepName == "Place" then
                local UnitData = GetUnitDataFromID(stepData[3])
                local UnitName = stepData[2]
                MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Placing "..UnitName)
                local UnitPos = string_to_vector3(stepData[4])
                local UnitID = stepData[3]
             
                local UnitRotation = stepData[5]
                if UnitData["Price"] > CurrentYen then
                    MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Placing "..UnitName..", waiting for "..tostring(UnitData["Price"]).."Yen")
                    repeat task.wait() if UILib.Unloaded or not MacroPlaying then return end until PlayerYenHandler:GetYen() >= UnitData["Price"]
                end
                PlaceUnit(UnitID, UnitPos, UnitRotation)
            elseif stepName == "Sell" then
                MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Selling a unit")
                local UnitPos = string_to_vector3(stepData[2])
                local Wave = stepData[3]
                local UnitGUID = GetUnitGUIDFromPos(UnitPos)
                if not UnitGUID then continue end
                if Wave then
                    if CurrentWave < Wave then
                        MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | Selling a Unit, Waiting for "..Wave.."Wave")
                        repeat task.wait()
                            if UILib.Unloaded then continue end
                            if not MacroPlaying then return end
                        until CurrentWave >= Wave
                    end
                end

                SellUnit(UnitGUID)
            elseif stepName == "Upgrade" then
                local UnitPos = string_to_vector3(stepData[2])
                
                local UnitGUID = GetUnitGUIDFromPos(UnitPos)
                if not UnitGUID then continue end
                local PlacedUnitData = GetPlacedUnitDataFromGUID(UnitGUID)

                local UpgradeLevel = PlacedUnitData["UpgradeLevel"]
                local UpgradeStats = PlacedUnitData["UnitObject"]["Data"]["Upgrades"][UpgradeLevel+1]
                if not UpgradeStats then
                     continue
                end
                local UpgradePrice = PlacedUnitData["UnitObject"]["Data"]["Upgrades"][UpgradeLevel+1]["Price"]
                local UnitName = PlacedUnitData["UnitObject"]["Name"]
                MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Upgrading "..UnitName)
                if UpgradePrice > CurrentYen then
                    MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Upgrading "..UnitName..", waiting for "..tostring(UpgradePrice))
                    repeat task.wait()
                        if UILib.Unloaded or not MacroPlaying then return end
                    until PlayerYenHandler:GetYen() >= UpgradePrice
                end
                UpgradeUnit(UnitGUID)
            end
        end
        MacroStatusLabel:SetText("DONE")
    end
end

MacroPlayToggle.Callback = PlayMacro

--// MACRO RECORD \\--
local lastRecordStatus = false
local gameMeta = getrawmetatable(game)
local gameNamecall = gameMeta.__namecall

local makewriteable
if setreadonly ~= nil then
    makewriteable = function() setreadonly(gameMeta, false) end
elseif make_writeable ~= nil then
    makewriteable = function() make_writeable(gameMeta) end
end
makewriteable()

MacroRecordToggle:OnChanged(function()
    if MacroPlaying and MacroRecordToggle.Value == true then MacroRecordToggle:SetValue(false) Notify("You can't record a macro while playing a macro..") return end
    if lastRecordStatus == MacroRecordToggle.Value then return end
    lastRecordStatus = MacroRecordToggle.Value
    if not CurrentMacroName then Notify("Choose a macro first!") return end
    RecordingMacro = MacroRecordToggle.Value
    if not RecordingMacro then
        local UnitsUsed = {}
        for UnitPos, UnitData in pairs(CurrentUnits) do
            if not table.find(UnitsUsed, UnitData["Name"]) then
                table.insert(UnitsUsed, UnitData["Name"])
            end
        end
        local FinalMacroData = {["UnitsData"] = UnitsUsed, ["Steps"] = CurrentRecordData}
        local success = WriteMacroFile(CurrentMacroName, FinalMacroData)
        CurrentMacroData = FinalMacroData
        CurrentRecordData = {}
        CurrentRecordStep = 1
        UpdateMacroDropdowns()
        Notify("Macro "..tostring(CurrentMacroName).." recording ended.")
        MacroRecordStatusLabel:SetText("Recording Ended")
    else
        MacroRecordStatusLabel:SetText("Recording Started")
        Notify("Macro "..tostring(CurrentMacroName).." recording started.")
    end
end)

local on_namecall = function(obj, ...)
    if UILib.Unloaded then return gameNamecall(obj, ...) end
    local args = {...}
    local method = tostring(getnamecallmethod())
    local isRemoteMethod = method == "FireServer" or method == "InvokeServer"

    if RecordingMacro then
        if method:match("Server") and isRemoteMethod then
            if obj == UnitEvent then
                if args[1] == "Render" then
                    local UnitTable = args[2]
                    local UnitName = UnitTable[1]
                    local UnitID = UnitTable[2]
                    local UnitPos = UnitTable[3]
                    local UnitRotation = UnitTable[4]

                    CurrentRecordData[CurrentRecordStep] = {"Place", UnitName, UnitID, tostring(UnitPos), UnitRotation}
                elseif args[1] == "Sell" then
                    local UnitGUID = args[2]
                    local PlacedUnitData = GetTrackedUnitDataFromGUID(UnitGUID)

                    CurrentRecordData[CurrentRecordStep] = {"Sell", tostring(PlacedUnitData["Position"]), CurrentWave}
                elseif args[1] == "Upgrade" then
                    local UnitGUID = args[2]
                    local PlacedUnitData = GetTrackedUnitDataFromGUID(UnitGUID)

                    CurrentRecordData[CurrentRecordStep] = {"Upgrade", tostring(PlacedUnitData["Position"])}
                end
                CurrentRecordStep += 1
            end
        end
    end

    return gameNamecall(obj, ...)
end
gameMeta.__namecall = on_namecall

if AutoStartToggle.Value then
    task.wait(5)
    SkipWavesCall()
end
end