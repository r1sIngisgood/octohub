local HttpService = game:GetService("HttpService")

local ConfigManager = {}


local ScriptFilePath = "OctoHub"..[[/]].."Anime Vanguards"..[[/]]
local MacroPath = ScriptFilePath.."Macro"..[[/]]
local ConfigPath = ScriptFilePath.."Config"..[[/]]

local function checkJSON(str)
    local result = pcall(function()
        HttpService:JSONDecode(str)
    end)
    return result
end

function ConfigManager.SaveConfig(User:string, GameName:string, ConfigData)
    local Filename = GameName.."_"..User..".json"
    local ConfigData = HttpService:JSONEncode(ConfigData)
    writefile(ConfigPath..Filename, ConfigData)
end

function ConfigManager.LoadConfig(User, GameName)
    local Filename = GameName.."_"..User..".json"
    local ConfigFile = readfile(ConfigPath..Filename)
    if not ConfigFile then return end
    if not checkJSON(ConfigFile) then return end
    return HttpService:JSONDecode(ConfigFile)
end

return ConfigManager