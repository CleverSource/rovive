-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Icons
local Icons = require(ReplicatedStorage.GameIcons)

local function DirtOverlay()
    return React.createElement("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 3,
        Image = Icons.DirtOverlay,
        ImageColor3 = Color3.new(1, 1, 1),
        ImageTransparency = 0.25,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 150, 0, 150),
    })
end

return DirtOverlay