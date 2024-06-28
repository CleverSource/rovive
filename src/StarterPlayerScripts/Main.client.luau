-- Main client setup script
-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Variables
local Player = Players.LocalPlayer

-- Systems
local ToolSystem = require(script.Parent.ToolSystem)
local InputSystem = require(script.Parent.InputSystem)

-- Player State
local PlayerStateController = require(script.Parent.PlayerStateController)

-- Initialize player's character
if Player.Character then
    PlayerStateController:AddCharacter(Player.Character) 
end

Player.CharacterAdded:Connect(function(character)
    PlayerStateController:AddCharacter(character)
end)

Player.CharacterAdded:Wait()

-- Handle player input
InputSystem:MapKeybinds()

-- TODO: SUPER DEBUG TEST
-- NOTE: DOWNLOAD DOUBLE BARREL SKINS
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        ToolSystem:StopAnimation("Idle", 1)
        ToolSystem:PlayAnimation("Reload", true)
        ToolSystem:PlayAnimation("Idle")
    end
end)