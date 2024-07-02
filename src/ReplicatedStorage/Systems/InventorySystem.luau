-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local DataObjects = ReplicatedStorage.DataObjects
local InventoryData = require(DataObjects.InventoryData)
local ItemData = require(DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

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

function InventorySystem:AddNewItem(inventoryObject: Instance, slot: number, item: ItemData.ItemData)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData = inventory[storeKey]

    if GetStaticData(item.Name) == nil then
        warn("InventorySystem: Attempted to add item that does not exist in GameItemData.")
        return
    end

    if slot > inventoryData.Data.InventorySlots then
        warn("InventorySystem: Attempted to add item to slot that does not exist.")
        return
    end

    if inventoryData then
        inventoryData.RawData[slot] = item
        Store:SetState(state)
    else
        warn("InventorySystem: Attempted to add item to non-existent inventory.")
    end
end

function InventorySystem:GetAmmoStacks(inventoryObject: Instance, ammoType: string)
    local inventoryData = self:GetInventoryFromObject(inventoryObject)

    local bestStacks = {}
    for slot, itemData in inventoryData.RawData do
        if itemData.Name == ammoType then
            table.insert(bestStacks, self:GetItemData(inventoryObject, slot))
        end
    end
    return bestStacks
end

function InventorySystem:GetItemData(inventoryObject: Instance, slot: number): () -> FetchedItemData
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData = inventory[storeKey]

    local item = inventoryData.RawData[slot]
    if item and item.Name ~= nil then
        return {
            Name = item.Name,
            Data = item,
            StaticData = GetStaticData(item.Name),
            InventoryObj = inventoryObject,
            Slot = slot
        }
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