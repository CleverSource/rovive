-- Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local DataObjects = ReplicatedStorage.DataObjects
local InventoryData = require(DataObjects.InventoryData)
local ItemData = require(DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Systems
local EffectsSystem = require(ReplicatedStorage.Systems.EffectsSystem)

-- Game data
local GameItemData = require(ReplicatedStorage.GameItemData)

-- Store
local Store = require(ReplicatedStorage:WaitForChild("Store")).new()

-- Inventory System
local InventorySystem = {}

export type FetchedItemData = {
    Name: string,
    Data: ItemData.ItemData,
    StaticData: GameItemData.StaticData,
    InventoryObj: Instance,
    Slot: number
}

function InventorySystem:GetDataKey(inventoryObject: Instance)
    if inventoryObject:IsA("Player") then
        return tostring(inventoryObject.UserId)
    else
        return tostring(inventoryObject:GetFullName())
    end
end

function InventorySystem:InitializeInventory(inventoryData: InventoryData.InventoryData)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryData.InventoryObject)
    inventory[storeKey] = {
        RawData = {},
        Data = inventoryData
    }
    for i = 1, inventoryData.InventorySlots do
        inventory[storeKey].RawData[i] = {}
    end
    
    Store:SetState(state)
end

function InventorySystem:EquipItem(inventoryObject: Instance, slot: number)
    if inventoryObject:IsA("Player") then
        local inventoryData = self:GetInventoryFromObject(inventoryObject)

        if slot and slot > inventoryData.Data.InventorySlots then
            warn("InventorySystem: Attempted to equip item from slot that does not exist.")
            return
        end

        if inventoryData then
            local item = self:GetItemData(inventoryObject, slot)
            if item and item.StaticData.Equipable then
                inventoryObject:SetAttribute("EquippedSlot", slot)
            end
        end
    end
end

function InventorySystem:UnequipItem(inventoryObject: Instance)
    if inventoryObject:IsA("Player") then
        inventoryObject:SetAttribute("EquippedSlot", nil)
    end
end

function InventorySystem:GetEquippedItemSlot(inventoryObject: Instance)
    if inventoryObject:IsA("Player") then
        return inventoryObject:GetAttribute("EquippedSlot")
    else
        return nil
    end
end

function InventorySystem:GetInventoryFromObject(inventoryObject: Instance)
    local state = Store:GetState()
    local inventory = state.GlobalInventory
    local storeKey = self:GetDataKey(inventoryObject)

    return inventory[storeKey]
end

-- TODO: hella testing
function InventorySystem:AddItem(inventoryObject: Instance, item: ItemData.ItemData)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData = inventory[storeKey]

    if inventoryData then
        -- Check if other items in inventory of same name
        -- if true, add to stack, if possible
        -- if not possible, check if remainder is possible, and add to full on that stack, and create new inventory item of remainder
        -- if not possible, create completely new inventory item
        -- If no other stacks of name exist, then create completely new item
        -- If inventory is full, decline adding item

        local stackType = item.Name
        local bestStacks = self:GetBestStacks(inventoryObject, stackType)
        for _, stack in ipairs(bestStacks) do
            if stack.Data.Stack < stack.StaticData.MaxStack then
                local remainder = stack.StaticData.MaxStack - stack.Data.Stack
                if item.Stack <= remainder then
                    stack.Data.Stack = stack.Data.Stack + item.Stack
                    self:Update(stack)
                else
                    stack.Data.Stack = stack.StaticData.MaxStack
                    item.Stack = item.Stack - remainder
                    self:Update(stack)
                end
            end
        end

        self:AddNewItem(inventoryObject, item)
    end
end

function InventorySystem:IsInventoryFull(inventoryObject: Instance)
    local inventoryData = self:GetInventoryFromObject(inventoryObject)
    for _, item in inventoryData.RawData do
        if item.Name == nil then
            return false
        end
    end
    return true
end

function InventorySystem:IsInventoryTrulyFull(inventoryObject: Instance)
    if self:IsInventoryFull(inventoryObject) then
        for _, item in self:GetInventoryFromObject(inventoryObject) do
            print(item)
        end
    end
end

function InventorySystem:AddNewItem(inventoryObject: Instance, item: ItemData.ItemData, slot: number?)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData = inventory[storeKey]

    if GetStaticData(item.Name) == nil then
        warn("InventorySystem: Attempted to add item that does not exist in GameItemData.")
        return
    end

    if slot then
        if slot > inventoryData.Data.InventorySlots then
            warn("InventorySystem: Attempted to add item to slot that does not exist.")
            return
        end
    else
        for i = 1, inventoryData.Data.InventorySlots do
            if inventoryData.RawData[i].Name == nil then
                slot = i
            end
        end
    end

    if slot == nil then
        item.ItemId = HttpService:GenerateGUID(false)
        EffectsSystem:MakeDroppedItem(self:CreateItemData(item, inventoryObject, nil))
        return
    end

    if inventoryData then
        inventoryData.RawData[slot] = item
        Store:SetState(state)
    else
        warn("InventorySystem: Attempted to add item to non-existent inventory.")
    end
end

function InventorySystem:GetBestStacks(inventoryObject: Instance, stackType: string)
    local inventoryData = self:GetInventoryFromObject(inventoryObject)

    local bestStacks = {}
    for slot, itemData in inventoryData.RawData do
        local staticData = GetStaticData(itemData.Name)
        if itemData.Name == stackType and staticData.MaxStack > 1 then
            table.insert(bestStacks, self:GetItemData(inventoryObject, slot))
        end
    end
    return bestStacks
end

function InventorySystem:CreateItemData(item: ItemData.ItemData, inventoryObject: Instance, slot: number): FetchedItemData
    return {
        Name = item.Name,
        Data = item,
        StaticData = GetStaticData(item.Name),
        InventoryObj = inventoryObject,
        Slot = slot
    }
end

function InventorySystem:GetItemData(inventoryObject: Instance, slot: number): () -> FetchedItemData
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData = inventory[storeKey]

    local item = inventoryData.RawData[slot]
    if item and item.Name ~= nil then
        return self:CreateItemData(item, inventoryObject, slot)
    end

    return nil
end

function InventorySystem:Update(itemData: FetchedItemData)
    local inventoryObj = itemData.InventoryObj
    local slot = itemData.Slot
    
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObj)
    local inventoryData = inventory[storeKey]
    local item = inventoryData.RawData[slot]

    if item then
        inventoryData.RawData[slot] = itemData.Data
        Store:SetState(state)
    end
end

return InventorySystem