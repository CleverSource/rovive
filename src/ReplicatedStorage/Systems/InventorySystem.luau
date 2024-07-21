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
        local state, inventoryData = self:GetStateAndInventoryData(inventoryObject)

        if slot and slot > inventoryData.Data.InventorySlots then
            warn("InventorySystem: Attempted to equip item from slot that does not exist.")
            return
        end

        if inventoryData then
            local item = self:GetItemData(inventoryObject, slot)
            if item and item.StaticData.Equipable then
                inventoryData.Data.EquippedSlot = slot
                inventoryObject:SetAttribute("EquippedSlot", slot)
                self:UpdateInventoryState(state, inventoryData)
            end
        end
    end
end

function InventorySystem:UnequipItem(inventoryObject: Instance)
    if inventoryObject:IsA("Player") then
        local state, inventoryData = self:GetStateAndInventoryData(inventoryObject)

        inventoryData.Data.EquippedSlot = nil
        inventoryObject:SetAttribute("EquippedSlot", nil)
        self:UpdateInventoryState(state, inventoryData)
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
    local _, inventoryData = self:GetStateAndInventoryData(inventoryObject)

    if inventoryData then
        -- Check if other items in inventory of same name
        -- if true, add to stack, if possible
        -- if not possible, check if remainder is possible, and add to full on that stack, and create new inventory item of remainder
        -- if not possible, create completely new inventory item
        -- If no other stacks of name exist, then create completely new item
        -- If inventory is full, decline adding item

        local stackType = item.Name
        local bestStacks = self:GetBestStacks(inventoryObject, stackType)
        local stackToAdd = item.Stack

        for _, stack in ipairs(bestStacks) do
            if stackToAdd <= 0 then break end

            if stack.Data.Stack < stack.StaticData.MaxStack then
                local remainder = stack.StaticData.MaxStack - stack.Data.Stack
                if item.Stack <= remainder then
                    stack.Data.Stack = stack.Data.Stack + item.Stack
                    self:Update(stack)
                    stackToAdd = 0
                else
                    stack.Data.Stack = stack.StaticData.MaxStack
                    item.Stack = item.Stack - remainder
                    self:Update(stack)
                    stackToAdd = item.Stack
                end
            end
        end

        if stackToAdd > 0 then
            self:AddNewItem(inventoryObject, item)
        end
    end
end

function InventorySystem:MoveItem(inventoryObject: Instance, fromSlot: number, toSlot: number)
    local state, inventoryData = self:GetStateAndInventoryData(inventoryObject)

    if fromSlot == toSlot then
        return
    end

    if fromSlot > inventoryData.Data.InventorySlots or toSlot > inventoryData.Data.InventorySlots then
        warn("InventorySystem: Attempted to move item to/from slot that does not exist.")
        return
    end

    local fromItem = self:GetItemData(inventoryObject, fromSlot)
    local toItem = self:GetItemData(inventoryObject, toSlot)

    local equippedSlot = self:GetEquippedItemSlot(inventoryObject)

    -- Unequip items if they are in the fromSlot or toSlot
    if equippedSlot == fromSlot or equippedSlot == toSlot then
        self:UnequipItem(inventoryObject)
    end

    if fromItem and fromItem.Data.Name then
        if toItem and toItem.Data.Name then
            if fromItem.Name == toItem.Name then
                -- Same item, handle stacking
                local totalStack = fromItem.Data.Stack + toItem.Data.Stack
                local maxStack = fromItem.StaticData.MaxStack

                if totalStack <= maxStack then
                    -- All items fit into toSlot
                    toItem.Data.Stack = totalStack
                    self:Update(toItem)
                    inventoryData.RawData[fromSlot] = {}
                else
                    -- Only some items fit into the toSlot
                    toItem.Data.Stack = maxStack
                    self:Update(toItem)
                    fromItem.Data.Stack = totalStack - maxStack
                    self:Update(fromItem)
                end
            else
                -- Different items, swap item
                inventoryData.RawData[fromSlot], inventoryData.RawData[toSlot] = inventoryData.RawData[toSlot], inventoryData.RawData[fromSlot]
            end
        else
            -- Move item to an empty slot
            inventoryData.RawData[toSlot] = inventoryData.RawData[fromSlot]
            inventoryData.RawData[fromSlot] = {}
        end
        self:UpdateInventoryState(state, inventoryData)
    else
        warn("InventorySystem: Attempted to move item from an empty slot.")
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

-- function InventorySystem:IsInventoryTrulyFull(inventoryObject: Instance)
--     if self:IsInventoryFull(inventoryObject) then
--         for _, item in self:GetInventoryFromObject(inventoryObject) do
--             print(item)
--         end
--     end
-- end

function InventorySystem:AddNewItem(inventoryObject: Instance, item: ItemData.ItemData, slot: number?)
    local state, inventoryData = self:GetStateAndInventoryData(inventoryObject)

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
                break
            end
        end
    end

    if slot == nil and inventoryObject ~= nil then
        item.ItemId = HttpService:GenerateGUID(false)
        EffectsSystem:MakeDroppedItem(self:CreateItemData(item, inventoryObject, nil))
        return
    end

    if inventoryData then
        inventoryData.RawData[slot] = item
        self:UpdateInventoryState(state, inventoryData)
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
    local _, inventoryData = self:GetStateAndInventoryData(inventoryObject)

    local item = inventoryData.RawData[slot]
    if item and item.Name ~= nil then
        return self:CreateItemData(item, inventoryObject, slot)
    end

    return nil
end

function InventorySystem:Update(itemData: FetchedItemData)
    local inventoryObj = itemData.InventoryObj
    local slot = itemData.Slot
    
    local state, inventoryData = self:GetStateAndInventoryData(inventoryObj)
    local item = inventoryData.RawData[slot]

    if item then
        inventoryData.RawData[slot] = itemData.Data
        self:UpdateInventoryState(state, inventoryData)
    end
end

function InventorySystem:UpdateInventoryState(state, inventoryData)
    inventoryData.Data.LastUpdate = tick()
    Store:SetState(state)
end

function InventorySystem:GetStateAndInventoryData(inventoryObject: Instance)
    local state = Store:GetState()
    local inventory = state.GlobalInventory

    local storeKey = self:GetDataKey(inventoryObject)
    return state, inventory[storeKey]
end

return InventorySystem