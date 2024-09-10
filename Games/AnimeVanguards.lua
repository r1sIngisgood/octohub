local repo = "https://raw.githubusercontent.com/r1sIngisgood/octohub/main/"
local UILib = loadstring(game:HttpGet(repo.."UILib/Linoria.lua"))
local SaveManager = loadstring(game:HttpGet(repo.."UILib/SaveManager.lua"))

--// IG SERVICES \\--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--// GAME MODULES \\--
local ModulesFolder = ReplicatedStorage.Modules

local EntityIDHandler = require(ModulesFolder.Data.Entities.EntityIDHandler)
local UnitsModule = require(game:GetService("ReplicatedStorage").Modules.Data.Entities.Units)
local ClientUnitHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.ClientUnitHandler)

--// REMOTES \\--
local NetworkingFolder = ReplicatedStorage:WaitForChild("Networking")

local StartWavesEvent = NetworkingFolder.SkipWaveEvent
local UnitEvent = NetworkingFolder.UnitEvent
local VoteEvent = NetworkingFolder.EndScreen.VoteEvent

--// Script Consts \\--
local ScriptFilePath = "OctoHub"..[[\]].."Anime Vanguards"..[[\]]
local MacroPath = ScriptFilePath.."Macro"..[[\]]
local ConfigPath = ScriptFilePath.."Config"..[[\]]

--// Script Runtime Values \\--
local CurrentRecordStep = 1
local CurrentRecordData = {}

local ChosenMacro = nil

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

local MacroLeftGroupBox = Tabs.Macro:AddLeftGroupbox('Macro1')
local MacroRightGroupBox = Tabs.Macro:AddRightGroupbox('Macro1')

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

local function getUnitModelByGUID(UnitGUID: string)
    if not UnitGUID then return end
    return ClientUnitHandler.GetUnitModelFromGUID(nil, UnitGUID)
end

local function PlaceUnit(UnitName: string, Pos: Vector3, Rotation: number)
    if not UnitName or not Pos then return end
    if not Rotation then Rotation = 90 end
    local UnitID = getUnitIDByName(UnitName)
    local Payload = {UnitName, UnitID, Pos, Rotation}

    UnitEvent:FireServer("Render", Payload)
end

local function RemoveUnit(UnitUUID: string)
    if not UnitUUID then return end
    UnitEvent:FireServer("Sell", UnitUUID)
end

--// MACRO FILES MANIPULATIONS \\--
local function CreateMacro(MacroName)
    if not MacroName then return end
    local MacroFile = MacroPath..MacroName..".json"
    if isfile(MacroFile) then return end
    writefile(MacroPath..MacroName..".json", HttpService:JSONEncode({}))
end

local function DeleteMacro(MacroName)
    if not MacroName then return end
    local MacroFile = MacroPath..MacroName..".json"
    if not isfile(MacroFile) then return end
    delfile(MacroPath..MacroName..".json")
end

local function ChooseMacro(ChosenMacroName)
    if not ChosenMacroName or type(ChosenMacroName) ~= "string" or not ChosenMacroName == "" then return end
    if not isfile(MacroPath..ChosenMacroName..".json") then
        writefile()
    end
end

--// MACRO PLAY \\--
local MacroPlaying = false
local function PlayMacro_Start()

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

local on_namecall = function(obj, ...)
    local args = {...}
    local method = tostring(getnamecallmethod())
    local isRemoteMethod = method == "FireServer" or method == "InvokeServer"

    if method:match("Server") and isRemoteMethod then
        if obj == UnitEvent then
            if args[1] == "Render" then
                local UnitTable = args[2]
                -- UnitName = UnitTable[1]
                -- UnitID = UnitTable[2]
                -- UnitPos = UnitTable[3]
                -- UnitRotation = UnitTable[4]

                CurrentRecordData[CurrentRecordStep] = {"Place", UnitTable}
            elseif args[1] == "Sell" then
                local UnitGUID = args[2]
                local UnitModel = getUnitModelByGUID(UnitGUID)
                local UnitPos = UnitModel.HumanoidRootPart.Position

                CurrentRecordData[CurrentRecordStep] = {"Sell", UnitPos}
            elseif args[1] == "Upgrade" then
                local UnitGUID = args[2]
                local UnitModel = getUnitModelByGUID(UnitGUID)
                local UnitPos = UnitModel.HumanoidRootPart.Position

                CurrentRecordData[CurrentRecordStep] = {"Upgrade", UnitPos}
            end
            CurrentRecordStep += 1
        end
    end

    return gameNamecall(obj, ...)
end
gameMeta.__namecall = on_namecall