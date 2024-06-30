-- Main client setup script
-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Variables
local Player = Players.LocalPlayer

-- Systems
local ToolSystem = require(script.Parent.Systems.ToolSystem)
local InputSystem = require(script.Parent.Systems.InputSystem)

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
-- TODO: DOWNLOAD DOUBLE BARREL SKINS
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        ToolSystem:StopAnimation("Idle", 1)
        ToolSystem:PlayAnimation("Reload", true)
        require(script.Parent.Systems.InputSystem):ForceStopAction("Reload")
        ToolSystem:PlayAnimation("Idle")
    end
end)