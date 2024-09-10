if not isfolder("OctoHub") then makefolder("OctoHub") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards") then makefolder("OctoHub"..[[/]].."Anime Vanguards") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro") then makefolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro") end
if not isfolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Config") then makefolder("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Config") end

local repo = "https://raw.githubusercontent.com/r1sIngisgood/octohub/main/"
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/r1sIngisgood/octohub/main/UILib/Linoria.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/r1sIngisgood/octohub/main/UILib/SaveManager.lua"))()

--// IG SERVICES \\--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

--// GAME MODULES \\--
local ModulesFolder = ReplicatedStorage.Modules

local EntityIDHandler = require(ModulesFolder.Data.Entities.EntityIDHandler)
local UnitsModule = require(game:GetService("ReplicatedStorage").Modules.Data.Entities.Units)
local ClientUnitHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.ClientUnitHandler)
local PlayerYenHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.PlayerYenHandler)
local GameHandler = require(game:GetService("ReplicatedStorage").Modules.Gameplay.GameHandler)
local UnitPlacementsHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.UnitManager.UnitPlacementsHandler)

--// IG OBJECTS \\--
local NetworkingFolder = ReplicatedStorage:WaitForChild("Networking")

local StartWavesEvent = NetworkingFolder.SkipWaveEvent
local UnitEvent = NetworkingFolder.UnitEvent
local VoteEvent = NetworkingFolder.EndScreen.VoteEvent

local UnitsFolder = workspace.Units

--// Script Consts \\--
local ScriptFilePath = "OctoHub"..[[/]].."Anime Vanguards"..[[/]]
local MacroPath = ScriptFilePath.."Macro"..[[/]]
local ConfigPath = ScriptFilePath.."Config"..[[/]]
local EmptyFunc = function() end

--// Script Runtime Values \\--
local Options = getgenv().Options
local Toggles = Options.Toggles

local Functions = {CreateMacro = EmptyFunc, DeleteMacro = EmptyFunc, ChooseMacro = EmptyFunc}
local Macros = {}
local CurrentRecordStep = 1
local CurrentRecordData = {}

local CurrentMacroName = nil
local CurrentMacroData = nil
local RecordingMacro = false
local PlayingMacro = false

--// UTIL FUNCTIONS \\--
local function cfgbeautify(str) return string.gsub(string.gsub(str,MacroPath,""),".json","") end
local function isdotjson(file) return string.sub(file, -5) == ".json" end
local function string_to_vector3(str) return Vector3.new(table.unpack(str:gsub(" ",""):split(","))) end

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
    Macro = Window:AddTab('Main'),
    UISettings = Window:AddTab('UI Settings')
}

local UISettingsBox = Tabs.UISettings:AddLeftGroupbox("UI Settings")
UISettingsBox:AddButton("Unload", function() UILib:Unload() end)

local MacroSettingsBox = Tabs.Macro:AddLeftGroupbox('Macro Settings')
local MacroRightGroupBox = Tabs.Macro:AddRightGroupbox('Macros')

local MacroPlayToggle = MacroSettingsBox:AddToggle("MacroPlayToggle", {Text = "Play Macro", Default = false, Tooltip = "Play Selected Macro"})
local MacroPlayDepBox = MacroSettingsBox:AddDependencyBox()
local MacroStatusLabel = MacroPlayDepBox:AddLabel("Macro Status Here!", true)
local CurrentMacroDropdown = MacroSettingsBox:AddDropdown("CurrentMacroDropdown", {Values = {}, AllowNull = true, Multi = false, Text = "Current Macro", Tooltip = "Choose a macro here", Callback = Functions.ChooseMacro})
local function ChangeMacroName(NewName)
    CurrentMacroName = NewName
end
local MacroNameInput = MacroSettingsBox:AddInput("MacroNameInput", {Default = "", Numeric = false, Finished = false, Text = "Macro Name", Tooltip = "Input a name to create a macro", Placeholder = "Name here (32 char max)", MaxLength = 32, Callback = ChangeMacroName})
local CreateMacroButton = MacroSettingsBox:AddButton({Text = "Create Macro", Func = EmptyFunc})
local DeleteMacroConfirmToggle = MacroSettingsBox:AddToggle("DeleteMacroConfirmToggle", {Text = "I want to delete the macro", Tooltip = "Turn this on to see the macro delete button"})
local MacroDeleteDepBox = MacroSettingsBox:AddDependencyBox()
local MacroDeleteButton = MacroDeleteDepBox:AddButton({Text = "Delete Macro", Func = EmptyFunc})
local MacroRecordToggle = MacroSettingsBox:AddToggle("MacroRecordToggle", {Text = "Record Macro", Tooltip = "Starts a macro recording. Toggle off to end it."})

