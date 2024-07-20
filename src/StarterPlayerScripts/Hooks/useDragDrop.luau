-- React
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Components
local Components = script.Parent.Parent:WaitForChild("Components")
local DragDropContext = require(Components.DragDrop.DragDropContext)

return function(innerComponent)
    local componentName = (`DragDropConnection{tostring(innerComponent)}`)
    local connection = React.Component:extend(componentName)

    function connection:init(props)
        self.dropContext = props.dropContext

        if self.dropContext == nil then
            error("Cannot initialize useStore connection without being a descendent of StoreProvider!")
        end

        self:setState(self:computeProps())
    end

    function connection:computeProps()
        local computedProps = {
            renderProps = {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
            },
            dropContext = self.dropContext
        }
        for key, value in next, self.props do
            if key ~= "innerProps" and key ~= "children" then
                computedProps[key] = value
            end
        end
        for key, value in next, self.props.innerProps do
            if key ~= "innerProps" and key ~= "children" then
                computedProps[key] = value
            end
        end
        return computedProps
    end

    function connection:render()
        return React.createElement(innerComponent, self.state, self.props.innerProps.children)
    end

    local connectedComponent = React.Component:extend(componentName)

    function connectedComponent:render()
        return React.createElement(DragDropContext.Consumer, nil, function(dropContext)
            return React.createElement(connection, {
                innerProps = self.props,
                dropContext = dropContext
            })
        end)
    end

    return connectedComponent
end