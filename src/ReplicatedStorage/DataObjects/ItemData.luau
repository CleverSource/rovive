-- ItemData Data Object
local ItemData = {}
ItemData.__index = ItemData

export type ItemData = {
    Name: string,
    Stack: number,
}

function ItemData.new(name: string, stack: number)
    local item = setmetatable({}, ItemData)

    item.Name = name
    item.Stack = stack

    return item
end

return ItemData