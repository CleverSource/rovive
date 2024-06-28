-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Game Data
local GameItemData = require(ReplicatedStorage.GameItemData)

return function(itemName: string)
    local staticData = GameItemData[itemName]
    return staticData
end