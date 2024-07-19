-- React
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent:WaitForChild("Components")
local StoreContext = require(Components.StoreContext)

-- Systems
local Systems = ReplicatedStorage.Systems
local InventorySystem = require(Systems.InventorySystem)

return function(innerComponent)
    local componentName = (`StoreConnection{tostring(innerComponent)}`)
    local connection = React.Component:extend(componentName)

    function connection:init(props)
        self.store = props.store

        if self.store == nil then
            error("Cannot initialize useStore connection without being a descendent of StoreProvider!")
        end

        local function updateState(state)
            local storeState = state
            local localDataKey = InventorySystem:GetDataKey(Players.LocalPlayer)
            
            self:setState({
                data = storeState.GlobalInventory[localDataKey]
            })
        end

        updateState(self.store:GetState())
        self.store.OnStateChanged:Connect(updateState)
    end

    function connection:render()
        return React.createElement(innerComponent, self.state)
    end

    local connectedComponent = React.Component:extend(componentName)

    function connectedComponent:render()
        return React.createElement(StoreContext.Consumer, nil, function(store)
            return React.createElement(connection, {
                innerProps = self.props,
                store = store
            })
        end)
    end

    return connectedComponent
end