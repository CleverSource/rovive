-- Main client setup script
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local ReplicateRemote = Remotes:Get("Replicate") 

-- Variables
local Player = Players.LocalPlayer

-- Systems
local Systems = script.Parent:WaitForChild("Systems")
local ToolSystem = require(Systems.ToolSystem)
local InputSystem = require(Systems.InputSystem)

-- ReplicatedStorage Systems
local RepSystems = ReplicatedStorage.Systems
local BulletSystem = require(RepSystems.BulletSystem)

-- Player State
local PlayerStateController = require(script.Parent.PlayerStateController)

-- Initialize player's character
if Player.Character then
    PlayerStateController:AddCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(character)
    PlayerStateController:AddCharacter(character)
end)

-- Remote events
ReplicateRemote:Connect(function(typeOfReplication, ...)
    local data = {...}
    if typeOfReplication == "BulletReplicate" then
        BulletSystem:ProjectileShoot(unpack(data))
    end
end)

task.spawn(function()
    task.wait(2)

    -- Handle player input
    InputSystem:MapKeybinds()

    InputSystem.OnStateChanged:Connect(function(state, value)
        if state == "Reload" and value == true then
            ToolSystem:Reload()
        end
    end)
end)