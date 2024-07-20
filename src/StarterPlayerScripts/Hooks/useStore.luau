-- NOTE: when using this hook, the inner component will only update when the client and server data are out of sync for the specific inventory
-- this means that the component will only update when the inventory data changes

-- React
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent:WaitForChild("Components")
local StoreContext = require(Components.Store.StoreContext)

-- Systems
local Systems = ReplicatedStorage.Systems
local InventorySystem = require(Systems.InventorySystem)

return function(innerComponent)
    local componentName = (`StoreConnection{tostring(innerComponent)}`)
    local connection = React.Component:extend(componentName)

    function connection:init(props)
        self.store = props.store
        self.lastUpdate = tick()

        if self.store == nil then
            error("Cannot initialize useStore connection without being a descendent of StoreProvider!")
        end

        local function updateState(state)
            local storeState = state
            local localDataKey = InventorySystem:GetDataKey(Players.LocalPlayer)
            local data = storeState.GlobalInventory[localDataKey]
            
            -- Only update when the client and server data are out of sync for the specific inventory
            if self.lastUpdate ~= data.Data.LastUpdate then
                self:setState({
                    storeData = data
                })
            end

            self.lastUpdate = data.Data.LastUpdate
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