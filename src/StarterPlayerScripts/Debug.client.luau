-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")

-- Iris
local Iris = require(ReplicatedStorage.Packages.Iris).Init()

local windowSize = Iris.State(Vector2.new(300, 400))
local isWindowOpen = Iris.State(false)
local openKeybind = Enum.KeyCode.Zero

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == openKeybind then
        isWindowOpen:set(not isWindowOpen:get())
    end
end)

local function count(tbl: table)
    local i = 0
    for _, _ in pairs(tbl) do
        i += 1
    end
    return i
end

Iris:Connect(function()
    local playerInventory: InventorySystem.InternalInventoryData = InventorySystem:GetInventoryFromObject(Players.LocalPlayer)
    local testCrateInventory: InventorySystem.InternalInventoryData = InventorySystem:GetInventoryFromObject(workspace:WaitForChild("TestCrate"))

    Iris.Window({"Rovive Debug"}, {size = windowSize, isOpened = isWindowOpen})
        Iris.Text({"The current time is: " .. time()})
        Iris.Text({`Equipped Item Slot: {InventorySystem:GetEquippedItemSlot(Players.LocalPlayer)}`})
        
        local input = Iris.InputText({"Inventory Slot"})
        if Iris.Button({"Equip Item"}).clicked() then
            InventorySystem:EquipItem(Players.LocalPlayer, tonumber(input.state.text.value))
            EquipItemRemote:SendToServer(input.state.text.value)
        end

        if Iris.Button({"Unequip Item"}).clicked() then
            InventorySystem:UnequipItem(Players.LocalPlayer)
            UnequipItemRemote:SendToServer()
        end

        if Iris.Button({"Screen Center Debug"}).clicked() then
            for _,v in pairs(workspace.CurrentCamera:GetDescendants()) do
                if v.Name == "ScreenCenter" then
                    v.Transparency = v.Transparency == 1 and 0 or 1
                end
            end
        end

        if testCrateInventory ~= nil then
            Iris.Tree({"Test Crate Data"})
                for i = 1, testCrateInventory.Data.InventorySlots do
                    if count(testCrateInventory.RawData[i]) == 0 then
                        Iris.Text({`Slot {i}: Empty`})
                    else
                        Iris.Text({`Slot {i}: {testCrateInventory.RawData[i].Name} x{testCrateInventory.RawData[i].Stack}`})
                    end
                end
            Iris.End()
        end

        if playerInventory ~= nil then
            Iris.Tree({"Local Inventory Data"})
                for i = 1, playerInventory.Data.InventorySlots do
                    if count(playerInventory.RawData[i]) == 0 then
                        Iris.Text({`Slot {i}: Empty`})
                    else
                        Iris.Text({`Slot {i}: {playerInventory.RawData[i].Name} x{playerInventory.RawData[i].Stack}`})
                    end
                end
            Iris.End()
        end
    Iris.End()
end)