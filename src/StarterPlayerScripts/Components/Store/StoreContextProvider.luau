-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent
local StoreContext = require(Components.Store.StoreContext)

-- StoreContextProvider
local StoreContextProvider = React.Component:extend("StoreContextProvider")

function StoreContextProvider:init(props)
    self.store = props.store
end

function StoreContextProvider:render()
    return React.createElement(StoreContext.Provider, {
        value = self.store
    }, self.props.children)
end

return StoreContextProvider