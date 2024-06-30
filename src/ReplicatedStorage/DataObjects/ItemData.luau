-- ItemData Data Object
local ItemData = {}
ItemData.__index = ItemData

export type ItemData = {
    Name: string,
    Stack: number,
}

function ItemData.new(name: string, stack: number?, ammo: number?)
    local item = setmetatable({}, ItemData)

    item.Name = name
    item.Stack = stack or 1
    item.Ammo = ammo or 0

    return item
end

return ItemData