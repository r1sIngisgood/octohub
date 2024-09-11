if game.Players.LocalPlayer.UserId == (1834825389 or 506636671) then return end

getgenv().Octohub = {}

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

local UnitsFolder = workspace.Units
local StagesDataFolder = ReplicatedModulesFolder.Data.StagesData
local StoryStages = StagesDataFolder.Story

--// Script Consts \\--
local ScriptFilePath = "OctoHub"..[[/]].."Anime Vanguards"..[[/]]
local MacroPath = ScriptFilePath.."Macro"..[[/]]
local ConfigPath = ScriptFilePath.."Config"..[[/]]
local EmptyFunc = function() end

--// Script Runtime Values \\--
local Options = getgenv().Options

local Functions = {CreateMacro = EmptyFunc, DeleteMacro = EmptyFunc, ChooseMacro = EmptyFunc}
local Macros = {}
local CurrentRecordStep = 1
local CurrentRecordData = {}
local CurrentUnits = {}

local CurrentMacroName = nil
local CurrentMacroData = nil
local RecordingMacro = false
local PlayingMacro = false
local CurrentMacroStage = nil

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
}

local FarmSettingsBox = Tabs.Main:AddLeftGroupbox("Farm Settings")
local AutoRetryToggle = FarmSettingsBox:AddToggle("AutoRetryToggle", {Text = "Auto Retry", Default = false, Tooltip = "Auto press the retry button"})
local AutoNextStoryToggle = FarmSettingsBox:AddToggle("AutoNextStoryToggle", {Text = "Auto Next Story", Default = false, Tooltip = "Auto press the next story button"})

local UISettingsBox = Tabs.UISettings:AddLeftGroupbox("UI Settings")
local UnloadButton = UISettingsBox:AddButton("Unload", EmptyFunc)

local MacroSettingsBox = Tabs.Macro:AddLeftGroupbox('Macro Settings')
local MacroStageBox = Tabs.Macro:AddRightGroupbox('Macros')

local MacroStageDropdown = MacroStageBox:AddDropdown("StageDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Map", Tooltip = "Choose a map to manage macros for it"})
local MacroStageStoryDropdown = MacroStageBox:AddDropdown("MacroStageStoryDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Story"})
local MacroStageInfDropdown = MacroStageBox:AddDropdown("MacroStageInfDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Infinite"})
local MacroStageParagonDropdown = MacroStageBox:AddDropdown("MacroStageParagonDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Paragon"})

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

local ConfigBox = Tabs.Config:AddLeftGroupbox("ConfigBox")
local ConfigLoadButton = ConfigBox:AddButton({Text = "Load Config", Func = EmptyFunc})
local ConfigSaveButton = ConfigBox:AddButton({Text = "Save Config", Func = EmptyFunc})

MacroDeleteDepBox:SetupDependencies({
    {DeleteMacroConfirmToggle, true}
})
RecordMacroDepBox:SetupDependencies({
    {MacroRecordToggle, true}
})

local MacroDropdowns = {["CurrentMacroDropdown"] = CurrentMacroDropdown, ["MacroStageInfDropdown"] = MacroStageInfDropdown, ["MacroStageParagonDropdown"] = MacroStageParagonDropdown, ["MacroStageStoryDropdown"] = MacroStageStoryDropdown}
local idxtoact = {["MacroStageStoryDropdown"] = "Story", ["MacroStageInfDropdown"] = "Infinite", ["MacroStageParagonDropdown"] = "Paragon"}

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
    writefile("Macros.json",HttpService:JSONEncode(MacroDropdowns))
end

local StageList = {}

local MacroMaps = {}
for _, StoryFolder in pairs(StoryStages:GetChildren()) do
    local StageModule = require(StoryFolder[StoryFolder.Name])
    local StageName = StageModule["Name"]

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

getgenv().Octohub.Config = LoadConfig() or DefaultCFG
for Name, Value in DefaultCFG do
    local CurrentCFGVal = getgenv().Octohub.Config[Name]
    if not CurrentCFGVal then
        getgenv().Octohub.Config[Name] = Value
    end
end