MacroDeleteDepBox:SetupDependencies({
    {DeleteMacroConfirmToggle, true}
})
MacroPlayDepBox:SetupDependencies({
    {MacroPlayToggle, true}
})

local MacroDropdowns = {CurrentMacroDropdown}
local function UpdateMacroDropdowns()
    Macros = {}
    local MacroFileList = listfiles("OctoHub"..[[/]].."Anime Vanguards"..[[/]].."Macro")
    
    for _, file in ipairs(MacroFileList) do
        if isdotjson(file) then
            local MacroName = cfgbeautify(file)
            table.insert(Macros, MacroName)
        end
    end
    for _, Dropdown in ipairs(MacroDropdowns) do
        Dropdown.Values = Macros
        Dropdown:SetValues()
    end
end

--// GAME RELATED FUNCTIONS \\--
local function SkipWavesCall()
    StartWavesEvent:FireServer("Skip")
end

local function RetryCall()
    VoteEvent:FireServer("Retry")
end

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
        if (vHRP.Position - Pos).Magnitude <= 1 then
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
    Notify("Macro created")
    UpdateMacroDropdowns()
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
    Notify("Macro deleted")
    UpdateMacroDropdowns()
end
Functions.DeleteMacro = DeleteMacro
MacroDeleteButton.Func = function()
    DeleteMacro(CurrentMacroName)
end

local function ChooseMacro(ChosenMacroName)
    if not ChosenMacroName or type(ChosenMacroName) ~= "string" or not ChosenMacroName == "" then return end
    if not isfile(MacroPath..ChosenMacroName..".json") then CurrentMacroDropdown:SetValues() return end
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
    MacroPlaying = not MacroPlaying
    if MacroPlaying then
        for stepCount, stepData in pairs(CurrentMacroData) do
            task.wait(0.1)
            local CurrentYen = PlayerYenHandler:GetYen()

            local stepName = stepData[1]
            if stepName == "Place" then
                
                local UnitName = stepData[2]
                MacroStatusLabel:SetText("Placing "..UnitName)
                local UnitPos = string_to_vector3(stepData[4])
                local UnitID = stepData[3]
                local UnitData = GetUnitDataFromID(stepData[3])
                local UnitRotation = stepData[5]
                if UnitData["Price"] > CurrentYen then
                    MacroStatusLabel:SetText("Placing "..UnitName..", waiting for "..tostring(UnitData["Price"]))
                    repeat task.wait() until PlayerYenHandler:GetYen() >= UnitData["Price"]
                end
                PlaceUnit(UnitName, UnitPos, UnitRotation)
            elseif stepName == "Sell" then
                MacroStatusLabel:SetText("Selling a unit")
                local UnitPos = string_to_vector3(stepData[2])
                local UnitGUID = GetUnitGUIDFromPos(UnitPos)

                SellUnit(UnitGUID)
            elseif stepName == "Upgrade" then
                local UnitPos = string_to_vector3(stepData[2])
                
                local UnitGUID
                local PlacedUnitData
                repeat
                    UnitGUID = GetUnitGUIDFromPos(UnitPos)
                    warn(UnitGUID)
                    PlacedUnitData = GetPlacedUnitDataFromGUID(UnitGUID)
                    task.wait(0.1)
                until PlacedUnitData ~= nil and UnitGUID ~= nil

                local UpgradeLevel = PlacedUnitData["UpgradeLevel"]
                local UpgradePrice = PlacedUnitData["UnitObject"]["Data"]["Upgrades"][UpgradeLevel+1]["Price"]
                local UnitName = PlacedUnitData["UnitObject"]["Name"]
                MacroStatusLabel:SetText("Upgrading "..UnitName)
                if UpgradePrice > CurrentYen then
                    MacroStatusLabel:SetText("Upgrading "..UnitName..", waiting for "..tostring(UpgradePrice))
                    repeat task.wait() until PlayerYenHandler:GetYen() >= UpgradePrice
                end
                UpgradeUnit(UnitGUID)
            end
        end
    end
end

MacroPlayToggle.Callback = PlayMacro

--// MACRO RECORD \\--
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
    if PlayingMacro and MacroRecordToggle.Value == true then MacroRecordToggle:SetValue(false) Notify("You can't record a macro while playing a macro..") return end
    RecordingMacro = MacroRecordToggle.Value
    if not RecordingMacro then
        local success = WriteMacroFile(CurrentMacroName, CurrentRecordData)
        CurrentRecordData = {}
        CurrentRecordStep = 1
        UpdateMacroDropdowns()
    end
end)

local on_namecall = function(obj, ...)
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
                    warn(tostring(UnitPos))
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