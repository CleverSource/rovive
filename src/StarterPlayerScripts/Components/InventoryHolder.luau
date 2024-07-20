-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Hooks
local Hooks = script.Parent.Parent:WaitForChild("Hooks")
local useStore = require(Hooks.useStore)

-- Components
local Components = script.Parent
local InventorySlot = require(Components.InventorySlot)

-- InventoryHolder
-- TODO
local RESERVED_INVENTORY_SLOTS = 24
local SLOTS_PER_ROW = 6

local function InventoryHolder(props)
    local inventoryData = props.storeData
    
    local rows = {}

    for row = 1, (RESERVED_INVENTORY_SLOTS / SLOTS_PER_ROW) do
        local columns = {}

        for col = 1, SLOTS_PER_ROW do
            local slotNumber = (row - 1) * SLOTS_PER_ROW + col
            columns[col] = React.createElement(InventorySlot, {
                item = inventoryData.RawData[slotNumber]
            })
        end

        rows[row] = React.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0.25, 0)
        }, {
            ListLayout = React.createElement("UIListLayout", {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.Name,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            }),
            SizeConstraint = React.createElement("UISizeConstraint", {
                MaxSize = Vector2.new(math.huge, 80),
                MinSize = Vector2.new(0, 0)
            }),
            table.unpack(columns)
        })
    end
    
    return React.createElement("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0)
    }, {
        ListLayout = React.createElement("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.Name,
            VerticalAlignment = Enum.VerticalAlignment.Bottom, 
        }),
        table.unpack(rows)
    })
end

return useStore(InventoryHolder)