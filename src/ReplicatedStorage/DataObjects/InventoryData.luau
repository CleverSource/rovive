-- InventoryData Data Object
local InventoryData = {}
InventoryData.__index = InventoryData

export type InventoryData = {
    InventoryObject: Instance,
    InventorySlots: number,
    LastUpdate: number
}

function InventoryData.new(inventoryObject: Instance, inventorySlots: number)
    local inventory = setmetatable({}, InventoryData)

    inventory.InventoryObject = inventoryObject
    inventory.InventorySlots = inventorySlots
    inventory.LastUpdate = tick()

    return inventory
end

return InventoryData