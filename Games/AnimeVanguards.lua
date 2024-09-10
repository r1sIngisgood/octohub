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

local MacroSettingsBox = Tabs.Macro:AddLeftGroupbox('Macro Settings')
local MacroRightGroupBox = Tabs.Macro:AddRightGroupbox('Macros')

local MacroPlayToggle = MacroSettingsBox:AddToggle("MacroPlayToggle", {Text = "Play Macro", Default = false, Tooltip = "Play Selected Macro"})
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
    writefile("r1singdebug1.json", tostring(HttpService:JSONEncode(Macros)))
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

local function getUnitIDByName(UnitName: string)
    if not UnitName then return end
    return EntityIDHandler.GetIDFromName(nil, "Unit", UnitName)
end

local function getUnitDataByID(UnitID: number)
    if not UnitID then return end
    return UnitsModule.GetUnitDataFromID(nil, UnitID, true)
end

local function Notify(message)
    UILib:Notify(message)
end

local function getUnitModelByGUID(UnitGUID: string)
    if not UnitGUID then return end
    return ClientUnitHandler.GetUnitModelFromGUID(nil, UnitGUID)
end

local function GetUnitGUIDFromPos(Pos: Vector3)
    if not Pos then return end
    for i, v in pairs(UnitsFolder:GetChildren()) do
        local vHRP = v:FindFirstChild("HumanoidRootPart")
        if not vHRP then return end
        if (vHRP.Position - Pos).Magnitude <= 1 then
            return v.Name
        end
    end
end

local function PlaceUnit(UnitName: string, Pos: Vector3, Rotation: number)
    if not UnitName or not Pos then return end
    if not Rotation then Rotation = 90 end
    local UnitID = getUnitIDByName(UnitName)
    local Payload = {UnitName, UnitID, Pos, Rotation}

    UnitEvent:FireServer("Render", Payload)
end

local function RemoveUnit(UnitGUID: string)
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
    if not MacroName then return end
    local MacroFile = MacroPath..MacroName..".json"
    writefile(MacroPath..MacroName..".json", HttpService:JSONEncode({}))
    Notify("ABC")
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
        
    end
end

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
                    -- UnitName = UnitTable[1]
                    -- UnitID = UnitTable[2]
                    -- UnitPos = UnitTable[3]
                    -- UnitRotation = UnitTable[4]
                    local UnitData = getUnitDataByID(UnitTable[2])
                    local Cost = UnitData["Price"]

                    CurrentRecordData[CurrentRecordStep] = {"Place", UnitTable}
                elseif args[1] == "Sell" then
                    local UnitGUID = args[2]
                    local UnitModel = getUnitModelByGUID(UnitGUID)
                    local UnitPos = UnitModel.HumanoidRootPart.Position
                    print(require(game:GetService("ReplicatedStorage").Modules.Data.Entities.EntityIDHandler):GetNameFromID(UnitGUID))
                    CurrentRecordData[CurrentRecordStep] = {"Sell", UnitPos}
                elseif args[1] == "Upgrade" then
                    local UnitGUID = args[2]
                    local UnitModel = getUnitModelByGUID(UnitGUID)
                    local UnitPos = UnitModel.HumanoidRootPart.Position
                    local UnitData = getUnitDataByID(UnitTable[2])
                    local Cost = UnitData["Upgrades"]

                    CurrentRecordData[CurrentRecordStep] = {"Upgrade", UnitPos}
                end
                CurrentRecordStep += 1
            end
        end
    end

    return gameNamecall(obj, ...)
end
gameMeta.__namecall = on_namecall