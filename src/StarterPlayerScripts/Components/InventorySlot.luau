-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Modules
local CountTable = require(ReplicatedStorage.Modules.CountTable)
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Components
local Components = script.Parent
local InventoryIcon = require(Components.InventoryIcon)
local DirtOverlay = require(Components.DirtOverlay)

-- Icons
local Icons = require(ReplicatedStorage.GameIcons)

-- TODO: magical system for UI updates being handled PER item, not the entire inventory
local function InventorySlot(props)
    local item = props.item
    local isEmpty = CountTable(item) == 0

    local staticData = GetStaticData(item.Name)
    local isGun = staticData and staticData.WeaponType == "Gun"

    return React.createElement("ImageButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Image = Icons.InventorySlot,
        ImageColor3 = props.color or Color3.fromRGB(99, 99, 99),
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 90, 90),
    }, {
        DirtOverlay = React.createElement(DirtOverlay),
        Item = not isEmpty and React.createElement("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 2
        }, {
            InventoryIcon = React.createElement(InventoryIcon, {
                itemName = item.Name
            }),
            Stack = not isGun and item.Stack > 1 and React.createElement("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, -4, 0, -2),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 5,
                FontFace = Font.fromName(Enum.Font.Arimo.Name, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                Text = `x{tostring(item.Stack)}`,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 15,
                TextStrokeColor3 = Color3.new(0, 0, 0),
                TextStrokeTransparency = 0.7,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Bottom
            })
        }),
        Ammo = isGun and React.createElement("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(-0.075, -5, 0, -2),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 5,
            FontFace = Font.fromName(Enum.Font.Arimo.Name, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            Text = tostring(item.Ammo),
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 16,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.7,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Bottom
        }),
        table.unpack(React.Children.toArray(props.children))
    })
end

return InventorySlot