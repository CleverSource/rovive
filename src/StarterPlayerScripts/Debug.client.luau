-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local InputSystem = require(script.Parent.Systems.InputSystem)
local ToolSystem = require(script.Parent.Systems.ToolSystem)

-- Packages
local FastCast = require(ReplicatedStorage.Packages.FastCast)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")
local DropItemRemote = Remotes:Get("DropItem")

-- Assets
local Assets = ReplicatedStorage.Assets
local DebugHud = Assets.DebugHud

-- Variables
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Iris
local Iris = require(ReplicatedStorage.Packages.Iris).Init()

local windowSize = Iris.State(Vector2.new(300, 400))
local isWindowOpen = Iris.State(false)
local debugHudRef = Iris.State(nil)
local openKeybind = Enum.KeyCode.Zero

-- TODO: possibly make this available via admin commands
-- or based on group rank, idk
local Devs = {
    ["47248306"] = true, -- CleverSource
    ["472765608"] = true -- baydocks
}

if Devs[tostring(Players.LocalPlayer.UserId)] == nil then
    return
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == openKeybind and Devs[tostring(Players.LocalPlayer.UserId)] then
        isWindowOpen:set(not isWindowOpen:get())
    end
end)

task.spawn(function()
    task.wait()
    if PlayerGui:FindFirstChild(DebugHud.Name) == nil and Devs[tostring(Players.LocalPlayer.UserId)] then
        local debugHudClone = DebugHud:Clone()
        debugHudClone.Parent = PlayerGui
        debugHudRef:set(debugHudClone)

        -- Debug Hud
        task.spawn(function()
            while task.wait() do
                local activeItem = ToolSystem.CurrentItem
                if activeItem ~= nil then
                    local gunNameLabel = debugHudClone.Weapon.NameLabel
                    local ammoLabel = debugHudClone.Weapon.AmmoLabel
                    local staticData = GetStaticData(activeItem.Name)
                    gunNameLabel.Text = activeItem and ToolSystem.CurrentItem.Name or "nil"

                    if staticData and staticData.MaxAmmo then
                        ammoLabel.Visible = true
                        ammoLabel.Text = activeItem and `<b>{ToolSystem.CurrentItem.Ammo}</b> / <i>{staticData.MaxAmmo}</i>`
                    else
                        ammoLabel.Text = "nil"
                    end
                end
            end
        end)
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
    local playerInventory = InventorySystem:GetInventoryFromObject(Players.LocalPlayer)
    local testCrateInventory = InventorySystem:GetInventoryFromObject(workspace:WaitForChild("TestCrate"))

    Iris.Window({"Rovive Debug"}, {size = windowSize, isOpened = isWindowOpen})
        Iris.Text({`Most Important State: {InputSystem:GetImportantState()}`})

        Iris.Tree({"State Data"})
            for state, data in pairs(InputSystem.States) do
                Iris.Text({`{state}: {data}`})
            end
        Iris.End()

        Iris.Text({`Shoot Tick: {ToolSystem.LastFireTick}`})
        Iris.Text({`Hip Fire: {InputSystem:IsStateActive("Aim") == false}`})
        Iris.Text({`Equipped Item Slot: {InventorySystem:GetEquippedItemSlot(Players.LocalPlayer)}`})
        local debugWorkspace = workspace:FindFirstChild("Debug")
        if debugWorkspace then
            local dummy = debugWorkspace:FindFirstChild("Dummy")
            if dummy then
                Iris.Text({`Dummy Health: {dummy.Dummy.Humanoid.Health}`})
            end
        end
        
        local input = Iris.InputText({"Inventory Slot"})
        if Iris.Button({"Equip Item"}).clicked() then
            if input.state.text.value ~= nil then
                InventorySystem:EquipItem(Players.LocalPlayer, tonumber(input.state.text.value))
                EquipItemRemote:SendToServer(input.state.text.value)
            end
        end

        if Iris.Button({"Unequip Item"}).clicked() then
            InventorySystem:UnequipItem(Players.LocalPlayer)
            UnequipItemRemote:SendToServer()
        end

        if Iris.Button({"Drop Item"}).clicked() then
            DropItemRemote:SendToServer(input.state.text.value)
        end

        if Iris.Button({"Drop All Items"}).clicked() then
            for i = 1, playerInventory.Data.InventorySlots do
                DropItemRemote:SendToServer(i)
            end
        end

        if Iris.Button({"Toggle Debug Hud"}).clicked() then
            local debugHud = debugHudRef:get()
            debugHud.Enabled = not debugHud.Enabled
        end

        if Iris.Button({`{FastCast.VisualizeCasts == false and "Enable" or "Disable"} Bullet Rays`}).clicked() then
            local fastCastObjects = workspace.Terrain:FindFirstChild("FastCastVisualizationObjects")
            if fastCastObjects then
                fastCastObjects:Destroy()
            end
            FastCast.VisualizeCasts = not FastCast.VisualizeCasts
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
                for i, data in ipairs(playerInventory.RawData) do
                    if count(data) == 0 then
                        Iris.Text({`Slot {i}: Empty`})
                    else
                        Iris.Text({`Slot {i}: {data.Name} x{data.Stack}`})
                    end
                end
                -- for i = 1, playerInventory.Data.InventorySlots do
                --     if count(playerInventory.RawData[i]) == 0 then
                --         Iris.Text({`Slot {i}: Empty`})
                --     else
                --         Iris.Text({`Slot {i}: {playerInventory.RawData[i].Name} x{playerInventory.RawData[i].Stack}`})
                --     end
                -- end
            Iris.End()
        end
    Iris.End()
end)