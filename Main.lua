local gameId = game.GameId

local LocalPlayer = game:GetService("Players").LocalPlayer

local hub_games_list = require(game:HttpGet(""))

if not hub_games_list[gameId] then 
    LocalPlayer:Kick("Game is not on the list!")
end