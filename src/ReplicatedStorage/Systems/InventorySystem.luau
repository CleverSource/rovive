-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local DataObjects = ReplicatedStorage.DataObjects
local InventoryData = require(DataObjects.InventoryData)
local ItemData = require(DataObjects.ItemData)

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
        inventory[storeKey].RawData[i] = nil
    end
    
    Store:SetState(state)
end

function InventorySystem:GetInventoryFromObject(inventoryObject: Instance)
    local store = Store:GetState()
    local inventory = store.GlobalInventory
    local storeKey = self:GetDataKey(inventoryObject)

    return inventory[storeKey]
end

function InventorySystem:AddItem(inventoryObject: Instance, slot: number, item: ItemData.ItemData)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    local inventoryData: _InternalInventoryData = inventory[storeKey]

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