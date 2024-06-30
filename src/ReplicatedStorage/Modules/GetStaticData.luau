-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Game Data
local GameItemData = require(ReplicatedStorage.GameItemData)

return function(itemName: string)
    local staticData = GameItemData[itemName]
    if not staticData then
        return nil
    end
    return staticData
end