local function SaveConfig()
    for ToggleName, ToggleProps in pairs(getgenv().Toggles) do
        if table.find(ConfigBlacklistNames, ToggleName) then continue end
        getgenv().Octohub.Config.Toggles[ToggleName] = ToggleProps.Value
    end
    for DropdownName, DropdownProps in pairs(MacroDropdowns) do
        if table.find(ConfigBlacklistNames, DropdownName) then continue end
        getgenv().Octohub.Config.MacroDropdowns[DropdownName] = DropdownProps.Value
    end
    getgenv().Octohub.Config.MacroMaps = MacroMaps

    local ConfigData = HttpService:JSONEncode(getgenv().Octohub.Config)
    writefile(ConfigPath..Filename, ConfigData)
end
ConfigSaveButton.Func = SaveConfig
UnloadButton.Func = function()
    SaveConfig()
    UILib:Unload()
end

Players.PlayerRemoving:Connect(function(plr)
    if plr == Players.LocalPlayer then
        SaveConfig()
    end
end)

task.wait(0.5)
for StageName, StageMacros in pairs(MacroMaps) do
    local curMacroList = getgenv().Octohub.Config.MacroMaps[StageName]
    if curMacroList then
        MacroMaps[StageName] = curMacroList
    end
end
for DropdownName, DropdownValue in pairs(getgenv().Octohub.Config.MacroDropdowns) do
    if table.find(ConfigBlacklistNames, DropdownName) then return end
    local Dropdown = getgenv().Options[DropdownName]
    if not Dropdown then continue end
    getgenv().Options[DropdownName]:SetValue(DropdownValue)
end
for ToggleName, ToggleValue in pairs(getgenv().Octohub.Config.Toggles) do
    local Toggle = getgenv().Options[ToggleName]
    if not Toggle then continue end
    getgenv().Toggles[ToggleName]:SetValue(ToggleValue)
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

ShowEndScreenEvent.OnClientEvent:Connect(function(...)
    task.wait(5)
    local EndScreenData = ...
    if AutoNextStoryToggle.Value and EndScreenData["StageType"] == "Story" and EndScreenData["Status"] ~= "Failed" then
        NextCall()
    elseif AutoRetryToggle.Value then
        RetryCall()
    end
end)

local function GetUnitIDFromName(UnitName: string)
    if not UnitName then return end
    return EntityIDHandler.GetIDFromName(nil, "Unit", UnitName)
end

local function GetPlacedUnitDataFromGUID(UnitGUID: string)
    local AllPlacedUnits = UnitPlacementsHandler:GetAllPlacedUnits()
    local PlacedUnitData = AllPlacedUnits[UnitGUID]
    if not PlacedUnitData then warn(PlacedUnitData, AllPlacedUnits, AllPlacedUnits[UnitGUID], UnitGUID) end

    return PlacedUnitData
end

local function GetUnitDataFromID(UnitID: number)
    if not UnitID then return end
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
    local UnitGUID: string
    for i, v in pairs(UnitsFolder:GetChildren()) do
        local vHRP = v:FindFirstChild("HumanoidRootPart")
        if not vHRP then return end
        warn(vHRP.Position, Pos)
        if (vHRP.Position - Pos).Magnitude <= 2 or vHRP.Position == Pos then
            UnitGUID = v.Name
        end
    end
    return UnitGUID
end

local function PlaceUnit(UnitIDOrName: number|string, Pos: Vector3, Rotation: number)
    if not UnitIDOrName or not Pos then return end
    if not Rotation then Rotation = 90 end
    local UnitName, UnitID
    if typeof(UnitIDOrName) == "string" then
        UnitName = UnitIDOrName
        UnitID = GetUnitIDFromName(UnitName)
    elseif typeof(UnitIDOrName) == "number" then
        UnitID = UnitIDOrName
        UnitName = GetUnitNameFromID(UnitID)
    end
    local Payload = {UnitName, UnitID, Pos, Rotation}

    return UnitEvent:FireServer("Render", Payload)
end

local function SellUnit(UnitGUID: string)
    if not UnitGUID then return end
    UnitEvent:FireServer("Sell", UnitGUID)
