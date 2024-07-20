-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- GameItemData
local GameItemData = require(ReplicatedStorage.GameItemData)

-- Icons
local Icons = require(ReplicatedStorage.GameIcons)

local function InventoryIcon(props)
    local itemName = props.itemName
    local itemData = GameItemData[itemName]

    return React.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.475, 0, 0.5, 0),
        Size = UDim2.new(0.75, 0, 0.75, 0),
        ZIndex = 4,
        Image = itemData.Icon or Icons.Null,
        ImageColor3 = Color3.new(1, 1, 1),
        ScaleType = Enum.ScaleType.Stretch
    })
end

return InventoryIcon