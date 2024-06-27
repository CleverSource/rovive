-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local GetStateRemote = Remotes:Get("GetState")
local StateChangedRemote = Remotes:Get("StateChanged")

-- Client store
local ServerStore = require(script.Parent.Server)
local Store = nil

GetStateRemote:CallServerAsync()
        :andThen(function(state)
            Store = ServerStore.new()
            Store:SetState(state)

            StateChangedRemote:Connect(function(newState)
                Store:SetState(newState)
            end)
        end)
        :await()

return Store