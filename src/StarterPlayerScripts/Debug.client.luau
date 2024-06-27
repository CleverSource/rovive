-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)

-- Iris
local Iris = require(ReplicatedStorage.Packages.Iris).Init()

local windowSize = Iris.State(Vector2.new(300, 400))
local isWindowOpen = Iris.State(false)
local openKeybind = Enum.KeyCode.Q

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == openKeybind then
        isWindowOpen:set(not isWindowOpen:get())
    end
end)

Iris:Connect(function()
    local playerInventory: InventorySystem.InternalInventoryData = InventorySystem:GetInventoryFromObject(Players.LocalPlayer)

    Iris.Window({"Rovive Debug"}, {size = windowSize, isOpened = isWindowOpen})
        Iris.Text({"The current time is: " .. time()})

        if playerInventory ~= nil then
            Iris.Tree({"Local Inventory Data"})
                for i = 1, playerInventory.Data.InventorySlots do
                    if playerInventory.RawData[i] == nil then
                        Iris.Text({`Slot {i}: Empty`})
                    else
                        Iris.Text({`Slot {i}: {playerInventory.RawData[i].Name} x{playerInventory.RawData[i].Stack}`})
                    end
                end
            Iris.End()
        end
    Iris.End()
end)