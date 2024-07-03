-- Services
local HttpService = game:GetService("HttpService")

-- ItemData Data Object
local ItemData = {}
ItemData.__index = ItemData

export type ItemData = {
    Name: string,
    Stack: number,
    Ammo: number?,
    ItemId: string
}

function ItemData.new(name: string, stack: number?, ammo: number?)
    local item = setmetatable({}, ItemData)

    item.Name = name
    item.Stack = stack or 1
    item.Ammo = ammo or 0
    item.ItemId = HttpService:GenerateGUID(false)

    return item
end

return ItemData