-- Main client setup script
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local Player = Players.LocalPlayer

-- Systems
local Systems = script.Parent:WaitForChild("Systems")
local ToolSystem = require(Systems.ToolSystem)
local InputSystem = require(Systems.InputSystem)

-- Player State
local PlayerStateController = require(script.Parent.PlayerStateController)

-- Initialize player's character
if Player.Character then
    PlayerStateController:AddCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(character)
    PlayerStateController:AddCharacter(character)
end)

task.spawn(function()
    task.wait(2)

    -- Handle player input
    InputSystem:MapKeybinds()

    InputSystem.OnStateChanged:Connect(function(state, value)
        if state == "Reload" and value == true then
            ToolSystem:Reload()
        elseif state == "Fire" and value == true then
            -- Gun shooting
            if ToolSystem:IsReadyToFire() and ToolSystem:GetWeaponType() == "Gun" and not PlayerStateController:CharacterIsNearWall() then
                ToolSystem:Fire()
            else
                InputSystem:ForceStopAction("Fire")
            end
        end
    end)
end)