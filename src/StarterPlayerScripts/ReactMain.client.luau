-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- React
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

-- Components
local Components = script.Parent:WaitForChild("Components")
local InventoryHolder = require(Components.Inventory.InventoryHolder)
local StoreContextProvider = require(Components.Store.StoreContextProvider)
local DragDropProvider = require(Components.DragDrop.DragDropProvider)
local Hotbar = require(Components.Inventory.Hotbar)
local ItemDropZone = require(Components.Inventory.ItemDropZone)

-- Store
local Store = require(ReplicatedStorage.Store)

-- Root
local handle = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
local root = ReactRoblox.createRoot(handle)

root:render(React.createElement("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0)
}, {
    StoreProvider = React.createElement(StoreContextProvider, {
        store = Store
    }, {
        DragDropProvider = React.createElement(DragDropProvider, nil, {
            -- Inventory
            Inventory = React.createElement("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
            }, {
                YourInventory = React.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0.9, -8),
                    Size = UDim2.new(1, 0, 0.34, 0)
                }, {
                    InventoryHolder = React.createElement(InventoryHolder)
                })
            }),

            -- Hotbar
            Hotbar = React.createElement(Hotbar),

            -- Drop zones (for dropping items from inventory)
            DropZones = React.createElement("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            }, {
                React.createElement(ItemDropZone, { -- Top zone
                    AnchorPoint = Vector2.new(0.5, 0),
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(1, 0, 0.5, 0)
                }),
                React.createElement(ItemDropZone, { -- Right zone
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.35, 0, 0.5, 0)
                }),
                React.createElement(ItemDropZone, { -- Left zone
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(0.35, 0, 0.5, 0)
                })
            })
        })
    }),
}))