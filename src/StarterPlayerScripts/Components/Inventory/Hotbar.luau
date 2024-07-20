-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Hooks
local Hooks = script.Parent.Parent.Parent:WaitForChild("Hooks")
local useStore = require(Hooks.useStore)

-- Components
local Components = script.Parent
local InventorySlot = require(Components.InventorySlot)

-- TODO
local RESERVED_INVENTORY_SLOTS = 24
local SLOTS_PER_ROW = 6

local function Hotbar(props)
    local inventoryData = props.storeData
    
    local column = {}

    for i = 1, SLOTS_PER_ROW do
        local slotNumber = i + RESERVED_INVENTORY_SLOTS

        column[i] = React.createElement(InventorySlot, {
            item = inventoryData.RawData[slotNumber],
            color = inventoryData.Data.EquippedSlot == slotNumber and Color3.fromRGB(87, 137, 255) or Color3.fromRGB(129, 129, 129),
        }, {
            -- TODO
            Keybind = React.createElement("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, -2),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 5,
                FontFace = Font.fromName("PressStart2P", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                Text = tostring(i),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 17,
                TextStrokeColor3 = Color3.new(0, 0, 0),
                TextStrokeTransparency = 0.7,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top
            })
        })
    end

    return React.createElement("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -5),
        Size = UDim2.new(1, 0, 0.085, 0)
    }, {
        ListLayout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.Name,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        }),
        SizeConstraint = React.createElement("UISizeConstraint", {
            MaxSize = Vector2.new(math.huge, 80),
            MinSize = Vector2.new(0, 0)
        }),
        table.unpack(column)
    })
end

return useStore(Hotbar)