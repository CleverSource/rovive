-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Game Data
local GameItemData = require(ReplicatedStorage.GameItemData)

return function(itemName: string)
    local staticData = GameItemData[itemName]
    if not staticData then
        warn("Attempted to fetch static data:", itemName)
    end
    return staticData
end