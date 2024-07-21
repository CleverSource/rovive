-- Services
local Players = game:GetService("Players")

-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Modules
local CountTable = require(ReplicatedStorage.Modules.CountTable)
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local MoveItemRemote = Remotes:Get("MoveItem")

-- Components
local Components = script.Parent.Parent
local InventoryIcon = require(Components.Inventory.InventoryIcon)
local DirtOverlay = require(Components.Generic.DirtOverlay)
local DroppableFrame = require(Components.DragDrop.DroppableFrame)
local DraggableFrame = require(Components.DragDrop.DraggableFrame)

-- Systems
local Systems = ReplicatedStorage.Systems
local InventorySystem = require(Systems.InventorySystem)

-- Variables
local Player = Players.LocalPlayer

-- Icons
local Icons = require(ReplicatedStorage.GameIcons)

-- TODO: magical system for UI updates being handled PER item, not the entire inventory
local function InventorySlot(props)
    local item = props.item
    local slot = props.slot
    local isEmpty = CountTable(item) == 0

    local staticData = GetStaticData(item.Name)
    local isGun = staticData and staticData.WeaponType == "Gun"

    local inventorySlotRef = React.useRef(nil)

    local dragging, setDragging = React.useState(false)
    
    return React.createElement(DroppableFrame, {
        dropId = "InventorySlot",
        dropRef = inventorySlotRef,
        onTargetDropped = function(data, gui)
            if data == slot then
                return
            end
            print(`{data} -> {slot}`)
            InventorySystem:MoveItem(Player, data, slot)
            MoveItemRemote:SendToServer(data, slot)
        end,
        renderProps = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
        }
    }, {
        React.createElement("ImageButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Image = Icons.InventorySlot,
            ImageColor3 = props.color or Color3.fromRGB(99, 99, 99),
            ImageTransparency = 0.3,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(10, 10, 90, 90),
            ref = inventorySlotRef
        }, {
            DirtOverlay = React.createElement(DirtOverlay),
            Icon = not isEmpty and React.createElement(DraggableFrame, {
                dropId = { "InventorySlot", "DropZone" },
                targetRef = inventorySlotRef,
                targetData = slot,
                dragBegin = function()
                    setDragging(true)
                end,
                dragEnd = function()
                    setDragging(false)
                end,
                renderProps = {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                }
            }, {
                Item = React.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = not dragging and UDim2.new(1, 0, 1, 0) or UDim2.new(0, inventorySlotRef.current.AbsoluteSize.X + 20, 0, inventorySlotRef.current.AbsoluteSize.Y + 20),
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
            }),
            Ammo = isGun and not dragging and React.createElement("TextLabel", {
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
    })
end

return InventorySlot