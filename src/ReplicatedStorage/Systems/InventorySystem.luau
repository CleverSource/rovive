-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local DataObjects = ReplicatedStorage.DataObjects
local InventoryData = require(DataObjects.InventoryData)
local ItemData = require(DataObjects.ItemData)

-- Game Data
local GameItemData = require(ReplicatedStorage.GameItemData)

-- Store
local Store = require(ReplicatedStorage.Store).new()

-- InventorySystem
type _InternalInventoryData = {
    RawData: { [number]: ItemData.ItemData },
    Data: InventoryData.InventoryData
}
export type InternalInventoryData = _InternalInventoryData

local InventorySystem = {}

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

function InventorySystem:GetInventoryFromObject(inventoryObject: Instance): _InternalInventoryData
    local state = Store:GetState()
    local inventory = state.GlobalInventory
    local storeKey = self:GetDataKey(inventoryObject)

    return inventory[storeKey]
end

function InventorySystem:EquipItem(inventoryObject: Instance, slot: number)
    if inventoryObject:IsA("Player") then
        local state = Store:GetState()
        local inventory = state.GlobalInventory

        local storeKey = self:GetDataKey(inventoryObject)
        local inventoryData: _InternalInventoryData = inventory[storeKey]

        if slot > inventoryData.Data.InventorySlots then
            warn("InventorySystem: Attempted to equip item from slot that does not exist.")
            return
        end

        if inventoryData then
            local item = inventoryData.RawData[slot]
            if item ~= nil and GameItemData[item.Name].Equipable then
                inventoryObject:SetAttribute("EquippedSlot", slot)
            end
        end
    end
end

function InventorySystem:GetEquippedItemSlot(inventoryObject: Instance)
    if inventoryObject:IsA("Player") then
        return inventoryObject:GetAttribute("EquippedSlot")
    else
        return nil
    end
end

function InventorySystem:GetItemFromSlot(inventoryObject: Instance, slot: number)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData: _InternalInventoryData = inventory[storeKey]

    if inventoryData then
        return inventoryData.RawData[slot]
    else
        return nil
    end
end

function InventorySystem:AddItem(inventoryObject: Instance, slot: number, item: ItemData.ItemData)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData: _InternalInventoryData = inventory[storeKey]

    if GameItemData[item.Name] == nil then
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

return InventorySystem