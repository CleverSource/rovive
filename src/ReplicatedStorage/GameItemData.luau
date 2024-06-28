-- The single source of truth for item data in the game.
local ItemData = {
    ["Wood"] = {
        MaxStack = 1000
    },

    ["Double Barrel"] = {
        Equipable = true
    }
}

for itemName, itemData in ItemData do
    itemData.Name = itemName

    if itemData.MaxStack == nil then
        itemData.MaxStack = 1
    end

    if itemData.Equipable == nil then
        itemData.Equipable = false
    end
end

table.freeze(ItemData)
return ItemData