end

local function UpgradeUnit(UnitGUID)
    if not UnitGUID then return end
    UnitEvent:FireServer("Upgrade", UnitGUID)
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
    CurrentMacroData = ReadMacroFile(CurrentMacroName)
    Notify("Macro "..CurrentMacroName.." was loaded.")
    UpdateMacroDropdowns()
end
Functions.ChooseMacro = ChooseMacro
CurrentMacroDropdown:OnChanged(ChooseMacro)

UpdateMacroDropdowns()

--// MACRO PLAY \\--

local MacroPlaying = false
local function PlayMacro()
    if (not CurrentMacroName or not CurrentRecordData) and MacroPlaying then Notify("Invalid macro") return end
    MacroPlaying = MacroPlayToggle.Value
    if MacroPlaying then
        if not CurrentMacroData then return end
        local totalSteps = #CurrentMacroData
        for stepCount, stepData in pairs(CurrentMacroData) do
            if not MacroPlaying then break end
            task.wait(0.25)
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
                    MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Placing "..UnitName..", waiting for "..tostring(UnitData["Price"]))
                    repeat task.wait() if not MacroPlaying then return end until PlayerYenHandler:GetYen() >= UnitData["Price"]
                end
                warn(PlaceUnit(UnitID, UnitPos, UnitRotation))
                --CurrentUnits[UnitPos] = UnitName
            elseif stepName == "Sell" then
                MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Selling a unit")
                local UnitPos = string_to_vector3(stepData[2])
                local UnitGUID = GetUnitGUIDFromPos(UnitPos)

                SellUnit(UnitGUID)
            elseif stepName == "Upgrade" then
                local UnitPos = string_to_vector3(stepData[2])
                
                local UnitGUID
                local PlacedUnitData
                repeat
                    warn(UnitPos, UnitGUID, PlacedUnitData)
                    UnitGUID = GetUnitGUIDFromPos(UnitPos)
                    PlacedUnitData = GetPlacedUnitDataFromGUID(UnitGUID)
                    task.wait(0.1)
                until PlacedUnitData ~= nil and UnitGUID ~= nil

                local UpgradeLevel = PlacedUnitData["UpgradeLevel"]
                local UpgradePrice = PlacedUnitData["UnitObject"]["Data"]["Upgrades"][UpgradeLevel+1]["Price"]
                local UnitName = PlacedUnitData["UnitObject"]["Name"]
                MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Upgrading "..UnitName)
                if UpgradePrice > CurrentYen then
                    MacroStatusLabel:SetText(stepCount.."/"..totalSteps.." | ".."Upgrading "..UnitName..", waiting for "..tostring(UpgradePrice))
                    repeat task.wait()
                        if not MacroPlaying then return end
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
    if lastRecordStatus == MacroRecordToggle.Value then return end
    lastRecordStatus = MacroRecordToggle.Value
    if not CurrentMacroName then Notify("Choose a macro first!") return end
    if PlayingMacro and MacroRecordToggle.Value == true then MacroRecordToggle:SetValue(false) Notify("You can't record a macro while playing a macro..") return end
    RecordingMacro = MacroRecordToggle.Value
    if not RecordingMacro then
        local success = WriteMacroFile(CurrentMacroName, CurrentRecordData)
        CurrentMacroData = CurrentRecordData
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
                    local UnitModel = GetUnitModelFromGUID(UnitGUID)
                    local UnitPos = UnitModel.HumanoidRootPart.Position

                    CurrentRecordData[CurrentRecordStep] = {"Sell", tostring(UnitPos)}
                elseif args[1] == "Upgrade" then
                    local UnitGUID = args[2]
                    local UnitModel = GetUnitModelFromGUID(UnitGUID)
                    local UnitPos = UnitModel.HumanoidRootPart.Position

                    CurrentRecordData[CurrentRecordStep] = {"Upgrade", tostring(UnitPos)}
                end
                CurrentRecordStep += 1
            end
        end
    end

    return gameNamecall(obj, ...)
end
gameMeta.__namecall = on_namecall